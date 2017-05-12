package Bio::Das::ProServer::SourceAdaptor::bioseq;

# $Id: bioseq.pm,v 1.1 2003/11/28 15:52:18 avc Exp $
#
# bioseq.pm
#
# Andreas Kahari, andreas.kahari@ebi.ac.uk
#
#
# A ProServer source adaptor for converting Bio::Seq objects
# into DAS features.  See also "Transport/bioseqio.pm".
#

use strict;
use warnings;

use Bio::Das::ProServer::SourceAdaptor;

use vars qw(@ISA);
@ISA = qw(Bio::Das::ProServer::SourceAdaptor);

sub init
{
    my $self = shift;
    $self->{capabilities} = {
	'features'  => '1.0',
	'dna'	    => '1.0'
    };
}

sub length
{
    my $self = shift;
    my $id = shift;

    my $seq = $self->transport->query($id);

    if (defined $seq) {
	return $seq->length;
    }
    return 0;
}

sub build_features
{
    my $self = shift;
    my $opts = shift;

    my $seq = $self->transport->query($opts->{segment});

    if (!defined $seq) {
	return ();
    }

    my @features;
    foreach my $feature ($seq->get_SeqFeatures) {
	push @features, {
	    type    => $feature->primary_tag,
	    start   => $feature->start,
	    end	    => $feature->end,
	    method  => $feature->source_tag,
	    id	    => $feature->display_name ||
		sprintf("%s/%s:%d,%d",
		    $seq->display_name, $feature->primary_tag,
		    $feature->start, $feature->end),
	    ori	    => $feature->strand
	};
    }

    return @features;
}

sub sequence
{
    my $self = shift;
    my $opts = shift;

    my $seq = $self->transport->query($opts->{segment});

    if (!defined $seq) {
	return { seq => "", moltype => "" };
    }

    return {
	seq	=> $seq->seq || "",
	moltype	=> $seq->alphabet || ""
    };
}

1;
