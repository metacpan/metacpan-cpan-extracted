=head1 NAME

    Bio::KEGGI::pathway

=head1 DESCRIPTION

    Parse KEGG pathway file (ftp://ftp.genome.jp/pub/kegg/pathway/pathway).

=head1 METHODS

=head2 next_rec

    Name:   next_rec
    Desc:   Get next KEGG record
    Usage:  $o_keggi->next_rec()
    Args:   none
    Return: A Bio::KEGG::pathway object
    
=head1 VERSION

    v0.1.5

=head1 AUTHOR
    
    zeroliu-at-gmail-dot-com
    
=cut

=begin NOTE
    Returned data structure
    
    ----------------------------------------------------------------------------
    
    $rh_rec = {
        'id'          => $id,
        'name'        => $name,
        'definit'     => $definition,
        'class'       => [ $class, ... ],
        'map'         => $map,
        'module'      => [ $module_id, ... ],
        'disease'     => [ $disease_id, ... ],
        'organism'    => $organism,
        'abbr_org'    => $abbr_org,
        'dblink'      => [
            {
                'db'    => $db,
                'link' => [ $link, ... ],
            },
            ...
        ],
        'gene'        => [
            {
                'entry' => $name,
                'name'  => [ $alt_name, ... ],
                'ko'    => [ $ko, ... ],
                'ec'    => [ $ec, ... ],
            },
            ...
        ],
        'orthology'   => [ $orth_id, ... ],
        'compound'    => [ $compound_id, ... ],
        'pmid'        => [ $pmid, ...],
        'rel_pathway' => [ $rel_pathway_id, ... ],
        'ko_pathway'  => $ko_pathway,
    }
    
    ----------------------------------------------------------------------------

=cut

package Bio::KEGGI::pathway;

use strict;
use warnings;

use Switch;
use Text::Trim;

use Bio::KEGG::pathway;

# use Smart::Comments;

our $VERSION = 'v0.1.5';

use base qw(Bio::KEGGI);

=head2 next_rec
    Name:   next_rec
    Desc:   Get next KEGG record
    Usage:  $o_keggi->next_rec()
    Args:   none
    Return: A KEGG object
=cut

sub next_rec {
    my $self = shift;
    
    my $ra_rec = _get_next_rec($self->{'_FH'});
    my $rh_rec = _parse_pathway_rec($ra_rec);
    
    bless($rh_rec, "Bio::KEGG::pathway") if (defined $rh_rec);
    
    return $rh_rec;
}


=begin _get_next_rec
    Name:   _get_next_rec
    Desc:   Read a record from KEGG file
    Usage:  _get_next_rec(FH)
    Args:   A filehandle of KEGG file
    Return: A ref of an array for a KEGG record
=end
=cut

sub _get_next_rec {
    my $ifh = shift;
    
    # Since a KEGG record ended with '///'
    local $/ = "\/\/\/\n";
    
    my $rec;
    
    if ($rec = <$ifh>) {
        my @rec = split(/\n/, $rec);
        
        return \@rec;
    }
    else { # To the end of file
        return;
    }
}

=begin _parse_pathway_rec
    Name:   _parse_pathway_rec
    Disc:   Parse KEGG pathway record
    Usage:  _parse_pathway_rec($ra_rec)
    Args:   A reference of an array of Bio::KEGGI::pathway
    Return: A reference of a hash of Bio::KEGG
=end
=cut

sub _parse_pathway_rec {
    my $ra_rec = shift;
    
    # KO record: $ra_rec
    
    my $rh_rec;
    my $cur_section = '';
    my $db_tag = '';
    my $gene_tag = '';
    
    for my $row ( @{$ra_rec} ) {
        next if ( $row =~ /^\s*$/);
        next if ( $row =~ /\/\/\// );
        
        if ($row =~ /^ENTRY\s+(.+?)\s+/) {
            $rh_rec->{'id'} = $1;
        }
        elsif ($row =~ /^NAME\s{8}(.+)$/ ) {
            $rh_rec->{'name'} = $1;
        }
        elsif ($row =~ /^DESCRIPTION\s(.+)?/) { # There might be multi rows for DEFINITION
            $cur_section = 'DESCRIPTION';
            
            $rh_rec->{'definit'} = $1;
        }
        elsif ($row =~ /^CLASS\s{7}(.+)$/) {
            $cur_section = 'CLASS';
            
            push @{ $rh_rec->{'class'} }, $1;
        } 
        elsif ($row =~ /^PATHWAY_MAP\s(\w+\d{5})/) {
            $rh_rec->{'map'} = $1;
        }
        elsif ($row =~ /^MODULE\s{6}(M\d{5})/) {
            $cur_section = 'MODULE';
            
            push @{ $rh_rec->{'module'} }, $1;
        }
        elsif ($row =~ /^ENZYME\s{6}(\S+)$/) {
            $cur_section = 'ENZYME';
            
            push @{ $rh_rec->{'ec'} }, $1;
        }
        elsif ($row =~ /^DISEASE\s{5}(\w+\d+)\s/) {
            $cur_section = 'DISEASE';
            
            push @{ $rh_rec->{'disease'} }, $1;
        }
        elsif ($row =~ /^DRUG\s{8}(D\d{5})/) {
            $cur_section = 'DRUG';
            
            push @{ $rh_rec->{'drug'} }, $1;
        }
        elsif ($row =~ /^ORGANISM\s{4}(.+?)\s\[GN:(\w+)\]$/) {
            $rh_rec->{'organism'} = $1;
            $rh_rec->{'org_abbr'} = $2;
        }
        elsif ($row =~ /DBLINKS\s{5}(\S+):\s(.+)?/) {
            $cur_section = 'DBLINKS';
            $db_tag = $1;
            
            my $dblinks = $2;
            my @dblinks = split(/\s/, $dblinks);
            
            my $rh_dblink = {
                'db' => $db_tag,
                'link' => \@dblinks,                
            };
            
            push @{ $rh_rec->{'dblink'} }, $rh_dblink;
        }
        elsif ($row =~ /^GENE\s{8}(.+?)$/) {
            $cur_section = 'GENE';
            
            my $gene_str = $1;
            
            # my ($rh_name, $ko, $ec) = _parse_gene($gene_str);
            
            # my $rh_gene;
            
            # $rh_gene->{'name'} = $rh_name if ($rh_name);
            # $rh_gene->{'ko'} = $ko if ($ko);
            # $rh_gene->{'ec'} = $ec if ($ec);
            
            my $rh_gene = _parse_gene($gene_str);
            
            push @{ $rh_rec->{'gene'} }, $rh_gene;
        }
        elsif ($row =~ /^ORTHOLOGY\s{3}(K\d{5})/) {
            $cur_section = 'ORTHOLOGY';
            
            push @{ $rh_rec->{'orthology'} }, $1;
        }
        elsif ($row =~ /^REACTION\s{4}(\w\d{5})/) {
            $cur_section = 'REACTION';
            
            push @{ $rh_rec->{'reaction'} }, $1;
        }
        elsif ($row =~ /^COMPOUND\s{4}(\w\d{5})/) {
            $cur_section = 'COMPOUND';
            
            push @{ $rh_rec->{'compound'} }, $1;
        }
        elsif ($row =~ /^REFERENCE/) {
            if ($row =~ /^REFERENCE\s+PMID:(\d+)/) {
                $cur_section = 'REFERENCE';
                push @{ $rh_rec->{'pmid'} }, $1;
            }
            elsif ($row =~ /^REFERENCE/) {
                $cur_section = 'REFERENCE';
                
                # Do nothing
            }
            else {
                ### Current ENTRY: $rh_rec->{'id'}
                ### Unrecognized REFERENCE: $row
            }
        }
        elsif ($row =~ /^REL_PATHWAY\s(\w+\d+)\s/) {
            $cur_section = 'REL_PATHWAY';
            
            push @{ $rh_rec->{'rel_pathway'} }, $1;
        }
        elsif ($row =~ /^KO_PATHWAY\s{2}(ko\d{5})$/) {
            $rh_rec->{'ko_pathway'} = $1;
        }
        elsif ($row =~ /^\s{2}(?:AUTHORS|TITLE|JOURNAL)/) { # REFERENCE section
            # Do nothing
        }
        elsif ($row =~ /^\s{12}\S/) { # Continuous text for existing section
            switch ($cur_section) {
                case 'DESCRIPTION' {
                    trim($row);
                    
                    $rh_rec->{'definit'} .= " $row";
                }
                case 'MODULE' {
                    if ($row =~ /(M\d{5})/) {
                        push @{ $rh_rec->{'module'} }, $1;
                    }
                    else {
                        ### Current entry: $rh_rec->{'id'}
                        ### Unrecognized MODULE: $row
                    }
                }
                case 'ENZYME' {
                    trim($row);
                    
                    push @{ $rh_rec->{'ec'} }, $row;
                }
                case 'CLASS' {
                    trim($row);
                    
                    if ($row =~ /^[A-Z]/) {
                        push @{ $rh_rec->{'class'} }, $row;
                    }
                    else {
                        my $class = pop @{ $rh_rec->{'class'} };
                        
                        $class .= " $row";
                        
                        push @{ $rh_rec->{'class'} }, $class;
                    }
                }
                case 'DRUG' {
                    trim($row);
                    
                    if ($row =~ /(D\d{5})/) {
                        push @{ $rh_rec->{'drug'} }, $1;
                    }
                    else {
                        # Do nothing
                    }
                }
                case 'DBLINKS' {
                    if ($row =~ /(\S+):\s(.+?)$/) {
                        my $db = $1;
                        my $dblinks = $2;
                        
                        my @dblinks = split(/\s/, $dblinks);
                        
                        my $rh_dblink = {
                            'db' => $db,
                            'link' => \@dblinks,
                        };
                        
                        push @{ $rh_rec->{'dblink'} }, $rh_dblink;
                    }
                    else {
                        ### Unrecognized DBLINKS: $row
                    }
                }
                case 'DISEASE' {
                    # Do nothing
                }
                case 'GENE' {
                    trim($row);
                    
                    # my ($rh_name, $ko, $ra_ec) = _parse_gene($row);
            
                    # my $rh_gene;
            
                    # $rh_gene->{'name'} = $rh_name if ($rh_name);
                    # $rh_gene->{'ko'} = $ko if ($ko);
                    # $rh_gene->{'ec'} = $ra_ec if ($ra_ec);
                    
                    my $rh_gene = _parse_gene($row);
            
                    push @{ $rh_rec->{'gene'} }, $rh_gene;
                }
                case 'ORTHOLOGY' {
                    if ($row =~ /^\s{12}(K\d{5})\s/) {
                        push @{ $rh_rec->{'orthology'} }, $1;
                    }
                    else {
                        ### Current entry: $rh_rec->{'id'}
                        ### Unrecognized ORTHOLOGY: $row
                    }
                }
                case 'REACTION' {
                    if ($row =~ /^\s{12}(\w\d{5})/) {
                        push @{ $rh_rec->{'reaction'} }, $1;
                    }
                    else {
                        ### Current entry: $rh_rec->{'id'}
                        ### Unrecognized REACTION: $row                        
                    }
                }
                case 'COMPOUND' {
                    if ($row =~ /^\s{12}(\w\d{5})/) {
                        push @{ $rh_rec->{'compound'} }, $1;
                    }
                    else {
                        ### Current entry: $rh_rec->{'id'}
                        ### Unrecognized COMPOUND: $row
                    }
                }
                case 'REFERENCE' {
                    # Do nothing
                }
                case 'REL_PATHWAY' {
                    if ($row =~ /\s{12}(\w+\d+)\s/) {
                        push @{ $rh_rec->{'rel_pathway'} }, $1;
                    }
                }
                else {
                    ### Current entry: $rh_rec->{'id'}
                    ### Current section: $cur_section
                    ### Unrecognized row: $row
                }
            }
        }

        else {    # Output unparsed row
            switch ($cur_section) {
                case 'DESCRIPTION' {
                    trim($row);
                    
                    $rh_rec->{'definit'} .= " $row";
                }
                case 'REFERENCE' {
                    # Do nothing
                }
                else {
                    # Print unrecognized row
                    
                    ### Current entry: $rh_rec->{'id'}
                    ### Unrecognized row:  $row
                }
            }

        }
    }
    
    return $rh_rec; 
    
}

=begin _parse_gene
    Name:   _parse_gene
    Return: A reference to a hash
    -----------------------------------
        {
            'name' => $name,
            'alt_name' => [
                alt_name,
                ...
            ],
            'ko' => $ko,
            'ec' => [
                ec,
                ...
            ],
        }
    -----------------------------------
=cut

sub _parse_gene {
    my $str = shift;
    
    my ($name_str, $ko_str, $ec_str);
    
    if ($str =~ /(.+?)\[/) { # '418071  POLR3B [KO:K03021] [EC:2.7.7.6]'
        $name_str = $1;
        
        $ko_str = $1 if ($str =~ /\[KO:(.+?)\]/);
        
        $ec_str = $1 if ($str =~ /\[EC:(.+?)\]/);
    }
    else {
        $name_str = $str;
    }
    
    trim($name_str);

    my $rh_gene;
    
    # $rh_gene->{'ko'} = $ko;
    
    # Parse $name_str

    # '771315  CSF2RB' or '396398  IFNA3, IFN-alpha, IFN-gamma, IFNA, IFNA1, IFNA2, IFNA6'
    if ($name_str =~ /(\S+)\s+(.+?)$/) {
        $rh_gene->{'entry'} = $1;
        
        my $names = $2;
        
        my @names = split(/,\s+/, $names);
        
        $rh_gene->{'name'} = \@names;
    }
    elsif ($name_str =~ /\S+/) {
        $rh_gene->{'entry'} = $name_str;
    }
    else {
        ### Unrecognized Gene name
    }
    
    # parse $ec for multiple EC entries
    if (defined $ec_str) {
        my @ecs = split(/\s/, $ec_str);
    
        $rh_gene->{'ec'} = \@ecs;
    }
    
    # Parse KO for multiple KO entris for a gene
    if (defined $ko_str) {
        my @kos = split(/\s/, $ko_str);
        
        $rh_gene->{'ko'} = \@kos;
    }
    
    return $rh_gene;
}

1;
