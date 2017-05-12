package Chloro::Role::Error;
BEGIN {
  $Chloro::Role::Error::VERSION = '0.06';
}

use Moose::Role;

use namespace::autoclean;

1;

# ABSTRACT: An interface role for error objects



=pod

=head1 NAME

Chloro::Role::Error - An interface role for error objects

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This role contains no methods or attributes. It is simply used to mark a class
as representing an error.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

