package App::Fasops::Command::separate;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;

use constant abstract => 'separate blocked fasta files by species';

sub opt_spec {
    return (
        [ "outdir|o=s", "Output location, [stdout] for screen", { default => '.' } ],
        [ "suffix|s=s", "Extensions of output files",           { default => '.fasta' } ],
        [ "rm|r",       "If outdir exists, remove it before operating" ],
        [ "rc",         "Revcom sequences when chr_strand is '-'" ],
        [ "nodash",     "Remove dashes ('-') from sequences" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops separate [options] <infile> [more infiles]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\t<infiles> are paths to blocked fasta files, .fas.gz is supported.\n";
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

    if ( !exists $opt->{outdir} ) {
        $opt->{outdir} = Path::Tiny::path( $args->[0] )->absolute . ".separate";
    }
    if ( -e $opt->{outdir} ) {
        if ( $opt->{rm} ) {
            Path::Tiny::path( $opt->{outdir} )->remove_tree;
        }
    }

    if ( lc( $opt->{outdir} ) ne "stdout" ) {
        Path::Tiny::path( $opt->{outdir} )->mkpath;
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

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
                    my $info = $info_of->{$key};
                    if ( $opt->{nodash} ) {
                        $info->{seq} =~ tr/-//d;
                    }
                    if ( $opt->{rc} and $info->{strand} ne "+" ) {
                        $info->{seq}
                            = App::Fasops::Common::revcom( $info->{seq} );
                        $info->{strand} = "+";
                    }

                    if ( lc( $opt->{outdir} ) eq "stdout" ) {
                        print ">" . App::RL::Common::encode_header($info) . "\n";
                        print $info->{seq} . "\n";
                    }
                    else {
                        my $outfile
                            = Path::Tiny::path( $opt->{outdir}, $info->{name} . $opt->{suffix} );
                        $outfile->append( ">" . App::RL::Common::encode_header($info) . "\n" );
                        $outfile->append( $info->{seq} . "\n" );
                    }
                }
            }
            else {
                $content .= $line;
            }
        }

        $in_fh->close;
    }
}

1;
