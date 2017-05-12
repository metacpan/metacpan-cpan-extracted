package Async::Selector::Watcher;
use strict;
use warnings;
use Scalar::Util qw(weaken);
use Carp;

sub new {
    my ($class, $selector, $conditions) = @_;
    my $self = bless {
        selector => $selector,
        conditions => $conditions,
        check_all => 0,
    }, $class;
    weaken($self->{selector});
    return $self;
}

sub detach {
    my ($self) = @_;
    $self->{selector} = undef;
}

sub get_check_all {
    my ($self) = @_;
    return $self->{check_all};
}

sub set_check_all {
    my ($self, $check_all) = @_;
    $self->{check_all} = $check_all;
}

sub cancel {
    my ($self) = @_;
    return $self if not defined($self->{selector});
    my $selector = $self->{selector};
    $self->detach();
    $selector->cancel($self);
    return $self;
}

sub conditions {
    my ($self) = @_;
    return %{$self->{conditions}};
}

sub resources {
    my ($self) = @_;
    return keys %{$self->{conditions}};
}

sub active {
    my ($self) = @_;
    return defined($self->{selector});
}

our $VERSION = '1.03';

1;

=pod

=head1 NAME

Async::Selector::Watcher - representation of resource watch in Async::Selector

=head1 VERSION

1.03

=head1 SYNOPSIS


    use Async::Selector;
    
    my $s = Async::Selector->new();
    
    setup_resources_with($s);
    
    ## Obtain a watcher from Selector.
    my $watcher = $s->watch(a => 1, b => 2, sub {
        my ($w, %res) = @_;
        handle_a($res{a}) if exists $res{a};
        handle_b($res{b}) if exists $res{b};
    });
    
    ## Is the watcher active?
    $watcher->active;                          ## => true
    
    ## Get the list of watched resources
    my @resources = sort $watcher->resources;  ## => ('a', 'b')
    
    ## Get the watcher conditions
    my %conditions = $watcher->conditions;     ## => (a => 1, b => 2)
    
    ## Cancel the watcher
    $watcher->cancel;


=head1 DESCRIPTION

L<Async::Selector::Watcher> is an object that stores information about a resource watch in L<Async::Selector> module.
It also provides its user with a way to cancel the watch.


=head1 CLASS METHODS

Nothing.

L<Async::Selector::Watcher> objects are created by C<watch()>, C<watch_lt()> and C<watch_et()> methods of L<Async::Selector>.


=head1 OBJECT METHODS

In the following description, C<$watcher> is an L<Async::Selector::Watcher> object.

=head2 $is_active = $watcher->active();

Returns true if the L<Async::Selector::Watcher> is active. Returns false otherwise.

Active watchers are the ones in L<Async::Selector> objects, watching some of the Selector's resources.
Callback functions of active watchers can be executed if the watched resources get available.

Inactive watchers are the ones that have been removed from L<Async::Selector> objects.
Their callback functions are never executed any more.

Note that watchers are automatically canceled and become inactive when their parent L<Async::Selector> object is destroyed.


=head2 $watcher->cancel();

Cancels the watch.

The C<$watcher> then becomes inactive and is removed from the L<Async::Selector> object it used to belong to.


=head2 @resources = $watcher->resources();

Returns the list of resource names that are watched by this L<Async::Selector::Watcher> object.



=head2 %conditions = $watcher->conditions();

Returns a hash whose keys are the resource names that are watched by this L<Async::Selector::Watcher> object,
and values are the condition inputs for the resources.



=head1 SEE ALSO

L<Async::Selector>


=head1 AUTHOR

Toshio Ito, C<< <toshioito at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.



=cut


