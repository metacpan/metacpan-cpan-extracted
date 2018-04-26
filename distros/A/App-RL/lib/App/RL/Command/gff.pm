package App::RL::Command::gff;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

sub abstract {
    return 'convert gff3 files to chromosome runlists';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename. [stdout] for screen" ],
        [ "tag|t=s",     "primary tag (the third field)" ],
        [ "remove|r",    "remove 'chr0' from chromosome names" ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "runlist gff [options] <infile> [more infiles]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

* .gff files can be gzipped

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
    my $set_of = {};
    for my $infile ( @{$args} ) {
        my @lines = App::RL::Common::read_lines($infile);

        for my $line (@lines) {
            next if substr( $line, 0, 1 ) eq "#";

            my @array = split( "\t", $line );
            my $feature_type = $array[2];

            if ( defined $opt->{tag} ) {
                next if $opt->{tag} ne $feature_type;
            }

            my $chr_name  = $array[0];
            my $chr_start = $array[3];
            my $chr_end   = $array[4];

            if ( $opt->{remove} ) {
                $chr_name =~ s/chr0?//i;
                $chr_name =~ s/\.\d+$//;
            }
            if ( !exists $set_of->{$chr_name} ) {
                $set_of->{$chr_name} = App::RL::Common::new_set;
            }
            $set_of->{$chr_name}->add_pair( $chr_start, $chr_end );
        }
    }

    # IntSpan to runlist
    for my $chr_name ( keys %{$set_of} ) {
        $set_of->{$chr_name} = $set_of->{$chr_name}->runlist;
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

    print {$out_fh} YAML::Syck::Dump($set_of);

    close $out_fh;
}

1;
