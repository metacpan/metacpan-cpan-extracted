#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Controller::ExtJS::Direct;
# ABSTRACT: Role to identify ExtJS::Direct controllers
$CatalystX::Controller::ExtJS::Direct::VERSION = '2.1.5';
use Moose::Role;

has is_direct => ( is => 'ro', isa => 'Bool', default => 1 );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Controller::ExtJS::Direct - Role to identify ExtJS::Direct controllers

=head1 VERSION

version 2.1.5

=head1 SYNOPSIS

  package MyApp::Controller::Calculator;
  
  use Moose;
  BEGIN { extends 'Catalyst::Controller' };
  with 'CatalystX::Controller::ExtJS::Direct';
  
  sub sum : Local : Direct {
      my ($self, $c) = @_;
      $c->res->body( $c->req->param('a') + $c->req->param('b') );
  }
  
  1;

=head1 DESCRIPTION

Apply this role to any Catalyst controller to enable Ext.Direct actions.

=head1 ATTRIBUTES

=head2 is_direct

This attribute is for duck typing only and is always C<1>.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
