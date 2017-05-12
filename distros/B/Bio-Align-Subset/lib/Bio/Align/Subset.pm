package Bio::Align::Subset;


use 5.006;
use strict;
no strict "refs";
use warnings;
use Carp;
use Bio::SeqIO;

use base("Bio::Root::Root");

=head1 NAME

Bio::Align::Subset - A BioPerl module to generate new alignments as subset from larger alignments

=head1 VERSION

Version 1.27

=cut

our $VERSION = '1.27';


=head1 SYNOPSIS
    
    use strict;
    use warnings;
    use Data::Dumper;
    
    use Bio::Align::Subset;
    
    # The alignment in a file
    my $filename = "alignmentfile.fas";
    # The format
    my $format = "fasta";
    
    # The subset of codons
    my $subset = [1,12,25,34,65,100,153,156,157,158,159,160,200,201,202,285];
    
    # Create the object
    my $obj = Bio::Align::Subset->new(
                                      file => $filename,
                                      format => $format
                                    );
    
    # View the result
    # This function returns a Bio::SimpleAlign object
    print Dumper($obj->build_subset($subset));

=cut

=head1 DESCRIPTION

Given an array of codon positions and an alignment, the function
L<Bio::Align::Subset-E<gt>build_subset> returns a new alignment with the codons at
those positions from the original alignment.

=cut

# Body ########################################################################
###############################################################################
###############################################################################
###############################################################################

=head1 CONSTRUCTOR

=head2 Bio::Align::Subset->new()

    $Obj = Bio::Align::Subset->new(file => 'filename', format => 'format')

The L<new> class method constructs a new L<Bio::Align::Subset> object.
The returned object can be used to retrieve, print and generate subsets
from alignment objects. L<new> accepts the following parameters:

=over 1

=item file

A file path to be opened for reading or writing.  The usual Perl
conventions apply:

   'file'       # open file for reading
   '>file'      # open file for writing
   '>>file'     # open file for appending
   '+<file'     # open file read/write
   'command |'  # open a pipe from the command
   '| command'  # open a pipe to the command

=item format

Specify the format of the file.  Supported formats include fasta,
genbank, embl, swiss (SwissProt), Entrez Gene and tracefile formats
such as abi (ABI) and scf. There are many more, for a complete listing
see the SeqIO HOWTO (L<http://bioperl.open-bio.org/wiki/HOWTO:SeqIO>).

If no format is specified and a filename is given then the module will
attempt to deduce the format from the filename suffix. If there is no
suffix that Bioperl understands then it will attempt to guess the
format based on file content. If this is unsuccessful then SeqIO will 
throw a fatal error.

The format name is case-insensitive: 'FASTA', 'Fasta' and 'fasta' are
all valid.

Currently, the tracefile formats (except for SCF) require installation
of the external Staden "io_lib" package, as well as the
Bio::SeqIO::staden::read package available from the bioperl-ext
repository.

=back

=cut

###############################################################################
# Class data and methods
###############################################################################
{  
    # A list of all attributes wiht default values and read/write/required properties
    my %_attribute_properties = (
        _file => ["????", "read.required"],
        _format    => ["????", "read.required"],
        _identifiers   => ["????", "read.write"   ],
        _sequences => ["????", "read.write"   ],
        _seq_length=> [0     , "read.write"   ]
    );
    
    # Global variable to keep count of existing objects
    my $_count = 0;
    
    # The list of all attributes
    sub _all_attributes {
        keys %_attribute_properties;
    }
    
    # Check if a given property is set for a given attribute
    sub _permissions{
        my ($self,$attribute, $permissions) = @_;
        $_attribute_properties{$attribute}[1] =~/$permissions/;
    }
    
    # Return the default value for a given attribute
    sub _attribute_default{
        my ($self,$attribute) = @_;
        $_attribute_properties{$attribute}[0];
    }
    
    # Manage the count of existing objects
    sub get_count{
        $_count;
    }
    sub _incr_count{
        ++$_count;
    }
    sub _decr_count{
        --$_count;
    }
    
}
#
# The constructor of the class
#
sub new {
    
    my ($class, %arg) = @_;
    my $self = bless {}, $class;
    
    foreach my $attribute ($self->_all_attributes()){
        
        # E.g. attribute = "_name", argument = "name"
        my ($argument) = ($attribute =~ /^_(.*)/);
        
        # If explicitly given
        if(exists $arg{$argument}){
            $self->{$attribute} = $arg{$argument};
        }
        
        # If not given but required
        elsif($self->_permissions($attribute, 'required')){
            croak("No $argument attribute as required");
        }
        
        # Set to default
        else{
            $self->{$attribute} = $self->_attribute_default($attribute);            
        }
        
    }
    
    # Called $class because it is a gobal method
    $class->_incr_count;
    
    $self->_extract_sequences;
    return $self;
    
}


#
# Obtaining the sequences in a Array
#
sub _extract_sequences{
    
    my $self = $_[0];
        
    my @identifiers;
    my @sequences;
    
    my $seqIO = Bio::SeqIO->new(
                             -file   => $self->get_file,
                             -format => $self->get_format
                            );
    
    while( my $seq = $seqIO->next_seq){
        
        my $sequence_string = $seq->seq;
        $sequence_string =~ s/\s//g;
        
        push(@identifiers, $seq->id);
        $self->_verify_chain($sequence_string);
        push(@sequences, $sequence_string);
        
    }
    
    $self->set_identifiers(\@identifiers);
    $self->set_sequences(\@sequences);
    
}

=head1 OBJECT METHODS

=head2 build_subset($index_list)

    my $subset = $obj->build_subset([1,12,25,34,65,100,153,156,157,158,159]);

Build a new alignment with the specified codons in C<$index_list>. It returns
a L<Bio::SimpleAlign> object.


=cut

#
# Build a subset
#
sub build_subset{
    
    my ($self, $subset) = @_;
    
    
    # Initialite array for the new sequences
    my @new_sequences = ();
    
    for(my $i=0;$i<=$#{$self->get_sequences};$i++){
        # Initialite a new string for the new sequence
        my $new_sequence = "";
        for my $index (@{$subset}){
            if(($index-1)*3 > length(${$self->get_sequences}[$i])){ last }
            $new_sequence.= substr(${$self->get_sequences}[$i],($index-1)*3,3);
        }
        push(@new_sequences, $new_sequence);
    }
    
    my @identifiers   = @{$self->get_identifiers};
    # Create the new align object
    my $aln_obj = Bio::SimpleAlign->new();
    
    # Build a new Bio::LocatableSeq obj for each sequence
    for(my $i=0;$i<=$#identifiers;$i++){
        
        my $id = substr($identifiers[$i],0,9);
        my $iden_plus_num = $i.$id;
        
        # Create such object
        my $newSeq = Bio::LocatableSeq->new(-seq   => $new_sequences[$i],
                                            -id    => substr($iden_plus_num,0,9),
                                            -start => 0,
                                            -end   => length($new_sequences[$i]));
        
        # Append the new sequence object to the new alignmen object
        $aln_obj->add_seq($newSeq);
        
    }
    
    # Once the loop is finished, return the alignment object
    # with all the sequences appended.
    return $aln_obj;
    
}

###############################################################################
# Auxiliary methods
###############################################################################
{
    #
    # Set the sequence length of the whole alignment
    #
    sub _set_sequence_length{
        my $self = $_[0];
        $self->{_seq_length} = $_[1];
    }
    
    #
    # Check if a the length of a given sequence match with the length of
    # the whole alignment.
    #
    sub _check_sequence_length{
        my $self = $_[0];
        my $tested_sequence_length = $_[1];
        $tested_sequence_length == $self->get_seq_length ? return 1 : return 0;
    }
    
    #
    # Verifies the integrity of a given sequence
    #
    sub _verify_chain{
        
        my ($self,$sequence) = @_;
        my $seq_length = length($sequence);
        
        
        # 1. The chain must be a DNA sequence
        $self->_isdna($sequence) ? 1 : $self->warn("\nThe following sequence does not seems as a dna/rna (ATGCU) sequence:\n\n<< $sequence >>\n");
        
        # 2. Also, all the sequences must be equal. But if $_sequence_length
        # has not been updated, it takes the value of the length of this sequence.
        if($self->get_seq_length == 0){
            # The input file must be wrapped (non untermitated codons)
            $seq_length % 3 == 0 ? 1 : $self->throw("The sequence length is not multiple of 3 ($seq_length)");
            $self->_set_sequence_length($seq_length);
        }else{
            $self->_check_sequence_length($seq_length) ? 1 : croak("A sequence length does not match with the length of the whole alignment");
        }
        return 1;
        
    }
    
    #
    # Verifies if a given string is a DNA sequence
    #
    sub _isdna{
        my ($self,$sequence) = ($_[0],uc($_[1]));
        if($sequence =~ /^[ACGTU]+$/){
             return 1;
        }else{
             return 0;
        }
    }
    
    
}
###############################################################################


###############################################################################
# Accessor Methods
###############################################################################
# This kind of method is called Accesor
# Method. It returns the value of a key
# and avoid the direct acces to the inner
# value of $obj->{_file}.
###############################################################################
sub get_file { $_[0] -> {_file} }
sub get_format    { $_[0] -> {_format}    }
sub get_sequences { $_[0] -> {_sequences} }
sub get_identifiers   { $_[0] -> {_identifiers}   }
sub get_seq_length{ $_[0] -> {_seq_length}}
###############################################################################


###############################################################################
# Mutator Methods
###############################################################################
sub set_file { my ($self, $file) = @_;
                    $self-> {_file} = $file if $file;
                  }
sub set_format    { my ($self, $format) = @_;
                    $self-> {_format} = $format if $format;
                  }
sub set_identifiers   { my ($self, $identifiers) = @_;
                    $self-> {_identifiers} = $identifiers if $identifiers;
                  }
sub set_sequences { my ($self, $sequences) = @_;
                    $self-> {_sequences} = $sequences if $sequences;
                  }
###############################################################################



# Footer ######################################################################
###############################################################################
###############################################################################
###############################################################################

=head1 ACCESSOR METHODS

=head2 get_count

    Title   : get_count
    Usage   : $instance_no = $obj->get_count
    Function: 
    Returns : Number of istances for this class
    Args    :

=head2 get_file

    Title   : get_file
    Usage   : $file_path = $obj->get_file
    Function:
    Returns : The file name of the alignment
    Args    :

=head2 get_format

    Title   : get_format
    Usage   : $format = $obj->get_format
    Function:
    Returns : The alignment format (fasta, phylip, etc.)
    Args    :

=head2 get_identifiers

    Title   : get_identifiers
    Usage   : $identifiers $obj->get_identifiers
    Function:
    Returns : An array reference with all the identifiers in an alignment
    Args    :

=head2 get_seq_length

    Title   : get_seq_length
    Usage   : $long = $obj->get_seq_length
    Function:
    Returns : The longitude of all the sequences in an alignment
    Args    :

=head2 get_sequences

    Title   : get_sequences
    Usage   : $sequences = $obj->get_sequences
    Function:
    Returns : An array reference with all the sequences in an alignment
    Args    :


=head1 MUTATOR METHODS

=head2 set_file

    Title   : set_file
    Usage   : $obj->set_file('filename')
    Function: Set the file path for an alignment
    Returns : 
    Args    : String

=head2 set_format

    Title   : set_format
    Usage   : $obj->set_format('fasta')
    Function: Set the file format for an alignment
    Returns :
    Args    : String

=head2 set_identifiers

    Title   : set_identifiers
    Usage   : $obj->set_identifiers(\@array_ids)
    Function: Change the identifiers for all the sequences in the alignment
    Returns :
    Args    : List

=head2 set_sequences

    Title   : set_sequences
    Usage   : $obj->set_sequences(\@array_seqs)
    Function: Change the sequences in the alignment
    Returns :
    Args    : List

=head1 AUTHOR - Hector Valverde

Hector Valverde, C<< <hvalverde@uma.es> >>

=head1 CONTRIBUTORS

Juan Carlos Aledo, C<< <caledo@uma.es> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-align-subset at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Align-Subset>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::Align::Subset


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Align-Subset>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-Align-Subset>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-Align-Subset>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-Align-Subset/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Hector Valverde and Juan Carlos Aledo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Bio::Align::Subset
