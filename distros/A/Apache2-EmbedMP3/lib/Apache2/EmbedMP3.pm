=head1 NAME

Apache2::EmbedMP3 - Embed MP3 audio files into a templated web interface
using WP Audio Player.

=head1 SYNOPSIS

On your Apache configuration file:

 <Files ~ "\.mp3$">
   SetHandler modperl
   PerlSetVar wpaudioplayer /audio-player/player.swf
   PerlSetVar wpaudioplayer_js /audio-player/wpaudioplayer.js
   PerlResponseHandler Apache2::EmbedMP3
 </Files>

If you want to restrict only a certain directory to serve MP3s using
C<Apache2::EmbedMP3>, you can wrap the C<Files> declaration on a
C<Directory> block. For more information, take a look at excellent
Apache2's documentation.

By default, you have to have C</wpaudioplayer.swf> and C</wpaudioplayer.js>
accessible on your webserver. You can download WP Audio Player from
L<http://wpaudioplayer.com/>, you only need the main JS file and the SWF.
WP Audio Player is a nice GPL product.

However, as specified on the SYNOPSIS, you can override these default behavior
and C<PerlSetVar> C<wpaudioplayer> and C<wpaudioplayer_js> to point
wherever you'd have them.

That's it. Just go to any MP3 file within your web server. With that
setup, C<Apache2::EmbedMP3> will use a default template.

=head1 TEMPLATING

Take a look at the default template located at example/template.tt.
That is not the real file used by this module but it's a verbatim copy.
The file is placed there just as an example so you can make
your own template without too much internal poking.

Once you have your own template, just C<PerlSetVar> it to the handler:

 <Files ~ "\.mp3$">
   SetHandler modperl
   PerlSetVar template /path/to/my/template.tt
   PerlResponseHandler Apache2::EmbedMP3
 </Files>

A more complete example:

 <Files ~ "\.mp3$">
   SetHandler modperl
   PerlSetVar template /path/to/my/template.tt
   PerlSetVar wpaudioplayer /somewhere/wpaudioplayer.swf
   # or...
   PerlSetVar wpaudioplayer_js http://my.other.server/rocks/wpaudioplayer.js
   PerlResponseHandler Apache2::EmbedMP3
</Files>

I believe it's pretty obvious that the templating system used and
required is L<Template::Toolkit>. Wherever you want to embed the player
within, just call: C<[% player %]>.

=head1 DESCRIPTION

C<Apache2::EmbledMP3> has been already described on the previous section
:-)

However...

C<Apache2::EmbedMP3> enables Apache to show MP3 files using WP Audio Player. 
This will ease any deployment of MP3 galleries you'd need to do
since you could just put the MP3s on an Apache accessible location, and
they will be presented on a proper way to your final user.

Additionally, the following information for the files is available:

=over

=item * artist

=item * title

=item * album name

=item * album year

=item * lyrics!

=back

These are presented by the default template and you can use them too
on your own templates. This information is possible by using L<Music::Tag::MP3>.

=head1 DEPENDENCIES

=over

=item * L<Music::Tag::MP3>

=item * L<Music::Tag::Lyrics>

=back

=head1 SEE IT IN ACTION

You can see it in action here: L<http://dev.axiombox.com/~david/mp3/>.

=head1 WORDPRESS AUDIO PLAYER

Find the WP Audio Player distribution on L<http://wpaudioplayer.com/>. It is a nice
little GPL audio player.

=head1 DOWNLOAD

Download it at CPAN: L<http://search.cpan.org/~damog>.

=head1 PROJECT

Code is hosted at L<http://github.com/damog/apache2-embedmp3>.

=head1 AUTHOR

David Moreno <david@axiombox.com>, L<http://damog.net/>.
Some other similar projects are announced on the Infinite Pig
Theorem blog: L<http://log.damog.net>.

=head1 SEE ALSO

L<Apache2::EmbedFLV>.

=head1 BUGS

Apparently, there's a bug if the filename of your MP3 contains spaces.
This will be tracked later.

=head1 THANKS

=over

=item * Raquel Hernandez, L<http://maggit.net>, who made the default template.

=back

=head1 COPYRIGHT

Copyright (C) 2009 by David Moreno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Apache2::EmbedMP3;

our $VERSION = '0.1';

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Util ();
use Apache2::Const -compile => qw/OK :common DIR_MAGIC_TYPE/;
use Apache2::EmbedMP3::Template;
use Data::Dumper;
use Cwd;
use Music::Tag;
use Digest::MD5 qw/md5_hex/;

sub handler {
	my($r) = shift;

	if(! -e $r->filename) {
		return Apache2::Const::NOT_FOUND;
	} elsif(! -r $r->filename) {
		return Apache2::Const::FORBIDDEN;
	} else {
		my $req = Apache2::Request->new($r);

		if(
				# let's face it, this is why Perl sucks
				$req->param and
				scalar keys %{$req->param} == 1 and
				not $req->param( ${ [ keys %{$param} ] }[0] ) and
				length ${ [ keys %{$req->param} ] }[0] == 32
		) {
			my($md5) = keys %{$req->param}; # not too intuitive
			if($md5 eq md5_hex($r->filename)) {
				$r->content_type("audio/mpeg");
				$r->headers_out->set("Content-Length" => -s $r->filename);
				open my $fh, "<", $r->filename or die "Apache2::EmbedMP3 wrong $!!";
				while(<$fh>) {
					$r->print($_);
				}
				close $fh;
				return Apache2::Const::OK;
			} else {
				return Apache2::Const::FORBIDDEN;
			}
		} else {
			my $md5 = md5_hex($r->filename);
			$r->content_type("text/html; charset=utf-8");

			my $template = $r->dir_config('template');
			my $wpaudioplayer = $r->dir_config("wpaudioplayer");

			my $t = Apache2::EmbedMP3::Template->new($template);
			my $info = Music::Tag->new($r->filename);
			$info->add_plugin("Lyrics");
			$info->get_tag();

			$r->print(
				$t->process(
					uri => $r->uri,
					md5 => $md5,
					wpaudioplayer => $r->dir_config("wpaudioplayer"),
					js => $r->dir_config("wpaudioplayer_js"),
					template => $template,
					lyrics => $info->lyrics,
					title => $info->title,
					artist => $info->artist,
					year => $info->year,
					album => $info->album,
				)
			);

			return Apache2::Const::OK;
		}
	}
}

1;

__END__
Hello! Your md5 cookie is [% md5 %]

