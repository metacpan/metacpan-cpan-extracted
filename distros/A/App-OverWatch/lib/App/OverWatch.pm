package App::OverWatch;

# ABSTRACT: Watch over your infrastructure
our $VERSION = '0.1'; # VERSION

use strict;
use warnings;

use App::OverWatch::DB;
use App::OverWatch::ServiceLock;
use App::OverWatch::EventLog;
use App::OverWatch::Notify;
use App::OverWatch::Config;

use Config::Tiny;

sub new {
    my $class = shift;
    my $rh_options = shift || {};

    my $self = bless( {}, $class );

    return $self;
}


sub servicelock {
    my $self = shift;

    if (!defined($self->{ServiceLock})) {
        $self->{ServiceLock} = App::OverWatch::ServiceLock->new({
            db => $self->_db()
        });
    }
    return $self->{ServiceLock};
}

sub notify {
    my $self = shift;

    if (!defined($self->{Notify})) {
        $self->{Notify} = App::OverWatch::Notify->new({
            db => $self->_db()
        });
    }
    return $self->{Notify};
}

sub eventlog {
    my $self = shift;

    if (!defined($self->{Eventlog})) {
        $self->{Eventlog} = App::OverWatch::Eventlog->new({
            db => $self->_db()
        });
    }
    return $self->{Eventlog};
}

sub check_options {
    my $self    = shift;
    my $rh_args = shift || {};

    my $ra_commands = $rh_args->{valid_commands};
    my $rh_options  = $rh_args->{options};
    my $rh_required = $rh_args->{required_options};

    ## Check that only one actual command was provided
    my $commands = join(', ', sort @$ra_commands);
    my @commands = map { $rh_options->{$_} ? $_ : () } @$ra_commands;
    die "Error: Please specify one and only one command ($commands)\n"
        if (scalar @commands != 1);

    my $command = $commands[0];

    ## Check all required options are defined
    for my $opt (@{ $rh_required->{$command} }) {
        die "Error: --$opt is a required option\n"
            if (!defined($rh_options->{$opt}));
    }

    return $command;
}

sub load_config {
    my $self = shift;
    my $path = shift;

    my $rh_conf;

    my @paths;
    if (defined($path)) {
        @paths = ( $path );
    } else {
        @paths = ( $ENV{HOME} . "/.overwatch.conf",
                       "/etc/overwatch.conf" );
    }

  FILE:
    for my $file (@paths) {
        next FILE
            if (!defined($file) || ! -f $file);

        my $Config = Config::Tiny->read($file);
        $rh_conf = $Config->{_}
            if ($Config && defined($Config->{_}));
    }

    die "Error: Couldn't load configuration from "
        . join(', ', @paths) . "\n"
            if (!defined($rh_conf));

    die "Error: Require 'db_type' to be set in config\n"
        if (!$rh_conf->{db_type});

    $self->{Config} = App::OverWatch::Config->new($rh_conf);
}

sub load_config_string {
    my $self = shift;
    my $string = shift;

    my $Config = Config::Tiny->read_string($string);
    my $rh_conf = $Config->{_}
        if ($Config && defined($Config->{_}));

    die "Error: Couldn't load configuration from string\n"
        if (!defined($rh_conf));

    die "Error: Require 'db_type' to be set in config\n"
        if (!$rh_conf->{db_type});

    $self->{Config} = App::OverWatch::Config->new($rh_conf);
}

sub _db {
    my $self = shift;

    if (!defined($self->{DB})) {
        $self->{DB} = App::OverWatch::DB->new( $self->{Config} );
    }
    return $self->{DB};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch - Watch over your infrastructure

=head1 VERSION

version 0.1

=head1 SYNOPSIS

  use App::OverWatch;
  my $OverWatch = App::OverWatch->new();
  $OverWatch->load_config();

  my $ServiceLock = $OverWatch->ServiceLock();

=head1 DESCRIPTION

Designed to provide a simple framework to give some oversight to applications
running in a distributed environment.  Applications can quickly
register/release simple locks, register and send notifications, and log events
to a database using a very simple interface.

=head1 CONFIGURATION

Database configuration is loaded from a config file by load_config() and
looks as follows:

  db_type = postgres
  user = test
  password = test
  dsn = DBI:Pg:database=test

Valid db_types are mysql, postgres, sqlite.

=head1 METHODS

=head2 new

Create an App::OverWatch object.

  my $OverWatch = App::OverWatch->new();

=head2 servicelock

Return a App::OverWatch::ServiceLock object.

=head2 notify

Return a App::OverWatch::Notify object.

=head2 eventlog

Return a App::OverWatch::EventLog object.

=head2 check_options

Checks Getopt::Long options for command line scripts.  Checks that only
one of a list of commands 'valid_commands' is provided, and that all
required options 'required_options' have been passed.

Dies on any missing requirements.  Returns the command.

=head2 load_config

    $OverWatch->load_config();

    $OverWatch->load_config($filename);

Loads OverWatch DB connection configuration from a text file, by
default it will try ~/.overwatch.conf and then /etc/overwatch.conf.

If a filename is provided, it will only try to load that file.

=head2 load_config_string

        $OverWatch->load_config_string('
# A comment
db_type = sqlite
user =
password =
dsn = DBI::SQLite:dbname=:memory:
');

Loads a configuration from a string.

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
