package App::Anchr::Command::cover;
use strict;
use warnings;
use autodie;

use App::Anchr - command;
use App::Anchr::Common;

use constant abstract => "trusted regions in the first file covered by the second";

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen", ],
        [ "range|r=s",    "ranges of first sequences",    { required => 1 }, ],
        [ 'coverage|c=i', 'minimal coverage',             { default  => 2 }, ],
        [ 'max|m=i',      'maximal coverage',             { default  => 200 }, ],
        [ "len|l=i",      "minimal length of overlaps",   { default  => 1000 }, ],
        [ "idt|i=f",      "minimal identity of overlaps", { default  => 0.85 }, ],
        [ "verbose|v",    "verbose mode", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr cover [options] <.ovlp.tsv>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\tAll operations are running in a tempdir and no intermediate files are kept.\n";
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
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".cover.json";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # make paths absolute before we chdir
    my $infile = Path::Tiny::path( $args->[0] )->absolute->stringify;

    if ( lc $opt->{outfile} ne "stdout" ) {
        $opt->{outfile} = Path::Tiny::path( $opt->{outfile} )->absolute->stringify;
    }

    # record cwd, we'll return there
    my $cwd     = Path::Tiny->cwd;
    my $tempdir = Path::Tiny->tempdir("anchr_cover_XXXXXXXX");
    chdir $tempdir;

    my $basename = $tempdir->basename();
    $basename =~ s/\W+/_/g;

    #@type AlignDB::IntSpan
    my $first_range = AlignDB::IntSpan->new->add_runlist( $opt->{range} );

    {
        # paf to meancov
        my $cmd;
        $cmd .= "jrange covered";
        $cmd .= " $infile";
        $cmd .= " --coverage $opt->{max}";
        $cmd .= " --meancov";
        $cmd .= " --len $opt->{len} --idt $opt->{idt}";
        $cmd .= " -o $basename.meancov.txt";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("$basename.meancov.txt")->is_file ) {
            Carp::croak "Failed: create $basename.meancov.txt\n";
        }
    }

    # anchor_id => mean coverage
    my $coverage_of = {};
    my $len_of      = {};
    my $stat        = Statistics::Descriptive::Full->new();
    for my $line ( App::RL::Common::read_lines("$basename.meancov.txt") ) {
        my @parts = split "\t", $line;
        next unless @parts == 3;

        my $seq_id = $parts[0];
        next unless $first_range->contains($seq_id);

        $len_of->{$seq_id} = $parts[1];

        $coverage_of->{$seq_id} = $parts[2];
        $stat->add_data( $parts[2] );
    }

    my $meta_of = { TRUSTED => $first_range->copy, };
    {
        my $median       = $stat->median();
        my @abs_res      = map { abs( $median - $_ ) } $stat->get_data();
        my $abs_res_stat = Statistics::Descriptive::Full->new();
        $abs_res_stat->add_data(@abs_res);
        my $MAD = $abs_res_stat->median();

        # the scale factor
        my $k = 3;

        my $lower_limit = ( $median - $k * $MAD ) / 2;
        my $upper_limit = ( $median + $k * $MAD ) * 1.5;

        $meta_of->{NON_OVERLAPPED} = AlignDB::IntSpan->new;
        $meta_of->{REPEAT_LIKE}    = AlignDB::IntSpan->new;
        for my $key ( keys %{$coverage_of} ) {
            if ( $coverage_of->{$key} < $lower_limit ) {
                $meta_of->{NON_OVERLAPPED}->add($key);
            }
            if ( $coverage_of->{$key} > $upper_limit ) {
                $meta_of->{REPEAT_LIKE}->add($key);
            }
        }

        $meta_of->{COV_MEDIAN}      = $median;
        $meta_of->{COV_MAD}         = $MAD;
        $meta_of->{COV_LOWER_LIMIT} = $lower_limit;
        $meta_of->{COV_UPPER_LIMIT} = $upper_limit;

        $meta_of->{TRUSTED}->subtract( $meta_of->{NON_OVERLAPPED} );
        $meta_of->{TRUSTED}->subtract( $meta_of->{REPEAT_LIKE} );
    }

    {
        # paf to covered
        my $cmd;
        $cmd .= "jrange covered";
        $cmd .= " $infile";
        $cmd .= " --coverage $opt->{coverage}";
        $cmd .= " --len $opt->{len} --idt $opt->{idt}";
        $cmd .= " -o $basename.covered.txt";
        App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );

        if ( !$tempdir->child("$basename.covered.txt")->is_file ) {
            Carp::croak "Failed: create $basename.covered.txt\n";
        }
    }

    # anchor_id => covered ragion
    my $covered_of = {};
    $meta_of->{PARTIAL_COVERED} = AlignDB::IntSpan->new;
    for my $line ( App::RL::Common::read_lines("$basename.covered.txt") ) {
        my @parts = split ":", $line;
        next unless @parts == 2;

        my $seq_id = $parts[0];
        next unless $first_range->contains($seq_id);

        my $covered = AlignDB::IntSpan->new()->add_runlist( $parts[1] );

        if ( $covered->size < $len_of->{$seq_id} ) {
            $meta_of->{TRUSTED}->remove($seq_id);
            $meta_of->{PARTIAL_COVERED}->add($seq_id);
            $covered_of->{$seq_id} = $covered->runlist;
        }
    }

    #    {
    #        # Create covered.fasta
    #        $tempdir->child("covered.fasta")->remove;
    #        for my $serial ( sort { $a <=> $b } keys %{$covered_of} ) {
    #            if ( $trusted->contains($serial) ) {
    #                my $cmd;
    #                $cmd .= "DBshow -U $basename $serial";
    #                $cmd .= " | faops replace -l 0 stdin first.replace.tsv stdout";
    #                $cmd .= " >> covered.fasta";
    #                App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    #            }
    #            else {
    #
    #                #@type AlignDB::IntSpan
    #                my $region = $covered_of->{$serial}{ $opt->{coverage} };
    #
    #                for my $set ( $region->sets ) {
    #                    next if $set->size < $opt->{len};
    #
    #                    my $cmd;
    #                    $cmd .= "DBshow -U $basename $serial";
    #                    $cmd .= " | faops replace -l 0 stdin first.replace.tsv stdout";
    #                    $cmd .= " | faops frag -l 0 stdin @{[$set->min]} @{[$set->max]} stdout";
    #                    $cmd .= " >> covered.fasta";
    #                    App::Anchr::Common::exec_cmd( $cmd, { verbose => $opt->{verbose}, } );
    #                }
    #            }
    #        }
    #
    #        if ( !$tempdir->child("covered.fasta")->is_file ) {
    #            Carp::croak "Failed: create covered.fasta\n";
    #        }
    #    }

    {
        $meta_of->{TRUSTED}         = $meta_of->{TRUSTED}->runlist;
        $meta_of->{NON_OVERLAPPED}  = $meta_of->{NON_OVERLAPPED}->runlist;
        $meta_of->{REPEAT_LIKE}     = $meta_of->{REPEAT_LIKE}->runlist;
        $meta_of->{PARTIAL_COVERED} = $meta_of->{PARTIAL_COVERED}->runlist;
        $meta_of->{TOTAL_RANGE}     = $first_range->runlist;

        $tempdir->child("meta.cover.json")
            ->spew( JSON::to_json( $meta_of, { pretty => 1, canonical => 1, } ) );
        $tempdir->child("meta.cover.json")->copy( $opt->{outfile} );

        $tempdir->child("partial.txt")
            ->spew( map { sprintf "%s:%s\n", $_, $covered_of->{$_} } keys %{$covered_of} );
        $tempdir->child("partial.txt")->copy("$opt->{outfile}.partial.txt");

        YAML::Syck::DumpFile( "coverage.yml", $coverage_of );
        $tempdir->child("coverage.yml")->copy("$opt->{outfile}.coverage.yml");
    }

    chdir $cwd;
}

1;
