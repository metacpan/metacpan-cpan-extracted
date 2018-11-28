package App::Rangeops::Command::sort;
use strict;
use warnings;
use autodie;

use App::Rangeops -command;
use App::Rangeops::Common;

sub abstract {
    return 'sort links and ranges within links';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "numeric|n",   "Sort chromosome names numerically.", ],
    );
}

sub usage_desc {
    return "rangeops sort [options] <infiles>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !@{$args} ) {
        $self->usage_error("This command need one or more input files.");
    }
    for ( @{$args} ) {
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile}
            = Path::Tiny::path( $args->[0] )->absolute . ".sort.tsv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my @lines;
    for my $file ( @{$args} ) {
        for my $line ( App::RL::Common::read_lines($file) ) {
            for my $part ( split /\t/, $line ) {
                my $info = App::RL::Common::decode_header($part);
                next unless App::RL::Common::info_is_valid($info);

                push @lines, $line;    # May produce duplicated lines
            }
        }
    }
    @lines = List::MoreUtils::PP::uniq(@lines);

    #----------------------------#
    # Sort
    #----------------------------#
    my @sorted_lines
        = @{ App::Rangeops::Common::sort_links( \@lines, $opt->{numeric} ) };

    #----------------------------#
    # Output
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = \*STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    print {$out_fh} "$_\n" for @sorted_lines;

    close $out_fh;
}

1;
