=head1 NAME

    Bio::KEGG::ko- Perl module to fetch details of KEGG file 'pathway'.

=head1 DESCRIPTION

    Fetch data from a Bio::KEGGI::pathway object

=head1 AUTHOR

    Haizhou Liu, zeroliu-at-gmail-dot-com

=head1 VERSION

    0.1.5
    
=head1 METHODS

=head2 ec

    Name:   ec
    Desc:   Get ecs for KEGG entry ENZYME
    
            $ra_ec = [ $ec, ... ];
            
    Usage:  $o_kegg->ec()
    Args:
    Return: A reference to an array
    
=head2 drug

    Name:   drug
    Desc:   Get drug ids for KEGG pathway entry DRUG.
    
            $ra_drug = [ $drug, ... ];
            
    Usage:  $o_kegg->drug()
    Args:
    Return: A reference to an array

=head2 map

    Name:   map
    Desc:   Get KEGG pathway entry PATHWAY_MAP.
    Usage:  $o_kegg->map()
    Args:
    Return: A string

=head2 organism

    Name:   organism
    Desc:   Get organism description for KEGG pathway entry ORGANISM.
    Usage:  $o_kegg->organism()
    Args:
    Return: A string

=head2 org

    Name:   org
    Desc:   Get abbrivated oeganism information for KEGG pathway entry
            ORGANISM.
    Usage:  $o_kegg->org()
    Args:
    Return: A string
    
=head2 gene

    Name:   gene
    Disc:   Get KEGG entry GENE information
        
        $rh_gene = {
            'entry' => $entry,
            'name'  => [ $name, ... ],
            'ko'    => [ $ko, ... ],
            'ec'    => [ $ec, ... ],
        };
    
    Usage:  $o_kegg->gene()
    Args:
    Return: A reference to a hash.
    Note:   This method returns different from the method of Bio::KEGG::ko.
    
=head2 orthology

    Name:   orthology
    Disc:   Get orthology ids for KEGG entry ORTHOLOGY.
        
        $ra_orthology = [ $orth_id, ... ];
    
    Usage:  $o_kegg->orthology
    Args:
    Return: A reference to an array
    
=head2 reaction

    Name:   reaction
    Desc:   Get reaction ids for KEGG entry REACTION
    
        $ra_reaction = [ $reaction_id, ... ];
        
    Usage:  $o_kegg->reaction()
    Args:
    Return: A reference to an array
    
=head2 compound

    Name:   compound
    Disc:   Get compound ids for KEGG entry COMPOUND
        
        $ra_compound = [ $compound_id, ... ];
    
    Usage:  $o_kegg->compound()
    Args:
    Return: A reference to an array
    
=head2 rel_pathway

    Name:   compound
    Disc:   Get related pathway ids for KEGG entry REL_PATHWAY
        
        $ra_rel_pathway = [ $rel_pathway_id, ... ];
    
    Usage:  $o_kegg->rel_pathway()
    Args:
    Return: A reference to an array

=head2 ko_pathway

    Name:   ko_pathway
    Disc:   Get related ko pathway id for KEGG entry KO_PATHWAY
    Usage:  $o_kegg->compound()
    Args:
    Return: A string
    
=cut

package Bio::KEGG::pathway;

use strict;
use warnings;

use base qw(Bio::KEGG);

# use Smart::Comments;

our $VERSION = 'v0.1.5';

=begin drug
    Name:   drug
    Desc:   Get KEGG pathway entry DRUG.
    Usage:  $o_kegg->drug()
    Args:
    Return: A reference to an array
=cut

sub drug {
    my $self = shift;
    
    return $self->{'drug'};
}

=begin map
    Name:   map
    Desc:   Get KEGG pathway entry PATHWAY_MAP.
    Usage:  $o_kegg->map()
    Args:
    Return: A string
=cut

sub map {
    my $self = shift;
    
    return $self->{'map'};
}

=begin organism
    Name:   organism
    Desc:   Get KEGG pathway entry ORGANISM.
    Usage:  $o_kegg->organism()
    Args:
    Return: A string
=cut

sub organism {
    my $self = shift;
    
    return $self->{'organism'};
}

=begin org
    Name:   org
    Desc:   Get KEGG pathway entry ORGANISM abbreviated.
    Usage:  $o_kegg->org()
    Args:
    Return: A string
=cut

sub org {
    my $self = shift;
    
    return $self->{'org_abbr'};
}
    
=begin gene
    Name:   gene
    Disc:   Get KEGG entry GENE information
    
        $rh_gene = {
            'entry' => $entry,
            'name'  => [ $name, ... ],
            'ko'    => [ $ko, ... ],
            'ec'    => [ $ec, ... ],
        };
    
    Usage:  $o_kegg->gene()
    Args:
    Return: A reference to a hash.
=cut

sub gene {
    my $self = shift;
    
    return $self->{'gene'};
}

=begin orthology
    Name:   orthology
    Disc:   Get KEGG entry ORTHOLOGY.
    
        $ra_orthology = [ $orth_id, ... ];
    
    Usage:  $o_kegg->orthology
    Args:
    Return: A reference to an array
=cut

sub orthology {
    my $self = shift;
    
    return $self->{'orthology'};
}

=begin reaction
    Name:   reaction
    Desc:   Get KEGG entry REACTION
    Usage:  $o_kegg->reaction()
    Args:
    Return: A reference to an array
=cut

sub reaction {
    my $self = shift;
    
    return $self->{'reaction'};
}

=begin compound
    Name:   compound
    Disc:   Get KEGG entry COMPOUND
    
        $ra_compound = [ $compound_id, ... ];
    
    Usage:  $o_kegg->compound()
    Args:
    Return: A reference to an array
=cut

sub compound {
    my $self = shift;
    
    return $self->{'compound'};
}

=begin rel_pathway
    Name:   compound
    Disc:   Get KEGG entry REL_PATHWAY
    
        $ra_rel_pathway = [ $rel_pathway_id, ... ];
    
    Usage:  $o_kegg->rel_pathway()
    Args:
    Return: A reference to an array
=cut

sub rel_pathway {
    my $self = shift;
    
    return $self->{'rel_pathway'};
}

=begin ko_pathway
    Name:   ko_pathway
    Disc:   Get KEGG entry KO_PATHWAY
    Usage:  $o_kegg->compound()
    Args:
    Return: A string
=cut

sub ko_pathway {
    my $self = shift;
    
    return $self->{'ko_pathway'};
}

1;
