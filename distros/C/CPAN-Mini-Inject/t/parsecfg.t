use strict;
use warnings;

use Test::More;

use File::Spec::Functions qw(catfile);

my $class = 'CPAN::Mini::Inject';

subtest sanity => sub {
    use_ok $class or BAIL_OUT( "$class did not compile: $@" );
    };

subtest 'no loadcfg' => sub {
    my $mcpi = $class->new;
    isa_ok $mcpi, $class;
    can_ok $mcpi, 'parsecfg';

    my $file = catfile qw(t .mcpani config);
    ok -e $file, "file <$file> exists";

    $mcpi->parsecfg( $file );

    ok exists $mcpi->{config}, 'config key exists';
    can_ok $mcpi, 'config';
    isa_ok $mcpi->config, ref {}, 'config returns a hash ref';

    is $mcpi->config->{local},      't/local/CPAN',           'value for local matches';
    is $mcpi->config->{remote},     'http://localhost:11027', 'value for remote matches';
    is $mcpi->config->{repository}, 't/local/MYCPAN',         'value for repository matches';
    };

subtest 'loadcfg' => sub {
    my $mcpi = $class->new;
    isa_ok $mcpi, $class;
    can_ok $mcpi, 'loadcfg';
    my $file = catfile qw(t .mcpani config);
    ok -e $file, "config file <$file> exists";

    $mcpi->loadcfg( $file );
    $mcpi->parsecfg;

    ok exists $mcpi->{config}, 'config key exists';
    can_ok $mcpi, 'config';
    isa_ok $mcpi->config, ref {}, 'config returns a hash ref';

    is $mcpi->config->{local},      't/local/CPAN',           'value for local matches';
    is $mcpi->config->{remote},     'http://localhost:11027', 'value for remote matches';
    is $mcpi->config->{repository}, 't/local/MYCPAN',         'value for repository matches';
    };

subtest 'whitespace' => sub {
    my $mcpi = $class->new;
    isa_ok $mcpi, $class;

    my $file = catfile qw(t .mcpani config_with_whitespaces);
    ok -e $file, "file <$file> exists";

    $mcpi->parsecfg( $file );

    is $mcpi->config->{local},      't/local/CPAN',           'value for local matches';
    is $mcpi->config->{remote},     'http://localhost:11027', 'value for remote matches';
    is $mcpi->config->{repository}, 't/local/MYCPAN',         'value for repository matches';
    is $mcpi->config->{dirmode},    '0775',                   'value for dirmode matches';
    is $mcpi->config->{passive},    'yes',                    'value for passive matches';
    };

done_testing();
