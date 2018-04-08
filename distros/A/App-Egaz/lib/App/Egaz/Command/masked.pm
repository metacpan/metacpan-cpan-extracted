package App::Egaz::Command::masked;
use strict;
use warnings;
use autodie;

use App::Egaz -command;
use App::Egaz::Common;

sub abstract {
    return 'masked (or gaps) regions in fasta files';
}

sub opt_spec {
    return (
        [ "outfile|o=s", "Output filename. [stdout] for screen", { default => "stdout" }, ],
        [ 'gaps',        'only record regions of N/n', ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "egaz masked [options] <infile> [more files]";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";

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

}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #----------------------------#
    # processing
    #----------------------------#
    my $region_of = {};
    for my $infile ( @{$args} ) {
        my $seq_of = App::Fasops::Common::read_fasta($infile);

        for my $seq_name ( keys %{$seq_of} ) {
            if ( exists $region_of->{$seq_name} ) {
                Carp::carp "Duplicated seqname [$seq_name]\n";
                next;
            }

            my $seq = $seq_of->{$seq_name};
            my $len = length $seq;

            my @lists;
            for my $i ( 1 .. $len ) {
                my $nt = substr $seq, $i - 1, 1;

                my $regex;
                if ( $opt->{gaps} ) {
                    $regex = qr{[Nn]};
                }
                else {
                    $regex = qr{[Nacgtun]};
                }

                if ( $nt =~ m{$regex} ) {
                    push @lists, $i;
                }
            }

            my $runlist = AlignDB::IntSpan->new()->add(@lists)->runlist;
            $region_of->{$seq_name} = $runlist;
        }
    }

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    print {$out_fh} YAML::Syck::Dump($region_of);

    close $out_fh;
}

1;
