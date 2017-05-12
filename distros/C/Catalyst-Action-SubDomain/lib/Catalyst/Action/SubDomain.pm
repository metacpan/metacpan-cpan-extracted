package Catalyst::Action::SubDomain;

use strict;
use warnings;

our $VERSION = '0.07';

use MRO::Compat;
use base 'Catalyst::Action';

sub match {
    my $self = shift @_;
    return $self->check_subdomain_constraints($_[0]->request->uri->host) && $self->next::method(@_);
}

sub check_subdomain_constraints {
    my ( $self, $host ) = @_;
    return !! scalar @{$self->_cached_domains->{$host}} if exists $self->_cached_domains->{$host};
    my @domains = reverse split(/\./, $host);
    $self->_cached_domains->{$host} = \@domains;
    return 1 unless exists $self->attributes->{SubDomain};
    foreach my $cnf (grep { $_->[0]=~/^\d+$/ } map([split(/,/, $_, 2)],  @{$self->attributes->{SubDomain}})) {
        if ((scalar(@domains) >= $cnf->[0]?$domains[$cnf->[0] - 1]:'') !~ qr#$cnf->[1]#) {
            $self->_cached_domains->{$host} = [];
            return undef;
        }
    }
    return 1;
}

sub domain {
    my ($self, $c, $level) = @_;
    return undef unless defined($c) && defined($level);
    return $self->number_of_domains($c) >= $level?$self->_cached_domains->{$c->request->uri->host}->[$level-1]:undef;
}

sub number_of_domains {
    my ($self, $c) = @_;
    return scalar(@{$self->_cached_domains->{$c->request->uri->host}});
}

sub _cached_domains {
    my $self = shift @_;
    return $self->{'_cached_domains'} ||= {};
}

1;

=head1 NAME

Catalyst::Action::SubDomain - Match action against names of subdomains

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

Match subdomain name

    sub method : ActionClass('SubDomain') :SubDomain('level,regexp') {
        my ( $self, $c ) = @_;
        ..
    }
    
Get number of domain levels and subdomain name at last level.   
    
    sub method : ActionClass('SubDomain') {
        my ( $self, $c ) = @_;
        my $max_level = $c->action->number_of_domains($c);
        my $subdomain = $c->action->domain($c, $max_level);
    }
    
=head1 EXAMPLES

Root controller action for main site and subdomain with no more than 3 chars

    sub default :Path('/') : ActionClass('SubDomain') : SubDomain('3,^\w{0,3}$') {
        my ( $self, $c ) = @_;
    }
    
Foo controller action for rest subdomains

    sub index :Path('/') :ActionClass('SubDomain') :SubDomain('3,^\w{4,}$') {
        my ( $self, $c ) = @_;
    }
    
This example shows that actions will be match only when 3-rd level domain exists and contains alpha-numerical chars (foo123.example.com).

    sub index :Path('/') :Args(0) :ActionClass('SubDomain') :SubDomain('3,^\w+$') {
        my ( $self, $c ) = @_;
        $c->response->body('Matched My::App::Controller');
    }
    
foo123.example.com/test
    
    sub test :Path('/test') :ActionClass('SubDomain') :SubDomain('3,^\w+$') {
        my ( $self, $c, @args ) = @_;
        $c->response->body(join('.', map($c->action->domain($c, $_), 1..$c->action->number_of_domains($c))));
    }
    
You can specify more that one subdomain constraint.

    sub test :Local :ActionClass('SubDomain') :SubDomain('3,^\w+$') :SubDomain('2,^example$') {
        my ( $self, $c, @args ) = @_;
        my $name = $self->action->domain($c, 3);
    }
    
Note: When combining :ActionClass('SubDomain') with :Chained action you should access action a little bit different way
    
    ..
    my $action = $c->action->isa('Catalyst::ActionChain')?$c->action->chain->[-1]:$c->action;
    my $name = $action->domain($c, 3);
    ..
    
=head1 METHODS

=head2 domain($context, $level)

Returns domain name of specified level. Works only for matched action.

=head2 number_of_domains($context)

Get number of domain levels

=head2 match

See L<Catalyst::Action/METHODS/match>.
    
=head1 INTERNAL METHODS

=head2 check_subdomain_constraints

Check subdomains constraints

=head2 _cached_domains

Cached domains

=head1 AUTHOR

Egor Korablev, C<< <egor.korablev at gmail.com> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut