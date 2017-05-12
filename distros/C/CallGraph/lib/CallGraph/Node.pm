package CallGraph::Node;

$VERSION = '0.55';

use strict;
use warnings;
use CallGraph::Dumper;

=head1 NAME

CallGraph::Node - represent a subroutine as a node in a call graph

=head1 SYNOPSIS

    my $sub1 = CallGraph::Node->new(name => 'main', type => 'internal');
    my $sub2 = CallGraph::Node->new(name => 'mysub', type => 'external');
    $sub1->add_call($sub2);
    print $sub1->dump;
    my @calls = $sub1->calls;
    my @callers = $sub2->callers;
    print $sub1->name; # prints 'main'
    print $sub1->type; # prints 'internal'

=head1 DESCRIPTION

This module creates a node within a "call graph" for a program. A node
corresponds to a subroutine (or function, method, or whatever it's called),
and it has the properties 'name' and 'type'. Subroutines are linked to 
one another by 'calls'.

=head1 METHODS

=over

=item my $sub = CallGraph::Node->new(option => value, ...)

Creates a new node. The available options are 'name' and 'type'. These 
properties really don't mean anything as far as CallGraph::Node is concerned.
However, CallGraph expects the name to be unique within a graph, and uses the
values 'internal' or 'external'.

=cut

sub new {
    my ($class, %opts) = @_;
    my $self = bless {
        %opts,
    }, ref $class || $class;
    $self;
}

=item $sub->add_call($sub2)

Add a link implying that $sub calls $sub2.

=cut

sub add_call {
    my ($self, $sub) = @_;
    $self->_add_call($sub);
    $sub->_add_caller($self);
}

sub _add_call {
    my ($self, $sub) = @_;
    $self->{children}{$sub->name} = $sub;
}

sub _add_caller {
    my ($self, $sub) = @_;
    $self->{parents}{$sub->name} = $sub;
}

=item my @calls = $sub->calls

Return a list of calls made by $sub. The items in the list are CallGraph::Node
items themselves.

=cut

sub calls {
    my ($self) = @_;
    @{$self->{children}}{sort keys %{$self->{children}}};
}

=item my @callers = $sub->callers

Return a list of calls received by $sub. The items in the list are
CallGraph::Node items themselves.

=cut

sub callers {
    my ($self) = @_;
    @{$self->{parents}}{sort keys %{$self->{parents}}};
}

=item my $name = $sub->name;

=item $sub->name($new_name);

Get or set the name of the subroutine. 

=cut

sub name {
    my ($self) = shift;
    if (@_) {
        ($self->{name}) = @_;
        $self;
    } else {
        $self->{name};
    }
}

=item my $type = $sub->type;

=item $sub->type($new_type);

Get or set the type of the subroutine. 

=cut

sub type {
    my ($self) = shift;
    if (@_) {
        ($self->{type}) = @_;
        $self;
    } else {
        $self->{type};
    }
}

=item my $dump = $sub->dump(option => value, ...)

Dump the call graph, starting from $sub, into a string representation. The
options are passed to L<CallGraph::Dumper>. 

=cut

sub dump {
    my ($self, %opts) = @_;
    CallGraph::Dumper->new(%opts, root => $self)->dump;
}


1;

=back

=head1 VERSION

0.55

=head1 SEE ALSO

L<CallGraph>, L<CallGraph::Dumper>, L<CallGraph::Lang::Fortran>

=head1 AUTHOR

Ivan Tubert E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Tubert. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut


