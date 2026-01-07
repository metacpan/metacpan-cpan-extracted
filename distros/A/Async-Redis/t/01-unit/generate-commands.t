# t/01-unit/generate-commands.t
use Test2::V0;
use File::Temp qw(tempdir);
use File::Spec;

# Test that the generator produces valid output
subtest 'generator produces Commands.pm' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $output = File::Spec->catfile($tempdir, 'Commands.pm');

    # Run generator with our cached commands.json
    my $result = system($^X, 'script/generate-commands',
        '--input', 'script/commands.json',
        '--output', $output,
    );

    is($result, 0, 'generator exits successfully');
    ok(-f $output, 'Commands.pm created');

    # Check content
    open my $fh, '<', $output or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;

    like($content, qr/package Async::Redis::Commands/, 'package declaration');
    like($content, qr/use Future::AsyncAwait/, 'uses async/await');
    like($content, qr/async sub get\b/, 'has get method');
    like($content, qr/async sub set\b/, 'has set method');
    like($content, qr/async sub hgetall\b/, 'has hgetall method');
    like($content, qr/async sub client_setname\b/, 'has subcommand methods');
};

subtest 'generator handles missing input' => sub {
    # Redirect stderr to suppress expected error message
    my $result = system("$^X script/generate-commands --input /nonexistent/file.json --output /dev/null 2>/dev/null");

    isnt($result, 0, 'generator fails on missing input');
};

subtest 'naming conventions' => sub {
    my $tempdir = tempdir(CLEANUP => 1);
    my $output = File::Spec->catfile($tempdir, 'Commands.pm');

    system($^X, 'script/generate-commands',
        '--input', 'script/commands.json',
        '--output', $output,
    );

    open my $fh, '<', $output or die $!;
    my $content = do { local $/; <$fh> };
    close $fh;

    # Multi-word commands become snake_case
    like($content, qr/async sub client_getname\b/, 'CLIENT GETNAME -> client_getname');
    like($content, qr/async sub cluster_addslots\b/, 'CLUSTER ADDSLOTS -> cluster_addslots');
    like($content, qr/async sub config_get\b/, 'CONFIG GET -> config_get');

    # Hyphens become underscores
    like($content, qr/async sub client_no_evict\b/, 'CLIENT NO-EVICT -> client_no_evict');
};

done_testing;
