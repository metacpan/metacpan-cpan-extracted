package App::Fasops::Command::replace;
use strict;
use warnings;
use autodie;

use App::Fasops -command;
use App::RL::Common;
use App::Fasops::Common;

use constant abstract => 'replace headers from a blocked fasta';

sub opt_spec {
    return ( [ "outfile|o=s", "Output filename. [stdout] for screen." ], { show_defaults => 1, } );
}

sub usage_desc {
    return "fasops replace [options] <infile> <replace.tsv>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\t<infile> is the path to blocked fasta file, .fas.gz is supported.\n";
    $desc .= "\tinfile == stdin means reading from STDIN\n";
    $desc .= "\t<replace.tsv> is a tab-separated file containing more than one fields.\n";
    $desc .= "\t\toriginal_name\treplace_name\tmore_replace_name\n";
    $desc .= "\t\tWith one field will delete the whole alignment block.\n";
    $desc .= "\t\tWith three or more fields will duplicate the whole alignment block.\n";
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

    my $replace = App::Fasops::Common::read_replaces( $args->[1] );

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
        while (1) {
            last if $in_fh->eof and $content eq '';
            my $line = '';
            if ( !$in_fh->eof ) {
                $line = $in_fh->getline;
            }
            if ( ( $line eq '' or $line =~ /^\s+$/ ) and $content ne '' ) {
                my $info_of = App::Fasops::Common::parse_block_header($content);
                $content = '';

                my @ori_names = keys %{$info_of};

                my @replace_names
                    = grep { exists $info_of->{$_} } keys %{$replace};

                if ( @replace_names == 0 ) {    # block untouched
                    for my $header (@ori_names) {
                        printf {$out_fh} ">%s\n",
                            App::RL::Common::encode_header( $info_of->{$header} );
                        printf {$out_fh} "%s\n", $info_of->{$header}{seq};
                    }
                    print {$out_fh} "\n";
                }
                elsif ( @replace_names == 1 ) {    # each replaces create a new block
                    my $ori_name = $replace_names[0];
                    for my $new_name ( @{ $replace->{$ori_name} } ) {
                        for my $header (@ori_names) {
                            if ( $header eq $ori_name ) {
                                printf {$out_fh} ">%s\n", $new_name;
                                printf {$out_fh} "%s\n",  $info_of->{$header}{seq};
                            }
                            else {
                                printf {$out_fh} ">%s\n",
                                    App::RL::Common::encode_header( $info_of->{$header} );
                                printf {$out_fh} "%s\n", $info_of->{$header}{seq};
                            }
                        }
                        print {$out_fh} "\n";
                    }
                }
                else {
                    Carp::carp "Don't support multiply records in one block. @replace_names\n";
                    for my $header (@ori_names) {
                        printf {$out_fh} ">%s\n",
                            App::RL::Common::encode_header( $info_of->{$header} );
                        printf {$out_fh} "%s\n", $info_of->{$header}{seq};
                    }
                    print {$out_fh} "\n";
                }

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
