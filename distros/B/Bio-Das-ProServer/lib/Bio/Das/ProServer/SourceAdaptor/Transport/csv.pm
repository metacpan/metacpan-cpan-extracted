#########
# Author:        jc3
# Maintainer:    $Author: zerojinx $
# Created:       2005-11-21
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: csv.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source$
#
package Bio::Das::ProServer::SourceAdaptor::Transport::csv;

use strict;
use warnings;
use File::Spec;
use File::stat;
use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::dbi);

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub dbh {
  my $self    = shift;
  my $dbname  = $self->dbname();
  my $csv_sep = $self->config->{csv_sep_char} || "\t";
  my $eol     = "\n";
  my $table   = $self->tablename();
  my $dsn     = qq(DBI:CSV:f_dir=$dbname;csv_sep_char=$csv_sep;csv_eol=$eol;);

  $self->{dbh} ||= DBI->connect($dsn);
  $self->{dbh}->{RaiseError} = 1;

  my %cfg = ();
  if($self->config->{col_names}) {
    my $cols = [split /:/mxs, $self->config->{col_names}];
    if ( scalar @{ $cols } ) {
      $cfg{col_names} = $cols;
    }
  }
  if (my $skip_rows = $self->config->{skip_rows}) {
    $cfg{skip_rows} = $skip_rows;
  }

  if ( scalar %cfg ) {
    $self->{dbh}->{csv_tables}->{$table} = \%cfg;
  }

  return $self->{dbh};
}

sub dbname {
  my $self = shift;
  return $self->config->{path} || q(/var/tmp/);
}

sub tablename {
  my $self = shift;
  return $self->config->{filename} || 'default';
}

sub filename {
  my $self = shift;
  return File::Spec->catfile( $self->dbname(), $self->tablename() );
}

sub last_modified {
  my $self = shift;
  return stat( $self->filename() )->mtime;
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::csv - Comma-separated-values transport layer

=head1 VERSION

$Revision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 dbh - DBI:CSV handle

  Overrides Transport::dbi

  my $dbh = $csvtransport->dbh();

=head2 dbname - The CSV database name (directory path)

  my $directory = $csvtransport->dbname();

=head2 tablename - The CSV table name (file name)

  my $file = $csvtransport->tablename();

=head2 filename - The full CSV file path

  my $filepath = $csvtransport->filename();

=head2 last_modified - machine time of last data change

  $csvtransport->last_modified();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Jody Clements <jc3@sanger.ac.uk>

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut
