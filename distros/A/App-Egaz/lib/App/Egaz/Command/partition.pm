package App::Egaz::Command::partition;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'partitions fasta files by size';
}

sub opt_spec {
    return (
        [ 'chunk=i',   'chunk size',   { default => 10_010_000 }, ],
        [ 'overlap=i', 'overlap size', { default => 10_000 }, ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz partition [options] <infile> [more files]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<MARKDOWN;

* Start coordinates of output is 1-based
* <infile> can't be stdin
* There is no --output option, outputs must be in the same directory of inputs
* Each fasta files should contain only one sequence. `faops split-name` can be use to do this.

MARKDOWN

    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( @{$args} < 1 ) {
        my $message = "This command need one or more input files.\n\tIt found";
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

    for my $infile ( @{$args} ) {
        my $seq_of = App::Fasops::Common::read_fasta($infile);

        my @seq_names = keys %{$seq_of};
        Carp::croak "More than one sequence in [$infile]\n" if @seq_names > 1;

        my $seq_size = length $seq_of->{ $seq_names[0] };

        if ( $seq_size > $opt->{chunk} + $opt->{overlap} ) {

            # break it up
            my $ranges
                = App::Egaz::Common::overlap_ranges( 1, $seq_size, $opt->{chunk}, $opt->{overlap} );
            for my $i ( @{$ranges} ) {
                my ( $start, $end ) = @{$i};
                Path::Tiny::path( $infile . "[$start,$end]" )->touch;
            }

        }
        else {
            Path::Tiny::path( $infile . "[1,$seq_size]" )->touch;
        }
    }
}

1;
