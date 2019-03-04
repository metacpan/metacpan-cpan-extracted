#
#
# BioPerl module for Bio::DB::EMBL
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Cared for by Heikki Lehvaslaiho <heikki-at-bioperl-dot-org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::DB::EMBL - Database object interface for EMBL entry retrieval

=head1 SYNOPSIS

  use Bio::DB::EMBL;

  $embl = Bio::DB::EMBL->new();

  # remember that EMBL_ID does not equal GenBank_ID!
  $seq = $embl->get_Seq_by_id('HSFOS'); # EMBL ID
  print "cloneid is ", $seq->id, "\n";

  # or changeing to accession number and Fasta format ...
  $embl->request_format('fasta');
  $seq = $embl->get_Seq_by_acc('J02231'); # EMBL ACC
  print "cloneid is ", $seq->id, "\n";

  # especially when using versions, you better be prepared
  # in not getting what what want
  eval {
      $seq = $embl->get_Seq_by_version('J02231.1'); # EMBL VERSION
  };
  print "cloneid is ", $seq->id, "\n" unless $@;

  # or ... best when downloading very large files, prevents
  # keeping all of the file in memory

  # also don't want features, just sequence so let's save bandwidth
  # and request Fasta sequence
  $embl = Bio::DB::EMBL->new(-retrievaltype => 'tempfile' ,
 			    -format => 'fasta');
  my $seqio = $embl->get_Stream_by_id(['AC013798', 'AC021953'] );
  while( my $clone =  $seqio->next_seq ) {
 	print "cloneid is ", $clone->id, "\n";
  }

=head1 DESCRIPTION

Allows the dynamic retrieval of sequence objects L<Bio::Seq> from the
EMBL database using the dbfetch script at EBI:
L<http://www.ebi.ac.uk/Tools/dbfetch/dbfetch>.

In order to make changes transparent we have host type (currently only
ebi) and location (defaults to ebi) separated out.  This allows later
additions of more servers in different geographical locations.

The functionality of this module is inherited from L<Bio::DB::DBFetch>
which implements L<Bio::DB::WebDBSeqI>.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  https://github.com/bioperl/bioperl-live/issues

=head1 AUTHOR - Heikki Lehvaslaiho

Email Heikki Lehvaslaiho E<lt>heikki-at-bioperl-dot-orgE<gt>

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::DB::EMBL;
$Bio::DB::EMBL::VERSION = '1.7.4';
use strict;
use vars qw($MODVERSION %HOSTS %FORMATMAP  $DEFAULTFORMAT);

$MODVERSION = '0.2';

use base qw(Bio::DB::DBFetch);

BEGIN {
    # you can add your own here theoretically.
    %HOSTS = (
	       'dbfetch' => {
		   baseurl => 'http://%s/Tools/dbfetch/dbfetch?db=embl&style=raw',
		   hosts   => {
		       'ebi'  => 'www.ebi.ac.uk'
		       }
	       }
	      );
    %FORMATMAP = ( 'embl' => 'embl',
		   'fasta' => 'fasta'
		   );
    $DEFAULTFORMAT = 'embl';
}

=head2 new

 Title   : new
 Usage   : $gb = Bio::DB::GenBank->new(@options)
 Function: Creates a new genbank handle
 Returns : New genbank handle
 Args    : -delay   number of seconds to delay between fetches (3s)

NOTE:  There are other options that are used internally.

=cut

sub new {
    my ($class, @args ) = @_;
    my $self = $class->SUPER::new(@args);

    $self->{ '_hosts' } = {};
    $self->{ '_formatmap' } = {};

    $self->hosts(\%HOSTS);
    $self->formatmap(\%FORMATMAP);
    $self->{'_default_format'} = $DEFAULTFORMAT;

    return $self;
}

1;
