package Catalyst::Action::Role::ACL;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
with 'Catalyst::ActionRole::ACL';

use vars qw($VERSION);
$VERSION = '0.07'; # Note - Remember to keep in sync with Catalyst::ActionRole::ACL

{
    my $has_warned = 0;
    after BUILD => sub {
        my ($c) = @_;
        my $app = blessed($c) ? blessed($c) : $c;
        warn("Catalyst::Action::Role::ACL in $app is deprecated, please move you code to use Catalyst::ActionRole::ACL\n")
            unless $has_warned++;
    };
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Catalyst::Action::Role::ACL - Deprecated user role-based authorization action class

=head1 SYNOPSIS

 sub foo
 :Local
 :ActionClass(Role::ACL)
 :RequiresRole(admin)
 :ACLDetachTo(denied)
 {
     my ($self, $c) = @_;
     ...
 }

 sub denied :Private {
     my ($self, $c) = @_;

     $c->res->status('403');
     $c->res->body('Denied!');
 }

=head1 DESCRIPTION

Provides a L<Catalyst reusable action|Catalyst::Manual::Actions> for user
role-based authorization. ACLs are applied via the assignment of attributes to
application action subroutines.

You are better using L<Catalyst::ActionRole::ACL> to do this, as it plays
nicely with other extensions. This package is maintained to allow compatibility
with people using this in existing code, but will warn once when used.

=head1 AUTHOR

David P.C. Wollmann E<lt>converter42@gmail.comE<gt>

=head1 BUGS

This is new code. Find the bugs and report them, please.

=head1 COPYRIGHT & LICENSE

Copyright 2009 by David P.C. Wollmann

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

