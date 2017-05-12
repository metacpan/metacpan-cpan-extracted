package App::Fasops::Command::join;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;

use constant abstract => 'join multiple blocked fasta files by common target';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen" ],
        [ "name|n=s",    "According to this species. Default is the first one" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops join [options] <infile> [more infiles]";
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
        $opt->{outfile}
            = Path::Tiny::path( $args->[0] )->absolute . ".join.fas";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    tie my %block_of, "Tie::IxHash";
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

                # set $opt->{name} to the first one of the first block
                if ( !defined $opt->{name} ) {
                    ( $opt->{name} ) = keys %{$info_of};
                }

                # target name
                my $header = App::RL::Common::encode_header( $info_of->{ $opt->{name} } );

                if ( exists $block_of{$header} ) {
                    my @other_names
                        = grep { $_ ne $opt->{name} } keys %{$info_of};
                    for my $name (@other_names) {
                        $block_of{$header}->{$name} = $info_of->{$name};
                    }
                }
                else {
                    $block_of{$header} = $info_of;
                }
            }
            else {
                $content .= $line;
            }
        }
        $in_fh->close;
    }

    for my $header ( keys %block_of ) {
        my $info_of = $block_of{$header};

        my @names = keys %{$info_of};

        for my $name (@names) {
            my $info = $info_of->{$name};
            printf {$out_fh} ">%s\n", App::RL::Common::encode_header($info);
            printf {$out_fh} "%s\n",  $info->{seq};
        }
        print {$out_fh} "\n";
    }

    close $out_fh;
}

1;
