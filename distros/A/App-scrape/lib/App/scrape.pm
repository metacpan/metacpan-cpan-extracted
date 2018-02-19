package App::scrape;
use strict;
use URI;
use HTML::TreeBuilder::XPath;
use HTML::Selector::XPath 'selector_to_xpath';
use Exporter 'import';

our $VERSION = '0.06';

our @EXPORT_OK = qw<scrape>;

=head1 NAME

App::scrape - simple HTML scraping

=head1 ABSTRACT

This is a simple module to extract data from HTML by
specifying CSS3 or XPath selectors.

=head1 SYNOPSIS

    use App::scrape 'scrape';
    use LWP::Simple 'get';
    use Data::Dumper;

    my $html = get('http://perlmonks.org');
    my @posts = scrape(
        $html,
        ['a','a@href'],
        {
            absolute => [qw[href src rel]],
            base => 'http://perlmonks.org',
        },
    );
    print Dumper \@posts;

    my @posts = scrape(
        $html,
        {
          title => 'a',
          url   => 'a@href',
        },
        {
            absolute => [qw[href src rel]],
            base => 'http://perlmonks.org',
        },
    );
    print Dumper \@posts;

=head1 DESCRIPTION

This module implements yet another scraping engine
to extract data from HTML.

This engine does not (yet) support nested data
structures. For an engine that supports nesting, see
L<Web::Scraper>.

=cut

sub scrape {
    my ($html, $selectors, $options) = @_;

    $options ||= {};
    my $delete_tree;
    if (! ref $options->{tree}) {
        $options->{tree} = HTML::TreeBuilder::XPath->new;
        $options->{tree}->parse($html);
        $options->{tree}->eof;
        $delete_tree = 1;
    };
    my $tree = $options->{tree};

    $options->{make_uri} ||= {};
    my %make_uri = %{$options->{make_uri}};

    # now fetch all "rows" from the page. We do this once to avoid
    # fetching a page multiple times
    my @rows;

    my %known_uri = (
        'href' => 1, # a@href
        'src'  => 1, # img@src , script@src
    );

    my @selectors;
    if (ref $selectors eq 'ARRAY') {
        @selectors = @$selectors
    } else {
        @selectors = map { $selectors->{ $_ } } sort keys %$selectors;
    };

    my $rowidx=0;
    my $found_max = 0;
    for my $selector (@selectors) {
        my ($attr);
        my $s = $selector;
        if ($selector =~ s!/?\@(\w+)$!!) {
            $attr = $1;
        };
        if ($selector !~ m!^\.?/!) {
            $selector = selector_to_xpath( $selector );
        };
        # We always make the selector relative to the current node:
        $selector = ".$selector" unless $selector =~ /^\./;
        my @nodes;
        if (! defined $attr) {
            @nodes = map { $_->as_trimmed_text } $tree->findnodes($selector);
        } else {
            $make_uri{ $rowidx } ||= (($known_uri{ lc $attr }) and ! $options->{no_known_uri});
            @nodes = $tree->findvalues("$selector/\@$attr");
        };
        if ($make_uri{ $rowidx }) {
            @nodes = map { URI->new_abs( $_, $options->{base} )->as_string } @nodes;
        };
        if( $found_max < @nodes) {
            $found_max = @nodes
        };
        push @rows, \@nodes;
        $rowidx++;
    };

    # Now convert the result from rows to columns
    my @result;
    for my $idx (0.. $found_max-1) {
        push @result, [ map {
                $rows[$_]->[$idx]
        } 0..$#rows ];
    };

    # Now check what the user wants, array or hash:
    if( ref $selectors eq 'HASH') {
        @result = map {
                my $arr = $_;
                my $i = 0;
                my @keys = sort { $a cmp $b } keys( %$selectors );
                $_ = +{
                    map { $_ => $arr->[$i++] } @keys
                };
            } @result
    };

    $tree->delete
        if $delete_tree;
    @result
};

=head1 SEE ALSO

L<Web::Scraper> - the scraper inspiring this module

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
