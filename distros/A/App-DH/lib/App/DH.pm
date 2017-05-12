use 5.006;    # our
use strict;
use warnings;

package App::DH;

our $VERSION = '0.004001';

# ABSTRACT: Deploy your DBIx::Class Schema to DDL/Database via DBIx::Class::DeploymentHandler

our $AUTHORITY = 'cpan:MSTROUT'; # AUTHORITY

use Carp qw( croak );
use DBIx::Class::DeploymentHandler;
use Moose qw( with has around );
use MooseX::Getopt 0.48 ();
use PerlX::Maybe qw( maybe );

with 'MooseX::Getopt';














has connection_name => (
  traits        => ['Getopt'],
  is            => ro =>,
  isa           => Str =>,
  required      => 1,
  cmd_aliases   => c =>,
  default       => sub { 'development' },
  documentation => 'either a valid DBI DSN or an alias configured by DBIx::Class::Schema::Config',
);









has force => (
  traits        => ['Getopt'],
  is            => ro =>,
  isa           => Bool =>,
  default       => sub { 0 },
  cmd_aliases   => f =>,
  documentation => 'forcefully replace existing DDLs. [DANGER]',
);












has schema => (
  traits        => ['Getopt'],
  is            => ro =>,
  isa           => Str =>,
  required      => 1,
  cmd_aliases   => s =>,
  documentation => 'the class name of the schema to generate DDLs/deploy for',
);














has include => (
  traits        => ['Getopt'],
  is            => ro =>,
  isa           => ArrayRef =>,
  default       => sub { [] },
  cmd_aliases   => I =>,
  documentation => 'paths to load into INC',
);














has script_dir => (
  traits        => ['Getopt'],
  is            => ro =>,
  isa           => Str =>,
  default       => sub { 'share/ddl' },
  cmd_aliases   => o =>,
  documentation => 'output path',
);
















has database => (
  traits        => ['Getopt'],
  is            => 'ro',
  lazy          => 1,
  builder       => '_build_database',
  isa           => ArrayRef =>,
  cmd_aliases   => d =>,
  documentation => 'SQL::Translator::Producer::* database backends to generate DDLs for',
);











has target => (
  traits        => ['Getopt'],
  isa           => 'Str',
  is            => 'ro',
  predicate     => 'has_target',
  cmd_aliases   => 'v',
  documentation => 'version to install/upgrade to',
);

has _dh     => ( is => 'ro', lazy => 1, builder => '_build__dh' );
has _schema => ( is => 'ro', lazy => 1, builder => '_build__schema' );

sub _build__schema {
  my ($self) = @_;
  require lib;
  lib->import($_) for @{ $self->include };
  require Module::Runtime;
  my $class = Module::Runtime::use_module( $self->schema );
  return $class->connect( $self->connection_name );
}

sub _build__dh {
  my ($self) = @_;
  return DBIx::Class::DeploymentHandler->new(
    {
      schema           => $self->_schema,
      force_overwrite  => $self->force,
      script_directory => $self->script_dir,
      databases        => $self->database,
      maybe to_version => $self->target,
    },
  );
}

sub _build_database {
  my ($self) = @_;
  my $type = $self->_schema->storage->sqlt_type;

  # Note: This seemingly needless stringification
  # exists to solve an incredibly complex problem on bleadperl
  # with COW, and for some reason, the string sqlt_type
  # returns as the flag 'IsCOW',
  # which for some reason causes a warning when the invoking
  # perl interpreter terminates.
  #
  # If you can solve the bug in bleadperl, I'll
  # gladly remove the forced stringification of the COW string.
  #
  # -- kentnl @ Feb 16/2013
  # -- perl (v5.17.9 (v5.17.8-156-g012528a))
  return ["$type"];
}









sub cmd_write_ddl {
  my ($self) = @_;
  $self->_dh->prepare_install;
  my $v = $self->_dh->schema_version;
  if ( $v > 1 ) {
    $self->_dh->prepare_upgrade(
      {
        from_version => $v - 1,
        to_version   => $v,
      },
    );
  }
  return;
}









sub cmd_install {
  my $self = shift;
  $self->_dh->install;
  return;
}









sub cmd_upgrade {
  my $self = shift;
  $self->_dh->upgrade;
  return;
}







sub cmd_database_version {
    my $self = shift;

  ## no critic (RequireCheckedSyscalls)
  print $self->_dh->database_version . "\n";

  return;
}









sub cmd_schema_version {
  my $self = shift;

  ## no critic (RequireCheckedSyscalls)
  print $self->_dh->schema_version . "\n";

  return;
}

my (%cmds) = (
  write_ddl        => \&cmd_write_ddl,
  install          => \&cmd_install,
  upgrade          => \&cmd_upgrade,
  database_version => \&cmd_database_version,
  schema_version   => \&cmd_schema_version,
);
my (%cmd_desc) = (
  write_ddl        => 'only write ddl files',
  install          => 'install to the specified database connection',
  upgrade          => 'upgrade the specified database connection',
  database_version => 'report the version of the specified database connection',
  schema_version   => 'report the version of the schema class',
);
my $list_cmds = join q[ ], sort keys %cmds;
my $list_cmds_opt = '(' . ( join q{|}, sort keys %cmds ) . ')';
my $list_cmds_usage =
  ( join qq{\n}, q{}, qq{\tcommands:}, q{}, ( map { ( sprintf qq{\t%-30s%s}, $_, $cmd_desc{$_} ) } sort keys %cmds ), q{} );














around print_usage_text => sub {
  my ( undef, undef, $usage ) = @_;
  my ($text) = $usage->text();
  $text =~ s{
        ( long\s+options[.]+[]] )
    } {
        $1 . ' ' . $list_cmds_opt
    }msex;
  $text .= qq{\n} . $text . $list_cmds_usage . qq{\n};
  print $text or croak q[Cannot write to STDOUT];
  exit 0;
};

sub run {
  my ($self) = @_;
  my ( $cmd, @what ) = @{ $self->extra_argv };
  croak "Must supply a command\nCommands: $list_cmds\nFailed" unless $cmd;
  croak "Extra argv detected - command only please\nFailed" if @what;
  croak "No such command ${cmd}\nCommands: $list_cmds\nFailed"
    unless exists $cmds{$cmd};
  my $code = $cmds{$cmd};
  return $self->$code();
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DH - Deploy your DBIx::Class Schema to DDL/Database via DBIx::Class::DeploymentHandler

=head1 VERSION

version 0.004001

=head1 SYNOPSIS

Basic usage:

    #!/usr/bin/env perl
    #
    # dh.pl

    use App::DH;
    App::DH->new_with_options->run;

--

	usage: dh.pl [-?cdfhIos] [long options...] (install|upgrade|write_ddl)
		-h -? --usage --help     Prints this usage information.
		-c --connection_name     either a valid DBI DSN or an alias
		                         configured by DBIx::Class::Schema::Config
		-f --force               forcefully replace existing DDLs. [DANGER]
		-s --schema              the class name of the schema to generate
		                         DDLs/deploy for
		-I --include             paths to load into @INC
		-o --script_dir          output path
		-d --database            database backends to generate DDLs for. See
		                         SQL::Translator::Producer::* for valid values

		commands:

		install                       install to the specified database connection
		upgrade                       upgrade the specified database connection
		write_ddl                     only write ddl files

If you don't like any of the defaults, you can subclass to override

    use App::DH;
    {
        package MyApp;
        use  Moose;
        extends 'App::DH';

        has '+connection_name' => ( default => sub { 'production' } );
        has '+schema'          => ( default => sub { 'MyApp::Schema' } );
        __PACKAGE__->meta->make_immutable;
    }
    MyApp->new_with_options->run;

=head1 DESCRIPTION

App::DH is a basic skeleton of a command line interface for the excellent
L<< C<DBIx::Class::DeploymentHandler>|DBIx::Class::DeploymentHandler >>, to make executing database deployment stages easier.

=head1 COMMANDS

=head2 write_ddl

Only generate ddls for deploy/upgrade

    dh.pl [...params] write_ddl

=head2 install

Install to connection L</--connection_name>

    dh.pl [...params] install

=head2 upgrade

Upgrade connection L</--connection_name>

    dh.pl [...params] upgrade

=head2 database_version

Report database_version of L</--connection>

=head2 schema_version

Report schema_version of L</--schema>

    dh.pl [...params] schema_version

=head1 PARAMETERS

=head2 --connection_name

    -c/--connection_name

Specify the connection details to use for deployment.
Can be a name of a configuration in a C<DBIx::Class::Schema::Config> configuration if the L</--schema> uses it.

    --connection_name 'dbi:SQLite:/path/to/db'

    -cdevelopment

=head2 --force

Overwrite existing DDL files of the same version.

    -f/--force

=head2 --schema

    -s/--schema

The class name of the schema to load for DDL/Deployment

    -sMyProject::Schema
    --schema MyProject::Schema

=head2 --include

    -I/--include

Add a given library path to @INC prior to loading C<schema>

    -I../lib
    --include ../lib

May be specified multiple times.

=head2 --script_dir

    -o/--script_dir

Specify where to write the per-backend DDL's.

Default is ./share/ddl

    -o/tmp/ddl
    --script_dir /tmp/ddl

=head2 --database

    -d/--database

Specify the C<SQL::Translator::Producer::*> backend to use for generating DDLs.

    -dSQLite
    --database PostgreSQL

Can be specified multiple times.

Default is introspected from looking at whatever L</--connection_name> connects to.

=head2 --target

    --target

Specify which version to install/upgrade to.

If not specified, defaults to the latest version.

=for Pod::Coverage     cmd_write_ddl
    cmd_install
    cmd_upgrade
    cmd_database_version
    cmd_schema_version
    run

=head1 CREDITS

This module is mostly code by mst, sponsored by L<nordaaker.com|http://nordaaker.com>, and I've only tidied it up and made it
more CPAN Friendly.

=head1 SPONSORS

The authoring of the initial incarnation of this code is kindly sponsored by L<nordaaker.com|http://nordaaker.com>.

=head1 AUTHORS

=over 4

=item *

kentnl - Kent Fredric (cpan:KENTNL) <kentnl@cpan.org>

=item *

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by The App::DH Authors, Contributors, and Sponsors.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
