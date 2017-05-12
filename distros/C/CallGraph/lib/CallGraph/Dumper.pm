package CallGraph::Dumper;

$VERSION = '0.55';

use strict;
use warnings;
use Carp;

=head1 NAME

CallGraph::Dumper - Dump a call graph into a string representation

=head1 SYNOPSIS

    my $dumper = CallGraph::Dumper->new(root => $root, 
        indent => 8, dups => 0);
    print $dumper->dump;

=head1 DESCRIPTION

This module dumps a call graph into a string representation. The output
looks something like this:

    MAIN
            EXTSUB *
    1       SUB1
                    SUB11
                    SUB12
            SUB2
                    SUB1 (1)
                    SUB21

This means that MAIN calls EXTSUB, which is labeled with an asterisk because it
is external (meaning it is not defined within the program that was parsed),
SUB1, and SUB2. SUB1 calls SUB11 and SUB12. SUB2 calls SUB1; to avoid
duplication, a link is made by labeling SUB1 with a 1. This is the default
behavior, with 'dups' => 0. When dups => 1, the branch is duplicated:

    MAIN
            EXTSUB *
            SUB1
                    SUB11
                    SUB12
            SUB2
                    SUB1
                            SUB11
                            SUB12
                    SUB21

In case of recursion, the label system is used even with dups => 1, to avoid
an endless loop.

=head1 METHODS

=over

=item my $sub = CallGraph::Dumper->new(root => $root, option => value, ...)

Creates a new dumper. The root option must be given and it must be a 
CallGraph::Node object. The other options are the following:

=over

=item indent
    
The number of spaces to indent each call level. The default is 8.

=item dups

If true, duplicate a branch that has already been called. If false, 
place a level pointing to the first place where the branch was defined.
The default is false.

=back

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        indent => 8,
        dups => 0,
        %opts,
    }, ref $class || $class;
    unless ($self->{root}) { croak "${class}->new: unspecified 'root'" }
    $self->init;
    $self;
}

sub init {
    my ($self) = @_;
    $self->{tree} = $self->{root};
}

=item my $dump = $dumper->dump

Turn the call graph into a string representation.

=cut

sub dump {
    my ($self) = @_;
    $self->{labels} = {}; # used for linking duplicate calls
    $self->{used} = {}; # used for linking duplicate calls
    $self->{label_count} = 1;  # used for linking duplicate calls
    $self->_paint($self->{tree});
    $self->_dump($self->{tree}, 0);
}

sub _paint {
    my ($self, $node, %parents) = @_;
    my $name = $node->name;
    my $parents = $self->{parents};
    if ($parents{$name}) {
        #warn "found a loop at $name\n";
        $self->{reuse}{$name} = 1;
        return;
    } else {
        $parents{$name} = 1;
    }
    if(! $self->{dups} and defined $self->{reuse}{$name}) {
        $self->{reuse}{$name} = 1;
    } else {
        $self->{reuse}{$name} = 0;
        for my $child ($node->calls) {
            $self->_paint($child, %parents);
        }
    }
    
}

# n
sub _dump {
    my ($self, $node, $level) = @_;
    my $ret;
    my $name = $node->name;
    my $sw = $self->{indent};
    my $left_label = $level == 0 ? '' : ' ' x $sw;
    my $right_label = $node->type eq 'external' ? ' *' : '';
    if (not $self->{labels}{$name} and $self->{reuse}{$name}) {
        $self->{labels}{$name} = $self->{label_count}++;
    }
    my $label = $self->{labels}{$name};

    if ($label) { 
        if (! $self->{used}{$name}) {
            $self->{used}{$name} = 1;
            $left_label = sprintf "%-${sw}i", $label;
        } else {
            $right_label = " ($label)";
        }
    }
    $ret .= $left_label . ' ' x ($sw * ($level-1)) ."$name" . $right_label . "\n";

    unless ($right_label) {
        for my $child ($node->calls) {
            $ret .= $self->_dump($child, $level+1);
        }
    }
    $ret;
}


1;

=back

=head1 VERSION

0.55

=head1 SEE ALSO

L<CallGraph>, L<CallGraph::Node>, L<CallGraph::Lang::Fortran>

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut


