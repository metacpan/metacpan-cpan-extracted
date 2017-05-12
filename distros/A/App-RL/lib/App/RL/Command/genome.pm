package App::RL::Command::genome;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

use constant abstract => 'convert chr.size to full genome runlists';

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen." ],
        [ "remove|r",    "Remove 'chr0' from chromosome names." ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "runlist genome [options] <infile>";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".yml";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # Loading
    #----------------------------#
    my $length_of = App::RL::Common::read_sizes( $args->[0], $opt->{remove} );

    #----------------------------#
    # Operating
    #----------------------------#
    my $r_of = {};
    for my $key ( keys %{$length_of} ) {
        my $set = App::RL::Common::new_set();
        $set->add_pair( 1, $length_of->{$key} );
        $r_of->{$key} = $set->runlist;
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
    print {$out_fh} YAML::Syck::Dump($r_of);

    close $out_fh;
}

1;
