package DemoPanda;
use strict;
use warnings;
use CGI::Portable;

sub main {
	my ($class, $globals) = @_;
	$globals->set_page_body( <<__endquote );
<P>Food: @{[$globals->pref( 'food' )]}
<BR>Color: @{[$globals->pref( 'color' )]}
<BR>Size: @{[$globals->pref( 'size' )]}</P>
<P>Now let's look at some files; take your pick:
__endquote
	$globals->navigate_url_path( $globals->pref( 'file_reader' ) );
	foreach my $frag (@{$globals->pref( 'files' )}) {
		my $url = $globals->url_as_string( $frag );
		$globals->append_page_body( "<BR><A HREF=\"$url\">$frag</A>" );
	}
	$globals->append_page_body( "</P>" );
}

1;
