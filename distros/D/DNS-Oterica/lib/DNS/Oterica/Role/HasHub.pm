package DNS::Oterica::Role::HasHub;
# ABSTRACT: any part of the dnso system that has a reference to the hub
$DNS::Oterica::Role::HasHub::VERSION = '0.312';
use Moose::Role;

use namespace::autoclean;

has hub => (
  is   => 'ro',
  isa  => 'DNS::Oterica::Hub',
  weak_ref => 1,
  required => 1,
  # handles  => 'DNS::Oterica::Role::RecordMaker',
  handles  => [ qw(rec) ],
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Oterica::Role::HasHub - any part of the dnso system that has a reference to the hub

=head1 VERSION

version 0.312

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
