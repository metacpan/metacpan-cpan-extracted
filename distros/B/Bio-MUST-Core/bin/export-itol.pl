#!/usr/bin/env perl
# PODNAME: export-itol.pl
# ABSTRACT: Download formatted trees from iTOL
# CONTRIBUTOR: Valerian LUPO <valerian.lupo@uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use Smart::Comments '###';

use Config::Any;
use HTTP::Request::Common;
use LWP::UserAgent;

use Bio::MUST::Core;
use Bio::MUST::Core::Constants qw(:files);
use Bio::MUST::Core::Utils qw(change_suffix insert_suffix);


my $download_url = "https://itol.embl.de/batch_downloader.cgi";

my $suffix_like = qr{ \bsvg\b | \bpdf\b | \beps\b | \bps\b | \bpng\b
    | \bnewick\b | \bnexus\b | \bphyloxml\b }xms;

FILE:
for my $infile (@ARGV_infiles) {

    ### Processing: $infile
    my $id_for = read_tree_ids($infile);

    # determine config file (global or infile-dependent)
    $infile =~ s/$_//xms for @ARGV_in_strip;
    my $cfgfile = $ARGV_config ? $ARGV_config : change_suffix($infile, '.ini');

    ### config file: $cfgfile
    my $config = Config::Any->load_files( {
        files           => [ $cfgfile ],
        flatten_to_hash => 1,
        use_ext         => 1,
     } );

    my %param_for = %{ $config->{$cfgfile} };

    if ($param_for{'format'} !~ $suffix_like) {
        warn <<"EOT";
Warning: unspecified or invalid output format: $param_for{format}; skipping!
EOT
        next FILE;
    }

    TREE:
    while ( my ($outfile, $tree) = each %{$id_for} ) {

        unless ($outfile && $tree) {
            warn <<'EOT';
Warning: missing tree filename or id; skipping!
EOT
            next TREE;
        }

        $outfile .= q{.} . $param_for{'format'};
        $outfile  = insert_suffix($outfile, $ARGV_out_suffix)
            if $ARGV_out_suffix;
        $param_for{'outFile'} = $outfile;

        $param_for{'tree'   } = $tree;

        # submit the data
        my $ua = LWP::UserAgent->new();
        $ua->agent("iTOLbatchDownloader5.0");
        my $request = POST $download_url,
            Content_Type => 'form-data', Content => [ %param_for ];
        my $response = $ua->request($request);

        message( $response, $param_for{'outFile'} )
    }
}


sub read_tree_ids {
    my $infile = shift;

    open my $in, '<', $infile;

    my %id_for;

    LINE:
    while (my $line = <$in>){
        chomp $line;

        # skip empty lines and process comments
        next LINE if $line =~ $EMPTY_LINE
                  || $line =~ $COMMENT_LINE;

        # Note: var names after import-itol.pl
        my ($file, $tree_id) = split /\t/xms, $line;
        $id_for{$file} = $tree_id;
    }

    return \%id_for;
}

# TODO: use standard BMC error message scheme
sub message {
    my $response = shift;
    my $outfile  = shift;

    if ( $response->is_success() ) {
        my @res = split /\n/xms, $response->content;

        # check for export error
        if ($response->header('Content-type') =~ /text\/html/xms) {
            warn <<"EOT";
Warning: export failed. iTOL returned the following error message:
$res[0]
EOT
        }

        # if no warnings, export tree to outfile
        else {
            ### Exporting tree to: $outfile
            open my $out, '>', $outfile;
            say {$out} join "\n", @res;
        }
    }

    else {
        warn <<"EOT";
Warning: iTOL returned a web server error; full message follows:
EOT
        print $response->as_string;
    }

    return;
}

__END__

=pod

=head1 NAME

export-itol.pl - Download formatted trees from iTOL

=head1 VERSION

version 0.251810

=head1 USAGE

    export-itol.pl <infiles> [optional arguments]

=head1 REQUIRED ARGUMENTS

This script is based on C<iTOL_downloader.pl>.

=over

=item <infiles>

Path to input TSV tree id files [repeatable argument].

Such files are generated when uploading trees with the script L<import-itol.pl>.

=for Euclid: infiles.type: readable
    repeatable

=back

=head1 OPTIONS

=over

=item --config=<file>

Path to input INI config file. When not specified, INI config files must have
the same basename as C<infiles> (but see C<--in-strip> below) [default: none].

A config file requires at least the C<format> argument. Supported outfile
formats are: C<svg>, C<pdf>, C<eps>, C<ps>, C<png>, C<newick>, C<nexus> and
C<phyloxml>.

To display all optional parameters and values, see iTOL help page:
L<https://itol.embl.de/help.cgi#bExOpt>

An example of INI config file follows:

    format=svg
    dpi=300
    display_mode=2
    current_font_name=Courier
    datasets_visible=3
    range_mode=2
    include_ranges_legend=1

=for Euclid: file.type: readable

=item --in[-strip]=<str>

Substring(s) to strip from infile basenames before attempting to derive INI
infiles [default: none].

=for Euclid: str.type: string
    repeatable

=item --out[-suffix]=<suffix>

Suffix to append to tree file basenames for deriving outfile names [default:
none].

=for Euclid: suffix.type: string

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Valerian LUPO

Valerian LUPO <valerian.lupo@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
