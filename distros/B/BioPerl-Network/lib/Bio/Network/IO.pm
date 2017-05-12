#
# BioPerl module for Bio::Network::IO
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1  NAME

Bio::Network::IO - Class for reading and writing biological network data.

=head1  SYNOPSIS

This is a modules for reading and writing protein-protein interaction
and creating networks from this data.

  # Read protein interaction data in some format
  my $io = Bio::Network::IO->new(-file => 'bovine.xml',
                                 -format => 'psi25' );
  my $network = $io->next_network;

=head1  DESCRIPTION

This class is analagous to the SeqIO and AlignIO classes. To read in a
file of a particular format, file and format are given as key/value
pairs as arguments.  The Bio::Network::IO checks that the appropriate
module is available and loads it.

At present only the DIP tab-delimited format and PSI XML format are 
supported.

=head1 METHODS

The main methods are:

=head2  $net = $io-E<gt>next_network

The next_network method does not imply that multiple networks are
contained in a file, this is to maintain a consistent nomenclature
with Bioperl methods like $seqio-E<gt>next_seq and $alnio-E<gt>next_aln.

=head2  $io-E<gt>write_network($network)

UNIMPLEMENTED.

=head1 REQUIREMENTS

To read from PSI XML you will need the XML::Twig module, 
available from CPAN.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.

Your participation is much appreciated.

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

  http://bugzilla.open-bio.org/

=head1 AUTHORS

Brian Osborne bosborne at alum.mit.edu
Richard Adams richard.adams@ed.ac.uk

=cut

package Bio::Network::IO;
use strict;
use base 'Bio::Root::IO';
use vars qw(%DBNAMES);

# these values are used to standardize database names
%DBNAMES = (
				DIP => "DIP",     # found in DIP files
				SWP => "UniProt", # found in DIP files
				PIR => "PIR",     # found in DIP files
				GI  => "GenBank"  # found id DIP files
			  );

=head2  new

 Name       : new
 Usage      : $io = Bio::Network::IO->new(-file => 'myfile.xml', 
                                          -format => 'psi25');
 Returns    : A Bio::Network::IO stream initialised to the appropriate format.
 Args       : Named parameters: 
              -file      => $filename
              -format    => format
				  -threshold => a confidence score for the interaction, optional
              -source    => optional database name (e.g. "intact")
              -verbose   => optional, set to 1 to get commentary

=cut

sub new {
	my ($caller, @args) = @_;
	my $class = ref($caller) || $caller;
	if ($class =~ /Bio::Network::IO::(\S+)/){
		my $self = $class->SUPER::new(@args);
		$self->_initialize_io(@args);
		return $self;
	} else {
		my %param = @args;
		@param{ map { lc $_ } keys %param } = values %param;
		if (!exists($param{'-format'})) {
			Bio::Root::Root->throw("Must specify a valid format!");
		} 
		my $format = $param{'-format'};
		$format = "\L$format";	
		return undef unless ($class->_load_format_module($format)); 
		return "Bio::Network::IO::$format"->new(@args);
	}
}

=head2 next_network

 Name       : next_network
 Usage      : $gr = $io->next_network
 Returns    : A Bio::Network::ProteinNet object.
 Args       : None

=cut

sub next_network {
   my ($self, $gr) = @_;
   $self->throw("Sorry, you cannot read from a generic Bio::Network::IO object.");
}

=head2 write_network

 Name       : write_network
 Usage      : $gr = $io->write_network($net).
 Args       : A Bio::Network::ProteinNet object.
 Returns    : None

=cut

sub write_network {
   my ($self, $gr) = @_;
   $self->throw("Sorry, you can't write from a generic Bio::NetworkIO object.");
}

=head2 threshold

 Name       : get or set a threshold
 Usage      : $io->threshold($val)
 Returns    : The threshold
 Args       : A number or none

=cut

sub threshold {
   my $self = shift;
   $self->{_th} = @_ if @_;
   return $self->{_th};
}

=head2 verbose

 Name       : get or set verbosity
 Usage      : $io->verbose(1)
 Returns    : The verbosity setting
 Args       : 1 or none

=cut

sub verbose {
   my $self = shift;
   $self->{_verbose} = @_ if @_;
   return $self->{_verbose};
}

=head2 _load_format_module

 Title   : _load_format_module
 Usage   : INTERNAL Bio::Network::IO stuff
 Function: Loads up (like use) a module at run time on demand
 Returns :
 Args    :

=cut

sub _load_format_module {
	my ($self, $format) = @_;
	my $module = "Bio::Network::IO::" . $format;
	my $ok;

	eval {
		$ok = $self->_load_module($module);
	};
	if ( $@ ) {
		print STDERR <<END
$self: $format cannot be found
Exception $@
For more information about the Bio::Network::IO system please see the Bio:Network::IO docs.
END
;
	}
	return $ok;
}

=head2 _initialize_io

 Title   : _initialize_io
 Usage   : *INTERNAL Bio::Network::IO stuff*
 Function: 
 Returns :
 Args    :

=cut

sub _initialize_io {
	my ($self, @args) = @_;
	$self->SUPER::_initialize_io(@args);
	my ($th,$verbose) = $self->_rearrange( [qw(THRESHOLD VERBOSE)], @args);
	$self->{'_th'} = $th;
	$self->{'_verbose'} = $verbose;
	return $self;
}

=head2 _get_standard_name

 Title   : _get_standard_name
 Usage   :
 Function: Returns some standard name for a database, uses global
           %DBNAMES
 Returns :
 Args    :

=cut

sub _get_standard_name {
	my ($self,$name) = @_;
	$DBNAMES{$name};
}

1;

__END__
