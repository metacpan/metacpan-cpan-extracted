package App::test::travis;
use 5.10.0;
use strict;
use warnings;

use version; our $VERSION = version->declare("v0.9.7");

use encoding::warnings 'FATAL';
use Fatal qw(open close);

use File::Temp qw(tempdir);
use Config qw(%Config);
use File::Spec ();
use Getopt::Long qw(GetOptionsFromArray :config posix_default no_ignore_case bundling auto_version);
use autouse 'Pod::Usage' => qw(pod2usage);
use autouse 'Pod::Find'  => qw(pod_where);
use YAML ();

my $path_sep = $Config{path_sep};

my %tab = (
    c => {
        script => './configure && make && make test',
    },
    cpp => {
        script => './configure && make && make test',
    },
    clojure => {
        script => 'lein test',
    },
    erlang => {
        install => 'rebar get-deps',
        script => 'rebar compile && rebar skip_deps=true eunit',
    },
    go => {
        install => 'go get -d -v ./... && go build -v ./...',
        script => 'make',
    },
    groovy => {
        install => 'gradle assemble',
        script => 'gradle check',
    },
    haskell => {
        install => 'cabal install --only-dependencies --enable-tests',
        script => 'cabal configure --enable-tests && cabal build && cabal test',
    },
    java => {
        install => 'mvn install -DskipTests=true',
        script => 'mvn test',
    },

    node_js => {
        setup => sub {
            my($config, $tempdir, $cb) = @_;
            local $ENV{PATH} = join $path_sep, "node_modules/.bin", $ENV{PATH};
            $cb->();
        },
        install => 'npm install',
        script => 'npm test',
    },

    perl => {
        setup => sub {
            my($config, $tempdir, $cb) = @_;
            local $ENV{PERL_CPANM_OPT} = "-l$tempdir --verbose";
            local $ENV{PERL5OPT}       = "-Mlib=$tempdir/lib/perl5";
            local $ENV{PATH}           = join $path_sep, "$tempdir/bin", $ENV{PATH};

            $cb->();
        },
        install => 'cpanm --installdeps --notest .',
        script => 'cpanm --test-only .',
    },

    php => {
        script => 'phpunit',
    },

    python => {
        install => 'pip install -r requirements.txt --use-mirrors',
    },

    ruby => {
        install => 'bundle install',
        script => 'bundle exec rake',
    },

    scala => {
        script => 'sbt test',
    },
);

sub run {
    my($class, @args) = @_;

    my $start = time();

    my $DRY_RUN;
    my $HELP;

    GetOptionsFromArray(\@args,
        '--dry-run' => \$DRY_RUN,
        '--help'    => \$HELP,
    ) or return help(1);
    return help(0) if $HELP;

    my($travis_yml) = @args;
    $travis_yml //= '.travis.yml';

    my $config = YAML::LoadFile($travis_yml);

    my $language = lc($config->{language} // 'ruby');

    my $behavior = $tab{$language} or die "no behavior defined for $language\n";

    close STDIN;
    open STDIN, '<', File::Spec->devnull;

    if ($ENV{TRAVIS} && $ENV{CI}) {
        say '# skip because TRAVIS and CI are already set';
        return;
    }
    say "# running $travis_yml";

    # Travis CI Environment Variables
    # http://about.travis-ci.org/docs/user/osx-ci-environment/
    local $ENV{CI} = 'true';
    local $ENV{TRAVIS} = 'true';

    my $tempdir = tempdir('.travis-run-XXXXXXX', CLEANUP => 1);
    my $setup = $behavior->{setup} //  sub {
        my($config, $tempdir, $cb) = @_;
        $cb->();
    };

    for my $mode(qw(before_install install script)) {
        $config->{$mode} //= $behavior->{$mode};
    }

    $setup->($config, $tempdir, sub {
        my $versions = $config->{$language} // []; # TODO

        # http://about.travis-ci.org/docs/user/build-configuration/#Build-Lifecycle
        run_commands($config, $DRY_RUN, 'before_install');
        run_commands($config, $DRY_RUN, 'install');
        run_commands($config, $DRY_RUN, 'before_script');
        eval {
            run_commands($config, $DRY_RUN, 'script');
        };
        if (! $@) {
            run_commands($config, $DRY_RUN, 'after_success');
        }
        else {
            run_commands($config, $DRY_RUN, 'after_failure');
        }
        run_commands($config, $DRY_RUN, 'after_script');

        say '# finished: ', scalar localtime;

        my $duration = (time() - $start);
        if ($duration > 60) {
            say sprintf '# duration: %d min %d sec', int($duration / 60), $duration % 60;
        }
        else {
            say sprintf '# duration: %d sec', $duration;
        }
    });
    return 0;
}

sub run_commands {
    my($config, $dry_run, $mode) = @_;
    return unless defined $config->{$mode};
    say "# $mode";
    my @cmds = ref($config->{$mode}) eq 'ARRAY'
        ? @{$config->{$mode}}
        :  ($config->{$mode});
    for my $cmd(@cmds) {
        xsystem($dry_run, $cmd);
    }
}

sub xsystem {
    my($dry_run, @command) = @_;

    say "\$ @command";
    unless($dry_run) {
        system(@command) == 0 or die "failed to call `@command`";
    }
}

sub help {
    my($exit_status) = @_;
    my $pod_file = pod_where({ -inc => 1 }, __PACKAGE__);
    pod2usage(
        -exitval => 'noexit',
        -input   => $pod_file,
    );
    return $exit_status;
}
1;
__END__

=encoding utf-8

=head1 NAME

App::test::travis - Runs Travis-CI scripts (.travis.yml)

=head1 USAGE

    test-travis [--dry-run] [.travis.yml]

=head1 DESCRIPTION

C<test-travis(1)> is a helper script which runs scripts defined in F<.travis.yml>, emulating Travis-CI environments.

Note that the actual Travis-CI runs projects on Linux, so Linux specific commands like C<apt-get(1)> won't work.

=head1 SEE ALSO

L<http://about.travis-ci.org/docs/user/getting-started/>

L<http://about.travis-ci.org/docs/user/build-configuration/#Build-Lifecycle> for the build lifecycle

=head1 LICENSE

Copyright (C) Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=cut

