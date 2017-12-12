package Testing;
use strict;
use warnings;
use 5.10.1;
use Capture::Tiny qw( capture_stdout );
use Carp;
#use Data::Dump qw( dd pp );
use File::Spec;
use File::Temp qw( tempdir );
use JSON;
use Path::Tiny ();
use Test::More ();
use parent ('Exporter');
our @EXPORT_OK = ( qw|
    test_one_log_file
    test_no_test_output
    test_multiple_log_files
    test_absence_of_stdout
| );


=pod

    test_one_log_file( {
        build_logfile   => 'build.single.log',
        json_title      => 'BINGOS.Module-CoreList-3.07',
        expected        =>  {
            author        => 'BINGOS',
            distname      => 'Module-CoreList-3.07',
            dist          => 'Module-CoreList',
            distversion   => '3.07',
            grade         => 'PASS',
            test_output   => qr/Building and testing Module-CoreList-3.07/s,
        },
    } );

=cut 

sub test_one_log_file {
    my $args = shift;
    _check_args($args);
    my $reporter = _create_reporter($args);

    {
        no warnings 'redefine';
        local *CPAN::cpanminus::reporter::RetainReports::_check_cpantesters_config_data = sub { 1 };
        my $tdir = tempdir( CLEANUP => 1 );
        $reporter->set_report_dir($tdir);
        $reporter->run;
        _analyze_json_file($tdir, $args);
    }
    return 1;
}

sub test_no_test_output {
    my $args = shift;
    _check_args($args);
    my $reporter = _create_reporter($args);

    {
        no warnings 'redefine';
        local *CPAN::cpanminus::reporter::RetainReports::_check_cpantesters_config_data = sub { 1 };
        my $tdir = tempdir( CLEANUP => 1 );
        $reporter->set_report_dir($tdir);
        my $output = capture_stdout { $reporter->run; };
        Test::More::like($output, qr/No test output found for '$args->{expected}->{distname}'/s,
            "Got expected output indicating no test output for $args->{expected}->{distname}");
    }
    return 1;
}

sub _check_args {
    my $args = shift;
    croak "Must pass hashref to test_one_log_file()"
        unless ref($args) eq 'HASH';
    my @top_keys = (qw| build_logfile json_title expected |);
    for my $k (@top_keys) {
        croak "Must provide value for element '$k'"
            unless exists $args->{$k};
    }
    for my $l (qw| author distname dist distversion grade test_output | ) {
        croak "Must provide value for element '$l' in 'expected'"
            unless exists $args->{expected}->{$l};
    }
    return 1;
}

sub _create_reporter {
    my $args = shift;
    my $dir = -d 't' ? 't/data' : 'data';
    my $reporter = CPAN::cpanminus::reporter::RetainReports->new(
        force => 1, # ignore mtime check on build.log
        build_logfile => File::Spec->catfile($dir, $args->{build_logfile}),
        'ignore-versions' => 1,
    );
    Test::More::ok(defined $reporter, 'created new reporter object');
    return $reporter;
}

sub _analyze_json_file {
    my ($tdir, $hr) = @_;
    my $lfile = File::Spec->catfile($tdir, "$hr->{json_title}.log.json");
    Test::More::ok(-f $lfile, "Log file $lfile created");
    my $f = Path::Tiny::path($lfile);
    my $decoded = decode_json($f->slurp_utf8);
    _test_json_output($decoded, $hr->{expected});
    return 1;
}

sub _test_json_output {
    my ($got, $expected) = @_;
    my $pattern = "%-28s%s";
    Test::More::is($got->{author}, $expected->{author},
        sprintf($pattern => ('Got expected author:', $expected->{author})));
    Test::More::is($got->{distname}, $expected->{distname},
        sprintf($pattern => ('Got expected distname:', $expected->{distname})));
    Test::More::is($got->{dist}, $expected->{dist},
        sprintf($pattern => ('Got expected dist:', $expected->{dist})));
    Test::More::is($got->{distversion}, $expected->{distversion},
        sprintf($pattern => ('Got expected distversion:', $expected->{distversion})));
    Test::More::is($got->{grade}, $expected->{grade},
        sprintf($pattern => ('Got expected grade:', $expected->{grade})));
    Test::More::like($got->{test_output}, $expected->{test_output},
        "Got expected test output");
    return 1;
}

=pod

    test_multiple_log_files( {
        build_logfile   => 'build.dist_subdir.log',
        logs            => [
            {
                json_title      => 'RGARCIA.Sub-Identify-0.04',
                expected        =>  {
                      author        => 'RGARCIA',
                      distname      => 'Sub-Identify-0.04',
                      dist          => 'Sub-Identify',
                      distversion   => '0.04',
                      grade         => 'PASS',
                      test_output   => qr/Building and testing Sub-Identify-0\.04/s,
                },
            },
            # additional per-distro hash refs
        ],
    } );

=cut

sub test_multiple_log_files {
    my $args = shift;
    croak "Must pass hashref to test_multiple_log_files()"
        unless ref($args) eq 'HASH';
    for my $k (qw| build_logfile logs |) {
        croak "Must provide value for element '$k'"
            unless exists $args->{$k};
    }
    croak "Value of 'logs' must be array reference"
        unless ref($args->{logs}) eq 'ARRAY';

    for my $hr (@{$args->{logs}}) {
        for my $k (qw| json_title expected |) {
            croak "Must provide value for element '$k'"
                unless exists $hr->{$k};
        }
        for my $l (qw| author distname dist distversion grade test_output | ) {
            croak "Must provide value for element '$l' in 'expected'"
                unless exists $hr->{expected}->{$l};
        }
    }

    my $reporter = _create_reporter($args);

    {
        no warnings 'redefine';
        local *CPAN::cpanminus::reporter::RetainReports::_check_cpantesters_config_data = sub { 1 };
        my $tdir = tempdir( CLEANUP => 1 );
        $reporter->set_report_dir($tdir);
        $reporter->run;
        for my $hr (@{$args->{logs}}) {
            _analyze_json_file($tdir, $hr);
        }
    };
}

=pod

    test_absence_of_stdout( {
        build_logfile   => 'mixed_scheme.build.log',
        json_title      => 'JKEENAN.Data-Presenter-1.03',
        expected        =>  {
            author        => 'JKEENAN',
            distname      => 'Data-Presenter-1.03',
            dist          => 'Data-Presenter',
            distversion   => '1.03',
            grade         => 'PASS',
            test_output   => qr/Building and testing Data-Presenter-1\.03/s,
            superseded    => qr/invalid scheme 'file' for resource.*Skipping/s,
        },
    } );

=cut

sub test_absence_of_stdout {
    my $args = shift;
    _check_args($args);
    my $reporter = Testing::_create_reporter($args);
    {
        no warnings 'redefine';
        local *CPAN::cpanminus::reporter::RetainReports::_check_cpantesters_config_data = sub { 1 };
        my $tdir = File::Temp::tempdir( CLEANUP => 1 );
        $reporter->set_report_dir($tdir);
        my $output = capture_stdout { $reporter->run; } || '';
        Test::More::unlike($output, qr/$args->{expected}->{superseded}/,
            "Got no message on STDOUT indicating problem");
        _analyze_json_file($tdir, $args);
    }
    return 1;
}

1;
