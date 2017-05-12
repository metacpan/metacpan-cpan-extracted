use strict;
use warnings;

use Test::More;
use Try::Tiny;

use_ok('Captive::Portal::Role::Utils');

# enable this code fragment to get DEBUG logging for this tests

=pod

my $log4perl_conf = <<EO_CONF;
log4perl.logger                 = DEBUG, screen
log4perl.appender.screen   = Log::Log4perl::Appender::Screen
log4perl.appender.screen.layout   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.screen.layout.ConversionPattern = [%04R ms] [%5P pid] [%p{1}] [%15.15M{1}] %m %n
EO_CONF

use Log::Log4perl;
Log::Log4perl->init(\$log4perl_conf);

=cut

my ( $stdout, $stderr, $error );

try {
    Captive::Portal::Role::Utils->spawn_cmd(qw(sleep 1));
}
catch { $error = $_ };
ok( !$error, "external cmd 'sleep 1'" );

undef $error;
try { Captive::Portal::Role::Utils->spawn_cmd(qw(sleep 3)) }
catch { $error = $_ };

like( $error, qr/timed out/i, "throws error message like 'timed out'" );

undef $error;
try {
    Captive::Portal::Role::Utils->spawn_cmd( qw(ls pipapo),
        { ignore_exit_codes => [1,2], } );
}
catch { $error = $_ };
ok( !$error, "ignore exit_codes" );
#diag explain $error;

undef $error;
try { Captive::Portal::Role::Utils->spawn_cmd(qw(pipapo)) } catch { $error = $_ };
ok( $error, "throws error for unknown command"
);
#diag explain $error;

( $stdout, $stderr ) = Captive::Portal::Role::Utils->spawn_cmd(qw(echo asdf));
like( $stdout, qr/^asdf\s*/, 'stdout for external cmd' );

( $stdout, $stderr ) =
  Captive::Portal::Role::Utils->spawn_cmd( qw(perl -e), 'warn "foobarbaz\n"' );
like( $stderr, qr/^foobarbaz$/, 'stderr for external cmd' );

my @ip_addresses = qw(010.100.010.001 00001.1.00002.0004 1.2.3.4);
my @expected     = qw(10.100.10.1 1.1.2.4 1.2.3.4);

@ip_addresses =
  map { Captive::Portal::Role::Utils->normalize_ip($_) } @ip_addresses;

is_deeply( \@ip_addresses, \@expected, 'ip addr normalization' );

done_testing(8);
