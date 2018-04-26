package App::Fasops::Command::concat;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;

sub abstract {
    return 'concatenate sequence pieces in blocked fasta files';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen" ],
        [ "total|t=i", "Stop when exceed this length", { default => 10_000_000, }, ],
        [ "relaxed",   "output relaxed phylip instead of fasta" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops concat [options] <infile> <name.list>";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute
            . ( $opt->{relaxed} ? ".concat.phy" : ".concat.fasta" );
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

    my $all_seq_of = { map { $_ => "" } @names };
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

                my $first_name   = ( keys %{$info_of} )[0];
                my $align_length = length $info_of->{$first_name}{seq};

                for my $name (@names) {
                    if ( exists $info_of->{$name} ) {
                        $all_seq_of->{$name} .= $info_of->{$name}{seq};
                    }
                    else {
                        # fill absent names with ------
                        $all_seq_of->{$name} .= '-' x $align_length;
                    }
                }

                if ( $opt->{total} and $opt->{total} < length $all_seq_of->{ $names[0] } ) {
                    last BLOCK;
                }
            }
            else {
                $content .= $line;
            }
        }
    }

    my $all_seq_length = length $all_seq_of->{ $names[0] };
    if ( $opt->{relaxed} ) {
        print {$out_fh} scalar @names, " $all_seq_length\n";
        for my $name (@names) {
            print {$out_fh} "$name ";
            print {$out_fh} $all_seq_of->{$name}, "\n";
        }
    }
    else {
        for my $name (@names) {
            print {$out_fh} ">$name\n";
            print {$out_fh} $all_seq_of->{$name}, "\n";
        }
    }

    close $out_fh;
    $in_fh->close;
}

1;
