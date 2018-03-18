package Clustericious::Client::Object::DateTime;

use strict;
use warnings;

# ABSTRACT: Clustericious DateTime object
our $VERSION = '1.29'; # VERSION


use DateTime::Format::ISO8601;


sub new
{
    my $class = shift;
    my ($datetime) = @_;

    DateTime::Format::ISO8601->new->parse_datetime($datetime);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Client::Object::DateTime - Clustericious DateTime object

=head1 VERSION

version 1.29

=head1 SYNOPSIS

 my $obj = Clustericious::Client::Object::DateTime->new('2000-01-01');

 returns a DateTime object from the string date/time.  Expects the
 date/time to be in ISO 8601 format.

=head1 DESCRIPTION

A simple wrapper around DateTime::Format::ISO8601 that provides a
new() function that acts like Clustericious::Client::Object wants it
to.

=head1 METHODS

=head2 new

 my $obj = Clustericious::Client::Object::DateTime->new('2000-01-01');

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Yanick Champoux

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
