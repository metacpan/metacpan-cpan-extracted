package Data::Tree::Describe;

=head1 NAME

Data::Tree::Describe - Create annotated versions of complex data trees

=head1 WARNING

This module is in active development and has been uploaded simply as part of a 
standard and automated release procedure.

If you have any ideas for what would be helpful to implement, please contact the 
author!

=head1 SYNOPSIS

=for comment Small howto

    use Data::Tree::Describe;

    my $data_object = {test=>['some','stuff']};

    my $described_tree = Data::Tree::Describe->new($data_object);

=head1 DESCRIPTION

=for comment The module's description.

This module was originally developed for data trees or objects created from 
json::maybexs, though it technically will work on any perl data tree.

The module is fairly heavy processing wise and recursively iterates through a 
tree determining the type for every node as well as other handy attributes such
as how many children are in any HASH or ARRAY type. 

=cut

# Internal perl
use v5.30.0;

# Internal perl modules (core)
use strict;
use warnings;

# Internal perl modules (core,recommended)
use utf8;
use experimental qw(signatures);

# External modules
use Carp qw(cluck croak longmess shortmess);

# Version of this software
our $VERSION = '0.009';

=head1 METHODS

Callable methods

=head2 new

Create a new annotated data tree

Takes 1 argument an $object

BEWARE large objects will take some time to be processed.

=cut

# Primary code block
sub new($class,$input = {}) {

    my $self = bless {
        source  =>  $input,
        paths   =>  []
    }, $class;

    $self->{tree} = $self->_digest($input);
    return $self; 
}

=head2 paths_list

Return a list of all paths in the format: [element,element,element],[element,element]

Of the list returned, the first element [0] will always have a blank 'child name'
as it is representative of the parent node.

=cut 

# Reverse this as due to the way the recursion works, the base element is
# returned first.
sub paths_list($self) {
    return reverse @{$self->{paths}};
}

=head2 extract

Return a block of data starting from the point specified.

Accepts 1 argument; the path in the format of a list ['some_node',3,'element']

If you pass a blank or undefined list to the function it will return the entire
tree, as it will presume you are selecting the root/base node.

=cut

sub extract($self,$path = []) {
    if (ref($path) ne 'ARRAY') { croak 'Passed non-array value to extract' }
    croak 'Not implemented';
}

# This is the main worker routing that loops through the data structure
sub _digest($self,$tree,$stash = { depth=>0 }) {
    my $type    =   ref($tree) ? ref($tree) : 'ELEMENT';

    my @json_path       =   ();
    if ($stash->{path}) {
        @json_path  =   @{delete $stash->{path}};
    }

    # Handle booleans more nicely, I imagine there are more of these to deal with
    if ($type =~ m/Bool/i)   {
        $type = 'BOOLEAN';
    }

    # Dependant on the type of item recurse over them correctly
    if      ($type eq 'HASH')   {
        $stash->{_count}    =   scalar(keys %{$tree});
        foreach my $child (keys %{$tree})   { 
            my @passed_path             =   (@json_path,$child);
            my $depth                   =   $stash->{depth};
            $stash->{_data}->{$child}   =
                $self->_digest(
                    $tree->{$child},
                    { 
                        path    =>  [@passed_path], 
                        depth   =>  scalar(@passed_path)
                    }
                );
        }
    }
    elsif   ($type eq 'ARRAY')  {
        my $index = 0;
        $stash->{_count}    =   scalar(@{$tree});
        foreach my $child (@{$tree})        {
            my @passed_path             =   (@json_path,$index++);
            # You can have unnamed HASH elements within an ARRAY
            # For this we will change the hash-memory-reference to simply HASH
            if (ref($child) eq 'HASH') {
                $stash->{_data}->{HASH}     =
                    $self->_digest(
                        $child,
                        { 
                            path    =>  [@passed_path],
                            depth   =>  scalar(@passed_path)
                        }
                    ); 
            }
            else {
                $stash->{_data}->{$child}   =
                    $self->_digest(
                        $child,
                        { 
                            path    =>  [@passed_path],
                            depth   =>  scalar(@passed_path)
                        }
                    );
            }
        }
    }

    # Add in additional details about this node
    $stash->{_type}     =   $type;
    $stash->{_key}      =   $json_path[-1];
    $stash->{_path}     =   [@json_path];
    $stash->{_depth}    =   delete $stash->{depth};

    push(@{$self->{paths}},$stash->{_path});

    return $stash;
}


=head1 CORROSPONDANCE

Regarding bugs, featuire requests, patches, forks or other please view 
the project on github here L<https://github.com/PaulGWebster/p5-Data-Tree-Describe>

=head1 AUTHOR

Paul G Webster <daemon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Paul G Webster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
