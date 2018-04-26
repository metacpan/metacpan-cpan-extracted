package App::Fasops::Command::mergecsv;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::Fasops::Common;

sub abstract {
    return 'merge csv files based on @fields';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen",    { default => "stdout" }, ],
        [ 'fields|f=i@', 'fields as identifies, 0 as first column', { default => [0] }, ],
        [ 'concat|c',    'do concat other than merge. Keep first ID fields', ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops mergecsv [options] <infile> [more files]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* Accept one or more csv files
* infile == stdin means reading from STDIN

    cat 1.csv 2.csv | egaz mergecsv -f 0 -f 1
    egaz mergecsv -f 0 -f 1 1.csv 2.csv

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} < 1 ) {
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

    # make array splicing happier
    $opt->{fields} = [ sort @{ $opt->{fields} } ];
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # read
    #----------------------------#
    my $index_of = {};    # index of ids in @lines
    my @lines;
    my ( $count_all, $index ) = ( 0, 0 );

    for my $infile ( @{$args} ) {

        #@type IO::Handle
        my $in_fh;
        if ( lc $infile eq "stdin" ) {
            $in_fh = *STDIN{IO};
        }
        else {
            $in_fh = IO::Zlib->new( $infile, "rb" );
        }

        while ( !$in_fh->eof ) {
            my $line = $in_fh->getline;
            chomp $line;
            next unless $line;

            $count_all++;
            my $id = join( "_", ( split ",", $line )[ @{ $opt->{fields} } ] );
            if ( exists $index_of->{$id} ) {
                if ( $opt->{concat} ) {
                    my $ori_index = $index_of->{$id};
                    my $ori_line  = $lines[$ori_index];

                    my @fs = split ",", $line;
                    for my $f_idx ( reverse @{ $opt->{fields} } ) {
                        splice @fs, $f_idx, 1;
                    }
                    $lines[$ori_index] = join ",", $ori_line, @fs;
                }
            }
            else {
                $index_of->{$id} = $index;
                push @lines, $line;
                $index++;
            }
        }

        $in_fh->close;
    }

    #----------------------------#
    # check
    #----------------------------#
    {
        my %seen;
        for (@lines) {
            my $number = scalar split(",");
            $seen{$number}++;
        }
        if ( keys(%seen) > 1 ) {
            Carp::carp "*** Fields not identical, be careful.\n";
            Carp::carp YAML::Syck::Dump { fields => \%seen, };
        }
    }

    #----------------------------#
    # write outputs
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    for (@lines) {
        print {$out_fh} $_ . "\n";
    }
    close $out_fh;

    printf STDERR "Total lines [%d]; Result lines [%d].\n", $count_all, scalar @lines;

    return;
}

1;
