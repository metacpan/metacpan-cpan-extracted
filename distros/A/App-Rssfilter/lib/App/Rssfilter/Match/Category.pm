# ABSTRACT: match an RSS item by category

use strict;
use warnings;


package App::Rssfilter::Match::Category;
{
  $App::Rssfilter::Match::Category::VERSION = '0.07';
}
use Method::Signatures;
use List::MoreUtils qw( any );


func match ( $item, @bad_cats ) {
    my @categories = $item->find("category")->pluck( 'text' )->each;
    my @split_categories = map { ( / \A ( [^:]+ ) ( [:] .* ) \z /xms, $_ ) } @categories;
    my %cats = map { $_ => 1 } @split_categories;
    return List::MoreUtils::any { defined $_ } @cats{ @bad_cats };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Rssfilter::Match::Category - match an RSS item by category

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use App::Rssfilter::Match::Category;

    use Mojo::DOM;
    my $rss = Mojo::DOM->new( <<"End_of_RSS" );
<?xml version="1.0" encoding="UTF-8"?>
<rss>
  <channel>
    <item>
      <title>Jumping jackrabbit smash long jump record</title>
      <category>Sport:leporine</category>
    </item>
    <item>
      <title>Online poll proves programmers cool, successful</title>
      <category>Internet:very_real_and_official</category>
    </item>
  </channel>
</rss>
End_of_RSS

    print $_, "\n" for $rss->find( 'item' )->grep(
        sub {
            App::Rssfilter::Match::Category::match( shift, 'Sport' ) ) {
        }
    );

    # or with an App::Rssfilter::Rule

    use App::Rssfilter::Rule;
    App::Rssfilter::Rule->new(
        condition => 'Category[Sport]',
        action    => sub { print shift->to_xml, "\n" },
    )->constrain( $rss );

    # either way, prints

    # <item>
    #   <title>Jumping jackrabbit smash long jump record</title>
    #   <category>Sport:leporine</category>
    # </item>

=head1 DESCRIPTION

This module will match an RSS item if it has one or more specific category.

=head1 FUNCTIONS

=head2 match

    my $item_has_category = App::Rssfilter::Match::Category::match( $item, @categories );

Returns true if C<$item> has a category which matches any of C<@categories>. Since some RSS feeds specify categories & subcategories as 'C<main category:subcategory>', elements of C<@categories> can be:

=over 4

=item *

C<category> - this category, with any subcategory

=item *

C<category:subcategory> - only this category with this subcategory

=item *

C<:subcategory> - any category with a matching subcategory

=back

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
