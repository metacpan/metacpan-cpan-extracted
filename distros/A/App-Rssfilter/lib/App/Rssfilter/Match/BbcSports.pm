# ABSTRACT: match a BBC sport RSS item

use strict;
use warnings;


package App::Rssfilter::Match::BbcSports;
{
  $App::Rssfilter::Match::BbcSports::VERSION = '0.07';
}
use Method::Signatures;


func match ( $item ) {
    return $item->guid->text =~ qr{ www [.] bbc [.] co [.] uk / sport [1]? / }xms;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::Match::BbcSports - match a BBC sport RSS item

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use App::Rssfilter::Match::BbcSports;

    use Mojo::DOM;
    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <guid>http://www.bbc.co.uk/sport/some_article</guid>
      <description>here is an article about a sporting event</description>
    </item>
    <item>
      <guid>http://www.bbc.co.uk/tech/new_rss_tool_changes_how_we_read_news</guid>
      <description>here is an article about an rss tool</description>
    </item>
  </channel>
</rss>
End_of_RSS

    print $_, "\n" for $rss->find( 'item' )->grep( \&App::Rssfilter::Match::BbcSports::match );

    # or with an App::Rssfilter::Rule

    use App::Rssfilter::Rule;
    App::Rssfilter::Rule->new(
        condition => 'BbcSports',
        action    => sub { print shift->to_xml, "\n" },
    )->constrain( $rss );

    # either way, prints
    
    # <item>
    #   <guid>http://www.bbc.co.uk/tech/new_rss_tool_changes_how_we_read_news</guid>
    #   <description>here is an article about an rss tool</description>
    # </item>

=head1 DESCRIPTION

This module will match items from BBC RSS feeds which are about sporting events.

=head1 FUNCTIONS

=head2 match

    my $item_is_BBC_sport = App::Rssfilter::Match::BbcSports::match( $item );

Returns true if ther GUID of C<$item> looks like a BBC sport GUID (like C<http://www.bbc.co.uk/sport>).

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
