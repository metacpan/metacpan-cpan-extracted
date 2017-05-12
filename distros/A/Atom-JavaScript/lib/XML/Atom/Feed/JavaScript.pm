package XML::Atom::Feed::JavaScript;

use strict;
use warnings;
use base qw( XML::Atom::Feed );

our $VERSION = 0.5;

=head1 NAME

XML::Atom::Feed::JavaScript - Atom syndication with JavaScript 

=head1 SYNOPSIS

    ## get an Atom feed from the network

    use XML::Atom::Client
    use XML::Atom::Feed::JavaScript;

    my $client = XML::Atom::Client->new();
    my $feed = $client->getFeed( 'http://example.com/atom.xml' );
    print $feed->asJavascript();

    ## or get an atom feed from disk

    use XML::Atom::Feed::JavaScript;

    my $feed = XML::Atom::Feed->new( Stream => 'atom.xml' );
    print $feed->asJavascript();

=head1 DESCRIPTION

XML::Atom::Feed::JavaScript exports an additional function into the XML::Atom
package for outputting Atom feeds as javascript. 

=head1 FUNCTIONS 

=head2 asJavascript()

Returns a XML::Atom::Feed object as a string of JavaScript code. If 
you want to limit the amount of entries you can pass in an integer argument:

    ## limit to first 10 entries
    my $javascript = $feed->asJavascript( 10 );

=cut

sub XML::Atom::Feed::asJavascript {
	my ( $feed, $max ) = @_ or die q( can't get feed );

	my @entries = $feed->entries();
	my $items   = scalar @entries;

	if ( not $max or $max > $items ) { $max = $items; }

	## open javascript section
	my $output = _jsPrint( '<div class="atom_feed">' );
	$output   .= _jsPrint( '<div class="atom_feed_title">' . 
	    $feed->title() . '</div>' );

	## open our list
	$output .= _jsPrint( '<ul class="atom_item_list">' );

	## generate content for each item
	foreach my $item ( @entries[ 0..$max - 1 ] ) {
		my $link  = $item->link->href();
		my $title = $item->title();
		my $desc  = $item->content->body();
		my $data  = <<"JAVASCRIPT_TEXT";
<li class="atom_item">
<span class="atom_item_title">
<a class="atom_item_link" href="$link">$title</a>
</span>
<span class="atom_item_desc">$desc</span>
</li>
JAVASCRIPT_TEXT
		$output .= _jsPrint( $data );
	}
	
	## close our item list, and return 
	$output .= _jsPrint( '</ul>' );
	$output .= _jsPrint( '</div>' );
	return $output;
} 


sub _jsPrint { 
    my $string = shift;
    $string =~ s/"/\\"/g;
    $string =~ s/'/\\'/g;
    $string =~ s/\n//g;	
    return( "document.write('$string');\n" );
}

=head1 AUTHORS

=over 4

=item David Jacobs <globaldj@mac.com>

=item Ed Summers <ehs@pobox.com>

=item Brian Cassidy <bricas@cpan.org>

=back

=cut
  
1;
