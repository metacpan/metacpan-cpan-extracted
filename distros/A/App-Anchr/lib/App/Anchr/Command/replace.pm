package App::Anchr::Command::replace;
use strict;
use warnings;
use autodie;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => 'replace IDs in .ovlp.tsv';

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen" ],
        [ "reverse|r",   "to-from instead of from-to in .replace.tsv", ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr replace [options] <.ovlp.tsv> <.replace.tsv>";
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

    my $replace_of
        = App::Anchr::Common::get_replaces2( $args->[1], { reverse => $opt->{reverse}, } );

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

    while ( my $line = <$in_fh> ) {
        my @fields = split "\t", $line;
        next unless @fields == 13;

        my ( $f_id, $g_id, ) = @fields[ 0 .. 1 ];

        printf $out_fh "%s", exists $replace_of->{$f_id} ? $replace_of->{$f_id} : $f_id;
        print $out_fh "\t";
        printf $out_fh "%s", exists $replace_of->{$g_id} ? $replace_of->{$g_id} : $g_id;
        print $out_fh "\t";
        print $out_fh join( "\t", @fields[ 2 .. 12 ] );
    }
    close $in_fh;
    close $out_fh;
}

1;
