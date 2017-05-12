package App::mimi;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp qw(croak);
use File::Spec;
use File::Basename ();
use DBI;
use App::mimi::db;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{dsn}       = $params{dsn};
    $self->{schema}    = $params{schema};
    $self->{dry_run}   = $params{dry_run};
    $self->{verbose}   = $params{verbose};
    $self->{migration} = $params{migration};
    $self->{dbh}       = $params{dbh};

    return $self;
}

sub setup {
    my $self = shift;

    my $db = $self->_build_db;

    die "Error: migrations table already exists\n" if $db->is_prepared;

    $self->_print("Creating migrations table");

    $db->prepare unless $self->_is_dry_run;

    return $self;
}

sub migrate {
    my $self = shift;

    die "Error: Schema directory is required\n"
      unless $self->{schema} && -d $self->{schema};

    my @schema_files = glob("$self->{schema}/*.sql");
    die "Error: No schema *.sql files found in '$self->{schema}'\n"
      unless @schema_files;

    my $db = $self->_build_db_prepared;

    my $last_migration = $db->fetch_last_migration;

    if ($last_migration && $last_migration->{status} ne 'success') {
        $last_migration->{error} ||= 'Unknown error';
        die "Error: Migrations are dirty. "
          . "Last error was in migration $last_migration->{no}:\n\n"
          . "    $last_migration->{error}\n"
          . "After fixing the problem run <fix> command\n";
    }

    $self->_print("Found last migration $last_migration->{no}")
      if $last_migration;

    my @migrations;
    for my $file (@schema_files) {
        my ($no, $name) = File::Basename::basename($file) =~ /^(\d+)(.*)$/;
        next unless $no && $name;

        $no = int($no);

        next if $last_migration && $no <= $last_migration->{no};

        my @sql = split /;/, $self->_slurp($file);

        push @migrations,
          {
            file => $file,
            no   => $no,
            name => $name,
            sql  => \@sql
          };
    }

    if (@migrations) {
        my $dbh = $self->{dbh};
        foreach my $migration (@migrations) {
            $self->_print("Migrating '$migration->{file}'");

            my $e;
            if (!$self->_is_dry_run) {
                eval { $dbh->do($_) for @{$migration->{sql} || []} } or do {
                    $e = $@;

                    $e =~ s{ at .*? line \d+.$}{};
                };
            }

            $self->_print("Creating migration: $migration->{no}");

            $db->create_migration(
                no      => $migration->{no},
                created => time,
                status  => $e ? 'error' : 'success',
                error   => $e
            ) unless $self->_is_dry_run;

            die "Error: $e\n" if $e;
        }
    }
    else {
        $self->_print("Nothing to migrate");
    }

    return $self;
}

sub check {
    my $self = shift;

    $self->{verbose} = 1;

    my $db = $self->_build_db;

    if (!$db->is_prepared) {
        $self->_print('Migrations are not installed');
    } else {
        my $last_migration = $db->fetch_last_migration;

        if (!defined $last_migration) {
            $self->_print('No migrations found');
        } else {
            $self->_print(sprintf 'Last migration: %d (%s)',
                $last_migration->{no}, $last_migration->{status});

            if (my $error = $last_migration->{error}) {
                $self->_print("\n" . $error);
            }
        }
    }
}

sub fix {
    my $self = shift;

    my $db = $self->_build_db_prepared;

    my $last_migration = $db->fetch_last_migration;

    if (!$last_migration || $last_migration->{status} eq 'success') {
        $self->_print('Nothing to fix');
    }
    else {
        $self->_print("Fixing migration $last_migration->{no}");

        $db->fix_last_migration unless $self->_is_dry_run;
    }
}

sub set {
    my $self = shift;

    my $db = $self->_build_db_prepared;

    $self->_print("Creating migration $self->{migration}");

    $db->create_migration(
        no      => $self->{migration},
        created => time,
        status  => 'success'
    ) unless $self->_is_dry_run;
}

sub _build_db_prepared {
    my $self = shift;

    my $db = $self->_build_db;

    die "Error: Migrations table not found. Run <setup> command first\n"
      unless $db->is_prepared;

    return $db;
}

sub _build_db {
    my $self = shift;

    my $dbh = $self->{dbh};

    if (!$dbh) {
        $dbh = DBI->connect($self->{dsn}, '', '',
            {RaiseError => 1, PrintError => 0, PrintWarn => 0});
        $self->{dbh} = $dbh;
    }

    return App::mimi::db->new(dbh => $dbh);
}

sub _print {
    my $self = shift;

    return unless $self->_is_verbose;

    print 'DRY RUN: ' if $self->_is_dry_run;

    print @_, "\n";
}

sub _is_dry_run { $_[0]->{dry_run} }
sub _is_verbose { $_[0]->{verbose} || $_[0]->_is_dry_run }

sub _slurp {
    my $self = shift;
    my ($file) = @_;

    open my $fh, '<', $file or croak $!;
    local $/;
    <$fh>;
}

1;
__END__
=pod

=head1 NAME

App::mimi - Migrations for small home projects

=head1 SYNOPSIS

    mimi --dns 'dbi:SQLite:database.db' migration --schema schema/

=head1 DESCRIPTION

You want to look at C<script/mimi> documentation instead. This is just an
implementation.

=head1 METHODS

=head2 C<new>

Creates new object. Duh.

=head2 C<check>

Prints current state.

=head2 C<fix>

Fixes last error migration by changing its status to C<success>.

=head2 C<migrate>

Finds the last migration number and runs all provided files with greater number.

=head2 C<set>

Manually set the last migration.

=head2 C<setup>

Creates migration table.

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<viacheslav.t@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017, Viacheslav Tykhanovskyi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

This program is distributed in the hope that it will be useful, but without any
warranty; without even the implied warranty of merchantability or fitness for
a particular purpose.

=cut
