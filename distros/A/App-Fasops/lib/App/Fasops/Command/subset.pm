package App::Fasops::Command::subset;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;

sub abstract {
    return 'extract a subset of species from a blocked fasta';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen" ],
        [ "first",       "Always keep the first species" ],
        [ "required",    "Skip blocks not containing all the names" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops subset [options] <infile> <name.list>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infile> is the path to blocked fasta file, .fas.gz is supported
* infile == stdin means reading from STDIN
* <name.list> is a file with a list of names to keep, one per line
* Names in the output file will following the order in <name.list>

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
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".fas";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my @names = @{ App::RL::Common::read_names( $args->[1] ) };

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

    {
        my $content = '';    # content of one block
    BLOCK: while (1) {
            last if $in_fh->eof and $content eq '';
            my $line = '';
            if ( !$in_fh->eof ) {
                $line = $in_fh->getline;
            }
            if ( ( $line eq '' or $line =~ /^\s+$/ ) and $content ne '' ) {
                my $info_of = App::Fasops::Common::parse_block($content);
                $content = '';

                my @needed_names = @names;
                if ( $opt->{first} ) {
                    my $first = ( keys %{$info_of} )[0];
                    @needed_names = App::Fasops::Common::uniq( $first, @needed_names );
                }

                if ( $opt->{required} ) {
                    for my $name (@needed_names) {
                        next BLOCK unless exists $info_of->{$name};
                    }
                }

                for my $name (@needed_names) {
                    if ( exists $info_of->{$name} ) {
                        printf {$out_fh} ">%s\n",
                            App::RL::Common::encode_header( $info_of->{$name} );
                        printf {$out_fh} "%s\n", $info_of->{$name}{seq};
                    }
                }
                print {$out_fh} "\n";
            }
            else {
                $content .= $line;
            }
        }
    }
    close $out_fh;
    $in_fh->close;
}

1;
