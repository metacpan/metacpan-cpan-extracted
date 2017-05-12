package CallGraph;

$VERSION = '0.55';

use strict;
use warnings;

use Carp;
use CallGraph::Node;

=head1 NAME

CallGraph - create, navigate, and dump the call graph for a program

=head1 SYNOPSIS

    # note: you need a subclass for the language you are using
    use CallGraph::Lang::Fortran;
    my $graph = CallGraph::Lang::Fortran->new(files => [glob('*.f')]);
    print $graph->dump;

    # navigate the call graph...
    my $root = $graph->root;     # returns a CallGraph::Node object
    my (@calls) = $root->calls;
    
    # if you want to create your own language subclass:
    package CallGraph::Lang::MyLanguage;
    use base 'CallGraph';
    # must define the parse method
    sub parse {
        my ($self, $fh) = @_;
        while (<$fh>) {
            # add subroutines and calls by using
            # $self->new_sub and $self->add_call
        }
    }

=head1 DESCRIPTION

This module creates a "call graph" for a program. Please note that you need
another module to actually parse your program and add the calls by using
the CallGraph methods. The current distribution includes a module for parsing
Fortran 77, L<CallGraph::Lang::Fortran>.

=head1 METHODS

=over

=item CallGraph->new(option => value, ...)

Create a new CallGraph object. The following options are available:

=over

=item files => $file1

=item files => [$file1, $file2...]

Reads and parses the given files. $file1, etc. can be either filenames or
filehandles.

=item lines => \@lines

Parses the array reference, which is expected to be an array of program lines.
You can use this if you have already slurped your program into an array.

=item dump_options => {option => value, ...}

Pass the options to L<CallGraph::Dumper> when dumping the call graph.

=back

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        dump_options => {},
    }, ref $class || $class;
    if (ref $opts{files}) {
        $self->add_files(@{$opts{files}}) 
    } elsif ($opts{files}) {
        $self->add_files($opts{files});
    }
    if (ref $opts{lines}) {
        $self->add_lines($opts{lines});
    }
    if (ref $opts{dump_options}) {
        $self->{dump_options} = $opts{dump_options};
    }
    $self;
}

=item $graph->add_files($file1, $file2, ...)

Reads and parses the given files. $file1, etc. can be either filenames or
filehandles.

=cut

sub add_files {
    my ($self, @fnames) = @_;
    for my $fname (@fnames) {
        my $fh;
        if (ref $fname) {
            $fh = $fname;
        } else {
            open $fh, "<", $fname or croak "couldn't open $fname: $!";
        }
        $self->parse($fh);
    }
}

=item $graph->add_lines(\@lines)

Parses the array reference, which is expected to be an array of program lines.
You can use this if you have already slurped your program into an array.

=cut

sub add_lines {
    my ($self, $lines) = @_;
    my $f = join "", @$lines;
    open my $fh, "<", \$f or croak "couldn't open: $!";
    $self->parse($fh);
}

=item $graph->add_call($from, $to)

Add a call (a link) to the graph. $from and $to must be subroutine I<names>.
The nodes are created automatically (by calling new_sub) if needed, with
type 'external' (meaning that they haven't been defined explicitly yet).

=cut

sub add_call {
    my ($self, $from, $to) = @_;
    my $sub_to = $self->new_sub(name => $to);
    my $sub_from = $self->new_sub(name => $from);
    $sub_from->add_call($sub_to);
}

=item my $sub = $graph->get_sub($sub_name)

Returns the L<CallGraph::Node> object for the subroutine named $sub_name.
Note that there can be only one subroutine with a given name in a call
graph.

=cut

sub get_sub {
    my ($self, $name) = @_;
    $self->{'index'}{$name};
}

=item my @subs = $graph->subs

Returns the list of all the subroutines contained in the graph, as
L<CallGraph::Node> objects.

=cut

sub subs {
    my ($self) = @_;
    @{$self->{'index'}}{sort keys %{$self->{'index'}}};
}

=item my $root = $graph->root;

=item $graph->root($new_root);

Get or set the root of the call graph. $root is a CallGraph::Node object;
$new_root can be either an object or a subroutine name.

=cut

sub root {
    my ($self, $root) = @_;
    if ($root) {
        ($self->{root}) = ref $root ? $root : $self->get_sub($root);
        $self;
    } else {
        $self->{root};
    }
}

=item my $sub = $graph->new_sub(name => $sub_name, [type => $type])

Create and add a new subroutine (a L<CallGraph::Node> object) to the graph.
There can only be one subroutine with a given name; if new_sub is called
with a name that has been used before, it returnes the previously existing
object (note that the type of an existing object can be changed by this call).

If the type is not specified when a subroutine is first created, it defaults to
'external'.

=cut

sub new_sub {
    my ($self, %opts) = @_;
    my $name = $opts{name};
    my $sub;
    if ($sub = $self->get_sub($name)) {
        if ($opts{type}) { # change type?
            $sub->type($opts{type});
        }
    } else {
        $sub = CallGraph::Node->new(type => 'external', %opts);
        $self->{'index'}{$name} = $sub;
    }
    $sub;
}

=item my $dump = $graph->dump(option => value, ...)

Dump the call graph into a string representation. The options are passed 
to L<CallGraph::Dumper>. The root of the graph must be defined for dump to work.

=cut

sub dump {
    my ($self, %opts) = @_;
    unless ($self->{root}) { croak ref($self) . "->dump: undefined root" }
    $self->root->dump(%{$self->{dump_options}}, %opts);
}

1;

=back

=head1 VERSION

0.55

=head1 SEE ALSO

L<CallGraph::Node>, L<CallGraph::Dumper>, L<CallGraph::Lang::Fortran>

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut


