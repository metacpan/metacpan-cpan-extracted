package App::DoubleUp;
use strict;
use warnings;
our $VERSION = '0.4.2';

use 5.010;


use Carp;
use DBI;
use YAML;
use File::Slurp;
use SQL::SplitStatement;
use File::Spec::Functions 'catfile';
use IO::Handle;

sub new {
    my ($klass, $args) = @_;

    my $self = bless {}, $klass;

    if (!$args->{config_file}) {
        for ('.', $ENV{HOME}) {
            my $filename = catfile($_, '.doubleuprc');
            if (-e $filename) {
                $args->{config_file} = $filename;
                last;
            }
        }
    }
    $self->{config_file} = $args->{config_file};

    $self->{config} = $self->load_config($self->config_file);

    return $self; 
}

sub config_file {
    my $self = shift;
    return $self->{config_file};
}

sub load_config {
    my ($self, $filename) = @_;
    return YAML::LoadFile($filename);
}

sub source {
    my ($self) = @_;
    return $self->{config}{source};
}

sub process_args {
    my ($self, @args) = @_;

    $self->{command} = shift @args;

    if ($self->{command} eq 'import1') {
        $self->{db} = [shift @args];
        $self->{command} = 'import';
    }

    $self->{files} = \@args;

    return;
}

sub process_files {
    my ($self, $files) = @_;

    my @querys;

    local $/ = ";\n";

    for my $filename (@$files) {
        push @querys, $self->split_sql_file($filename);
    }

    return @querys;
}
sub split_sql_file {
    my ($self, $filename) = @_;
    my $splitter = SQL::SplitStatement->new();
    return $splitter->split(scalar read_file($filename));
}

sub db_prepare {
    my ($db, $query) = @_;
    my $stmt = $db->prepare($query);
    return $stmt;
}

sub db_flatarray {
    my ($db, $query, @args) = @_;
    my $stmt = db_prepare($db, $query);
    $stmt->execute(@args);
    my @vals;
    while (my $row = $stmt->fetchrow_arrayref) {
        push @vals, $row->[0];
    }
    return @vals;
}

sub list_of_schemata {
    my ($self) = @_;
    my $source = $self->source;
    if ($source->{type} eq 'config') {
        return @{ $source->{databases} };
    }
    elsif ($source->{type} eq 'database') {
        my $db = $self->connect_to_db('dbi:mysql:information_schema', $self->credentials);
        return db_flatarray($db, $source->{schemata_sql});
    }
}

sub credentials {
    my $self = shift;
    return @{$self->{config}{credentials}};
}

sub connect_to_db {
    my ($self, $dsn, $user, $password) = @_;
    return DBI->connect($dsn, $user, $password, { RaiseError => 1, PrintError => 0 }) || croak "Error while connecting to '$dsn'";
}

sub process_querys_for_one_db {
    my ($self, $db, $querys) = @_;

    for my $q (@$querys) {
        if ($self->process_one_query($db, $q)) {
            print '.';
        }
        else {
            print '!';
        }
    }
    return;
}

sub process_one_query {
    my ($self, $db, $q) = @_;

    eval { 
        $db->do($q);
    };
    if ($@) {
        return;
    }
    return 1;
}

sub command {
    my $self = shift;
    return $self->{command};
}

sub database_names {
    my $self = shift;
    $self->{db} //= [ $self->list_of_schemata ];
    return $self->{db};
}

sub files {
    my $self = shift;
    return $self->{files};
}

sub run {
    my ($self) = @_;

    STDOUT->autoflush(1);

    given ($self->command) {
        when ('version') {
            say "doubleup version $VERSION";
        }
        when ('listdb') {
            my @db = $self->list_of_schemata();
            for (@db) {
                say;
            }
        }
        when ('import') {
            my @querys = $self->process_files($self->files);

            for my $schema (@{ $self->database_names }) {
                my $dsn = 'dbi:mysql:'.$schema;
                say "DB: $schema";
                my $db = $self->connect_to_db($dsn, $self->credentials);
                $self->process_querys_for_one_db($db, \@querys);
                say '';
            }
        }
        when (undef) {
            $self->usage;
        }
        default {
            say "Unknown command: $_";
            $self->usage;
        }
    }
    return;

}
sub usage {
    my $self = shift;
    say "Usage: doubleup [command] [options]";
    say "";
    say "List of commands";
    say "";
    say "  listdb                   list of schemata";
    say "  import [filename]        import a file into each db";
    say "  import1 [db] [filename]  import a file into one db";
    say "  version                  show version";
    say "";
    return;
}

1;

=head1 NAME

App::DoubleApp - Import SQL files into MySQL

=head1 SYNOPSIS

    $ doubleup listdb
    ww_test1
    ww_test2
    ww_test3
    ww_test4
    $ doubleup import1 ww_test db/01_base.sql
    .
    $ doubleup import db/02_upgrade.sql
    ....

=head1 DESCRIPTION

Import SQL files into a DBI compatible database.

=head1 AUTHOR

Peter Stuifzand E<lt>peter@stuifzand.euE<gt>

=head1 COPYRIGHT

Copyright 2013- Peter Stuifzand

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
