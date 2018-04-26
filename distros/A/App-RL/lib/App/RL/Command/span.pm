package App::RL::Command::span;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

sub abstract {
    return 'operate spans in a YAML file';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename. [stdout] for screen" ],
        [ "op=s", "operations: cover, holes, trim, pad, excise or fill", { default => "cover" } ],
        [ "number|n=i", "apply this number to trim, pad, excise or fill", { default => 0 } ],
        [ "remove|r",   "remove 'chr0' from chromosome names" ],
        [ "mk",         "YAML file contains multiple sets of runlists" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "runlist span [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

List of operations:

* cover:  a single span from min to max
* holes:  all the holes in runlist
* trim:   remove N integers from each end of each span of runlist
* pad:    add N integers from each end of each span of runlist
* excise: remove all spans smaller than N
* fill:   fill in all holes smaller than N

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
        next if lc $_ eq "stdin";
        if ( !Path::Tiny::path($_)->is_file ) {
            $self->usage_error("The input file [$_] doesn't exist.");
        }
    }

    if ( $opt->{op} =~ /^cover/i ) {
        $opt->{op} = 'cover';
    }
    elsif ( $opt->{op} =~ /^hole/i ) {
        $opt->{op} = 'holes';
    }
    elsif ( $opt->{op} =~ /^trim/i ) {
        $opt->{op} = 'trim';
    }
    elsif ( $opt->{op} =~ /^pad/i ) {
        $opt->{op} = 'pad';
    }
    elsif ( $opt->{op} =~ /^excise/i ) {
        $opt->{op} = 'excise';
    }
    elsif ( $opt->{op} =~ /^fill/i ) {
        $opt->{op} = 'fill';
    }
    else {
        Carp::confess "[@{[$opt->{op}]}] is invalid\n";
    }

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = $opt->{op} . ".yml";
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

    my $s_of = {};
    my @keys;
    if ( $opt->{mk} ) {
        my $yml = YAML::Syck::LoadFile($infile);
        @keys = sort keys %{$yml};

        for my $key (@keys) {
            $s_of->{$key}
                = App::RL::Common::runlist2set( $yml->{$key}, $opt->{remove} );
        }
    }
    else {
        @keys = ("__single");
        $s_of->{__single}
            = App::RL::Common::runlist2set( YAML::Syck::LoadFile($infile), $opt->{remove} );
    }

    #----------------------------#
    # Operating
    #----------------------------#
    my $op_result_of = { map { $_ => {} } @keys };

    for my $key (@keys) {
        my $s = $s_of->{$key};

        for my $chr ( keys %{$s} ) {
            my $op     = $opt->{op};
            my $op_set = $s->{$chr}->$op( $opt->{number} );
            $op_result_of->{$key}{$chr} = $op_set->runlist;
        }
    }

    #----------------------------#
    # Output
    #----------------------------#
    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    if ( $opt->{mk} ) {
        print {$out_fh} YAML::Syck::Dump($op_result_of);
    }
    else {
        print {$out_fh} YAML::Syck::Dump( $op_result_of->{__single} );
    }

    close $out_fh;
}

1;
