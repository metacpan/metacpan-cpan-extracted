#########
# Author:        Andreas Kahari, andreas.kahari@ebi.ac.uk
# Maintainer:    $Author: zerojinx $
# Created:       ?
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: bioseqio.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source: /nfs/team117/rmp/tmp/Bio-Das-ProServer/Bio-Das-ProServer/lib/Bio/Das/ProServer/SourceAdaptor/Transport/bioseqio.pm,v $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/Transport/bioseqio.pm $
#
package Bio::Das::ProServer::SourceAdaptor::Transport::bioseqio;
use strict;
use warnings;
use base qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);
use Bio::SeqIO;
use Bio::DB::Flat;
use Carp;
use English qw(-no_match_vars);

our $VERSION = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub init {
  my $self = shift;
  $self->{_data} = undef; # Will hold latest Bio::SeqIO object

  # Make sure that the database index exists if the
  # $self->config->{index} configuration entry exists.
  if (defined $self->config->{index} &&
      ! -f sprintf q(%s/%s/config.dat),
                   $self->config->{dbroot},
                   $self->config->{dbname}) {
    my $db = Bio::DB::Flat->new(
				-directory  => $self->config->{dbroot},
				-dbname     => $self->config->{dbname},
				-format     => $self->config->{format},
				-index      => $self->config->{index},
				-write_flag => 1
			       );

    my $msg = sprintf qq(Building %s index for DB %s in %s\n),
                      $self->config->{index},
		      $self->config->{dbname},
		      $self->config->{dbroot};

    carp $msg;
    $db->build_index($self->config->{filename});
  }
  return;
}

sub query {
  my ($self, $query) = @_;

  if (defined $self->{_data} &&
      $self->{_data}->display_name eq $query) {
    return $self->{_data};
  }

  if (defined $self->config->{index}) {
    return $self->_query_indexed($query);
  }

  return $self->_query_sequentially($query);
}

#########
# Opens the file specified by the configuration and looks
# through it sequentially until one sequence is found whose
# display_name corresponds to the segment.  The found
# sequence is cached and returned as a Bio::Seq object.
#
sub _query_sequentially {
  my ($self, $query) = @_;

  my $fname  = $self->{filename} || $self->config->{filename};
  my $format = $self->{format}   || $self->config->{format};

  $self->{_data} = Bio::Seq->new( -display_id => 'notfound' );

  my $seqio = Bio::SeqIO->new(
			      -file   => $fname,
			      -format => $format,
			     );

  while (defined (my $seq = $seqio->next_seq())) {
    if ($seq->display_name eq $query) {
      $self->{_data} = $seq;
      last;
    }
  }

  return $self->{_data};
}

#########
# Uses Bio::DB::Flat to look for the sequence whose
# display_name corresponds to the segment.  The found
# sequence is cached and returned as a Bio::Seq object.
#
sub _query_indexed {
  my ($self, $query) = @_;

  my $db = Bio::DB::Flat->new(
			      -directory => $self->config->{dbroot},
			      -dbname    => $self->config->{dbname},
			      -format    => $self->config->{format},
			      -index     => $self->config->{index},
			     );

  $self->{_data} = $db->get_Seq_by_id($query);

  return $self->{_data};
}

1;

__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::bioseqio - A ProServer
transport module that works off any flat file that Bio::SeqIO
supports.

=head1 VERSION

$Revision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

NB: This is *not* what you want to use if your files are large.  As an
example, a single query for "Z261_HUMAN" on the complete Swissprot
file "sprot42.dat" takes several minutes.

=head1 SUBROUTINES/METHODS

=head2 init

=head2 query

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

For sequential querying flat files, the following
configuration entries are needed:

  filename	The name of the flat file to search.

  format	The format of the flat file.

If using Bio::DB::Flat (this is depedent on the existance of
the 'index' configuration entry), the following additional
configuration entries are needed:

  index       The type of index to create and/or use ('bdb' or
              'binarysearch').  Corresponds to the '-index'
              option of Bio::DB::Flat::new().

  dbname      The name of the database to create and/or
              use.  Corresponds to the '-dbname' option of
              Bio::DB::Flat::new().

  dbroot      The directory where the database index is
              or will be located.  Corresponds to the
              '-directory' option of Bio::DB::Flat::new().

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Andreas Kahari, andreas.kahari@ebi.ac.uk

=head1 LICENSE AND COPYRIGHT

