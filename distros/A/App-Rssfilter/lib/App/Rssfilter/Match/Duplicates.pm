# ABSTRACT: match an RSS item which has been seen before

use strict;
use warnings;


package App::Rssfilter::Match::Duplicates;
{
  $App::Rssfilter::Match::Duplicates::VERSION = '0.07';
}
use Method::Signatures;
use Try::Tiny;


func match ( $item ) {
    use feature 'state';
    state %prev;

    my @matchables = 
        map  { s/ [?] .* \z //xms; $_ }
        grep { $_ ne '' }
        $item->find( 'guid, link' )->pluck( 'text' )->each;

    my $res = grep { defined } @prev{ @matchables };
    @prev{ @matchables } = ( 1 ) x @matchables;
    return 0 < $res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::Match::Duplicates - match an RSS item which has been seen before

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use App::Rssfilter::Match::Duplicates;

    use Mojo::DOM;
    my $first_rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <link>http://rss.slashdot.org/~r/Slashdot/slashdot/~6/gu7UEWn8onK/is-typing-tiring-your-toes</link>
      <description>type with toes for tighter tarsals</description>
    </item>
    <item>
      <link>http://rss.slashdot.org/~r/Slashdot/slashdot/~9/lloek9InU2p/new-planet-discovered-on-far-side-of-sun</link>
      <description>vulcan is here</description>
    </item>
  </channel>
</rss>
End_of_RSS

    my $second_rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <link>http://rss.slashdot.org/~r/Slashdot/slashdot/~3/mnej39gJa9E/new-rocket-to-visit-mars-in-60-days</link>
      <description>setting a new speed record</description>
    </item>
    <item>
      <link>http://rss.slashdot.org/~r/Slashdot/slashdot/~9/lloek9InU2p/new-planet-discovered-on-far-side-of-sun</link>
      <description>vulcan is here</description>
    </item>
  </channel>
</rss>
End_of_RSS

    print "$_\n" for $first_rss->find( 'item' )->grep( \&App::Rssfilter::Match::Duplicates::match );
    print "$_\n" for $second_rss->find( 'item' )->grep( \&App::Rssfilter::Match::Duplicates::match );

    # or with an App::Rssfilter::Rule

    use App::Rssfilter::Rule;
    my $dupe_rule = App::Rssfilter::Rule->new(
        condition => 'Duplicates',
        action    => sub { print shift->to_xml, "\n" },
    );
    $dupe_rule->constrain( $first_rss );
    $dupe_rule->constrain( $second_rss );

    # either way, prints

    # <item>
    #   <link>http://rss.slashdot.org/~r/Slashdot/slashdot/~9/lloek9InU2p/new-planet-discovered-on-far-side-of-sun</link>
    #   <description>vulcan is here</description>
    # </item>

=head1 DESCRIPTION

This module will match RSS items if either the GUID or link of the item have been seen previously.

=head1 FUNCTIONS

=head2 match

    my $item_seen_before = App::Rssfilter::Match::Duplicate::match( $item );

Returns true if C<$item> has a GUID or link which matches a previously-seen GUID or link. Query strings in links and GUIDs will be ignored for the purposes of matching a previous link.

=head1 SEE ALSO

=over 4

=item *

L<App::Rssfilter>

=item *

L<App::Rssfilter::Rule>

=back

=head1 AUTHOR

Daniel Holz <dgholz@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Daniel Holz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
