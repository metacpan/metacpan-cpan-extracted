package Cvs::Command::Checkout;

use strict;
use Cvs::Result::Checkout;
use Cvs::Cvsroot;
use base qw(Cvs::Command::Base);

sub init
{
    my($self, $module, $param) = @_;
    $self->SUPER::init(@_) or return;

    $self->default_params
      (
       cvsroot => undef,
       revision => undef,
       date => undef,
       reset => 0,
      );
    $self->param($param);

    return $self->error('Mandatory option: module')
      unless(defined $module);

    $self->command('checkout');
    $self->push_arg('-d', $self->workdir())
      if defined $self->workdir();
    $self->push_arg('-A')
      if $self->param->{reset};
    $self->push_arg('-r', $self->param->{revision})
      if defined $self->param->{revision};
    $self->push_arg('-D', $self->param->{date})
      if defined $self->param->{date};
    $self->push_arg($module);
    $self->go_into_workdir(0);

    my $result = new Cvs::Result::Checkout;
    $self->result($result);

    my $main = $self->new_context();
    $self->initial_context($main);

    return $self;
}

1;
=pod

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=head1 COPYRIGHT

Copyright (C) 2003 - Olivier Poitrey

