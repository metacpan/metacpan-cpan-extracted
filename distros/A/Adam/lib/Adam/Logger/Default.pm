package Adam::Logger::Default;
# ABSTRACT: Default logger for Adam bots
our $VERSION = '1.000';
use Moose;


with qw(
  Adam::Logger::API
  MooseX::LogDispatch::Levels
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Adam::Logger::Default - Default logger for Adam bots

=head1 VERSION

version 1.000

=head1 DESCRIPTION

Default logging implementation for Adam bots using L<MooseX::LogDispatch::Levels>.

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
