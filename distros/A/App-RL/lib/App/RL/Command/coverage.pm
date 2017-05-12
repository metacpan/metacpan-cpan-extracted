package App::RL::Command::coverage;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

use constant abstract => 'output detailed depthes of coverages on chromosomes';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen", ],
        [ "size|s=s", "chr.sizes",           { required => 1 }, ],
        [ "max|m=i",  "count to this depth", { default  => 1 }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "runlist coverage [options] <infiles>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= " " x 4 . "Like `runlist cover`, also output depthes of coverages.\n";
    $desc .= " " x 4 . "I:1-100\n";
    $desc .= " " x 4 . "I(+):90-150\n";
    $desc .= " " x 4 . "S288c.I(-):190-200\tSpecies names will be omitted.\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !@{$args} ) {
        my $message = "This command need one or more input files.\n\tIt found";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".yml";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $length_of = App::RL::Common::read_sizes( $opt->{size} );

    my %count_of;    # YAML::Sync can't Dump tied hashes
    for my $depth ( 0 .. $opt->{max} ) {
        if ( !exists $count_of{$depth} ) {
            $count_of{$depth} = {};
        }
    }
    {
        for my $chr ( keys %{$length_of} ) {
            $count_of{0}->{$chr} = App::RL::Common::new_set();
            $count_of{0}->{$chr}->add_pair( 1, $length_of->{$chr} );
        }
    }

    for my $infile ( @{$args} ) {
        for my $line ( App::RL::Common::read_lines($infile) ) {
            next if substr( $line, 0, 1 ) eq "#";

            my $info = App::RL::Common::decode_header($line);
            next unless App::RL::Common::info_is_valid($info);

            my $chr_name = $info->{chr};
            next unless exists $length_of->{$chr_name};

            # count depth
            my $set = App::RL::Common::new_set()->add_pair( $info->{start}, $info->{end} );
            $set = $count_of{0}->{$chr_name}->intersect($set);
        DEPTH: for my $cur ( 0 .. $opt->{max} ) {
                if ( !exists $count_of{$cur}->{$chr_name} ) {
                    $count_of{$cur}->{$chr_name} = App::RL::Common::new_set();
                }

                #
                my $iset_cur = $count_of{$cur}->{$chr_name}->intersect($set);

                if ( $iset_cur->is_empty ) {
                    $count_of{$cur}->{$chr_name}->add($set);
                    $set->clear;
                    last DEPTH;
                }
                else {
                    $count_of{$cur}->{$chr_name}->add($set);
                    $set = $iset_cur;
                }
            }
        }
    }

    # remove regions from lower coverages
    my $max_depth = List::Util::max( keys %count_of );
    for my $i ( 0 .. $max_depth - 1 ) {
        for my $j ( $i + 1 .. $max_depth ) {
            for my $chr_name ( keys %{ $count_of{$i} } ) {
                if ( exists $count_of{$j}->{$chr_name} ) {
                    $count_of{$i}->{$chr_name}->remove( $count_of{$j}->{$chr_name} );
                }
            }
        }
    }

    # IntSpan to runlist
    for my $key ( keys %count_of ) {
        if ( keys %{ $count_of{$key} } == 0 ) {
            delete $count_of{$key};
            next;
        }
        for my $chr_name ( keys %{ $count_of{$key} } ) {
            $count_of{$key}->{$chr_name} = $count_of{$key}->{$chr_name}->runlist;
        }
    }

    #----------------------------#
    # Output
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    print {$out_fh} YAML::Syck::Dump( \%count_of );
    close $out_fh;
}

1;
