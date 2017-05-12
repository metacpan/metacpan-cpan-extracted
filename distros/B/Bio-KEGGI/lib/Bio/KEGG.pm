=head1 NAME

    Bio::KEGG - Perl module to fetch details parsed by Bio::KEGGI.
    
=head1 SYNOPSIS
    
    my $keggi = Bio::KEGGI->new(
        -file => 'keggfilename',
        -type => 'ko',
    );
    
    while (my $kegg = $keggi->next_rec) {
        print $kegg->id;
    }

=head1 DESCRIPTION

    This module is used to fetch details from object created by Bio::KEGGI.
    Create a new Bio::KEGG object is not supported.
    
    For more details for different input files, please refer to documents of
    L<Bio::KEGG::genome>, L<Bio::KEGG::ko>, L<Bio::KEGG::pathway> and
    L<Bio::KEGG::gene>.
    
=head1 AUTHOR

    Haizhou Liu, zeroliu-at-gmail-dot-com

=head1 VERSION

    0.1.5
    
=head1 METHODS

=head2 id

    Name:   id
    Desc:   Get KEGG entry id
    Usage:  $acc = $o_kegg->id()
    Args:
    Return: A string
    
=head2 name

    Name:   name
    Desc:   Get KEGG entry NAME.
    Usage:  $name = $o_kegg->name()
    Args:
    Return: A string
    
=head2 desc

    Name:   desc
    Desc:   Get KEGG entry DEFINITION information.
    Usage:  $desc = $o_kegg->desc()
    Args:
    Return: A string
    
=head2 ec

    Name:   ec
    Desc:   Get KEGG EC information.
    Usage:  $ra_ec = $o_kegg->ec()
    Args:
    Retuen: A reference to an array

=head2 disease

    Name:   disease
    Desc:   Get KEGG entry DISEASE information.
    
            $ra_disease = [ $disease_id, ... ];
    
    Usage:  $rh_diseases = $o_kegg->disease()
    Args:
    Return: A reference to an array.    
    
=head2 pmid

    Name:   pmid
    Disc:   Get KEGG entry PUBMED ids.
    
            $ra_pmid = [ $pmid, ... ];
    
    Usage:  $o_kegg->pmids()
    Args:
    Return: A reference to an array.
    
=head2 module

    Name:   module
    Disc:   Get KEGG entry MODULE ids
    
            $ra_module = [ $module_id, ... ];
    
    Usage:  $o_kegg->module()
    Args:
    Return: A reference to an array
    
=head2 class

    Name:   class
    Disc:   Get KEGG entry CLASS information
        
        $ra_class = [ $class, ... ];
    
    Usage:  $o_kegg->class()
    Args:
    Return: A reference to an array
    
=head2 pathway

    Name:   pathway
    Disc:   Get KEGG entry PATHWAY ids
    
            $ra_pathways = [ pathway_id, ... ];
    
    Usage:  $o_kegg->pathway()
    Args:
    Return: A reference to an array.

=head2 dblink

    Name:   dblink
    Disc:   Get KEGG entry DBLINKS information
    
        $rh_dblink = [
            {
                'db' => $db,
                'entry' => [ entry, ... ],
            },
            ...
        ];
    
    Usage:  $o_kegg->dblink()
    Args:
    Return: A reference to a hash.
    
=cut

package Bio::KEGG;

use strict;
use warnings;

our $VERSION = "v0.1.5";

=begin new
    Name:   new
    Desc:   Constructor for Bio::KEGG object
    Usage:  
    Args:
    Return: A KEGG object

sub new {
    my $class = shift;
    warn "Sorry, construct $class object is not supported now.\n";
    
    return;
}

=cut

=begin id
    Name:   id
    Desc:   Get KEGG entry id
    Usage:  $acc = $o_kegg->id()
    Args:
    Return: A string
=cut

sub id {
    my $self = shift;
    
    return $self->{'id'};
}

=begin name
    Name:   name
    Desc:   Get KEGG entry NAME.
    Usage:  $name = $o_kegg->name()
    Args:
    Return: A string
=cut

sub name {
    my $self = shift;
    
    return $self->{'name'};
}

=begin desc
    Name:   desc
    Desc:   Get KEGG entry DEFINITION information.
    Usage:  $desc = $o_kegg->desc()
    Args:
    Return: A string
=cut

sub desc {
    my $self = shift;
    
    return $self->{'definit'};
}

=begin ec
    Name:   ec
    Desc:   Get EC information
    Usage:  $o_kegg->ec()
    Args:
    Return: A reference to an array
=cut

sub ec {
    my $self = shift;
    
    return $self->{'ec'};
}

=begin disease
    Name:   disease
    Desc:   Get KEGG entry DISEASE information.
    
            $ra_disease = [ $disease_id, ... ];
    
    Usage:  $rh_diseases = $o_kegg->disease()
    Args:
    Return: A reference to an array.
=cut

sub disease {
    my $self = shift;
    
    return $self->{'disease'};
}

=begin pmid
    Name:   pmid
    Disc:   Get KEGG entry PUBMED ids.
    
            $ra_pmid = [ $pmid, ... ];
    
    Usage:  $o_kegg->pmids()
    Args:
    Return: A reference to an array.
=cut

sub pmid {
    my $self = shift;
    
    return $self->{'pmid'};
}

=begin module
    Name:   module
    Disc:   Get KEGG entry MODULE ids
    
        $ra_module = [ $module_id, ... ];
    
    Usage:  $o_kegg->module()
    Args:
    Return: A reference to an array
=cut

sub module {
    my $self = shift;
    
    return $self->{'module'};
}

=begin class
    Name:   class
    Disc:   Get KEGG entry CLASS information
        
        $ra_class = [ $class, ... ];
    
    Usage:  $o_kegg->class()
    Args:
    Return: A reference to an array
=cut

sub class {
    my $self = shift;
    
    return $self->{'class'};
}

=begin pathway
    Name:   pathway
    Disc:   Get KEGG entry PATHWAY ids
    
            $ra_pathways = [ pathway_id, ... ];
    
    Usage:  $o_kegg->pathway()
    Args:
    Return: A reference to an array.
=cut

sub pathway {
    my $self = shift;
    
    return $self->{'pathway'};
}

=begin dblink
    Name:   dblink
    Disc:   Get KEGG entry DBLINKS information
    
        $rh_dblink = [
            {
                'db' => $db,
                'entry' => [ entry, ... ],
            },
            ...
        ];
    
    Usage:  $o_kegg->dblink()
    Args:
    Return: A reference to a hash.
=cut

sub dblink {
    my $self = shift;
    
    return $self->{'dblink'};
}

1;
