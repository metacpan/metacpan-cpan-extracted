package App::sdseasydyn;

use strict;
use warnings;

our $VERSION = '0.1.0';

# NOTE:
# Keep this module lightweight for CPAN indexing and documentation.
# The CLI entrypoint remains bin/sdseasydyn, which loads the implementation.
# Do not 'use EasyDNS::DDNS' here (compile-time), to keep perl -c and tooling simple.

1;

__END__

=pod

=head1 NAME

App::sdseasydyn - EasyDNS DDNS updater (CLI-first App distribution)

=head1 SYNOPSIS

  sdseasydyn update [--config /path/to/config.ini] [--ipv4 1.2.3.4] [...]

=head1 DESCRIPTION

C<App::sdseasydyn> is the CPAN-facing module for the C<sdseasydyn> command-line
tool.

The implementation lives in the C<EasyDNS::DDNS> namespace. The primary user
interface is the CLI (C<bin/sdseasydyn>).

=head1 BEHAVIOR (HIGH LEVEL)

=over 4

=item *

CLI command: C<sdseasydyn update>

=item *

Configuration precedence: CLI > ENV > config.ini > defaults

=item *

Secrets: C<EASYDNS_USER> + C<EASYDNS_TOKEN> (token is never logged)

=item *

Public IPv4 discovery; state file stores last IP; skip update if unchanged

=item *

Retries via L<Retry::Policy> around HTTP operations

=back

=head1 SECURITY

Tokens are treated as secrets and must not be logged.
See C<SECURITY.md> and C<docs/EASYDNS.md> for operational notes.

=head1 SEE ALSO

L<EasyDNS::DDNS>, L<Retry::Policy>

=head1 AUTHOR

Sergio de Sousa <sergio@serso.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

