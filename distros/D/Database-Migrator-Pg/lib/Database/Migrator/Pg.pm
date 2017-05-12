package Database::Migrator::Pg;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.06';

use Database::Migrator 0.07;
use Database::Migrator::Types qw( HashRef Str );
use Pg::CLI 0.11;
use Pg::CLI::createdb;
use Pg::CLI::dropdb;
use Pg::CLI::psql;

use Moose;

with 'Database::Migrator::Core';

for my $create_flag (
    qw( encoding locale lc_collate lc_ctype owner tablespace template )) {

    has $create_flag => (
        is        => 'ro',
        isa       => Str,
        predicate => '_has_' . $create_flag,
    );
}

has _psql => (
    is       => 'ro',
    isa      => 'Pg::CLI::psql',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_psql',
);

has _cli_constructor_args => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_cli_constructor_args',
);

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _create_database {
    my $self = shift;

    my $database = $self->database;

    $self->logger->info("Creating the $database database");

    my @opts;
    push @opts, '--encoding', $self->encoding
        if $self->_has_encoding;
    push @opts, '--locale', $self->locale
        if $self->_has_locale;
    push @opts, '--lc-collate', $self->lc_collate
        if $self->_has_lc_collate;
    push @opts, '--lc-ctype', $self->lc_ctype
        if $self->_has_lc_ctype;
    push @opts, '--owner', $self->owner
        if $self->_has_owner;
    push @opts, '--tablespace', $self->tablespace
        if $self->_has_tablespace;
    push @opts, '--template', $self->template
        if $self->_has_template;

    $self->_run_cli_or_die(
        'createdb',
        'run',
        database => $self->database,
        options  => \@opts,
    );

    return;
}

sub _run_ddl {
    my $self = shift;
    my $file = shift;

    $self->_run_cli_or_die(
        'psql',
        'execute_file',
        database => $self->database,
        file     => $file,
        options  => [ -v => 'ON_ERROR_STOP=1' ],
    );

    return;
}

sub _drop_database {
    my $self = shift;

    my $database = $self->database;

    $self->logger->info("Dropping the $database database");

    $self->_run_cli_or_die(
        'dropdb',
        'run',
        database => $self->database,
        options  => ['--if-exists'],
    );

    return;
}

sub _run_cli_or_die {
    my $self    = shift;
    my $cli_obj = shift;
    my $method  = shift;
    my %args    = @_;

    my $cli_obj_method = q{_} . $cli_obj;

    my $stdout;
    my $stderr;
    $self->$cli_obj_method->$method(
        %args,
        stdout => \$stdout,
        stderr => \$stderr,
    );

    die $stderr if $stderr;

    return $stdout;
}

sub _createdb {
    my $self = shift;

    return Pg::CLI::createdb->new( $self->_cli_constructor_args );
}

sub _dropdb {
    my $self = shift;

    return Pg::CLI::dropdb->new( $self->_cli_constructor_args );
}
## use critic

sub _build_psql {
    my $self = shift;

    return Pg::CLI::psql->new(
        %{ $self->_cli_constructor_args },
        quiet => 1,
    );
}

sub _build_cli_constructor_args {
    my $self = shift;

    my %args;
    for my $m (qw( username password host port )) {
        $args{$m} = $self->$m
            if defined $self->$m;
    }

    return \%args;
}

around _build_dbh => sub {
    my $orig = shift;
    my $self = shift;

    my $dbh = $self->$orig(@_);

    $dbh->do('SET CLIENT_MIN_MESSAGES = ERROR');

    return $dbh;
};

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _driver_name {'Pg'}
## use critic

__PACKAGE__->meta->make_immutable;

1;

#ABSTRACT: Database::Migrator implementation for Postgres

__END__

=pod

=encoding UTF-8

=head1 NAME

Database::Migrator::Pg - Database::Migrator implementation for Postgres

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  package MyApp::Migrator;

  use Moose;

  extends 'Database::Migrator::Pg';

  has '+database' => (
      required => 0,
      default  => 'MyApp',
  );

=head1 DESCRIPTION

This module provides a L<Database::Migrator> implementation for Postgres. See
L<Database::Migrator> and L<Database::Migrator::Core> for more documentation.

=head1 ATTRIBUTES

This class adds several attributes in addition to those implemented by
L<Database::Migrator::Core>. All of these attributes are optional.

=over 4

=item * encoding

The encoding of the database. This is only used when creating a new
database.

=item * locale

The locale of the database. This is only used when creating a new
database.

=item * lc_collate

The LC_COLLATE setting for the database. This is only used when creating a new
database.

=item * lc_ctype

The LC_CTYPE setting for the database. This is only used when creating a new
database.

=item * owner

The owner of the database. This is only used when creating a new
database.

=item * tablespace

The tablespace for the database. This is only used when creating a new
database.

=item * template

The template for the database. This is only used when creating a new database.

=back

=head1 SUPPORT

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Database-Migrator-Pg or via email at
bug-database-migrator-pg@rt.cpan.org.

Bugs may be submitted through L<https://github.com/maxmind/Database-Migrator-Pg/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Gregory Oschwald Kevin Phair

=over 4

=item *

Gregory Oschwald <goschwald@maxmind.com>

=item *

Kevin Phair <phair.kevin@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2017 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
