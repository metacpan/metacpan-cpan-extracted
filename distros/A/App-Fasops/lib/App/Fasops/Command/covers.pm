package App::Fasops::Command::covers;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::Fasops::Common;

use constant abstract => 'scan blocked fasta files and output covers on chromosomes';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen" ],
        [ "name|n=s",    "Only output this species" ],
        [ "length|l=i", "the threshold of alignment length", { default => 1 } ],
        [   "trim|t=i",
            "Trim align borders to avoid some overlaps in lastz results",
            { default => 0 }
        ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops covers [options] <infile> [more infiles]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\t<infiles> are blocked fasta files, .fas.gz is supported.\n";
    $desc .= "\tinfile == stdin means reading from STDIN\n";
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

    my %count_of;    # YAML::Sync can't Dump tied hashes
    for my $infile ( @{$args} ) {
        my $in_fh;
        if ( lc $infile eq "stdin" ) {
            $in_fh = *STDIN{IO};
        }
        else {
            $in_fh = IO::Zlib->new( $infile, "rb" );
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
                my $info_of = App::Fasops::Common::parse_block($content);
                $content = '';

                my @names = keys %{$info_of};
                if ( $opt->{name} ) {
                    if ( exists $info_of->{ $opt->{name} } ) {
                        @names = ( $opt->{name} );
                    }
                    else {
                        warn "$opt->{name} doesn't exist in this alignment\n";
                        next;
                    }
                }

                if ( $opt->{length} ) {
                    next
                        if length $info_of->{ $names[0] }{seq} < $opt->{length};
                }

                for my $key (@names) {
                    my $name     = $info_of->{$key}{name};
                    my $chr_name = $info_of->{$key}{chr};

                    if ( !exists $count_of{$name} ) {
                        $count_of{$name} = {};
                    }
                    if ( !exists $count_of{$name}->{$chr_name} ) {
                        $count_of{$name}->{$chr_name} = AlignDB::IntSpan->new();
                    }

                    my $intspan = AlignDB::IntSpan->new->add_pair( $info_of->{$key}{start},
                        $info_of->{$key}{end} );
                    if ( $opt->{trim} ) {
                        $intspan = $intspan->trim( $opt->{trim} );
                    }

                    $count_of{$name}->{$chr_name}->add($intspan);
                }
            }
            else {
                $content .= $line;
            }
        }

        $in_fh->close;
    }

    # IntSpan to runlist
    for my $name ( keys %count_of ) {
        for my $chr_name ( keys %{ $count_of{$name} } ) {
            $count_of{$name}->{$chr_name}
                = $count_of{$name}->{$chr_name}->runlist();
        }
    }

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    if ( defined $opt->{name} ) {
        print {$out_fh} YAML::Syck::Dump( $count_of{ $opt->{name} } );
    }
    else {
        print {$out_fh} YAML::Syck::Dump( \%count_of );
    }
    close $out_fh;
}

1;
