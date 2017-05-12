#########
# Author: rmp
# Maintainer: rmp
# Created: 2003-06-11
# Last Modified: 2003-06-12
# 
# Based on a mixture of Tony's AGPServer SQLStorage & Parser
#
package Bio::Das::ProServer::Loader::agp;

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

Based on AGPServer by

Tony Cox <avc@sanger.ac.uk>.

Copyright (c) 2003 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=cut

use strict;
use DBI;

sub new {
  my ($class, $self) = @_;

  bless $self, $class;
  $self->load();
  return $self;
}

sub dbh {
  my $self = shift;

  unless(defined $self->{'_dbh'}) {
    my $driver      = $self->{'driver'} || "mysql";
    my $dbdsn       = qq(dbi:$driver:database=$self->{'dbname'};host=$self->{'host'};port=$self->{'port'});
    $self->{'_dbh'} = DBI->connect($dbdsn, $self->{'username'}, $self->{'password'}, {RaiseError=>1}) or die $DBI::errstr;
  }
  return $self->{'_dbh'};
}

#########
# nicely disconnect from the db when we're removed
# maybe drop the temporary table too? - loader currently remains in scope for the lifetime of the server.
#
sub DESTROY {
  my $self = shift;

  $self->dbh->disconnect() if($self->{'_dbh'});
}

#########
# manage loading agp file(s)
#
sub load {
  my $self = shift;
  
  $self->drop_agp_table();
  $self->create_agp_table();

  my @files = ();
  push @files, $self->{'agpfile'} if(defined $self->{'agpfile'});

  if ($self->{'agpdir'}) {
    opendir(DIR, $self->{'agpdir'}) or die "Cannot open AGP directory: $!\n";
    push @files, map { $self->{'agpdir'}."/$_" } grep { /.*\.agp$/i } readdir DIR;
    closedir(DIR);
  }

  die qq(No AGP files to load) unless(scalar @files);

  for my $f (@files) {
    print STDERR "Loading AGP file: $f\n";
    $self->load_agp($f);
  }
}

#########
# drop any existing temporary table
#
sub drop_agp_table {
  my ($self) = @_;

  $self->dbh->do(qq(DROP TABLE IF EXISTS $self->{'tablename'})) or die $!;
#  print STDERR "Removed temporary table $self->{'tablename'}\n";
}

#########
# create new temporary table
#
sub create_agp_table {
  my $self  = shift;
  
  $self->dbh->do(qq(CREATE TABLE $self->{'tablename'}
		    (chr        CHAR(6),
		     chr_start  INTEGER,
		     chr_end    INTEGER,
		     ord        INTEGER,
		     type       CHAR(4),
		     embl_id    CHAR(20),
		     embl_start INTEGER,
		     embl_end   INTEGER,
		     embl_ori   CHAR(4)
		    ))) or die $!;
}


#########
# load an individual agp file
#
sub load_agp {
  my ($self, $filename) = @_;

  my $GAPCOUNT = 0;

  open(FIN, $filename);
  while(defined (my $line = <FIN>)) {
    chomp $line;

    my @fields = split(/\s+/, $line);
    $fields[0] =~ s/chr//i;
  
    ## We do a bit of data munging here. Set the orientation always to be "+"
    ## and the clone start/end to be the length of the gap. We should be able to
    ## treat it like a normal clone now...
    
    # F = Finished         = HTGS_PHASE3                                                                             
    # A = Almost finsished = HTGS_PHASE2 (Rare)                                                                      
    # U = Unfinished       = HTGS_PHASE1 (Not ususally in AGPs, but can be.)                                         
    # N = Gap in AGP - these lines have an optional qualifier (eg: CENTROMERE)
    
    if($fields[4] eq "N") {
      $fields[6] = 1;
      $fields[7] = $fields[5];
      $fields[5] = "GAP_$fields[0]_${GAPCOUNT}_$fields[5]";
      $fields[8] = "+";
      $GAPCOUNT++;
    }

    $self->dbh->do("INSERT INTO $self->{'tablename'} VALUES (?,?,?,?,?,?,?,?,?)", undef, @fields) or die $!;
  }
  close(FIN);
}

1;
