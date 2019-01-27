package App::Fasops::Command::vars;
use strict;
use warnings;
use autodie;

use Excel::Writer::XLSX;

use App::Fasops -command;
use App::Fasops::Common;

sub abstract {
    return 'list substitutions';
}

sub opt_spec {
    return (
        [ "outfile|o=s",    "Output filename. [stdout] for screen" ],
        [ "annotation|a=s", "YAML file for cds/repeat" ],
        [ "length|l=i", "the threshold of alignment length", { default => 1 } ],
        [ 'outgroup',   'alignments have an outgroup', ],
        [ 'nosingle',   'omit singleton', ],
        [ 'nocomplex',  'omit complex', ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops vars [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infiles> are paths to axt files, .fas.gz is supported
* infile == stdin means reading from STDIN

MARKDOWN

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

    if ( exists $opt->{annotation} ) {
        if ( !Path::Tiny::path( $opt->{annotation} )->is_file ) {
            $self->usage_error("The annotation file [$opt->{annotation}] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".tsv";
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

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    my $cds_set_of    = {};
    my $repeat_set_of = {};
    if ( $opt->{annotation} ) {
        my $anno = YAML::Syck::LoadFile( $opt->{annotation} );
        Carp::confess "Invalid annotation YAML. Need cds.\n"    unless defined $anno->{cds};
        Carp::confess "Invalid annotation YAML. Need repeat.\n" unless defined $anno->{repeat};
        $cds_set_of    = App::RL::Common::runlist2set( $anno->{cds} );
        $repeat_set_of = App::RL::Common::runlist2set( $anno->{repeat} );
    }

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

            # Use $target_seq_set to transform align positions to chr positions
            my $align_set        = AlignDB::IntSpan->new()->add_pair( 1, length $seq_refs->[0] );
            my $target_indel_set = App::Fasops::Common::indel_intspan( $seq_refs->[0] );
            my $target_seq_set   = $align_set->diff($target_indel_set);

            # Write lines
            my $vars = get_vars( $seq_refs, $opt );

            for my $pos ( sort { $a <=> $b } keys %{$vars} ) {
                my $var = $vars->{$pos};

                my $chr_name    = $info_of->{ $full_names[0] }{chr};
                my $snp_chr_pos = App::Fasops::Common::align_to_chr(
                    $target_seq_set, $var->{snp_pos},
                    $info_of->{ $full_names[0] }{start},
                    $info_of->{ $full_names[0] }{strand},
                );

                my $snp_coding  = "";
                my $snp_repeats = "";
                if ( $opt->{annotation} ) {
                    if ( defined $cds_set_of->{$chr_name} ) {
                        $snp_coding = $cds_set_of->{$chr_name}->contains($snp_chr_pos);
                    }
                    if ( defined $repeat_set_of->{$chr_name} ) {
                        $snp_repeats = $repeat_set_of->{$chr_name}->contains($snp_chr_pos);
                    }
                }

                print {$out_fh} join "\t",
                    $full_names[0],
                    $chr_name,
                    $var->{snp_pos},
                    $snp_chr_pos,
                    "$chr_name:$snp_chr_pos",
                    $var->{snp_target_base},
                    $var->{snp_query_base},
                    $var->{snp_all_bases},
                    $var->{snp_mutant_to},
                    $var->{snp_freq},
                    $var->{snp_occured},
                    $snp_coding,
                    $snp_repeats;
                print {$out_fh} "\n";
            }
        }
        else {
            $content .= $line;
        }
    }

    $in_fh->close;
    $out_fh->close;

    return;
}

# store all variations
sub get_vars {
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

    my %variations;

    my $snp_sites = App::Fasops::Common::get_snps($seq_refs);
    if ( $opt->{outgroup} ) {
        App::Fasops::Common::polarize_snp( $snp_sites, $out_seq );
    }

    for my $site ( @{$snp_sites} ) {
        if ( $opt->{nocomplex} and $site->{snp_freq} == -1 ) {
            next;
        }
        if ( $opt->{nosingle} and $site->{snp_freq} <= 1 ) {
            next;
        }

        $variations{ $site->{snp_pos} } = $site;
    }

    return \%variations;
}

1;
