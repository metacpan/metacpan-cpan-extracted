package App::Fasops::Command::check;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;


sub abstract {
    return 'check genome locations in (blocked) fasta headers';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "name|n=s",    "Which species to be checked, omit this will check all sequences" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops check [options] <infile> <genome.fa>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* <infiles> are paths to axt files, .axt.gz is supported
* infile == stdin means reading from STDIN
* <genome.fa> is one multi fasta file contains genome sequences

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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".check.txt";
    }

    # samtools should be in $PATH
    if ( !IPC::Cmd::can_run("samtools") ) {
        $self->usage_error("Can't find [samtools].");
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

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
        my $header;
        my $content = '';
        while ( my $line = $in_fh->getline ) {
            chomp $line;

            if ( $line =~ /^\>[\w:-]+/ ) {

                # the first sequence is ready
                if ( defined $header ) {
                    check_seq( $header, $content, $args->[1], $out_fh, $opt->{name}, );
                }

                # prepare to accept next sequence
                $line =~ s/^\>//;
                $header = $line;

                # clean previous sequence
                $content = '';
            }
            elsif ( $line =~ /^[\w-]+/ ) {
                $line =~ s/[^\w]//g;    # Delete '-'s
                $line = uc $line;
                $content .= $line;
            }
            else {                      # Blank line, do nothing
            }
        }

        # for last sequece
        check_seq( $header, $content, $args->[1], $out_fh, $opt->{name}, );
    }

    close $out_fh;
    $in_fh->close;
}

sub check_seq {
    my $header      = shift;
    my $seq         = shift;
    my $file_genome = shift;
    my $out_fh      = shift;
    my $name        = shift;

    my $info = App::RL::Common::decode_header($header);

    if ( $name and $name ne $info->{name} ) {
        return;
    }

    if ( $info->{strand} eq '-' ) {
        $seq = App::Fasops::Common::revcom($seq);
    }

    my $location;
    if ( $info->{end} and $info->{start} < $info->{end} ) {
        $location = sprintf "%s:%s-%s", $info->{chr}, $info->{start}, $info->{end};
    }
    else {
        $location = sprintf "%s:%s", $info->{chr}, $info->{start};
    }
    my $seq_in_genome = uc App::Fasops::Common::get_seq_faidx( $file_genome, $location );

    my $status = "FAILED";
    if ( $seq eq $seq_in_genome ) {
        $status = "OK";
    }

    printf {$out_fh} "%s\t%s\n", $header, $status;

    return;
}

1;
