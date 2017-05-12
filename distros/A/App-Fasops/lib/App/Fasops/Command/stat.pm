package App::Fasops::Command::stat;
use strict;
use warnings;
use autodie;

use Text::CSV_XS;

use App::Fasops -command;
use App::Fasops::Common;

use constant abstract => 'basic statistics on alignments';

sub opt_spec {
    return (
        [ "outfile|o=s", "output filename. [stdout] for screen" ],
        [ "length|l=i", "the threshold of alignment length", { default => 1 } ],
        [ 'outgroup',   'alignments have an outgroup', ],
        { show_defaults => 1, }
    );
}

sub usage_desc {
    return "fasops stat [options] <infile>";
}

sub description {
    my $desc;
    $desc .= ucfirst(abstract) . ".\n";
    $desc .= "\t<infile> are blocked fasta files, .fas.gz is supported.\n";
    $desc .= "\tinfile == stdin means reading from STDIN\n";
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
        $opt->{outfile} = Path::Tiny::path( $args->[0] )->absolute . ".csv";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    #@type IO::Handle
    my $in_fh;
    if ( lc $args->[0] eq "stdin" ) {
        $in_fh = *STDIN{IO};
    }
    else {
        $in_fh = IO::Zlib->new( $args->[0], "rb" );
    }

    my $out_fh;
    if ( lc( $opt->{outfile} ) eq "stdout" ) {
        $out_fh = *STDOUT{IO};
    }
    else {
        open $out_fh, ">", $opt->{outfile};
    }

    # csv object
    my $csv = Text::CSV_XS->new( { eol => $/, } );

    # headers
    my @headers = qw{
        first legnth comparables identities differences gaps ns errors D indel
    };
    $csv->print( $out_fh, \@headers );

    my $content = '';    # content of one block
    while (1) {
        last if $in_fh->eof and $content eq '';
        my $line = '';
        if ( !$in_fh->eof ) {
            $line = $in_fh->getline;
        }
        next if substr( $line, 0, 1 ) eq "#";

        if ( ( $line eq '' or $line =~ /^\s+$/ ) and $content ne '' ) {
            my $info_of = App::Fasops::Common::parse_block( $content, 1 );
            $content = '';

            my @full_names;
            my $seq_refs = [];

            for my $key ( keys %{$info_of} ) {
                push @full_names, $key;
                push @{$seq_refs}, $info_of->{$key}{seq};
            }

            if ( $opt->{length} ) {
                next if length $info_of->{ $full_names[0] }{seq} < $opt->{length};
            }

            # outgroup
            my $out_seq;
            if ( $opt->{outgroup} ) {
                $out_seq = pop @{$seq_refs};
            }

            my $first_name  = $full_names[0];
            my $result      = App::Fasops::Common::multi_seq_stat($seq_refs);
            my $indel_sites = App::Fasops::Common::get_indels($seq_refs);

            $csv->print( $out_fh, [ $first_name, @{$result}, scalar( @{$indel_sites} ) ] );
        }
        else {
            $content .= $line;
        }
    }

    close $out_fh;
    $in_fh->close;
}

1;
