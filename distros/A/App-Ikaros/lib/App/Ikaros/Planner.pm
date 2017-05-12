package App::Ikaros::Planner;
use strict;
use warnings;
use parent qw/Class::Accessor::Fast/;
use List::Util qw/shuffle/;
use List::MoreUtils qw/part/;
use App::Ikaros::PathMaker;
use App::Ikaros::Helper qw/load_from_yaml/;
use Data::Dumper;
use constant {
    PROVE_STATE_FILE => '.prove',
};

__PACKAGE__->mk_accessors(qw/
    prove_tests
    forkprove_tests
    saved_tests
    sorted_tests
/);

sub new {
    my ($class, $hosts, $args) = @_;
    unless ($args->{prove_tests} || $args->{forkprove_tests}) {
        die "must be set 'prove_tests' and 'forkprove_tests(optional)'";
    }
    my $self = $class->SUPER::new({ %$args });
    $self->__load_prove_state([ @{$args->{prove_tests}}, @{$args->{forkprove_tests}} ])
        if (-f PROVE_STATE_FILE);
    $self->__setup_testing_cluster($hosts);
    return $self;
}

sub planning {
    my ($self, $host, $args) = @_;
    my $commands = $self->__make_command($args, $host);
    $host->plan($commands);
}

sub __load_prove_state {
    my ($self, $tests) = @_;

    my %tests_map;
    $tests_map{$_}++ foreach @$tests;
    my $saved_tests = (load_from_yaml PROVE_STATE_FILE)->{tests};

    my %elapsed_times;
    foreach my $saved_test (keys %$saved_tests) {
        next unless exists $tests_map{$saved_test};
        my $elapsed_time = $saved_tests->{$saved_test}->{elapsed};
        $elapsed_times{$saved_test} = $elapsed_time + 0;
    }
    my @elapsed_times = reverse sort {
        $elapsed_times{$a} <=> $elapsed_times{$b}
    } keys %elapsed_times;
    $self->saved_tests(\%elapsed_times);
    $self->sorted_tests(\@elapsed_times);
}

sub __setup_testing_cluster {
    my ($self, $hosts) = @_;

    my ($prove_host_num, $forkprove_host_num);
    foreach my $host (@$hosts) {
        if ($host->runner eq 'prove') {
            $prove_host_num++;
        } elsif ($host->runner eq 'forkprove') {
            $forkprove_host_num++;
        } else {
            die "unknown keyword at runner [$host->{runner}]";
        }
    }

    my $prove_test_clusters     = $self->__make_test_cluster($self->prove_tests, $prove_host_num);
    my $forkprove_test_clusters = $self->__make_test_cluster($self->forkprove_tests, $forkprove_host_num);

    foreach my $host (@$hosts) {
        if ($host->runner eq 'prove') {
            $host->tests(shift @$prove_test_clusters);
        } else {
            $host->tests(shift @$forkprove_test_clusters);
        }
    }
}

sub __make_test_cluster {
    my ($self, $tests, $host_num) = @_;
    my $sorted_tests = $self->__get_sorted_tests($tests);
    my $host_idx = 0;
    return [ part { $host_idx++ % $host_num } @$sorted_tests ];
}

sub __get_sorted_tests {
    my ($self, $tests) = @_;
    if (defined $self->saved_tests) {
        my %tests_map;
        $tests_map{$_}++ foreach @$tests;
        my @new_tests = shuffle grep { not exists $self->saved_tests->{$_} } @$tests;
        my @sorted_tests = grep { exists $tests_map{$_} } @{$self->sorted_tests};
        return [ @sorted_tests, @new_tests ];
    }
    return [ shuffle @$tests ];
}

sub devel_cover_opt {
    my ($self, $host) = @_;
    my $workdir = $host->workdir;
    my $lib = "$workdir/ikaros_lib";
    return "-MDevel::Cover=-db,cover_db,-coverage,statement,time,+ignore,$lib,local/lib/perl5";
}

sub __make_command {
    my ($self, $args, $host) = @_;
    my $workdir = $host->workdir;
    my $chdir = "cd $workdir";

    my $lib = "$workdir/ikaros_lib";
    my $bin = "$lib/bin";
    my @cover_opt = ($host->coverage) ? ($self->devel_cover_opt($host)) : ();

    my @prove_commands = map {
        ($_ =~ /\$prove/) ? ("-I$lib", "-I$lib/lib/perl5", "$bin/Prove.pm", '--state=save') : $_;
    } @{$args->{prove_command}};
    my @forkprove_commands = map {
        ($_ =~ /\$forkprove/) ? ("-I$lib", "-I$lib/lib/perl5", @cover_opt, "$bin/ForkProve.pm", '--state=save') : $_;
    } @{$args->{forkprove_command}};

    $host->prove(($host->runner eq 'prove') ? \@prove_commands : \@forkprove_commands);

    my $before_command = $self->__join_command($chdir, $args->{before_commands});
    my $main_command   = $self->__make_main_command($chdir . '/' . $args->{chdir}, $host);
    my $after_command  = $self->__join_command($chdir, $args->{after_commands});

    return [
        "mkdir -p $workdir/ikaros_lib/bin",
        $before_command,
        $main_command,
        $after_command
    ];
}

sub __make_main_command {
    my ($self, $chdir, $host) = @_;

    my $workdir = $host->workdir;
    my $trigger_filename = $host->trigger_filename;
    my $continuous_template = '((%s) || echo 1)';
    my $devel_cover_opt = $self->devel_cover_opt($host);
    my $cover_env = ($host->coverage) ? "export HARNESS_PERL_SWITCHES=$devel_cover_opt;" : '';

    my $build_start_flag = "echo 'IKAROS:BUILD_START'";
    my $build_end_flag   = "echo 'IKAROS:BUILD_END'";
    my $move_output    = $self->__move_result_to_dir('junit_output.xml', $workdir);
    my $move_dot_prove = $self->__move_result_to_dir('.prove', $workdir);
    my $move_cover_db  = ($host->coverage) ? $self->__move_result_to_dir('cover_db', $workdir) : 'echo \'skip move cover_db\'';
    my $perl = App::Ikaros::PathMaker::perl($host);
    my $kick_command = $cover_env . sprintf $continuous_template, "$perl -I$workdir/ikaros_lib $workdir/$trigger_filename";
    return join ' && ', (
        $chdir,
        $build_start_flag,
        $kick_command,
        $move_output,
        $move_dot_prove,
        $move_cover_db,
        $build_end_flag
    );
}

sub __move_result_to_dir {
    my ($self, $result, $workdir) = @_;
    return "(if [ -e $result ]; then mv $result $workdir; fi;)";
}

sub __join_command {
    my ($self, $chdir, $commands) = @_;
    my $continuous_template = '((%s) || echo 1)';
    return join ' && ', $chdir, map {
        sprintf $continuous_template, $_;
    } @$commands;
}

1;
