=head1 NAME

    Bio::KEGG::genome - Perl module to fetch details of KEGG file 'genome'.

=head1 DESCRIPTION

    Fetch data from a Bio::KEGGI::genome object.
    
    Some genomes contain multiple chromosomes or plasmids, these are designated
    as genome 'components', which has 2 categories: 'chromosome' and 'plasmid'.

=head1 AUTHOR

    Haizhou Liu, zeroliu-at-gmail-dot-com

=head1 VERSION

    0.1.5
    
=head1 METHODS

=head2 abbrsp

    Name:   abbrsp
    Desc:   Get KEGG genome entry abbreciated species name.
    Usage:  $sp = $o_kegg->abbrsp()
    Args:
    Return: A string

=head2 hamap_id

    Name:   hamap_id
    Desc:   Get KEGG genome entry HAMPA id.
    Usage:  $hamap_id = $o_kegg->hamap_id()
    Args:
    Return: A string

=head2 anno

    Name:   anno
    Desc:   Get KEGG genome entry ANNOTATION information.
    Usage:  $anno = $o_kegg->anno()
    Args:
    Return: A string
    
=head2 taxid
    
    Name:   taxid
    Desc:   Get KEGG genome entry taxonomy id.
    Usage:  $taxid = $o_kegg->taxid()
    Args:
    Return: A string    

=head2 taxonomy

    Name:   taxonomy
    Desc:   Get KEGG genome entry taxonomy information.
    usage:  $taxonomy = $o_kegg->taxonomy
    Args:
    Return: A string
    
=head2 data_src

    Name:   data_src
    Desc:   Get KEGG genome entry DATA_SOURCE information
    Usage:  $data_src = $o_kegg->data_src()
    Args:
    Return: A string

=head2 comment

    Name:   comment
    Desc:   Get KEGG genome entry COMMENT.
    usage:  $comment = $o_kegg->comment()
    Args:
    Return: A string
    
=head2 origin_db

    Name:   origin_db
    Desc:   Get KEGG genome entry ORIGINAL_DB.
    usage:  $origin_db = $o_kegg->original_db()
    Args:
    Return: A string
    
=head2 component

    Name:   component
    Desc:   Get KEGG genome entry CHROMOSOME and PLASMID information.
    
    $rh_component = [
        {
            'category'    => $category, # 'chromosome' or 'plasmid'
            'is_circular' => $is_cir,   # 0 or 1
            'name'        => $name,
            'refseq'      => $refseq_id,
            'length'      => $length
        },
        ...
    ]
    
    Usage:  Bio::KEGG::genome->component()
    Args:
    Return: A reference to an array    

=head2 statistics

    Name:   statistics
    Disc:   Get KEGG genome entry STATISTICS information.
            
            $rh_statistics = {
                'nt'  => $nt,  # Number of nucleotides
                'prn' => $prn, # Number of protein genes
                'rna' => $rna, # Number of RNA genes 
            }
    
    Usage:  $o_kegg->statistics()
    Args:
    Return: A reference to a hash.
    
=cut

package Bio::KEGG::genome;

use strict;
use warnings;

use base qw(Bio::KEGG);

# use Smart::Comments;

our $VERSION = "v0.1.5";

=begin abbrsp
    Name:   abbrsp
    Desc:   Get KEGG genome entry abbreciated species name.
    Usage:  $sp = $o_kegg->abbrsp()
    Args:
    Return: A string
=cut

sub abbrsp {
    my $self = shift;
    
    return $self->{'abbr'};
}

=begin hamap_id
    Name:   hamap_id
    Desc:   Get KEGG genome entry HAMPA id.
    Usage:  $hamap_id = $o_kegg->hamap_id()
    Args:
    Return: A string
=cut

sub hamap_id {
    my $self = shift;
    
    return $self->{'hamap_id'};
}

=begin anno
    Name:   anno
    Desc:   Get KEGG genome entry ANNOTATION information.
    Usage:  $anno = $o_kegg->anno()
    Args:
    Return: A string
=cut

sub anno {
    my $self = shift;
    
    return $self->{'annotation'};
}

=begin taxid
    Name:   taxid
    Desc:   Get KEGG genome entry taxonomy id.
    Usage:  $taxid = $o_kegg->taxid()
    Args:
    Return: A string
=cut

sub taxid {
    my $self = shift;
    
    return $self->{'taxid'};
}

=begin taxonomy
    Name:   taxonomy
    Desc:   Get KEGG genome entry taxonomy information.
    usage:  $taxonomy = $o_kegg->taxonomy
    Args:
    Return: A string
=cut

sub taxonomy {
    my $self = shift;
    
    return $self->{'tax_lineage'};
}

=begin data_src
    Name:   data_src
    Desc:   Get KEGG entry DATA_SOURCE information
    Usage:  $data_src = $o_kegg->data_src()
    Args:
    Return: A string
=cut

sub data_src {
    my $self = shift;
    
    return $self->{'data_src'};
}

=begin comment
    Name:   comment
    Desc:   Get KEGG entry COMMENT.
    usage:  $comment = $o_kegg->comment()
    Args:
    Return: A string
=cut

sub comment {
    my $self = shift;
    
    return $self->{'comment'};
}

=begin origin_db
    Name:   origin_db
    Desc:   Get KEGG entry ORIGINAL_DB.
    usage:  $origin_db = $o_kegg->original_db()
    Args:
    Return: A string
=cut

sub origin_db {
    my $self = shift;
    
    return $self->{'origin_db'};
}

=begin component
    Name:   component
    Desc:   Get KEGG entry CHROMOSOME and PLASMID information.
    ------------------------------------------------------------------
    $rh_component = [
        {
            'category'    => $category, # 'chromosome' or 'plasmid'
            'is_circular' => $is_cir,  # 0 or 1
            'name'        => $name,
            'refseq'      => $refseq_id,
            'length'      => $length
        },
        ...
    ]
    ------------------------------------------------------------------
    
    Usage:  Bio::KEGG::genome->component()
    Args:
    Return: A reference to an array
=cut

sub component {
    my $self = shift;
    
    return $self->{'component'};
}

=begin statistics
    Name:   statistics
    Disc:   Get KEGG entry STATISTICS information.
    ------------------------------------------------------------------
            $rh_statistics = {
                'nt'  => $nt,  # Number of nucleotides
                'prn' => $prn, # Number of protein genes
                'rna' => $rna, # Number of RNA genes 
            }
    ------------------------------------------------------------------
    Usage:  $o_kegg->statistics()
    Args:
    Return: A reference to a hash.
=cut

sub statistics {
    my $self = shift;

    my $rh_stat = {
        'nt'  => $self->{'nt'},
        'prn' => $self->{'prn'},
        'rna' => $self->{'rna'},
    };
    
    return $rh_stat;
}

1;
