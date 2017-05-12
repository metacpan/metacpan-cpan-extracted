package App::RL::Command::split;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

use constant abstract => 'split runlist yaml files';

sub opt_spec {
    return (
        [ "outdir|o=s", "output location, [stdout] for screen", { default => '.' } ],
        [ "suffix|s=s", "extension of output files,",           { default => '.yml' } ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "runlist split [options] <infile>";
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

    if ( !exists $opt->{outdir} ) {
        $opt->{outdir} = Path::Tiny::path( $args->[0] )->absolute . ".split";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $yml = YAML::Syck::LoadFile( $args->[0] );

    for my $key ( keys %{$yml} ) {
        if ( lc( $opt->{outdir} ) eq "stdout" ) {
            print YAML::Syck::Dump( $yml->{$key} );
        }
        else {
            YAML::Syck::DumpFile( Path::Tiny::path( $opt->{outdir}, $key . $opt->{suffix} ),
                $yml->{$key} );
        }
    }
}

1;
