package App::Ikaros;
use 5.008_001;
use strict;
use warnings;
use parent qw/Class::Accessor::Fast/;
use App::Ikaros::Config::Loader;
use App::Ikaros::Planner;
use App::Ikaros::LandingPoint;
use App::Ikaros::Builder;
use App::Ikaros::Reporter;
use App::Ikaros::PathMaker qw/prove lib_dir/;
use Data::Dumper;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(qw/
    hosts
    config
    tests
    output_filename
    enable_profile
    verbose
    recovery_testing_command
/);

sub new {
    my ($class, $options) = @_;

    my $loaded_conf = App::Ikaros::Config::Loader->new({
        config         => $options->{config},
        config_type    => $options->{config_type},
        config_options => $options->{config_options}
    })->load;

    my $ikaros = $class->SUPER::new({
        config   => $loaded_conf,
        hosts    => [],
        verbose  => $options->{verbose},
        enable_profile  => $options->{enable_profile},
        output_filename => $options->{output_filename}
    });

    $ikaros->__setup_landing_points;
    $ikaros->__planning;
    return $ikaros;
}

sub __setup_landing_points {
    my ($self) = @_;
    my $default = $self->config->{default};
    foreach my $host (@{$self->config->{hosts}}) {
        push @{$self->hosts}, App::Ikaros::LandingPoint->new($default, $host);
    }
}

sub __planning {
    my ($self) = @_;
    my $plan = $self->config->{plan};
    my $planner = App::Ikaros::Planner->new($self->hosts, $plan);
    $planner->planning($_, $plan) foreach @{$self->hosts};
    $self->tests([ @{$plan->{prove_tests}}, @{$plan->{forkprove_tests}} ]);
    $self->__setup_recovery_testing_command($plan);
}

sub __setup_recovery_testing_command {
    my ($self, $args) = @_;
    my $lib = lib_dir 'App/Prove.pm';
    my @prove_commands = map {
        ($_ =~ /\$prove/) ? ("-I$lib", prove) : $_;
    } @{$args->{prove_command}};
    $self->recovery_testing_command(\@prove_commands);
}

sub launch {
    my ($self, $callback) = @_;
    my $builder = App::Ikaros::Builder->new;
    $builder->rsync($self->hosts, $self->config->{plan}{rsync});
    $builder->build($self->hosts);
    my $failed_tests = App::Ikaros::Reporter->new({
        verbose => $self->verbose,
        tests   => $self->tests,
        enable_profile  => $self->enable_profile,
        output_filename => $self->output_filename,
        recovery_testing_command => $self->recovery_testing_command
    })->report($self->hosts);
    return &$callback($failed_tests);
}

1;

__END__

=head1 NAME

App::Ikaros - distributed testing framework for jenkins

=head1 SYNOPSIS

=head3  [EXECUTOR]

    use App::Ikaros;

    my $status = App::Ikaros->new({
        config      => 'config/ikaros.conf',
        config_type => 'dsl',
    })->launch(sub {
        my $failed_tests = shift;
        print "$failed_tests\n";
        # notify IRC or register issue tickets..
    });

=head3 [PLAN CONFIGURATION] : config/ikaros.conf

    use App::Ikaros::Helper qw/
        exclude_blacklist
        load_from_yaml
    /;
    use App::Ikaros::DSL;

    my $options = get_options;
    my $all_tests = [ 't/test0.t', 't/test1.t', 't/test2.t' ];
    my $blacklist = [ 't/test0.t' ];
    my $prove_tests = $blacklist;
    my $forkprove_tests = exclude_blacklist($all_tests, $blacklist); # [ 't/test1.t', 't/test2.t' ]

    my $conf = load_from_yaml('config/hosts.yaml');

    # setup host status
    hosts $conf;

    plan {
        # test list for prove
        prove_tests     => $prove_tests,

        # test list for forkprove
        forkprove_tests => $forkprove_tests,

        # change directory to execute main command
        chdir => 'work',

        # prove version of main command
        # '$prove' is expanded -I/path/to/ikaros_lib /path/to/ikaros_lib/bin/prove
        prove_command     => [ 'perl', '$prove', '-Ilocal/lib/perl5' ],

        # forkprove version of main command
        # '$forkprove' is expanded -I/path/to/ikaros_lib /path/to/ikaros_lib/bin/forkprove
        forkprove_command => [ 'perl', '$forkprove', '-Ilocal/lib/perl5' ],

        # commands before main command
        before_commands   => [
            'if [ -d work ]; then rm -rf work; fi;',
            'if [ -d cover_db ]; then rm -rf cover_db; fi;',
            'if [ -f junit_output.xml ]; then rm junit_output.xml; fi;',
            'git clone https://github.com/goccy/p5-App-Ikaros.git work',
        ],

        # commands after main command
        after_commands => []
    };

=head3 [HOST CONFIGURATION] : config/hosts.yaml

    # default status each hosts
    default:
      user: $USER_NAME                 # username for ssh connection
      private_key: $HOME/.ssh/id_rsa   # private_key for ssh connection
      runner: forkprove                # executor of main command ('prove' or 'forkprove')
      coverage: true                   # enable testing coverage
      perlbrew: true                   # find perl binary using perlbrew
      workdir: $HOME/ikaros_workspace  # working directory for testing

    # set status individually
    hosts:
      - remote # remote server name
      - remote:
          workdir: $HOME/ikaros_workspace_2 # override working directory name
      - remote:
          runner: prove # override executor of main command
          workdir: $HOME/ikaros_workspace_3

=head1 DESCRIPTION

App::Ikaros is distributed testing framework for jenkins.

=head1 METHODS

=head1 AUTHOR

Masaaki Goshima (goccy) <goccy54@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Masaaki Goshima (goccy).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
