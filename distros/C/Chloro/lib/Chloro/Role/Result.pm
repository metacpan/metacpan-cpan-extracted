package Chloro::Role::Result;
BEGIN {
  $Chloro::Role::Result::VERSION = '0.06';
}

use Moose::Role;

use namespace::autoclean;

requires 'key_value_pairs';

1;

# ABSTRACT: An interface-only role for results



=pod

=head1 NAME

Chloro::Role::Result - An interface-only role for results

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This role defines an interface for all result objects.

It requires one method, C<< $result->key_value_pairs() >>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

