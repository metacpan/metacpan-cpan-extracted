package App::Egaz::Command::exactmatch;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

use constant abstract => 'partitions fasta files by size';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen", { default => "stdout" }, ],
        [ 'length|l=i',  'match length of mummer',               { default => 100 }, ],
        [ 'discard=i',    'discard blocks with copy number larger than this', { default => 0 }, ],
        [ 'debug',        'write a file of exactmatch.json for debugging', ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz exactmatch [options] <infile> <genome.fa>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infile> can't be stdin
* `mummer` or `sparsemem` should be in $PATH

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 2 ) {
        my $message = "This command need two input files.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Run sparsemem
    #----------------------------#
    #@type Path::Tiny
    my $mem_result = Path::Tiny->tempfile;
    App::Egaz::Common::run_sparsemem( $mem_result, $args->[0], $args->[1], $opt->{length} );

    #----------------------------#
    # Parse sparsemem
    #----------------------------#
    tie my %match_of, "Tie::IxHash";
    my $fh_mem = $mem_result->openr;
    my $cur_name;
    while ( my $line = <$fh_mem> ) {
        if ( $line =~ /^\>/ ) {
            $line =~ s/^\>\s*//;
            chomp $line;
            $cur_name = $line;
        }
        elsif ( $line =~ /^\s*[\w-]+/ ) {
            chomp $line;

            #   XII    1065146         1      6369
            # ID
            # the position in the reference sequence
            # the position in the query sequence
            # the length of the match
            my @fields = grep {/\S+/} split /\s+/, $line;

            if ( @fields != 4 ) {
                warn "    Line [$line] seems wrong.\n";
                next;
            }

            if ( !exists $match_of{$cur_name} ) {
                $match_of{$cur_name} = [];
            }
            push @{ $match_of{$cur_name} }, \@fields;
        }
        else {    # Blank line, do nothing
        }
    }
    close $fh_mem;

    #----------------------------#
    # Get exact matches
    #----------------------------#
    my $size_of = App::Egaz::Common::get_size( $args->[0]);
    tie my %locations, "Tie::IxHash";    #  genome location - simple location
    for my $seq_name ( keys %match_of ) {
        my $ori_name   = $seq_name;
        my $chr_strand = "+";
        if ( $ori_name =~ / Reverse/ ) {
            $ori_name =~ s/ Reverse//;
            $chr_strand = "-";
        }
        my $species_name = App::RL::Common::decode_header($ori_name)->{name};

        for my $f ( @{ $match_of{$seq_name} } ) {
            next unless $f->[2] == 1;
            next unless $f->[3] == $size_of->{$ori_name};

            my $header = App::RL::Common::encode_header(
                {   name   => $species_name,
                    chr    => $f->[0],
                    start  => $f->[1],
                    end    => $f->[1] + $f->[3] - 1,
                    strand => $chr_strand,
                }
            );
            if ( !exists $locations{$ori_name} ) {
                $locations{$ori_name} = {};
            }

            $locations{$ori_name}->{$header} = 1;
        }
    }

    #----------------------------#
    # Write replace tsv file
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    for my $ori_name ( keys %locations ) {
        my @matches = keys %{ $locations{$ori_name} };
        if ( $opt->{discard} and @matches > $opt->{discard} ) {
            printf STDERR "    %s\tgot %d matches, discard it\n", $ori_name, scalar(@matches);
            print {$out_fh} "$ori_name\n";
        }
        elsif ( @matches > 1 ) {
            printf STDERR "    %s\tgot %d matches\n", $ori_name, scalar(@matches);
            print {$out_fh} join( "\t", $ori_name, @matches ) . "\n";
        }
        elsif ( $ori_name ne $matches[0] ) {
            printf STDERR "    %s\tgot wrong position, %s\n", $ori_name, $matches[0];
            print {$out_fh} join( "\t", $ori_name, @matches ) . "\n";
        }
    }

    #----------------------------#
    # Dump exactmatch.json
    #----------------------------#
    # YAML::Syck can't Dump Tie::IxHash
    if ($opt->{debug}) {
        Path::Tiny::path("exactmatch.json")->spew(
            JSON::to_json(
                {   mem_result => $mem_result->slurp,
                    match_of   => \%match_of,
                    locations  => \%locations
                },
                { utf8 => 1, pretty => 1 },
            )
        );
    }
}

1;
