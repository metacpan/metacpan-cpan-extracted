#################################################################
# TaxUnitSet.pm
#################################################################
# Author: Chengzhi Liang, Peter Yang, Thomas Hladish
# $Id: TaxUnitSet.pm,v 1.30 2007/09/24 04:52:14 rvos Exp $

#################### START POD DOCUMENTATION ##################

=head1 NAME

Bio::NEXUS::TaxUnitSet - Represents a sets of OTUS (Bio::NEXUS::TaxUnits objects) in a NEXUS file

=head1 SYNOPSIS

$otuset = new Bio::NEXUS::TaxUnitSet(\@otus);

=head1 DESCRIPTION

This module represents a set of OTUs (Bio::NEXUS::TaxUnit objects) in a NEXUS file (in characters block or History block)

=head1 COMMENTS

=head1 FEEDBACK

All feedback (bugs, feature enhancements, etc.) are greatly appreciated. 

=head1 AUTHORS

 Chengzhi Liang (liangc@umbi.umd.edu)
 Peter Yang (pyang@rice.edu)
 Thomas Hladish (tjhladish at yahoo)

=head1 VERSION

$Revision: 1.30 $

=head1 METHODS

=cut

package Bio::NEXUS::TaxUnitSet;

use strict;
use Bio::NEXUS::Functions;
use Bio::NEXUS::TaxUnit;
#use Data::Dumper; # XXX this is not used, might as well not import it!
#use Carp; # XXX this is not used, might as well not import it!
use Bio::NEXUS::Util::Exceptions 'throw';
use Bio::NEXUS::Util::Logger;
use vars qw($VERSION $AUTOLOAD);
use Bio::NEXUS; $VERSION = $Bio::NEXUS::VERSION;

my $logger = Bio::NEXUS::Util::Logger->new;

=head2 new

 Title   : new
 Usage   : $otuset = new Bio::NEXUS::TaxUnitSet(\@otus);
 Function: Creates a new Bio::NEXUS::TaxUnitSet object 
 Returns : Bio::NEXUS::TaxUnitSet object
 Args    : ref to an array of TaxUnit objects

=cut

sub new {
    my ( $class, $otus ) = @_;
    my $self = { otus => $otus, };
    bless( $self, $class );
    return $self;
}

=head2 clone

 Title   : clone
 Usage   : my $newset = $set->clone();
 Function: clone an TaxUnitSet object 
 Returns : TaxUnitSet object
 Args    : none

=cut

sub clone {
    my ($self) = @_;
    my $class = ref($self);
    my $newset  = bless( { %{$self} }, $class );
    my @otus    = @{ $newset->get_otus() };
    my @newotus = ();
    for my $otu (@otus) {
        push @newotus, $otu->clone();
    }
    $newset->set_otus( \@newotus );
    return $newset;
}

=head2 add_otu

 Title   : add_otu
 Usage   : $block->add_otu($otu);
 Function: add a taxon
 Returns : none
 Args    : a taxon  

=cut

sub add_otu {
    my ( $self, $otu ) = @_;
    push @{ $self->{'otus'} }, $otu;
}

=head2 set_otus

 Title   : set_otus
 Usage   : $set->set_otus($otus);
 Function: sets the list of OTUs 
 Returns : none
 Args    : array of OTUs

=cut

sub set_otus {
    my ( $self, $otus ) = @_;
    $self->{'otus'} = $otus;
}

=head2 get_otus

 Title   : get_otus
 Usage   : $set->get_otus();
 Function: Returns array of otus
 Returns : all otus
 Args    : none

=cut

sub get_otus {
    my ($self) = @_;
    return $self->{'otus'};
}

=head2 get_otu

 Title   : get_otu
 Usage   : $set->get_otu(name);
 Function: Returns an OTU with a specified name 
 Returns : an OTU (Bio::NEXUS::TaxUnit)
 Args    : OTU name as scalar string

=cut

sub get_otu {
    my ( $self, $name ) = @_;
    for my $otu ( @{ $self->get_otus() } ) {
        return $otu if ( lc($name) eq lc($otu->get_name()) );
    }
    return undef;
}

=head2 get_otu_names

 Title   : get_otu_names
 Usage   : $set->get_otu_names();
 Function: Returns array of OTU names
 Returns : all OTU names
 Args    : none

=cut

sub get_otu_names {
    my ($self) = @_;
    my @names = ();
    for my $otu ( @{ $self->get_otus() } ) {
        push @names, $otu->get_name();
    }

    #    @names = sort {lc $a cmp lc $b} @names;
    return \@names;
}

=head2 get_seq_string_hash

 Title   : get_seq_string_hash
 Usage   : $set->get_seq_string_hash($delimiter);
 Function: gets sequence string delimited by $delimiter (default is "")
 Returns : hashref
 Args    : scalar

=cut

sub get_seq_string_hash {
    my ( $self, $delimiter ) = @_;
    my %sequences;
    $delimiter = '' unless $delimiter;
    for my $otu ( @{ $self->get_otus() } ) {
        $sequences{ $otu->get_name() } = join $delimiter, @{ $otu->get_seq() };
    }
    return \%sequences;
}

=head2 get_seq_array_hash

 Title   : get_seq_array_hash
 Usage   : $set->get_seq_array_hash();
 Function: gets sequences as arrays
 Returns : hashref
 Args    : scalar

=cut

sub get_seq_array_hash {
    my ($self) = @_;
    my %sequences;
    for my $otu ( @{ $self->get_otus() } ) {
        $sequences{ $otu->get_name() } = $otu->get_seq();
    }
    return \%sequences;
}

=head2 rename_otus

 Title   : rename_otus
 Usage   : $set->rename_otus($names);
 Function: rename all OTUs
 Returns : none
 Args    : hash of OTU names

=cut

sub rename_otus {
    my ( $self, $translate ) = @_;
    for my $otu ( @{ $self->get_otus() } ) {
        my $name    = $otu->get_name();
        my $newname = $translate->{$name};
        if ($newname) {
            $otu->set_name($newname);
        }
    }
}

=head2 subset

 Title   : subset
 Usage   : $block->subset($otunames);
 Function: select a subset of OTUs
 Returns : new TaxUnitSet object
 Args    : OTU names

=cut

sub subset {
    my ( $self, $otunames ) = @_;
    my $names = " @{$otunames} ";
    my @newarray;
    for my $otu ( @{ $self->get_otus() } ) {
        my $name = $otu->get_name();
        if ( $names =~ /\s+$name\s+/ ) {
            push @newarray, $otu;
        }
    }
    my $newset = new Bio::NEXUS::TaxUnitSet( \@newarray );
    $newset->set_charlabels( $self->get_charlabels );
    $newset->set_charstatelabels( $self->get_charstatelabels );
    return $newset;
}

=head2 select_columns

 Title   : select_columns
 Usage   : $set->select_columns($columns);
 Function: select a subset of characters
 Returns : new $self with subset of columns of characters
 Args    : column numbers

=cut

sub select_columns {
    my ( $self, $columns ) = @_;
    $self->select_charlabels($columns);
    $self->select_charstatelabels($columns);
    $self->select_chars($columns);
    return $self;
}

=head2 select_chars

 Title   : select_chars
 Usage   : $set->select_chars($columns);
 Function: select a subset of characters
 Returns : new self with subset of characters
 Args    : column numbers

=cut

sub select_chars {
    my ( $self, $columns ) = @_;
    my @otus = @{ $self->get_otus() };
    for my $otu (@otus) {
        my @seq = @{ $otu->get_seq() };
        my @newseq;
        for my $i ( @{$columns} ) {
            if ( $i >= scalar @seq ) {
            	throw 'BadArgs' => "invalid column number: " . ( $i + 1 );
            }
            push @newseq, $seq[$i];
        }
        $otu->set_seq( \@newseq );
    }
    return $self;
}

=head2 set_charlabels

 Title   : set_charlabels
 Usage   : $set->set_charlabels($labels);
 Function: Set the character names
 Returns : none
 Args    : array of character names 

=cut

sub set_charlabels {
    my ( $self, $labels ) = @_;
    my $charstates;
    for ( my $i = 0; $i < @$labels; $i++ ) {
        push @$charstates,
            { id => $i + 1, charlabel => $$labels[$i], states => {} }

    }
    $self->{'charstates'} = $charstates;
}

=head2 get_charlabels

 Title   : get_charlabels
 Usage   : $set->get_charlabels();
 Function: Returns an array of character labels
 Returns : character names
 Args    : none

=cut

sub get_charlabels {
    my ($self) = @_;
    my $charlabels;
    for my $charstate ( @{ $self->{'charstates'} } ) {
        push @$charlabels, $charstate->{'charlabel'};
    }
    return $charlabels || [];
}

=head2 set_statelabels

 Title   : set_statelabels
 Usage   : $set->set_statelabels($labels);
 Function: Set the state names
 Returns : none
 Args    : array of state names 

=cut

sub set_statelabels {
    my ( $self, $labels ) = @_;
    $self->{'statelabels'} = $labels;
}

=head2 get_statelabels

 Title   : get_statelabels
 Usage   : $set->get_statelabels();
 Function: Returns an array of state labels
 Returns : state names
 Args    : none

=cut

sub get_statelabels {
    my ($self) = @_;
    return $self->{'statelabels'} || [];
}

=head2 set_charstatelabels

 Title   : set_charstatelabels
 Usage   : $set->set_charstatelabels($labels);
 Function: Set the character names and states
 Returns : none
 Args    : array of character states

=cut

sub set_charstatelabels {
    my ( $self, $states ) = @_;
    $self->{'charstatelabels'} = $states;
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
    return $self->{'charstatelabels'} || [];
}

=head2 get_ntax

 Title   : get_ntax
 Usage   : $set->get_ntax();
 Function: Returns the number of taxa of the block
 Returns : # taxa
 Args    : none

=cut

sub get_ntax {
    my $self = shift;
    my $otus = $self->get_otus();
    if ( ref $otus ) {
        return scalar @{ $self->get_otus() };
    }
    else { 
    	$logger->warn("No otus found\n") 
    }
}

=head2 get_nchar

 Title   : get_nchar
 Usage   : $set->get_nchar();
 Function: Returns the number of characters of the block
 Returns : # charaters
 Args    : none

=cut

sub get_nchar {
    my $self = shift;
    return scalar @{ $self->get_otus()->[0]->get_seq() };
}

=head2 select_charlabels

 Title   : select_charlabels
 Usage   : $set->select_charlabels($columns);
 Function: select a subset of charlabels
 Returns : new self with subset of charlabels
 Args    : column numbers

=cut

sub select_charlabels {
    my ( $self, $columns ) = @_;
    my @labels = @{ $self->get_charlabels() };
    if ( @labels == 0 ) { return; }

    my @newlabels = ();
    for my $i ( @{$columns} ) {
        push @newlabels, $labels[$i];
    }

    $self->set_charlabels( \@newlabels );
    return $self;
}

=head2 select_charstatelabels

 Title   : select_charstatelabels
 Usage   : $set->select_charstatelabels($columns);
 Function: select a subset of charstates
 Returns : new self with subset of charstates
 Args    : column numbers

=cut

sub select_charstatelabels {
    my ( $self, $columns ) = @_;
    my @labels = @{ $self->get_charstatelabels() };
    if ( @labels == 0 ) { return; }

    my @newlabels = ();
    for my $i ( @{$columns} ) {
        push @newlabels, $labels[$i];
    }

    $self->set_charstatelabels( \@newlabels );
    return $self;
}

=head2 equals

 Name    : equals
 Usage   : $set->equals($another);
 Function: compare if two TaxUnitSet objects are equal
 Returns : boolean 
 Args    : an TaxUnitSet object

=cut

sub equals {
    my ( $self, $set ) = @_;
    my @otus1 = @{ $self->get_otus() };
    my @otus2 = @{ $set->get_otus() };
    if ( @otus1 != @otus2 ) { return 0; }
    @otus1 = sort { $a->get_name() cmp $b->get_name() } @otus1;
    @otus2 = sort { $a->get_name() cmp $b->get_name() } @otus2;
    for ( my $i = 0; $i < @otus1; $i++ ) {

        # check names
        if ( $otus1[$i]->get_name() ne $otus2[$i]->get_name() ) {
				#carp "OTU names not equal: " . $otus1[$i]->get_name() . " ne " . $otus2[$i]->get_name() . "\n";
            return 0;
        }

        # check seq's
        my @seqs1 = @{ $otus1[$i]->get_seq() };
        my @seqs2 = @{ $otus2[$i]->get_seq() };

        if ( @seqs1 != @seqs2 ) { return 0; }
        for ( my $j = 0; $j < @seqs1; $j++ ) {

            # entry is an array ref of probability values
            if ( ref( $seqs1[$j] ) eq 'ARRAY' ) {
                my @prob1 = @{ $seqs1[$j] };
                my @prob2 = @{ $seqs2[$j] };
                for ( my $k = 0; $k < @prob1; $k++ ) {
                    if ( $prob1[$k] != $prob2[$k] ) {
                        return 0;
                    }
                }
            }

            # entry is a character datum
            elsif ( $seqs1[$j] ne $seqs2[$j] ) {
				#carp "Character values not equal: $seqs1[$j] != $seqs2[$j]\n";
                return 0;
            }
        }

    }
    return 1;
}

sub AUTOLOAD {
    return if $AUTOLOAD =~ /DESTROY$/;
    my $package_name = __PACKAGE__ . '::';

    # The following methods are deprecated and are temporarily supported
    # via a warning and a redirection
    my %synonym_for = (
        "${package_name}set_charstates" => "${package_name}set_charstatelabels",
        "${package_name}get_charstates" => "${package_name}get_charstatelabels",
        "${package_name}select_charstates" =>
            "${package_name}select_charstatelabels",
        "${package_name}get_otu_sequences" =>
            "${package_name}get_seq_string_hash",
    );

    if ( defined $synonym_for{$AUTOLOAD} ) {
        $logger->warn("$AUTOLOAD() is deprecated; use $synonym_for{$AUTOLOAD}() instead");
        goto &{ $synonym_for{$AUTOLOAD} };
    }
    else {
        throw 'UnknownMethod' => "ERROR: Unknown method $AUTOLOAD called";
    }
    return;
}

1;
