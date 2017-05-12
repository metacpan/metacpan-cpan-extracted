=head1 NAME

    Bio::KEGGI::ko

=head1 DESCRIPTION

    Parse KEGG ko file (ftp://ftp.genome.jp/pub/kegg/genes/ko).
    
=head1 METHODS

=head2 next_rec

    Name:   next_rec
    Desc:   Get next KEGG record
    Usage:  $o_keggi->next_rec()
    Args:   none
    Return: A Bio::KEGG::ko object
    
=head1 VERSION

    v0.1.5
    
=head1 AUTHOR
    
    Haizhou Liu (zeroliu-at-gmail-dot-com)
    
=cut

=begin NOTE

    Retruned data structure:
    
    ----------------------------------------------------------------------------
    
    $rh_rec = {
        'id'      => $id,
        'name'    => $name,
        'definit' => $definition,
        'ec'      => [ $ec, ... ],
        'pathway' => [ $pathway_id, ... ],
        'module'  => [ $module_id, ... ],
        'class'   => [ $class, ... ],
        'dblink'  => [
            {
                'db'   => $db,
                'link' => [ $link_id, ... ],
            },
            ...
        ],
        'gene'    => [
            {
                'org'  => $org,
                'org_gene' => [
                    {
                        entry => $entry,
                        name  => $name,
                    },
                    ...
                ],
                ...
            },
            ...
        ],
        'pmid'    => [ $pmid, ... ],
    }
    
    ----------------------------------------------------------------------------

=cut

package Bio::KEGGI::ko;

use strict;
use warnings;

use Switch;
use Text::Trim;

use Bio::KEGG::ko;

# use Smart::Comments;

our $VERSION = 'v0.1.5';

use base qw(Bio::KEGGI);

=begin next_rec
    Name:   next_rec
    Desc:   Get next KEGG record
    Usage:  $o_keggi->next_rec()
    Args:   none
    Return: A KEGG object
=cut

sub next_rec {
    my $self = shift;
    
    my $ra_rec = _get_next_rec($self->{'_FH'});
    my $rh_rec = _parse_ko_rec($ra_rec);
    
    bless($rh_rec, "Bio::KEGG::ko") if (defined $rh_rec);
    
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

=begin _parse_ko_rec
    Name:   _parse_ko_rec
    Desc:   Parse KEGG ko record
    Usage:  _parse_ko_rec($ra_rec)
    Args:   A reference to an array of Bio::KEGGI::ko record
    Return: A reference to a hash of Bio::KEGG record
=cut

sub _parse_ko_rec {
    my $ra_rec = shift;
    
    # KO record: $ra_rec
    
    my $rh_rec;
    my $cur_section = '';
    my $db_tag = '';
    my $gene_org_tag = '';
    
    for my $row ( @{$ra_rec} ) {
        next if ( $row =~ /^\s*$/);
        next if ( $row =~ /\/\/\// );
        
        if ($row =~ /^ENTRY\s+(.+?)\s+/) {
            $rh_rec->{'id'} = $1;
        }
        elsif ($row =~ /^NAME/ ) {
            # 'NAME        E1.1.1.3'
            # 'NAME        E1.2.1.2B2'
            # 'NAME        E1.1.-.-'
            if ($row =~ /^NAME\s{8}E[\w\.\-]+$/) {
                next;
                # $rh_rec->{'ec'} = $1;
            }
            # 'NAME        E1.1.1.1, adh'
            # 'NAME        E1.2.99.2A, cdhA'
            elsif ($row =~ /^NAME\s{8}E[\w\.\-]+,\s(.+?)$/) {
                # $rh_rec->{'ec'} = $1;
                $rh_rec->{'name'} = $1;
            }
            # 'NAME        BDH, butB'
            elsif ($row =~ /^NAME\s{8}(.+?)$/) {
                $rh_rec->{'name'} = $1;
            }
            else {  # Unrecognized NAME
                # Do nothing
                ### Unrecognized NAME: $row
            }
        }
        elsif ($row =~ /^DEFINITION\s{2}(.+)?/) { # There might be multi rows for DEFINITION
            $cur_section = 'DEFINITION';
            
            my $defin = $1;
            
            $rh_rec->{'definit'} = $defin;
            
            # if it ended with a ']'
            if ($defin =~ /]$/) {
                if (my $ra_ec = _get_definition_ec($defin) ) {
                    $rh_rec->{'ec'} = $ra_ec;
                }
            }
        }
        elsif ($row =~ /^PATHWAY\s{5}(\w+\d{5})\s/) {
            $cur_section = 'PATHWAY';
            
            push @{ $rh_rec->{'pathway'} }, $1;
        }
        elsif ($row =~ /^MODULE\s{6}(M\d{5})/) {
            $cur_section = 'MODULE';
            
            push @{ $rh_rec->{'module'} }, $1;
        }
        elsif ($row =~ /^DISEASE\s{5}(H\d{5})/) {
            $cur_section = 'DISEASE';
            
            push @{ $rh_rec->{'disease'} }, $1;
        }
        elsif ($row =~ /^CLASS\s{7}(.+)$/) {
            $cur_section = 'CLASS';
            
            push @{ $rh_rec->{'class'} }, $1;
        }
        elsif ($row =~ /DBLINKS\s{5}(\S+?):\s(.+)?/) {
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
        elsif ($row =~ /^GENES\s{7}(\S+):\s(.+?)$/) {
            $cur_section = 'GENES';
            $gene_org_tag = lc($1); # convert upper-cased organism name to lower-case
            
            my $genes = $2;
            # my @genes = split(/\s/, $genes);
            my $ra_org_gene = _parse_gene($genes);
            
            my $rh_gene = {
                'org'      => $gene_org_tag,
                'org_gene' => $ra_org_gene,
            };
            
            push @{ $rh_rec->{'gene'} }, $rh_gene;
        }
        elsif ($row =~ /^REFERENCE/) {
            if ($row =~ /^REFERENCE\s+PMID:(\d+)/) {
                $cur_section = 'REFERENCE';
                push @{ $rh_rec->{'pmid'} }, $1;
            }
            elsif ($row =~ /^REFERENCE/) {
                # Do nothing
            }
            else {
                print '-'x50, "\n", "Unrecognized:\n", $row, "\n", '-'x50, "\n";
            }
        }
        elsif ($row =~ /^\s{2}(?:AUTHORS|TITLE|JOURNAL)/) { # REFERENCE section
            # Do nothing
        }
        elsif ($row =~ /^\s{12}\S/) { # Continuous text for existing section
            switch ($cur_section) {
                case 'DEFINITION' {
                    trim($row);
                    
                    $rh_rec->{'definit'} .= " $row";
                    
                    if ($rh_rec->{'definit'} =~ /\]$/) {    # possible EC definition
                        if (my $ra_ec = _get_definition_ec( $rh_rec->{'definit'} ) ) {
                            $rh_rec->{'ec'} = $ra_ec;
                        }
                    }
                }
                case 'PATHWAY' {
                    # trim($row);
                    
                    if ($row =~ /ko(\d{5})/) {
                        push @{ $rh_rec->{'pathway'} }, $1;
                    }
                    else {
                        ### Unrecognized PATHWAY: $row
                    }
                }
                case 'MODULE' {
                    if ($row =~ /(M\d{5})/) {
                        push @{ $rh_rec->{'module'} }, $1;
                    }
                    else {
                        ### Unrecognized MODULE: $row
                    }
                }
                case 'DISEASE' {
                    if ($row =~ /(\H\d{5})/) {
                        push @{ $rh_rec->{'disease'} }, $1;
                    }
                    else {
                        ### Unrecognized MODULE: $row
                    }
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
                case 'DBLINKS' {
                    if ($row =~ /(\S+):\s(.+?)$/) {
                        $db_tag = $1;
                        my $dblinks = $2;
                        my @dblinks = split(/\s/, $dblinks);
                        
                        my $rh_dblink = {
                            'db'   => $db_tag,
                            'link' => \@dblinks,
                        };
                        
                        push @{ $rh_rec->{'dblink'} }, $rh_dblink;
                    }
                    else {
                        ### Unrecognized DBLINKS: $row
                    }
                }
                # =>'            OSA: 4330090(Os02g0637700) 4348152(Os10g0159800)'
                case 'GENES' {
                    if ($row =~ /([A-Z]+):\s(.+?)$/) {
                        $gene_org_tag = lc($1);
                        
                        my $genes = $2;
=begin
                        my @genes = split(/\s/, $genes);
                        
                        my $rh_gene = {
                            'org'  => $gene_org_tag,
                            'gene' => \@genes,
                        };
=end
=cut

                        my $ra_org_gene = _parse_gene($genes);
                        
                        my $rh_gene = {
                            'org'      => $gene_org_tag,
                            'org_gene' => $ra_org_gene,
                        };
                        
                        push @{ $rh_rec->{'gene'} }, $rh_gene;
                    }
                    else {
                        ### Unrecognized GENES: $row
                    }
                }
                case 'REFERENCE' {
                    # Do nothing
                }
                else {
                    ### Unrecognized row: $row
                }
            }
        }
        elsif ($row =~ /^\s{16}/) {
            switch ($cur_section) {
                case 'PATHWAY' {
                    # Do nothing
                }
                case 'DISEASE' {
                    # Do nothing
                }
                case 'DBLINKS' {
                    trim($row);
                    my @dblinks = split(/\s/, $row);
                    
                    my $rh_dblink = pop @{ $rh_rec->{'dblink'} };
                    
                    push @{ $rh_dblink->{'link'} }, @dblinks;
                    
                    push @{ $rh_rec->{'dblink'} }, $rh_dblink;
                }
                #   '             OSA: 4330090(Os02g0637700) 4348152(Os10g0159800)'
                # =>'                   4350053(Os11g0210300) 4350054(Os11g0210500)'
                case 'GENES' {
                    trim($row);
                    
                    # my @genes = split(/\s/, $row);
                    my $ra_org_gene = _parse_gene($row);
                    
                    my $rh_gene = pop @{ $rh_rec->{'gene'} };
                    
                    for my $rh_org_gene ( @{ $ra_org_gene } ) {
                        push @{ $rh_gene->{'org_gene'} }, $rh_org_gene;
                    }
                    
                    push @{ $rh_rec->{'gene'} }, $rh_gene;
                }
                case 'MODULE' {
                    # Do nothing
                }
                case 'REFERENCE' {
                    # Do nothing
                }
                else {
                    ### Unrecognized row: $row
                }
            }
        }
        else {    # Unparsed row
            # Do nothing
            
            ### Current entry: $rh_rec->{'id'}
            ### Unrecognized row:  $row
        }
    }
    
    return $rh_rec;
}

=begin _get_definition_ec
    Name:   _get_definition_ec
    Desc:   Parse EC from DEFINITION
    Usage:  _get_definition_ec($def)
    Args:   A string of DEFINITION
    Return: A string
=cut

sub _get_definition_ec {
    my $str = shift;
    
    if ($str =~ /\[EC:(.+?)\]/) {
        my $ecs = $1;
        my @ecs = split(/\s/, $ecs);
        
        return \@ecs;
    }
    else {  # without EC information
        return;
    }
}

=begin _parse_gene
    Name:   _parse_gene
    Desc:   Parse gene entries and names for an organism
            This subroutine presumes there is only ONE name for a gene entry.
            Such as: 'AT1G32780' 'AT1G77120(ADH1)'.
            If there was multiple names for a gene entry, it will print
            DEBUG messages.
            
            Return:
            ----------------------------------------------------------
            $ra_org_genes = [
                {
                    'entry' => $entry,
                    'name'  => $name,
                },
                ...
            ]
            ----------------------------------------------------------
    Usage:  _parse_gene($genes)
    Args:   A string of genes
    Return: A reference of hash
=cut

sub _parse_gene {
    my ($genes) = @_;
    
    my @genes = split(/\s/, $genes);
    
    my @org_genes;
    
    for my $gene (@genes) {
        my $rh_gene = {};   # Init hash
        
        if ($gene =~ /(\S+)\((\S+)\)/) {    # 'AT1G77120(ADH1)'
            $rh_gene->{'entry'} = $1;
            $rh_gene->{'name'}  = $2;
            
            # DEBUG
            if ($rh_gene->{'name'} =~ /\s/) {
                ### Multiple names for a gene:
                ### ENTRY: $rh_gene->{'entry'}
                ### NAMES: $rh_gene->{'name'}
            }
        }
        else {  # 'AT1G32780'
            $rh_gene->{'entry'} = $gene;
        }
        
        push @org_genes, $rh_gene;
    }
    
    return \@org_genes;
}

1;
