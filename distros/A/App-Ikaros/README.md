# NAME

App::Ikaros - distributed testing framework for jenkins

# SYNOPSIS

### \[EXECUTOR\]

    use App::Ikaros;

    my $status = App::Ikaros->new({
        config      => 'config/ikaros.conf',
        config_type => 'dsl',
    })->launch(sub {
        my $failed_tests = shift;
        print "$failed_tests\n";
        # notify IRC or register issue tickets..
    });

### \[PLAN CONFIGURATION\] : config/ikaros.conf

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

### \[HOST CONFIGURATION\] : config/hosts.yaml

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

# DESCRIPTION

App::Ikaros is distributed testing framework for jenkins.

# METHODS

# AUTHOR

Masaaki Goshima (goccy) <goccy54@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) Masaaki Goshima (goccy).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
