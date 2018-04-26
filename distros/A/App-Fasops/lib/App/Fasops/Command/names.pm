package App::Fasops::Command::names;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::Fasops::Common;

sub abstract {
    return 'scan blocked fasta files and output all species names';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen" ],
        [ "count|c",     "Also count name occurrences" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops names [options] <infile> [more infiles]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infiles> are paths to axt files, .axt.gz is supported
* infile == stdin means reading from STDIN

MARKDOWN

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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".list";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    tie my %count_of, "Tie::IxHash";
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
            if ( ( $line eq '' or $line =~ /^\s+$/ ) and $content ne '' ) {
                my $info_of = App::Fasops::Common::parse_block($content);
                $content = '';

                for my $key ( keys %{$info_of} ) {
                    my $name = $info_of->{$key}{name};
                    $count_of{$name}++;
                }
            }
            else {
                $content .= $line;
            }
        }

        $in_fh->close;
    }

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }
    for ( keys %count_of ) {
        print {$out_fh} $_;
        print {$out_fh} "\t" . $count_of{$_} if $opt->{count};
        print {$out_fh} "\n";
    }
    close $out_fh;
}

1;
