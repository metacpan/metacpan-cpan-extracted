package App::Zapzi::Roles::Distributor;
# ABSTRACT: role definition for distributor modules


use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use Carp;
use Moo::Role;


has file => (is => 'ro', required => 1);


has destination => (is => 'ro', required => 1);


has completion_message => (is => 'rwp', default => '');



requires qw(name distribute);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Roles::Distributor - role definition for distributor modules

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This defines the distributor role for Zapzi. Distributors take a
published eBook and send it somewhere else, eg copy to a reader, send
by email, run a script on it.

=head1 ATTRIBUTES

=head2 file

eBook file to distribute.

=head2 destination

Where to send the file, eg another directory or an email address

=head2 completion_message

Message from the distributer after completion - should be set in both
error and success cases.

=head1 REQUIRED METHODS

=head2 name

Name of distributor visible to user.

=head2 distribute

Distribute the file. Returns 1 if OK, undef if failed.

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
