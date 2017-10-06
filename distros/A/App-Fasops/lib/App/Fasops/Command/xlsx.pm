package App::Fasops::Command::xlsx;
use strict;
use warnings;
use autodie;

use Excel::Writer::XLSX;

use App::Fasops -command;
use App::Fasops::Common;

use constant abstract => 'paint substitutions and indels to an excel file';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen" ],
        [ "length|l=i", "the threshold of alignment length", { default => 1 } ],
        [ 'wrap=i',     'wrap length',                       { default => 50 }, ],
        [ 'spacing=i',  'wrapped line spacing',              { default => 1 }, ],
        [ 'colors=i',   'number of colors',                  { default => 15 }, ],
        [ 'section=i', 'start section', { default => 1, hidden => 1 }, ],
        [ 'outgroup',  'alignments have an outgroup', ],
        [ 'noindel',   'omit indels', ],
        [ 'nosingle',  'omit singleton SNPs and indels', ],
        [ 'nocomplex', 'omit complex SNPs and indels', ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops xlsx [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\t<infile> are blocked fasta files, .fas.gz is supported.\n";
    $desc .= "\tinfile == stdin means reading from STDIN\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 1 ) {
        my $message = "This command need one input file.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".xlsx";
    }

    if ( $opt->{colors} ) {
        $opt->{colors} = List::Util::min( $opt->{colors}, 15 );
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #@type IO::Handle
    my $in_fh;
    if ( lc $args->[0] eq "stdin" ) {
        $in_fh = *STDIN{IO};
    }
    else {
        $in_fh = IO::Zlib->new( $args->[0], "rb" );
    }

    # Create workbook and worksheet objects
    #@type Excel::Writer::XLSX
    my $workbook = Excel::Writer::XLSX->new( $opt->{outfile} );

    #@type Excel::Writer::XLSX::Worksheet
    my $worksheet = $workbook->add_worksheet;

    my $format_of       = create_formats($workbook);
    my $max_name_length = 1;

    my $content = '';    # content of one block
    while (1) {
        last if $in_fh->eof and $content eq '';
        my $line = '';
        if ( !$in_fh->eof ) {
            $line = $in_fh->getline;
        }
        next if substr( $line, 0, 1 ) eq "#";

        if ( ( $line eq '' or $line =~ /^\s+$/ ) and $content ne '' ) {
            my $info_of = App::Fasops::Common::parse_block( $content, 1 );
            $content = '';

            my @full_names;
            my $seq_refs = [];

            for my $key ( keys %{$info_of} ) {
                push @full_names, $key;
                push @{$seq_refs}, $info_of->{$key}{seq};
            }

            if ( $opt->{length} ) {
                next if length $info_of->{ $full_names[0] }{seq} < $opt->{length};
            }

            print "Section [$opt->{section}]\n";
            $max_name_length = List::Util::max( $max_name_length, map {length} @full_names );

            # including indels and snps
            my $vars = get_variations( $seq_refs, $opt );
            $opt->{section} = paint_variations( $worksheet, $format_of, $opt, $vars, \@full_names );

        }
        else {
            $content .= $line;
        }
    }

    $in_fh->close;

    # format column
    $worksheet->set_column( 0, 0, $max_name_length + 1 );
    $worksheet->set_column( 1, $opt->{wrap} + 3, 1.6 );

    return;
}

# Excel formats
sub create_formats {

    #@type Excel::Writer::XLSX
    my $workbook = shift;

    my $format_of = {};

    # species name
    $format_of->{name} = $workbook->add_format(
        font => 'Courier New',
        size => 10,
    );

    # variation position
    $format_of->{pos} = $workbook->add_format(
        font     => 'Courier New',
        size     => 8,
        align    => 'center',
        valign   => 'vcenter',
        rotation => 90,
    );

    $format_of->{snp}   = {};
    $format_of->{indel} = {};

    # background
    my $bg_of = {};

    # 15
    my @colors = (
        22,    # Gray-25%, silver
        43,    # Light Yellow       0b001
        42,    # Light Green        0b010
        27,    # Lite Turquoise
        44,    # Pale Blue          0b100
        46,    # Lavender
        47,    # Tan
        24,    # Periwinkle
        49,    # Aqua
        51,    # Gold
        45,    # Rose
        52,    # Light Orange
        26,    # Ivory
        29,    # Coral
        31,    # Ice Blue

        #        30,    # Ocean Blue
        #        41,    # Light Turquoise, again
        #        48,    # Light Blue
        #        50,    # Lime
        #        54,    # Blue-Gray
        #        62,    # Indigo
    );

    for my $i ( 0 .. $#colors ) {
        $bg_of->{$i}{bg_color} = $colors[$i];

    }
    $bg_of->{unknown}{bg_color} = 9;    # White

    # snp base
    my $snp_fg_of = {
        'A' => { color => 58, },        # Dark Green
        'C' => { color => 18, },        # Dark Blue
        'G' => { color => 28, },        # Dark Purple
        'T' => { color => 16, },        # Dark Red
        'N' => { color => 8, },         # Black
        '-' => { color => 8, },         # Black
    };

    for my $fg ( keys %{$snp_fg_of} ) {
        for my $bg ( keys %{$bg_of} ) {
            $format_of->{snp}{"$fg$bg"} = $workbook->add_format(
                font   => 'Courier New',
                size   => 10,
                align  => 'center',
                valign => 'vcenter',
                %{ $snp_fg_of->{$fg} },
                %{ $bg_of->{$bg} },
            );
        }
    }
    $format_of->{snp}{'-'} = $workbook->add_format(
        font   => 'Courier New',
        size   => 10,
        align  => 'center',
        valign => 'vcenter',
    );

    for my $bg ( keys %{$bg_of} ) {
        $format_of->{indel}->{$bg} = $workbook->add_format(
            font   => 'Courier New',
            size   => 10,
            bold   => 1,
            align  => 'center',
            valign => 'vcenter',
            %{ $bg_of->{$bg} },
        );
    }

    return $format_of;
}

# store all variations
sub get_variations {
    my $seq_refs = shift;
    my $opt      = shift;

    # outgroup
    my $out_seq;
    if ( $opt->{outgroup} ) {
        $out_seq = pop @{$seq_refs};
    }

    my $seq_count = scalar @{$seq_refs};
    if ( $seq_count < 2 ) {
        Carp::confess "Too few sequences [$seq_count]\n";
    }

    my $indel_sites = App::Fasops::Common::get_indels($seq_refs);
    if ( $opt->{outgroup} ) {
        App::Fasops::Common::polarize_indel( $indel_sites, $out_seq );
    }

    my $snp_sites = App::Fasops::Common::get_snps($seq_refs);
    if ( $opt->{outgroup} ) {
        App::Fasops::Common::polarize_snp( $snp_sites, $out_seq );
    }

    my %variations;
    for my $site ( @{$indel_sites} ) {
        if ( $opt->{nocomplex} and $site->{indel_freq} == -1 ) {
            next;
        }

        if ( $opt->{nosingle} and $site->{indel_freq} <= 1 ) {
            next;
        }

        if ( $opt->{noindel} ) {
            next;
        }

        $site->{var_type} = 'indel';
        $variations{ $site->{indel_start} } = $site;
    }

    for my $site ( @{$snp_sites} ) {
        if ( $opt->{nocomplex} and $site->{snp_freq} == -1 ) {
            next;
        }

        if ( $opt->{nosingle} and $site->{snp_freq} <= 1 ) {
            next;
        }

        $site->{var_type} = 'snp';
        $variations{ $site->{snp_pos} } = $site;
    }

    return \%variations;
}

# write execel
sub paint_variations {

    #@type Excel::Writer::XLSX::Worksheet
    my $sheet     = shift;
    my $format_of = shift;
    my $opt       = shift;
    my $vars      = shift;
    my $name_refs = shift;

    my $section_start = $opt->{section};
    my $color_loop    = $opt->{colors};

    my %variations     = %{$vars};
    my $section_cur    = $section_start;
    my $col_cursor     = 1;
    my $section_height = ( scalar( @{$name_refs} ) + 1 ) + $opt->{spacing};
    my $seq_count      = scalar @{$name_refs};
    $seq_count-- if $opt->{outgroup};

    for my $pos ( sort { $a <=> $b } keys %variations ) {
        my $var = $variations{$pos};
        my $pos_row = $section_height * ( $section_cur - 1 );

        # write SNPs
        if ( $var->{var_type} eq 'snp' ) {

            # write position
            $sheet->write( $pos_row, $col_cursor, $var->{snp_pos}, $format_of->{pos} );

            for my $i ( 1 .. $seq_count ) {
                my $base = substr $var->{snp_all_bases}, $i - 1, 1;

                my $occ
                    = $var->{snp_occured} eq "unknown"
                    ? 0
                    : substr( $var->{snp_occured}, $i - 1, 1 );

                if ( $occ eq "1" ) {
                    my $bg_idx     = oct( '0b' . $var->{snp_occured} ) % $color_loop;
                    my $base_color = $base . $bg_idx;
                    $sheet->write( $pos_row + $i,
                        $col_cursor, $base, $format_of->{snp}{$base_color} );
                }
                else {
                    my $base_color = $base . "unknown";
                    $sheet->write( $pos_row + $i,
                        $col_cursor, $base, $format_of->{snp}{$base_color} );
                }
            }

            # outgroup bases with no background colors
            if ( $opt->{outgroup} ) {
                my $base_color = $var->{snp_outgroup_base} . "unknown";
                $sheet->write(
                    $pos_row + $seq_count + 1,
                    $col_cursor,
                    $var->{snp_outgroup_base},
                    $format_of->{snp}{$base_color}
                );
            }

            # increase column cursor
            $col_cursor++;
        }

        # write indels
        if ( $var->{var_type} eq 'indel' ) {

            # how many column does this indel take up
            my $col_taken = List::Util::min( $var->{indel_length}, 3 );

            # if exceed the wrap limit, start a new section
            if ( $col_cursor + $col_taken > $opt->{wrap} ) {
                $col_cursor = 1;
                $section_cur++;
                $pos_row = $section_height * ( $section_cur - 1 );
            }

            my $indel_string = "$var->{indel_type}$var->{indel_length}";

            my $bg_idx = 'unknown';
            if ( $var->{indel_occured} ne 'unknown' ) {
                $bg_idx = oct( '0b' . $var->{indel_occured} ) % $color_loop;
            }

            for my $i ( 1 .. $seq_count ) {
                my $flag = 0;
                if ( $var->{indel_occured} eq "unknown" ) {
                    $flag = 1;
                }
                else {
                    my $occ = substr $var->{indel_occured}, $i - 1, 1;
                    if ( $occ eq '1' ) {
                        $flag = 1;
                    }
                }

                if ($flag) {
                    if ( $col_taken == 1 ) {

                        # write position
                        $sheet->write( $pos_row, $col_cursor, $var->{indel_start},
                            $format_of->{pos} );

                        # write in indel occured lineage
                        $sheet->write( $pos_row + $i,
                            $col_cursor, $indel_string, $format_of->{indel}{$bg_idx} );
                    }
                    elsif ( $col_taken == 2 ) {

                        # write indel_start position
                        $sheet->write( $pos_row, $col_cursor, $var->{indel_start},
                            $format_of->{pos} );

                        # write indel_end position
                        $sheet->write( $pos_row, $col_cursor + 1,
                            $var->{indel_end}, $format_of->{pos} );

                        # merge two indel position
                        $sheet->merge_range(
                            $pos_row + $i,
                            $col_cursor,
                            $pos_row + $i,
                            $col_cursor + 1,
                            $indel_string, $format_of->{indel}{$bg_idx},
                        );
                    }
                    else {

                        # write indel_start position
                        $sheet->write( $pos_row, $col_cursor, $var->{indel_start},
                            $format_of->{pos} );

                        # write middle sign
                        $sheet->write( $pos_row, $col_cursor + 1, '|', $format_of->{pos} );

                        # write indel_end position
                        $sheet->write( $pos_row, $col_cursor + 2,
                            $var->{indel_end}, $format_of->{pos} );

                        # merge two indel position
                        $sheet->merge_range(
                            $pos_row + $i,
                            $col_cursor,
                            $pos_row + $i,
                            $col_cursor + 2,
                            $indel_string, $format_of->{indel}{$bg_idx},
                        );
                    }
                }
            }

            # increase column cursor
            $col_cursor += $col_taken;
        }

        if ( $col_cursor > $opt->{wrap} ) {
            $col_cursor = 1;
            $section_cur++;
        }
    }

    # write names
    for my $i ( $section_start .. $section_cur ) {
        my $pos_row = $section_height * ( $i - 1 );

        for my $j ( 1 .. scalar @{$name_refs} ) {
            $sheet->write( $pos_row + $j, 0, $name_refs->[ $j - 1 ], $format_of->{name} );
        }
    }

    $section_cur++;
    return $section_cur;
}

1;
