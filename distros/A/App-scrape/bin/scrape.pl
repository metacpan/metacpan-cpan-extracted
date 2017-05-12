#!perl -w
use strict;
use App::scrape 'scrape';
use LWP::Simple qw(get);
use Getopt::Long;
use Pod::Usage;
use vars qw($VERSION);
$VERSION = '0.05';

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

=head1 DESCRIPTION

This program fetches an HTML page and extracts nodes
matched by XPath or CSS selectors from it.

If URL is C<->, input will be read from STDIN.

=head1 OPTIONS

=over 4

=item B<--sep>

Separator character to use for columns. Default is tab.

=item B<--uri> COLUMNS

Numbers of columns to convert into absolute URIs, if the
known attributes do not everything you want.

=item B<--no-uri>

Switches off the automatic translation to absolute
URIs for known attributes like C<href> and C<src>.

=back

=cut

GetOptions(
    'help|h' => \my $help,
    'uri:s' => \my @make_uri,
    'no-uri' => \my $no_known_uri,
    'sep:s' => \my $sep,
) or pod2usage(2);
pod2usage(1) if $help;

# make_uri can be a comma-separated list of columns to map
# The index starts at one
my %make_uri = map{ $_-1 => 1 } map{ split /,/ } @make_uri;
$sep ||= "\t";

# Now determine where we get the HTML to scrape from:
my $url = shift @ARGV;

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
my @rows = scrape($html, \@ARGV, {
    make_uri => \%make_uri,
    no_known_uri => $no_known_uri,
    base => $url,
});

for my $row (@rows) {
    print join $sep, @$row;
    print "\n";
};

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/App-scrape>.

=head1 SUPPORT

The public support forum of this program is
L<http://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2011-2011 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
