package Bio::Das::ProServer::SourceAdaptor::Transport::bioseqio;

# $Id: bioseqio.pm,v 1.1 2003/11/28 15:52:18 avc Exp $
#
# bioseqio.pm
#
# Andreas Kahari, andreas.kahari@ebi.ac.uk
#
#
# A ProServer transport module that works off any flat file that
# Bio::SeqIO supports.
#
# NB: This is *not* what you want to use if your files are
# large.  As an example, a single query for "Z261_HUMAN" on the
# complete Swissprot file "sprot42.dat" takes several minutes.
#
#
# For sequential querying flat files, the following
# configuration entries are needed:
#
#   filename	The name of the flat file to search.
#
#   format	The format of the flat file.
#
# If using Bio::DB::Flat (this is depedent on the existance of
# the 'index' configuration entry), the following additional
# configuration entries are needed:
#
#   index       The type of index to create and/or use ('bdb' or
#               'binarysearch').  Corresponds to the '-index'
#               option of Bio::DB::Flat::new().
#
#   dbname      The name of the database to create and/or
#               use.  Corresponds to the '-dbname' option of
#               Bio::DB::Flat::new().
#
#   dbroot      The directory where the database index is
#               or will be located.  Corresponds to the
#               '-directory' option of Bio::DB::Flat::new().
#

use strict;
use warnings;

use Bio::Das::ProServer::SourceAdaptor::Transport::generic;

use vars qw(@ISA);
@ISA = qw(Bio::Das::ProServer::SourceAdaptor::Transport::generic);

use Bio::SeqIO;
use Bio::DB::Flat;

sub init
{
    my $self = shift;
    $self->{_data} = undef;	# Will hold latest Bio::SeqIO object

    # Make sure that the database index exists if the
    # $self->config->{index} configuration entry exists.
    if (defined $self->config->{index} &&
	! -f sprintf("%s/%s/config.dat",
		     $self->config->{dbroot},
		     $self->config->{dbname})) {
	my $db = new Bio::DB::Flat(
	    -directory	=> $self->config->{dbroot},
	    -dbname	=> $self->config->{dbname},
	    -format	=> $self->config->{format},
	    -index	=> $self->config->{index},
	    -write_flag => 1
	);

	my $msg = sprintf("Building %s index for DB %s in %s\n",
			   $self->config->{index},
			   $self->config->{dbname},
			   $self->config->{dbroot});

	warn $msg;
	$db->build_index($self->config->{filename});
    }
}

sub query
{
    my $self = shift;

    if (defined $self->{_data} &&
	$self->{_data}->display_name eq $query) {
	return $self->{_data};
    }

    if (defined $self->config->{index}) {
	return $self->_query_indexed(@_);
    }
    return $self->_query_sequentially(@_);
}

sub _query_sequentially
{
    # Opens the file specified by the configuration and looks
    # through it sequentially until one sequence is found whose
    # display_name corresponds to the segment.  The found
    # sequence is cached and returned as a Bio::Seq object.

    my $self = shift;
    my $query = shift;

    my $fh;
    my $fname = $self->{filename} || $self->config->{filename};
    my $format = $self->{format} || $self->config->{format};

    open($fh, $fname) or die "Can't open '$fname' for reading: $!";

    my $seqio = new Bio::SeqIO(
	-fh	=> $fh,
	-format	=> $format
    );

    $self->{_data} = new Bio::Seq( -display_id => 'notfound' );

    while (defined (my $seq = $seqio->next_seq())) {
	if ($seq->display_name eq $query) {
	    $self->{_data} = $seq;
	    last;
	}
    }

    close($fh);

    return $self->{_data};
}

sub _query_indexed
{
    # Uses Bio::DB::Flat to look for the sequence whose
    # display_name corresponds to the segment.  The found
    # sequence is cached and returned as a Bio::Seq object.

    my $self = shift;
    my $query = shift;

    my $db = new Bio::DB::Flat(
	-directory  => $self->config->{dbroot},
	-dbname	    => $self->config->{dbname},
	-format	    => $self->config->{format},
	-index	    => $self->config->{index},
    );

    $self->{_data} = $db->get_Seq_by_id($query);

    return $self->{_data};
}

1;
