package App::Anchr::Command::paf2ovlp;
use strict;
use warnings;
use autodie;

use MCE;
use MCE::Flow Sereal => 1;
use MCE::Candy;

use App::Anchr -command;
use App::Anchr::Common;

use constant abstract => 'minimap paf to ovelaps';

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename, [stdout] for screen" ],
        [ "parallel|p=i", "number of threads", { default => 4 }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "anchr paf2ovlp [options] <minimap outputs>";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".ovlp.tsv";
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
        $in_fh = IO::Zlib->new( $args->[0], "rb" );
    }

    # A stream to 'stdout' or a standard file.
    my $out_fh;
    if ( lc $opt->{outfile} eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    my $worker = sub {
        my ( $self, $chunk_ref, $chunk_id ) = @_;

        my $info = App::Anchr::Common::parse_paf_line( $chunk_ref->[0] );

        # preserving output order
        MCE->gather( $chunk_id, App::Anchr::Common::create_ovlp_line($info) . "\n" );
    };

    MCE::Flow::init {
        chunk_size  => 1,
        max_workers => $opt->{parallel},
        gather      => MCE::Candy::out_iter_fh($out_fh),
    };
    MCE::Flow->run_file( $worker, $in_fh );
    MCE::Flow::finish;

    close $in_fh;
    close $out_fh;
}

1;
