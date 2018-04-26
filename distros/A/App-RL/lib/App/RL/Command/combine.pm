package App::RL::Command::combine;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

sub abstract {
    return 'combine multiple sets of runlists';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename. [stdout] for screen" ],
        [ "remove|r",    "remove 'chr0' from chromosome names" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "runlist combine [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* It's expected that the YAML file is --mk
* Otherwise this command will make no effects

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

    if ( !exists $opt->{outfile} ) {
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".combine.yml";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $s_of         = {};
    my $all_name_set = Set::Scalar->new;

    my $yml  = YAML::Syck::LoadFile( $args->[0] );
    my @keys = sort keys %{$yml};

    if ( ref $yml->{ $keys[0] } eq 'HASH' ) {
        for my $key (@keys) {
            $s_of->{$key} = App::RL::Common::runlist2set( $yml->{$key}, $opt->{remove} );
            $all_name_set->insert( keys %{ $s_of->{$key} } );
        }
    }
    else {
        @keys = ("__single");
        $s_of->{__single}
            = App::RL::Common::runlist2set( $yml, $opt->{remove} );
        $all_name_set->insert( keys %{ $s_of->{__single} } );
    }

    #----------------------------#
    # Operating
    #----------------------------#
    my $op_result_of = { map { $_ => App::RL::Common::new_set() } $all_name_set->members };

    for my $key (@keys) {
        my $s = $s_of->{$key};
        for my $chr ( keys %{$s} ) {
            $op_result_of->{$chr}->add( $s->{$chr} );
        }
    }

    # convert sets to runlists
    for my $chr ( keys %{$op_result_of} ) {
        $op_result_of->{$chr} = $op_result_of->{$chr}->runlist;
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

    print {$out_fh} YAML::Syck::Dump($op_result_of);

    close $out_fh;
}

1;
