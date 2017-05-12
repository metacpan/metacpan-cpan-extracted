package Adam::Logger::API;
BEGIN {
  $Adam::Logger::API::VERSION = '0.91';
}
# ABSTRACT: API Role for the Adam logger
# Dist::Zilla: +PodWeaver
use Moose::Role;
use namespace::autoclean;

requires qw(
  log
  debug
  info
  notice
  warning
  error
  critical
  alert
  emergency
);

1;


=pod

=head1 NAME

Adam::Logger::API - API Role for the Adam logger

=head1 VERSION

version 0.91

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de> L<http://www.raudssus.de/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
