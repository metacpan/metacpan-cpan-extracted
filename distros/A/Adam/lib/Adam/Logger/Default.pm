package Adam::Logger::Default;
BEGIN {
  $Adam::Logger::Default::VERSION = '0.91';
}
# ABSTRACT: Default logger for Adam bots
# Dist::Zilla: +PodWeaver
use Moose;

with qw(
  Adam::Logger::API
  MooseX::LogDispatch::Levels
);

1;


=pod

=head1 NAME

Adam::Logger::Default - Default logger for Adam bots

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
