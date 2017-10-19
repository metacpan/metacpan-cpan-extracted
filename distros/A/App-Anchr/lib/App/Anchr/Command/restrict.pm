package App::Anchr::Command::restrict;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => 'restrict overlaps to known pairs';

sub opt_spec {
    return ( [ "outfile|o=s", "output filename, [stdout] for screen" ], { show_defaults => 1, } );
}

sub usage_desc {
    return "anchr restrict [options] <.ovlp.tsv> <.restrict.tsv>";
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

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".replace.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    # A stream from 'stdin' or a standard file.
    my $in_fh;
    if ( lc $args->[0] eq 'stdin' ) {
        $in_fh = *STDIN{IO};
    }
    else {
        open $in_fh, "<", $args->[0];
    }

    # A stream to 'stdout' or a standard file.
    my $out_fh;
    if ( lc $opt->{outfile} eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    # Build hash of restrict
    my %restrict_of;
    my @lines = Path::Tiny::path( $args->[1] )->lines( { chomp => 1, } );
    for my $line (@lines) {
        my @fields = split "\t", $line;
        next unless @fields == 2;

        my $str = join "-", sort @fields;
        $restrict_of{$str}++;
    }

    while ( my $line = <$in_fh> ) {
        my @fields = split "\t", $line;
        next unless @fields == 13;

        my ( $f_id, $g_id, ) = @fields[ 0 .. 1 ];

        my $str = join "-", sort ( $f_id, $g_id, );

        next unless exists $restrict_of{$str};

        print $out_fh join( "\t", @fields );
    }
    close $in_fh;
    close $out_fh;
}

1;
