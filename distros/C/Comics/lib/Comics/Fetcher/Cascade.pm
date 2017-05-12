#! perl

use strict;
use warnings;
use utf8;
use Carp;

package Comics::Fetcher::Cascade;

our $VERSION = "1.00";

=head1 NAME

Comics::Fetcher::Cascade -- Cascading url grabber

=head1 SYNOPSIS

  package Comics::Plugin::Sigmund;
  use parent qw(Comics::Fetcher::Cascade);

  our $name    = "Sigmund";
  our $url     = "http://www.sigmund.nl/";
  our @patterns = ( [ qr{ ... (?<url>...) ... },
                      qr{ ... (?<url>...) ... },
                      ...
                      qr{ ... (?<url>...) ... } ],
                  );

  # Return the package name.
  __PACKAGE__;

=head1 DESCRIPTION

The C<Cascading> Fetcher can use one or more patterns to determine the
URL of the desired image. If multiple patterns are supplied, each
pattern is applied to the fetched page and must define the url for the
next page as a named capture. The process is repeated, and the final
pattern has to provide the final url and image name.

The Fetcher requires the common package variables:

=over 8

=item $name

The full name of this comic, e.g. "Fokke en Sukke".

=item $url

The url of this comic's starting (i.e. home) page.

=back

Fetcher specific arguments:

This Fetcher requires either C<$path> (direct URL fetch), C<$pattern>
(single fetch), or C<@patterns> (cascading fetch).

=over 8

=item $path

The URL of the desired image.

If I<path> is not an absolute URL, it will be interpreted relative to
the I<url>.

=item $pattern

A pattern to locate the image URL from the starting page.

=item @patterns

An array with patterns to locate the image URL.

When a pattern matches, it must define the named capture C<url>, which
points to the page to be loaded and used for the next pattern.

=back

Any of the patterns may additionally define:

=over 8

=item title

The image title.

=item alt

The alternative text.

=back

=cut

use parent qw(Comics::Fetcher::Base);

sub fetch {
    my ( $self ) = @_;
    my $state = $self->{state};
    my $pats  = $self->{patterns} || [ $self->{pattern} ];
    my $name  = $self->{name};
    my $url   = $self->{url};
    my $tag   = $self->{tag};
    delete $state->{fail};

    my ( $image, $title, $alt ) = @_;

    my $referer = "comics.html";
    if ( $self->{path} ) {
	$url = $self->urlabs( $url, $self->{path} );
    }
    else {
	my $pix = 0;
	my $data;
	foreach my $pat ( @$pats ) {
	    $pix++;

	    $state->{trying} = $url;
	    ::debug("Fetching page $pix $url");
	    $::ua->default_header( Referer => $referer );
	    my $res = $::ua->get($url);
	    unless ( $res->is_success ) {
		$self->{fail} = "Not found", return if $self->{optional};
		die($res->status_line);
	    }

	    $data = $res->content;
	    unless ( $data =~ $pat ) {
		$self->{fail} = "No match", return if $self->{optional};
		# Save a copy of the failed data.
		$self->save_html( ".$tag.html", $data ) if ::debugging();
		die("FAIL: pattern $pix not found");
	    }

	    $url = $self->urlabs( $url, $+{url} );
	    unless ( $url ) {
		die("FAIL: pattern $pix not found");
	    }

	    # Other match data expected:
	    $title = $+{title} if $+{title};
	    $alt   = $+{alt}   if $+{alt};

	    $referer = $url;
	}

        unless ( $title ) {
	    $title = $1 if $data =~ /<title>(.*?)<\/title>/;
	    $title ||= $name;
	}
    }

    $alt ||= $tag;
    $title ||= $name;

    my $etag = $state->{etag} || "None";
    $state->{trying} = $url;
    ::debug("Fetching image $url (ETag: $etag)");
    $::ua->default_header( Referer => $referer );
    $::ua->default_header( "If-None-Match" => $etag );
    my $res = $::ua->get($url);
    unless ( $res->is_success ) {
	$state->{fail} = $res->status_line;
	if ( $state->{fail} =~ /304 Not Modified/ ) {
	    ::debug("Not fetching: Up to date $url");
	    $::stats->{uptodate}++;
	    delete( $state->{trying} );
	    return $state;
	}
	die("FAIL (image): ", $state->{fail});
    }

    my $data = $res->content;
    my $info;
    if ( !$data or !($info = Image::Info::image_info(\$data)) ) {
	die("FAIL: image no data");
    }
    $state->{etag} = $res->header('etag');
    my $md5 = Digest::MD5::md5_base64($data);
    if ( $state->{md5} and $state->{md5} eq $md5 ) {
	::debug("Fetching: Up to date $url");
	$::stats->{uptodate}++;
	delete( $state->{trying} );
	return $state;
    }

    if ( $state->{c_img}
	 and my $oldimg = $self->spoolfile( $state->{c_img} ) ) {
	unlink($oldimg)
	  && ::debug("Removed: $oldimg");
    }

    unless ( $tag && $info->{file_ext} ) {
	use Data::Dumper;
	warn($tag, ": ", Dumper($info));
    }
    my $img = sprintf( "%s-%06x.%s", $tag,
		       int(rand(0x1000000)), $info->{file_ext} );
    $state->{c_width}  = $info->{width};
    $state->{c_height} = $info->{height};

    $self->save_image( $img, \$data );

    $state->{update} = time;
    $state->{md5} = $md5;
    delete( $state->{trying} );

    $state->{c_alt} = $alt;
    $state->{c_title} = $title;
    $state->{c_img} = $img;

    my $html = "$tag.html";
    $self->save_html($html);

    $state->{url} = $url;

    return 1;
}

1;
