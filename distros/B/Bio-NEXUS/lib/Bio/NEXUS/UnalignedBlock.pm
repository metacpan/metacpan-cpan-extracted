#######################################################################
# UnalignedBlock.pm
#######################################################################
# 
# thanks to Tom Hladish for the original version 
#
# $Id: UnalignedBlock.pm,v 1.25 2012/02/10 13:28:28 astoltzfus Exp $

#################### START POD DOCUMENTATION ##########################

=head1 NAME

Bio::NEXUS::UnalignedBlock - Represents an UNALIGNED block of a NEXUS file

=head1 SYNOPSIS

 if ( $type =~ /unaligned/i ) {
     $block_object = new Bio::NEXUS::UnalignedBlock($type, $block, $verbose);
 }

=head1 DESCRIPTION

This is a class representing an unaligned block in NEXUS file

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) is greatly appreciated. 

=head1 AUTHORS

 Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Id: UnalignedBlock.pm,v 1.25 2012/02/10 13:28:28 astoltzfus Exp $

=head1 METHODS

=cut

package Bio::NEXUS::UnalignedBlock;

use strict;
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp;# XXX this is not used, might as well not import it!
use Bio::NEXUS::Functions;
use Bio::NEXUS::TaxUnitSet;
use Bio::NEXUS::Matrix;
use Bio::NEXUS::Util::Exceptions;
use vars qw(@ISA $VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;
@ISA = qw(Bio::NEXUS::Matrix);
my $logger = Bio::NEXUS::Util::Logger->new();

=head2 new

 Title   : new
 Usage   : block_object = new Bio::NEXUS::UnalignedBlock($block_type, $commands, $verbose, $taxlabels);
 Function: Creates a new Bio::NEXUS::UnalignedBlock object
 Returns : Bio::NEXUS::UnalignedBlock object
 Args    : type (string), the commands/comments to parse (array ref), and a verbose flag (0 or 1)

=cut

sub new {
    my ( $class, $type, $commands, $verbose, $taxa ) = @_;
    unless ($type) { ( $type = lc $class ) =~ s/Bio::NEXUS::(.+)Block/$1/i; }
    my $self = { type => $type };
    bless $self, $class;
    $self->set_taxlabels($taxa);
    $self->{'otuset'} = new Bio::NEXUS::TaxUnitSet();
    $self->_parse_block( $commands, $verbose )
        if ( ( defined $commands ) and @$commands );
    return $self;
}

=begin comment

 Title   : _parse_format
 Usage   : $format = $self->_parse_format($buffer); (private)
 Function: Extracts format values from line and stores values in a hash
 Returns : hash of formats
 Args    : buffer (string)
 Methods : Separates formats by whitespace and creates hash containing
           key = format name and value = format value.

=end comment 

=cut

sub _parse_format {
    my ( $self, $string ) = @_;

    my %format = ();

    while ( $string =~ s/(\S+\s*=\s*[\"|\'][^\"\']+[\"|\'])// ) {
        my ( $name, $symbol ) = split /\s*=\s*/, $1;
        $format{ lc $name } = $symbol;
    }
    while ( $string =~ s/(\S+\s*=\s*\S+)// ) {
        my ( $name, $symbol ) = split /\s*=\s*/, $1;
        $format{ lc $name } = lc $symbol;
    }
    for my $other ( split /\s+/, $string ) {
        if ($other) { $format{ lc $other } = 1; }
    }
    return \%format;
}

=begin comment

 Title   : _parse_matrix
 Usage   : $self->_parse_matrix($buffer); (private)
 Function: Processes buffer containing matrix data
 Returns : none
 Args    : buffer (string)
 Method  : parse according to if name is quoted string or single word, 
           if each state is single character or multi-character (use token keyword)

=end comment 

=cut

sub _parse_matrix {
    my ( $self, $matrix, $verbose ) = @_;

    my @taxa;
    my ( $name, $seq ) = ();

    # Build an array of hashrefs, where each hash has "name" and "seq" values
    # corresponding to the name and sequence found in each row of the matrix
    for my $row ( split /\n|\r/, $matrix ) {
        if ( $row =~ /^\s*$/ ) { next; }
		
        #for quoted taxon name
        if ( $row =~ /^\s*[\"|\']([^\"\']+)[\"|\']\s*([^\[]*)(\[.*\]\s*)*/ ) {
            ( $name, $seq ) = ( $1, $2 );
            $name =~ s/\s+/_/g;
            if ( !$self->find_taxon($name) ) { 
            	Bio::NEXUS::Util::Exceptions::BadArgs->throw(
            		'error' => "Undefined Taxon: $name"
            	); 
            }
        }
        else {

            # for one-word non-quoted taxon name
            $row =~ /^\s*(\S+)(\s*)([^\[]*)(\[.*\]\s*)*/;
            if ( $self->find_taxon($1) ) {
                $name = $1;
                $seq  = $3;
                #print Dumper $seq;
            }
            else {
                print "taxon name $1 not found\n" if $verbose;
                $seq = $1 . $2 . $3;
            }
        }
        #print "> row: $row\n";
        #print "> name: $name\n";
        #print "> seq: $seq\n";
        
        my $newtaxon = 1;
        for my $taxon (@taxa) {
            if ( $taxon->{'name'} eq $name ) {
                $taxon->{'seq'} .= ' ' . $seq;
                $newtaxon = 0;
            }
        }
        if ($newtaxon) {
            push @taxa, { name => $name, seq => $seq };
        }
    }
	#print '> @taxa: ';
    # split each character
    my @otus;
    #print Dumper \@taxa;
    for my $taxon (@taxa) {
        $seq = $taxon->{'seq'};
        $seq =~ s/^\s*(.*\S)\s*$/$1/;

        my @seq;
        while ( $seq =~ s/([^\(]+)|\(([^\(]+)\)// ) {    # for +-(+ -)+-
            if ($1) {                                    # for +-
###             The following 4 commented lines of code are implemented in CharactersBlock.pm; they allow data tokens to be space-delimited.
###             Unaligned blocks do not include the tokens or continuous formats according the Maddison et al.  We
###             may decide that we don't want to restrict unaligned data to DNA/RNA/AA the way Maddison et al have.
#               if ($self->get_format->{'tokens'}  || lc $self->get_format->{'datatype'}  eq 'continuous') {  #LINE 1
#                   push @seq, split /\s+/, $1;                                                               #LINE 2
#               } else {                                                                                      #LINE 3
                push @seq, split /\s*/, $1;

#               }                                                                                             #LINE4
            }
            elsif ($2) {
                push @seq, [ split /,\s*|\s+/, $2 ];     # for (+ -)
            }
        }

        push @otus, Bio::NEXUS::TaxUnit->new( $taxon->{'name'}, \@seq );
    }
    
    my $otuset = $self->get_otuset();
    $otuset->set_otus( \@otus );
    $self->set_taxlabels( $otuset->get_otu_names() );
    return \@otus;
}

=head2 find_taxon

 Title   : find_taxon
 Usage   : my $is_taxon_present = $self->find_taxon($taxon_name);
 Function: Finds whether the input taxon name is present in the taxon label.
 Returns : 0 (not present)  or 1 (if present).
 Args    : taxon label (as string)

=cut

sub find_taxon {
    my ( $self, $name ) = @_;
    if ( @{ $self->get_taxlabels || [] } == 0 ) { return 1; }
    for my $taxon ( @{ $self->get_taxlabels() } ) {
        if ( lc $taxon eq lc $name ) { return 1; }
    }
    return 0;
}

=head2 set_format

 Title   : set_format
 Usage   : $block->set_format(\%format);
 Function: set the format of the characters
 Returns : none
 Args    : hash of format values

=cut

sub set_format {
    my ( $self, $format ) = @_;
    $self->{'format'} = $format;
}

=head2 get_format

 Title   : get_format
 Usage   : $block->get_format();
 Function: Returns the format of the characters
 Returns : hash of format values
 Args    : none

=cut

sub get_format { shift->{'format'} || {} }

=head2 set_otuset

 Title   : set_otuset
 Usage   : $block->set_otuset($otuset);
 Function: Set the otus
 Returns : none
 Args    : TaxUnitSet object

=cut

sub set_otuset {
    my ( $self, $otuset ) = @_;
    $self->{'otuset'} = $otuset;
    $self->set_taxlabels( $otuset->get_otu_names() );
}

=head2 set_charstatelabels

 Title   : set_charstatelabels
 Usage   : $block->set_charstatelabels($labels);
 Function: Set the character names and states
 Returns : none
 Args    : array of character states

=cut

sub set_charstatelabels {
    my ( $self, $charstatelabels ) = @_;
    $self->get_otuset->set_charstatelabels($charstatelabels);
}

=head2 get_charstatelabels

 Title   : get_charstatelabels
 Usage   : $set->get_charstatelabels();
 Function: Returns an array of character states
 Returns : character states
 Args    : none

=cut

sub get_charstatelabels {
    my ($self) = @_;
    return $self->get_otuset->get_charstatelabels();
}

=head2 get_ntax

 Title   : get_ntax
 Usage   : $block->get_ntax();
 Function: Returns the number of taxa of the block
 Returns : # taxa
 Args    : none

=cut

sub get_ntax {
    my $self = shift;
    return $self->get_otuset()->get_ntax();
}

=head2 rename_otus

 Title   : rename_otus
 Usage   : $block->rename_otus(\%translation);
 Function: Renames all the OTUs to something else
 Returns : none
 Args    : hash containing translation

=cut

sub rename_otus {
    my ( $self, $translation ) = @_;
    $self->get_otuset()->rename_otus($translation);
}

=head2 add_otu_clone

 Title   : add_otu_clone
 Usage   : ...
 Function: ...
 Returns : ...
 Args    : ...

=cut

sub add_otu_clone {
	my ( $self, $original_otu_name, $copy_otu_name ) = @_;
	# print "Warning: Bio::NEXUS::UnalignedBlock::add_otu_clone() method not fully implemented\n";
	
	if ($self->find_taxon($copy_otu_name)) {
		print "Error: an OTU with that name [$copy_otu_name] already exists.\n";
	}
	else {
		$self->add_taxlabel($copy_otu_name);
	}
	
	my @otu_set = ();
	if (defined $self->{'otuset'}->{'otus'}) {
	    @otu_set = @{ $self->{'otuset'}->{'otus'} };
	}
	foreach my $otu (@otu_set) {
		if (defined $otu) {
			if ($otu->get_name() eq $original_otu_name) {
				my $otu_clone = $otu->clone();
				$otu_clone->set_name($copy_otu_name);
				$self->{'otuset'}->add_otu($otu_clone);
			}
		}
	}
	
}

=head2 equals

 Name    : equals
 Usage   : $block->equals($another);
 Function: compare if two Bio::NEXUS::UnalignedBlock objects are equal
 Returns : boolean 
 Args    : a Bio::NEXUS::CharactersBlock object

=cut

sub equals {
    my ( $self, $block ) = @_;
    if ( !Bio::NEXUS::Block::equals( $self, $block ) ) { return 0; }
    return $self->get_otuset()->equals( $block->get_otuset() );
}

=begin comment

 Name    : _write
 Usage   : $block->_write();
 Function: Writes NEXUS block containing unaligned data
 Returns : none
 Args    : file name (string)

=end comment 

=cut

sub _write {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    Bio::NEXUS::Block::_write( $self, $fh );
    $self->_write_matrix_info( $fh, $verbose );
    $self->_write_matrix( $fh, $verbose );
    print $fh "END;\n";
    return;
}

=begin comment

 Name    : _write_matrix_info
 Usage   : $self->_write_matrix_info($file_handle,$verbose);
 Function: Writes UnalignedBlock info (all the block content except the matrix data) into the filehandle
 Returns : none
 Args    : $file_handle and $verbose 

=end comment 

=cut

sub _write_matrix_info {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    my $ntax = $self->get_ntax();
    print $fh "\tDIMENSIONS ntax=$ntax;\n";

    my %formats = %{ $self->get_format() };
    if ( scalar keys %formats ) {
        print $fh "\tFORMAT ";
        if ( defined $formats{'datatype'} ) {
            print $fh " datatype=$formats{'datatype'}";
        }

        for my $format ( keys %formats ) {
            if ( !$formats{$format} || $format =~ /datatype/i ) { next; }
            elsif ( $formats{$format} eq '1' ) {
                print $fh " $format";
            }
            else {
                print $fh " $format=$formats{$format}";
            }
        }
        print $fh ";\n";
    }
    return;
}

=begin comment

 Name    : _write_matrix
 Usage   : $self->_write_matrix($file_handle,$verbose);
 Function: Writes UnalignedBlock matrix( The data stored in the matrix command)  into the filehandle 
 Returns : none
 Args    : $file_handle and $verbose 

=end comment 

=cut

sub _write_matrix {
    my ( $self, $fh, $verbose ) = @_;
    $fh ||= \*STDOUT;

    my @otus = @{ $self->get_otuset()->get_otus() };
    print $fh "\tMATRIX\n";
    for my $otu (@otus) {
        my $seq = $otu->get_seq_string();
        print $fh "\t", $otu->get_name(), "\t", $seq, "\n";
    }
    print $fh "\t;\n";
    return;
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = __PACKAGE__ . '::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for = (
        "${package_name}set_charstates" => "${package_name}set_charstatelabels",
        "${package_name}get_charstates" => "${package_name}get_charstatelabels",
    );

    if ( defined $synonym_for{$AUTOLOAD} ) {
        $logger->warn( "$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead" );
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
        Bio::NEXUS::Util::Exceptions::UnknownMethod->throw(
        	'error' => "ERROR: Unknown method $AUTOLOAD called"
        );
    }
}

1;
