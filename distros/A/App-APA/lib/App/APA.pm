# ABSTRACT: Access APA News via RSS

use v5.37.9;
use experimental qw( class try builtin );
use builtin qw( true false trim );

package App::APA;

class App::APA;

use HTTP::Tiny; # methods: get
use URI;
use XML::RSS; # methods: parse

field $uri = URI -> new( 'https://apa.az/en/rss' );

my $http = HTTP::Tiny -> new;
my $rss = XML::RSS -> new;

# TODO: Make this a private method once supported
method get_items ( ) {
  my $content = $http -> get( $uri ) -> {content}; # Hashref
  $rss -> parse( $content );
  my @items = $rss -> {items} -> @*; # Arrayref of hashrefs (keys: title, pubDate)
  return @items;
}

method uri ( ) {
  return $uri;
}


method first_item ( ) {
  my @items = $self -> get_items;
  return trim $items[0] -> {title};
}


method limit_items ( $number ) {
  my @items = $self -> get_items;
  my @number;
  for ( 0 .. $number - 1 ) {
    push @number , trim $items[$_] -> {title};
  }
  return @number;
}


method all_items ( ) {
  my @items = $self -> get_items;
  my @all;
  for my $item ( @items ) {
    push @all , trim $item -> {title};
  }
  return @all;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

App::APA - Access APA News via RSS

=head1 VERSION

version 0.230470

=head1 ATTRIBUTES

=head2 uri

Return the URL of the news website

=head1 METHODS

=head2 first_item()

Returns the first item of the recent news list

=head2 limit_items($number)

Returns the number of items specified from the recent news list

=head2 all_items($object)

Returns all items in the news list

The default limit for this is 300

$item hashref has C<pubDate>, C<category>, and C<link> keys in addition to C<title>

=head1 AUTHOR

Elvin Aslanov <rwp.primary@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Elvin Aslanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
