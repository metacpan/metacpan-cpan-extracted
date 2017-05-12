use strict;
use warnings;

# ABSTRACT: remove clutter from your news feeds


package App::Rssfilter;
{
  $App::Rssfilter::VERSION = '0.07';
}

use Moo;
extends 'App::Rssfilter::Group';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter - remove clutter from your news feeds

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    $ rssfilter runfromconfig Rssfilter.yaml

OR

    use App::Rssfilter;

    App::Rssfilter->from_yaml( <<"End_Of_Config" )->update();
    name: My Feeds
    rules:
    - Duplicates: DeleteItem
    groups:
    - name: News
      feeds:
      - Cool News: http://cool.net/latest.rss
      - Hot News: http://hot.com/top-stories.rss
      rules:
      - Category[Examples]: MarkTitle[FOR INSTANCE]
    - name: Posts
      feeds:
      - Fence Blog: http://fence.com/entries.rss
      - The Mail Man: http://mail.org/posts.rss
      rules:
      - My::Custom::Matcher: My::Custom::Filter
    End_Of_Config

=head1 DESCRIPTION

App::Rssfilter downloads RSS feeds and then applies rules to remove duplicate items. It comes with matchers to match items with certain categories & links, and filters to delete items, or add text to item titles.

You should use App::Rssfilter if you:

=over 4

=item *

have a preferred RSS reader

=item *

subscribe to multiple RSS feeds from the same publisher

=item *

the same item may appear in more than one feed from that publisher

=item *

only wish to see it once

=item *

are comfortable with running C<rssfilter> periodically

=item *

are comfortable serving filtered RSS feeds over HTTP

=back

If all of the above hold, then you can simply create a cron job to run C<rssfilter> every 15 minutes to download all your RSS feeds, and serve its output folder, and configure your RSS reader to instead use your filtered feeds instead of the occasionally-duplicated originals.

You should not use App::Rssfilter if you:

=over 4

=item *

never want to see duplicate articles

=back

The duplicate matcher is quite pessimistic, and strictly avoids false positives.

=head1 EXTENDING

=head2 Writing your own filters and matchers

To use your own code to match or filter RSS items, create a package like:

    package My::Custom::Matcher;

    sub match {
        my( $class, $item ) = @_;
        return should_match( $item );
    }

Likewise for filters.

Include it in your C<PERL5LIB>, and use your package name as the key (for matchers) or value (or filters) of a rule in your configuration:

    name: things I read
    feeds:
    - a feed: http://a.feed.url/
    rules:
    - My::Custom::Matcher: My::Custom::Filter

L<App::Rssfilter::Rule> has more examples of writing your own matching & filtering code. Note that any changes made to the item by the matcher are preserved (for the time being).

=head2 Using App::Rssfilter to fetch RSS feeds

To use App::Rssfilter in your own project, create an L<App::Rssfilter::Group>, add feeds and rules and subgroups, then call its C<update> method. To load and save feeds to something other than the file system, extend L<App::Rssfilter::Feed::Storage> & provide an instance to the C<App::Rssfilter::Group> constructor as C<storage>.

=head1 BUGS

Only the current and last-fetched RSS documents are examined when filtering, so an item may not be classified as a duplicate and thus appear in two feeds. To illustrate, consider two RSS news feeds: National, which is frequently updated and contains items from multiple regions; and Regional, which is infrequently updated and contains items from one region. If National is filtered before Regional, an item C<A> which occurs in both will (correctly) be filtered out of Regional, but as National is updated, eventually C<A> will no longer be present in either the latest version of National or the last-fetched version, and so C<A> appears in Regional.

This can be mitigated by filtering Regional before National, or by fetching the National feed less frequently.

=head1 SEE ALSO

=over 4

=item *

L<Yahoo Pipes|http://pipes.yahoo.com/pipes/>

=back

=head1 AUTHOR

Daniel Holz <dgholz@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Daniel Holz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
