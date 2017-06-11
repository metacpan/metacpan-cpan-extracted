package App::RL::Command::convert;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

use constant abstract => 'convert runlist file to position file';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "remove|r",    "Remove 'chr0' from chromosome names." ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "runlist convert [options] <runlist file>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
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
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".pos.txt";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $infile;    # YAML::Syck::LoadFile handles IO::*
    if ( lc $args->[0] eq 'stdin' ) {
        $infile = *STDIN;
    }
    else {
        $infile = $args->[0];
    }
    my $r_of = App::RL::Common::runlist2set( YAML::Syck::LoadFile($infile), $opt->{remove} );

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    #----------------------------#
    # Operating
    #----------------------------#
    for my $key ( sort keys %{$r_of} ) {

        #@type AlignDB::IntSpan
        my $set = $r_of->{$key};
        next if $set->is_empty;
        for my $span ( $set->runlists ) {
            printf {$out_fh} "%s:%s\n", $key, $span;
        }
    }

    close $out_fh;
}

1;
