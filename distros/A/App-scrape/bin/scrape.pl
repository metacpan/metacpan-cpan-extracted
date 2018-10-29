#!perl -w
use strict;
use App::scrape 'scrape';
use List::MoreUtils 'zip';
use LWP::Simple qw(get);
use Getopt::Long;
use Pod::Usage;
our $VERSION = '0.08';

=head1 NAME

scrape.pl - simple HTML scraping from the command line

=head1 ABSTRACT

This is a simple program to extract data from HTML by
specifying CSS3 or XPath selectors.

=head1 SYNOPSIS

    scrape.pl URL selector selector ...

    # Print page title
    scrape.pl http://perl.org title
    # The Perl Programming Language - www.perl.org

    # Print links with titles, make links absolute
    scrape.pl http://perl.org a //a/@href --uri=2

    # Print all links to JPG images, make links absolute
    scrape.pl http://perl.org a[@href=$"jpg"]

    # print JSON about Amazon prices
    scrape.pl https://www.amazon.de/dp/0321751043
        --format json
        --name "title" #productTitle
        --name "price" #priceblock_ourprice
        --name "deal" #priceblock_dealprice

    # print JSON about Amazon prices for multiple products
    scrape.pl --format json
        --url https://www.amazon.de/dp/B01J90P010
        --url https://www.amazon.de/dp/B01M3015CT
        --name "title" #productTitle
        --name "price" #priceblock_ourprice
        --name "deal" #priceblock_dealprice

=cut

GetOptions(
    'help|h'      => \my $help,
    'uri:s'       => \my @make_uri,
    'no-uri'      => \my $no_known_uri,
    'sep:s'       => \my $sep,
    'format:s'    => \my $format,
    'name:s'      => \my @column_names,
    'url:s'       => \my @urls,
    'keep-url:s'  => \my $url_field,
) or pod2usage(2);
pod2usage(1) if $help;

$format ||= 'csv';

# make_uri can be a comma-separated list of columns to map
# The index starts at one
my %make_uri = map{ $_-1 => 1 } map{ split /,/ } @make_uri;
$sep ||= "\t";

# Now determine where we get the HTML to scrape from:
if( ! @urls ) {
    @urls = shift @ARGV;
};

my $args;
if( @ARGV ) {
    # we need columns here
    @column_names == @ARGV
        or die "Different number of column names and column expressions";

    $args = +{ zip @column_names, @ARGV };

} else {
    $args = \@ARGV;
}

my @rows;

for my $url ( @urls ) {
    my $html;
    if ($url eq '-') {
        # read from STDIN
        local $/;
        $html = <STDIN>;
    } else {
        $html = get $url;
    };

    # now fetch all "rows" from the page. We do this once to avoid
    # fetching a page multiple times
    push @rows, scrape($html, $args, {
        make_uri     => \%make_uri,
        no_known_uri => $no_known_uri,
        base         => $url,
        url_field    => $url_field,
    });
};

if( 'json' eq $format ) {
    require JSON;
    print JSON::encode_json(\@rows);

} else {
    require Text::CSV_XS;
    Text::CSV_XS->import('csv');
    csv( in => \@rows, out => \*STDOUT, sep_char => $sep );
};

=head1 DESCRIPTION

This program fetches an HTML page and extracts nodes
matched by XPath or CSS selectors from it.

If URL is C<->, input will be read from STDIN.

=head1 OPTIONS

=over 4

=item B<--format>

Output format, the default is C<csv>. Valid values are C<csv> or C<json>.

=item B<--url>

URL to fetch. This can be given multiple times to fetch multiple URLs in
one run. If this is not given, the first argument on the command line will be
taken as the only URL to be fetched.

=item B<--keep-url>

Add the fetched URL as another column with the given name in the output.
If you use CSV output, the URL will always be in the first column.

=item B<--name>

Name of the output column.

=item B<--sep>

Separator character to use for columns. Default is tab.

=item B<--uri> COLUMNS

Numbers of columns to convert into absolute URIs, if the
known attributes do not everything you want.

=item B<--no-uri>

Switches off the automatic translation to absolute
URIs for known attributes like C<href> and C<src>.

=back

=head1 REPOSITORY

The public repository of this module is
L<http://github.com/Corion/App-scrape>.

=head1 SUPPORT

The public support forum of this program is
L<http://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2011-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
