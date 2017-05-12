package Database::Migrator::mysql;
{
  $Database::Migrator::mysql::VERSION = '0.05';
}
BEGIN {
  $Database::Migrator::mysql::AUTHORITY = 'cpan:DROLSKY';
}

use strict;
use warnings;
use namespace::autoclean;

use Database::Migrator 0.07;
use Database::Migrator::Types qw( Str );
use DBD::mysql;
use DBI;
use File::Slurp qw( read_file );
use IPC::Run3 qw( run3 );

use Moose;

with 'Database::Migrator::Core';

has character_set => (
    is        => 'ro',
    isa       => Str,
    predicate => '_has_character_set',
);

has collation => (
    is        => 'ro',
    isa       => Str,
    predicate => '_has_collation',
);

sub _create_database {
    my $self = shift;

    my $database = $self->database();

    $self->logger()->info("Creating the $database database");

    my $create_ddl = "CREATE DATABASE $database";
    $create_ddl .= ' CHARACTER SET = ' . $self->character_set()
        if $self->_has_character_set();
    $create_ddl .= ' COLLATE = ' . $self->collation()
        if $self->_has_collation();

    $self->_run_command(
        [ $self->_cli_args(), qw(  --batch -e ), $create_ddl ] );

    return;
}

sub _drop_database {
    my $self = shift;

    my $database = $self->database();

    $self->logger()->info("Dropping the $database database");

    my $drop_ddl = "DROP DATABASE IF EXISTS $database";

    $self->_run_command(
        [ $self->_cli_args(), qw(  --batch -e ), $drop_ddl ] );
}

sub _run_ddl {
    my $self = shift;
    my $file = shift;

    my $ddl = read_file( $file->stringify() );

    $self->_run_command(
        [ $self->_cli_args(), '--database', $self->database(), '--batch' ],
        $ddl,
    );
}

sub _cli_args {
    my $self = shift;

    my @cli = 'mysql';
    push @cli, '-u' . $self->username() if defined $self->username();
    push @cli, '-p' . $self->password() if defined $self->password();
    push @cli, '-h' . $self->host()     if defined $self->host();
    push @cli, '-P' . $self->port()     if defined $self->port();

    return @cli;
}

sub _run_command {
    my $self    = shift;
    my $command = shift;
    my $input   = shift;

    my $stdout = q{};
    my $stderr = q{};

    my $handle_stdout = sub {
        $self->logger()->debug(@_);

        $stdout .= $_ for @_;
    };

    my $handle_stderr = sub {
        $self->logger()->debug(@_);

        $stderr .= $_ for @_;
    };

    $self->logger()->debug("Running command: [@{$command}]");

    return if $self->dry_run();

    run3( $command, \$input, $handle_stdout, $handle_stderr );

    if ($?) {
        my $exit = $? >> 8;

        my $msg = "@{$command} returned an exit code of $exit\n";
        $msg .= "\nSTDOUT:\n$stdout\n\n" if length $stdout;
        $msg .= "\nSTDERR:\n$stderr\n\n" if length $stderr;

        die $msg;
    }

    return $stdout;
}

sub _driver_name { 'mysql' }

__PACKAGE__->meta()->make_immutable();

1;

#ABSTRACT: Database::Migrator implementation for MySQL

__END__

=pod

=head1 NAME

Database::Migrator::mysql - Database::Migrator implementation for MySQL

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  package MyApp::Migrator;

  use Moose;

  extends 'Database::Migrator::mysql';

  has '+database' => (
      required => 0,
      default  => 'MyApp',
  );

=head1 DESCRIPTION

This module provides a L<Database::Migrator> implementation for MySQL. See
L<Database::Migrator> and L<Database::Migrator::Core> for more documentation.

=head1 ATTRIBUTES

This class adds several attributes in addition to those implemented by
L<Database::Migrator::Core>:

=over 4

=item * character_set

The character set of the database. This is only used when creating a new
database. This is optional.

=item * collation

The collation of the database. This is only used when creating a new
database. This is optional.

=back

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by MaxMind, Inc..

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
