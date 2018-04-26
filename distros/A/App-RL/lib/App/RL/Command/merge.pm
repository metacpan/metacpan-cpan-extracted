package App::RL::Command::merge;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

sub abstract {
    return 'merge runlist yaml files';
}

sub opt_spec {
    return ( [ "outfile|o=s", "output filename. [stdout] for screen" ], { show_defaults => 1, } );
}

sub usage_desc {
    return "runlist merge [options] <infiles>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    return $desc;
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    if ( !@{$args} ) {
        my $message = "This command need one or more input files.\n\tIt found";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".merge.yml";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT;
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    my $master = {};
    for my $file ( @{$args} ) {
        my $basename = Path::Tiny::path($file)->basename( ".yaml", ".yml" );
        my $dir = Path::Tiny::path($file)->parent->stringify;
        my ($word) = split /[^\w-]+/, $basename;

        my $content = YAML::Syck::LoadFile($file);
        $master->{$word} = $content;
    }
    print {$out_fh} YAML::Syck::Dump($master);

    close $out_fh;
}

1;
