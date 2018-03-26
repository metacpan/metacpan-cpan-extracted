package App::Egaz::Command::normalize;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

use constant abstract => 'normalize lav files';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen", { default => "stdout" }, ],
        [ 'tlen=i',      'target length',                        { default => 0 }, ],
        [ 'qlen=i',      'query length',                         { default => 0 }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz normalize [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<MARKDOWN;

* infile == stdin means reading from STDIN
* Start coordinates of output is 1-based
* Set --tlen and/or --qlen on partitioned sequences
* Ported from kentUtils src/hg/utils/automation/blastz-normalizeLav

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} != 1 ) {
        my $message = "This command need one input file.\n\tIt found";
        $message .= sprintf " [%s]", $_ for @{$args};
        $message .= ".\n";
        $self->usage_error($message);
    }
    for ( @{$args} ) {
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

}

sub execute {
    my ( $self, $opt, $args ) = @_;

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

    #----------------------------#
    # load lav
    #----------------------------#
    my $lav_content = Path::Tiny::path( $args->[0] )->slurp;
    my @lavs        = grep {/^[ds] /} split /\#\:lav\n/, $lav_content;
    my $d_stanza    = shift @lavs;
    $d_stanza = "d {\n  normalize-lav $opt->{tlen} $opt->{qlen}\n}\n" . $d_stanza;

    print {$out_fh} "#:lav\n";
    print {$out_fh} $d_stanza;

    for my $lav (@lavs) {
        print {$out_fh} "#:lav\n";

        my $t_from = 0;
        my $q_from = 0;
        my $t_to   = 0;
        my $q_to   = 0;
        my $isrc   = 0;

        #----------------------------#
        # s-stanza
        #----------------------------#
        # "<filename>[-]" <start> <stop> [<rev_comp_flag> <sequence_number>]
        $lav =~ /s \{\s+(.+?)\s+\}/s;
        my $s_stanza = $1;
        my @s_lines  = $s_stanza =~ /(.+ \s+ \d+ \s+ \d+ \s+ \d+ \s+ \d+)/gx;
        if ( scalar @s_lines != 2 ) {
            Carp::croak "s-stanza error.\n";
        }

        print {$out_fh} "s {\n";

        $s_lines[0] =~ /^\s*("[^"]*")\s+(\d+)\s+(\d+)\s+(.*)$/ or die;
        $t_from = $2;
        $t_to   = $3;
        print {$out_fh} "  $1 1 " . List::Util::max( $t_to, $opt->{tlen} ) . " $4\n";

        $s_lines[1] =~ /^\s*("[^"]*")\s+(\d+)\s+(\d+)\s+(.*)$/ or die;
        $q_from = $2;
        $q_to   = $3;
        print {$out_fh} "  $1 1 " . List::Util::max( $q_to, $opt->{qlen} ) . " $4\n";

        $isrc = scalar( $1 =~ /-"$/ );

        print {$out_fh} "}\n";

        #----------------------------#
        # h-stanza
        #----------------------------#
        if ( $lav =~ /h \{\n(.+?)\}/s ) {
            my $h_stanza = $1;
            print {$out_fh} "h {\n$h_stanza}\n";
        }

        #----------------------------#
        # a-stanza
        #----------------------------#
        # abs: 1....from....to....qlen
        # rel: .....1.......n.........
        #
        # n == (to-from+1)
        # rev(x) == n-x+1
        # abs(x) == from+x-1
        #
        # abs(rev(x)) == from+(to-from+1-x+1)-1 == to-x+1
        # Rev(abs(rev(x))) == qlen-(to-x+1)+1 == qlen-to+x

        my $St = sub {
            my $x = shift;
            return $x + $t_from - 1;
        };
        my $Mq = sub {
            my $x = shift;
            if ( $opt->{qlen} == 0 ) {
                return $x;
            }
            else {
                return $isrc ? $opt->{qlen} - $q_to + $x : $q_from + $x - 1;
            }
        };

        my @a_stanzas = $lav =~ /a \{\s+(.+?)\s+\}/sg;
        for my $a_stanza (@a_stanzas) {
            print {$out_fh} "a {\n";
            for my $line ( split /\n/, $a_stanza ) {
                if ( $line =~ /^\s*s\s+(\d+)/ ) {
                    printf {$out_fh} "  s %d\n", $1;
                }
                elsif ( $line =~ /^\s*b\s+(\d+)\s+(\d+)/ ) {
                    printf {$out_fh} "  b %d %d\n", $St->($1), $Mq->($2);
                }
                elsif ( $line =~ /^\s*e\s+(\d+)\s+(\d+)/ ) {
                    printf {$out_fh} "  e %d %d\n", $St->($1), $Mq->($2);
                }
                elsif ( $line =~ /^\s*l\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/ ) {
                    printf {$out_fh} "  l %d %d %d %d %g\n", $St->($1), $Mq->($2),
                        $St->($3), $Mq->($4), $5;
                }
            }
            print {$out_fh} "}\n";
        }

        #----------------------------#
        # x-stanza
        #----------------------------#
        if ( $lav =~ /x \{\n(.+?)\}/s ) {
            my $x_stanza = $1;
            print {$out_fh} "x {\n$x_stanza}\n";
        }

        #----------------------------#
        # m-stanza
        #----------------------------#
        if ( $lav =~ /m \{\n(.+?)\}/s ) {
            my $m_stanza = $1;
            print {$out_fh} "m {\n";
            for my $line ( split /\n/, $m_stanza ) {
                if ( $line =~ /^\s*n\s+(\d+)/ ) {
                    printf {$out_fh} "  n %d\n", $1;
                }
                elsif ( $line =~ /^\s*x\s+(\d+)\s+(\d+)/ ) {
                    printf {$out_fh} "  x %d %d\n", $1 + $t_from - 1, $2 + $t_from - 1;
                }
            }
            print {$out_fh} "}\n";
        }
    }

    print {$out_fh} "#:eof\n";
    close $out_fh;
}

1;
