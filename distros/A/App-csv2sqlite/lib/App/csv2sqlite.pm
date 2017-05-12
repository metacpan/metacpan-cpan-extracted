# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of App-csv2sqlite
#
# This software is copyright (c) 2012 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package App::csv2sqlite;
{
  $App::csv2sqlite::VERSION = '0.004';
}
# git description: v0.003-3-g85d53f9

BEGIN {
  $App::csv2sqlite::AUTHORITY = 'cpan:RWSTAUNER';
}
# ABSTRACT: Import CSV files into a SQLite database

use Moo 1;

use DBI 1.6 ();
use DBD::SQLite 1 ();
use DBIx::TableLoader::CSV 1.102 (); # catch csv errors and close transactions; file_encoding
use Getopt::Long 2.34 ();

sub new_from_argv {
  my ($class, $args) = @_;
  $class->new( $class->getopt($args) );
}

around BUILDARGS => sub {
  my ($orig, $self, @args) = @_;
  my $args = $self->$orig(@args);

  if( my $enc = delete $args->{encoding} ){
    ($args->{loader_options} ||= {})->{file_encoding} ||= $enc;
  }

  return $args;
};

has csv_files => (
  is         => 'ro',
  coerce     => sub { ref $_[0] eq 'ARRAY' ? $_[0] : [ $_[0] ] },
);

has csv_options => (
  is         => 'ro',
  default    => sub { +{} },
);

has loader_options => (
  is         => 'ro',
  default    => sub { +{} },
);

has dbname => (
  is         => 'ro',
);

has dbh => (
  is         => 'lazy',
);

sub _build_dbh {
  my ($self) = @_;
  # TODO: does the dbname need to be escaped in some way?
  my $dbh = DBI->connect('dbi:SQLite:dbname=' . $self->dbname, undef, undef, {
    RaiseError => 1,
    PrintError => 0,
    sqlite_unicode => $self->encoding ? 1 : 0,
  });
  return $dbh;
}

sub encoding {
  return $_[0]->loader_options->{file_encoding};
}

sub help { Getopt::Long::HelpMessage(2); }


sub getopt {
  my ($class, $args) = @_;
  my $opts = {};

  {
    local @ARGV = @$args;
    my $p = Getopt::Long::Parser->new(
      config => [qw(pass_through auto_help auto_version)],
    );
    $p->getoptions($opts,
      'csv_files|csv-file|csvfile|csv=s@',
      # TODO: 'named_csv_files=s%'
      # or maybe --csv and --named should be subs that append to an array ref to keep order?
      'csv_options|csv-opt|csvopt|o=s%',
      # TODO: tableloader options like 'drop' or maybe --no-create
      'loader_options|loader-opt|loaderopt|l=s%',
      'dbname|database=s',
      'encoding|enc|e=s',
    ) or $class->help;
    $args = [@ARGV];
  }

  # last arguments
  $opts->{dbname} ||= pop @$args;

  # first argument
  if( @$args ){
    push @{ $opts->{csv_files} ||= [] }, @$args;
  }

  return $opts;
}

sub load_tables {
  my ($self) = @_;

  # TODO: option for wrapping the whole loop in a transaction rather than each table

  foreach my $file ( @{ $self->csv_files } ){
    my %opts = (
      %{ $self->loader_options },
      csv_opts => { %{ $self->csv_options } },
      file => $file,
    );

    # TODO: This could work but i hate the escaping thing.
    # Allow table=file (use "=file" for files with an equal sign).
    #if( $file =~ /^([^=:]*)[=:](.+)$/ ){ $opts{name} = $1 if $1; $opts{file} = $2; }

    DBIx::TableLoader::CSV->new(
      %opts,
      dbh  => $self->dbh,
    )->load;
  }

  return;
}

sub run {
  my $class = shift || __PACKAGE__;
  my $args = @_ ? shift : [@ARGV];

  my $self = $class->new_from_argv($args);
  $self->load_tables;
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS TODO CSV csv sqlite csv2sqlite --csv
--csv-file --csv-opt --dbname cpan testmatrix url annocpan anno bugtracker
rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

App::csv2sqlite - Import CSV files into a SQLite database

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  csv2sqlite doggies.csv kitties.csv pets.sqlite

  # configure CSV parsing as necessary:
  csv2sqlite -o sep_char=$'\t' plants.tab plants.sqlite

=head1 DESCRIPTION

Import CSV files into a SQLite database
(using L<DBIx::TableLoader::CSV>).

Each csv file specified on the command line
will became a table in the resulting sqlite database.

=head1 OPTIONS

=over 4

=item --csv-file (or --csv)

The csv files to load

=item --csv-opt (or -o)

A hash of key=value options to pass to L<Text::CSV>

=item --dbname (or --database)

The file path for the SQLite database

=item --encoding (or -e)

The encoding of the csv files (a shortcut for C<< --loader-opt file_encoding=$enc >>);
(Strings will be stored in the database in UTF-8.)

=item --loader-opt (or -l)

A hash of key=value options to pass to L<DBIx::TableLoader::CSV>

=back

=for Pod::Coverage new_from_argv
help
getopt
load_tables
run
csv_files
csv_options
loader_options
dbname
dbh
BUILDARGS
encoding

=head1 TODO

=over 4

=item *

specific L<DBIx::TableLoader> options?

=item *

confirm using a pre-existing database?

=item *

more tests

=item *

allow specifying table names for csv files

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc App::csv2sqlite

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/App-csv2sqlite>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-csv2sqlite>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/App-csv2sqlite>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-csv2sqlite>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-csv2sqlite>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::csv2sqlite>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-csv2sqlite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-csv2sqlite>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/App-csv2sqlite>

  git clone https://github.com/rwstauner/App-csv2sqlite.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
