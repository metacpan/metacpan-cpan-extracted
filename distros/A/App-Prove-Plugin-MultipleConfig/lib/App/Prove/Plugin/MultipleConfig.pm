package App::Prove::Plugin::MultipleConfig;
use strict;
use warnings;

use POSIX::AtFork;
use DBI;

use ConfigCache;

our $VERSION = '0.02';

sub load {
    my ($class, $prove) = @_;

    my @args = @{$prove->{args}};
    foreach (@args) { $_ =~ s/"//g; }
    my $module = shift @args;
    my @configs = @args;
    my $jobs = $prove->{ app_prove }->jobs || 1;
    if (scalar @configs < $jobs){
        die "the number of dsn(" . scalar @configs . ") must be grater than jobs: $jobs.";
    }

    if ($module){
        eval "require $module"  ## no critic
            or die "$@";

        for my $config (@configs){
            my $valid = do $config;
            if (!defined $valid){
                die "argument: $config is invalid";
            }
            $module->can("prepare") ? $module->prepare($config) : die "$module don't have prepare method";
        }
    }

    ConfigCache->set_configs(\@configs);

    $prove->{ app_prove }->formatter('TAP::Formatter::MultipleConfig');
    $prove->{ app_prove }->harness('TAP::Harness::MultipleConfig');

    POSIX::AtFork->add_to_child( \&child_hook );
}


sub child_hook {
    my ($call) = @_;
    ($call eq 'fork') or return;

    my $config = ConfigCache->pop_configs();
    ConfigCache->set_config_by_pid($$, $config);
    $ENV{ PERL_MULTIPLE_CONFIG } = $config;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Prove::Plugin::MultipleConfig - set multiple configs for parallel prove tests

=head1 SYNOPSIS

 prove -j3 -PMySQLPool t::Prepare,./config/config1.pl,./config/config2.pl,./config/config3.pl

=head1 DESCRIPTION

App::Prove::Plugin::MultipleConfig is L<prove> plugin for setting multiple configs for parallel test.

This plugin enables you to change each environment for each test.
For example, if you want to use some databases and redis when testing, each test can use a different database and redis.

First, you make config files, the number of files is -j(the number of jobs).
Each test reads this config file like C<do $config_path;>.

    # ./config/config1.pl
    my $config = +{
        'DB' => {
            uri => 'DBI:mysql:database=test_db;hostname=127.0.0.1;port=10002',
            username => 'root',
            password => 'root',
        },
        'REDIS' => +{
            server => '127.0.0.1:20003',
        },
    };

    $config;

Next, you make a module for initializing tests. This method is called B<once every config> before starting tests.
This module must have a C<prepare> method whose second argument is a config path.

    # t/Prepare.pm
    sub prepare {
        my ($self, $config) = @_;
        my $conf = do $config;

        my $uri = $conf->{DB}->{uri};
        $uri =~ s/database=.+?;/database=mysql;/; # use mysql table
        my $dbh = DBI->connect($uri, $conf->{DB}->{username}, $conf->{DB}->{password},
            {'RaiseError' => 1}
        );
        ....
    }

In the end, you pass arguments to prove for specifying prepare module and config files paths.
This format is comma-separated value(CSV). First value is prepared module name. Subsequent values are config files path.

 prove -j3 -PMySQLPool t::Prepare,./config/config1.pl,./config/config2.pl,./config/config3.pl

Congratulations! In each test, you can read C<ENV{PERL_MULTIPLE_CONFIG}> which returns a config path.

    # your test code
    my $config_path = $ENV{PERL_MULTIPLE_CONFIG};
    my $conf = do $config_path;


=head1 LICENSE

Copyright (C) takahito.yamada.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

takahito.yamada

=head1 SEE ALSO

L<prove>, L<App::Prove::Plugin::MySQLPool>

=cut
