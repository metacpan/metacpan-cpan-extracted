use strict;
use warnings;

# ABSTRACT: remove an RSS item from its channel


package App::Rssfilter::Filter::DeleteItem;
{
  $App::Rssfilter::Filter::DeleteItem::VERSION = '0.07';
}

use Method::Signatures;


func filter ( $item, $matcher = 'no reason' ) {
    $item->replace(q{});
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::Filter::DeleteItem - remove an RSS item from its channel

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use App::Rssfilter::Filter::MarkTitle;

    use Mojo::DOM;
    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item><title>it's hi time</title><description>hi</description></item>
    <item><title>here we are again</title><description>hello</description></item>
  </channel>
</rss>
End_of_RSS

    $rss->find( 'item' )->each(
        sub {
          my $item = shift;
          if( $item =~ /hello/ ) {
            App::Rssfilter::Filter::DeleteItem::filter( $item );
          }
        }
    );

    # or with an App::Rssfilter::Rule

    use App::Rssfilter::Rule;
    App::Rssfilter::Rule->new(
        condition => sub { shift =~ m/hello/xms },
        action    => 'DeleteItem',
    )->constrain( $rss );

    # either way
    print $rss->to_xml;

    # <?xml version="1.0" encoding="UTF-8"?>
    # <rss>
    #   <channel>
    #     <item><title>it&#39;s hi time</title>hi</item>
    #   </channel>
    # </rss>

=head1 DESCRIPTION

This module will remove an RSS item from its channel. Actually, it will remove any L<Mojo::DOM> element from its parent. Use L<App::Rssfilter::Filter::MarkTitle> for a non-destructive filter.

=head1 FUNCTIONS

=head2 filter

    App::Rssfilter::Filter::DeleteItem::filter( $item, $matcher );

Removes C<$item> from its parent and discards it.

C<$matcher> is an optional string specifying the condition which caused C<$item> to be removed, and is ignored; it exists solely so that L<App::Rssfilter::Rule/constrain> can set it to the name of the condition causing the match.

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
