package Adam::Logger::API;
# ABSTRACT: API Role for the Adam logger
our $VERSION = '1.000';
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Adam::Logger::API - API Role for the Adam logger

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Defines the logging API interface required for Adam bot loggers.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/perigrin/adam-bot-framework/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris@prather.org>

=item *

Torsten Raudssus <torsten@raudssus.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Prather, Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
