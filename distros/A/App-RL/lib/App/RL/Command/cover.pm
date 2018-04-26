package App::RL::Command::cover;
use strict;
use warnings;
use autodie;

use App::RL -command;
use App::RL::Common;

sub abstract {
    return 'output covers of positions on chromosomes';
}


sub opt_spec {
    return ( [ "outfile|o=s", "output filename. [stdout] for screen" ], { show_defaults => 1, } );
}

sub usage_desc {
    return "runlist cover [options] <infile> [more infiles]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= <<'MARKDOWN';

Like `runlist combine`, but <infile> are genome positions

    I:1-100
    I(+):90-150
    S288c.I(-):190-200      # Species names will be omitted

MARKDOWN
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".yml";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my %count_of;    # YAML::Sync can't Dump tied hashes
    for my $infile ( @{$args} ) {
        for my $line ( App::RL::Common::read_lines($infile) ) {
            next if substr( $line, 0, 1 ) eq "#";

            my $info = App::RL::Common::decode_header($line);
            next unless App::RL::Common::info_is_valid($info);

            my $chr_name = $info->{chr};
            if ( !exists $count_of{$chr_name} ) {
                $count_of{$chr_name} = App::RL::Common::new_set();
            }
            $count_of{$chr_name}->add_pair( $info->{start}, $info->{end} );
        }
    }

    # IntSpan to runlist
    for my $chr_name ( keys %count_of ) {
        $count_of{$chr_name} = $count_of{$chr_name}->runlist;
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

    print {$out_fh} YAML::Syck::Dump( \%count_of );
    close $out_fh;
}

1;
