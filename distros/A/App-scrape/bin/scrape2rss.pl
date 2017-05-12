#!perl -w
use strict;
use App::scrape 'scrape';
use LWP::Simple qw(get);
use Getopt::Long;
use Pod::Usage;
use XML::Atom::SimpleFeed;
use Time::Piece;
use vars qw($VERSION);
$VERSION = '0.05';

=head1 NAME

scrape2rss.pl - extract information as RSS (well, Atom) feed

=head1 ABSTRACT

This is a simple program to extract data from HTML by
specifying CSS3 or XPath selectors.

=head1 SYNOPSIS

    scrape2rss.pl URL OPTIONS

    scrape2rss.pl
        http://conferences.yapceurope.org/gpw2011/news
        --feed-title "GPW 2011 Atom Feed"
        --title "h3 a"
        --summary "h3+p+p"
        --permalink "h3 a@href"
        --date "h3+p em"
        --date-fmt "%d/%m/%y %H:%M"
        -o gpw2011.de.atom 

=head1 DESCRIPTION

This program fetches an HTML page and creates
an RSS feed from it. The elements that are turned
into the RSS feed are specified as CSS or XPath selectors.

If the URL is C<->, input will be read from STDIN.

=head1 OPTIONS

=over 4

=item B<--title>

Selector for the entry title

=item B<--summary>

Selector for the entry summary

=item B<--permalink>

Selector for the entry permalink

=item B<--pages>

Selector for the pagination links to follow

=item B<--date>

Selector for the entry publication date

=item B<--date-fmt>

C<sprintf> format that the entry publication date is in
for conversion into a proper Atom timestamp

=item B<--outfile>

Name of the output file

Default is STDOUT

=item B<--debug>

Output information in clear text

=back

=cut

GetOptions(
    'help|h' => \my $help,
    'feed-url|b:s' => \my $feed_url,
    'feed-title|f:s' => \my $feed_title,
    'title|t:s' => \my $title,
    'summary|s:s' => \my $summary,
    'permalink|l:s' => \my $permalink,
    'pages|p:s' => \my $pages,
    'date:s' => \my $date,
    'date-fmt:s' => \my $date_fmt,
    'category|c:s' => \my $category,
    'outfile|o:s' => \my $outfile,
    'debug|d' => \my $debug,
) or pod2usage(2);
pod2usage(1) if $help;

die "No URL given.\n"
    unless @ARGV;

$feed_url ||= $outfile || 'feed.atom';
$feed_title ||= 'Atom feed';
$category ||= '';

my $updated = Time::Piece->gmtime->strftime('%Y-%m-%dT%H:%M:%SZ');

my $feed = XML::Atom::SimpleFeed->new(
    title   => $feed_title,
    link    => $feed_url,
    link    => { rel => 'self', href => $feed_url, },
    author  => 'scrape2rss',
    id      => $feed_url,
    updated => $updated,
);

my %seen;
while (@ARGV) {
    my $url = shift @ARGV;
    next if $seen{ $url }++;
    
    my $html;
    if ($url eq '-') {
        # read from STDIN
        local $/;
        $html = <>;
    } else {
        $html = get $url;
    };
    
    do_scrape($feed, $url, $html);
    
    if ($pages) {
        my @pagination = scrape( $html,
            { page => $pages },
            { base => $url },
        );
        push @ARGV, grep { !$seen{ $_ }} map {  $_->{page} } @pagination;
    };
};

if ($outfile) {
    open STDOUT, '>', $outfile
        or die "Couldn't create '$outfile': $!";
};
    
print $feed->as_string;

sub do_scrape {
    my ($feed, $url, $html) = @_;

    my @fields;

    my @rows = scrape($html, {
            summary => $summary,
            permalink => $permalink,
            title => $title,
            date => $date,
            #category => $category,
        }, {
        base => $url,
    });

    for my $item (@rows) {
        my $item_updated = $item->{date} || $updated;
        
        # Now, extract the information, just in case there is "garbage"
        # around the string
        (my $extr = $date_fmt) =~ s!%\w!\\d+!g;
        $extr = qr/($extr)/;
        
        if ($item_updated =~ /$extr/) {
            $item_updated = $1;
        } else {
            warn "Is [$updated] a valid date?\n";
            $item_updated = $updated;
        };
        
        my $ts = Time::Piece->strptime( $item_updated, $date_fmt );
        $updated = $ts->strftime('%Y-%m-%dT%H:%M:%SZ');

        my $enc_url = $item->{permalink};
        
        my %info = (
            title     => $item->{title},
            link      => $enc_url,
            id        => $enc_url,
            summary   => $item->{summary},
            updated   => $item_updated,
            category  => ($item->{category} || $category),
        );
        
        if ($debug) {
            for (sort keys %info) {
                printf "%10s : %s\n", $_, $info{ $_ };
            };
        };
            
        # beware. XML::Atom::SimpleFeed uses warnings => fatal,
        # so all warnings within it die.
        $feed->add_entry(%info);
    };
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
