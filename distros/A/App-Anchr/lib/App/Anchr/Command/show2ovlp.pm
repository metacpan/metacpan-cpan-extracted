package App::Anchr::Command::show2ovlp;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => 'LAshow outputs to ovelaps';

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen" ],
        [ 'replace|r=s', 'original names of sequences', ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr show2ovlp [options] <fasta file> <LAshow outputs>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
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

    if ( exists $opt->{replace} ) {
        if ( !Path::Tiny::path( $opt->{replace} )->is_file ) {
            $self->usage_error("The replace file [$opt->{replace}] doesn't exist.\n");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[1] )->absolute . ".ovlp.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $len_of = App::Anchr::Common::get_len_from_header( $args->[0] );

    #    print STDERR "Get @{[scalar keys %{$len_of}]} records of sequence length\n";

    my $replace_of = {};
    if ( exists $opt->{replace} ) {
        $replace_of = App::Anchr::Common::get_replaces( $opt->{replace} );
    }

    # A stream from 'stdin' or a standard file.
    my $in_fh;
    if ( lc $args->[1] eq 'stdin' ) {
        $in_fh = *STDIN{IO};
    }
    else {
        open $in_fh, "<", $args->[1];
    }

    # A stream to 'stdout' or a standard file.
    my $out_fh;
    if ( lc $opt->{outfile} eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    while ( my $line = <$in_fh> ) {
        $line =~ s/,//g;
        $line =~ m{
            ^\D*
                (\d+)       # f_id
                \s+(\d+)    # g_id
                \s+(\w)     # orientation
                \D+(\d+)    # f.B
                \D+(\d+)    # f.E
                \D+(\d+)    # g.B
                \D+(\d+)    # g.E
                \D+([\d.]+) # identity
                .*$
            }x or next;

        my $f_id = $1;
        my $g_id = $2;

        next unless exists $len_of->{$f_id};
        next unless exists $len_of->{$g_id};

        my $g_ori    = $3 eq "n" ? 0 : 1;
        my $f_B      = $4;
        my $f_E      = $5;
        my $g_B      = $6;
        my $g_E      = $7;
        my $identity = ( 100 - $8 ) / 100;

        my $ovlp_len = $f_E - $f_B;

        printf $out_fh "%s",   exists $replace_of->{$f_id} ? $replace_of->{$f_id} : $f_id;
        printf $out_fh "\t%s", exists $replace_of->{$g_id} ? $replace_of->{$g_id} : $g_id;
        printf $out_fh "\t%d\t%.3f", $ovlp_len, $identity;
        printf $out_fh "\t%d\t%d\t%d\t%d", 0, $f_B, $f_E, $len_of->{$f_id};
        printf $out_fh "\t%d\t%d\t%d\t%d", $g_ori, $g_B, $g_E, $len_of->{$g_id};

        # relations
        if (    ( $len_of->{$g_id} < $len_of->{$f_id} )
            and ( $g_B < 1 )
            and ( $len_of->{$g_id} - $g_E < 1 ) )
        {
            printf $out_fh "\tcontains\n";
        }
        elsif ( ( $len_of->{$f_id} < $len_of->{$g_id} )
            and ( $f_B < 1 )
            and ( $len_of->{$f_id} - $f_E < 1 ) )
        {
            printf $out_fh "\tcontained\n";
        }
        else {
            printf $out_fh "\toverlap\n";
        }
    }
    close $in_fh;
    close $out_fh;
}

1;
