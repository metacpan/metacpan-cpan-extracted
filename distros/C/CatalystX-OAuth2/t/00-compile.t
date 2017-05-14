use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.053

use Test::More;

plan tests => 34 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Catalyst/ActionRole/OAuth2/AuthToken/ViaAuthGrant.pm',
    'Catalyst/ActionRole/OAuth2/AuthToken/ViaRefreshToken.pm',
    'Catalyst/ActionRole/OAuth2/GrantAuth.pm',
    'Catalyst/ActionRole/OAuth2/ProtectedResource.pm',
    'Catalyst/ActionRole/OAuth2/RequestAuth.pm',
    'Catalyst/Authentication/Credential/OAuth2.pm',
    'CatalystX/OAuth2.pm',
    'CatalystX/OAuth2/ActionRole/Grant.pm',
    'CatalystX/OAuth2/ActionRole/RequestInjector.pm',
    'CatalystX/OAuth2/ActionRole/Token.pm',
    'CatalystX/OAuth2/Client.pm',
    'CatalystX/OAuth2/ClientContainer.pm',
    'CatalystX/OAuth2/ClientInjector.pm',
    'CatalystX/OAuth2/ClientPersistor.pm',
    'CatalystX/OAuth2/Controller/Role/Provider.pm',
    'CatalystX/OAuth2/Controller/Role/WithStore.pm',
    'CatalystX/OAuth2/Grant.pm',
    'CatalystX/OAuth2/Request.pm',
    'CatalystX/OAuth2/Request/AuthToken.pm',
    'CatalystX/OAuth2/Request/GrantAuth.pm',
    'CatalystX/OAuth2/Request/ProtectedResource.pm',
    'CatalystX/OAuth2/Request/RefreshToken.pm',
    'CatalystX/OAuth2/Request/RequestAuth.pm',
    'CatalystX/OAuth2/Schema.pm',
    'CatalystX/OAuth2/Schema/Result/AccessTokenToRefreshToken.pm',
    'CatalystX/OAuth2/Schema/Result/Client.pm',
    'CatalystX/OAuth2/Schema/Result/Code.pm',
    'CatalystX/OAuth2/Schema/Result/Owner.pm',
    'CatalystX/OAuth2/Schema/Result/RefreshToken.pm',
    'CatalystX/OAuth2/Schema/Result/RefreshTokenToAccessToken.pm',
    'CatalystX/OAuth2/Schema/Result/Token.pm',
    'CatalystX/OAuth2/Schema/ResultSet/Client.pm',
    'CatalystX/OAuth2/Store.pm',
    'CatalystX/OAuth2/Store/DBIC.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


