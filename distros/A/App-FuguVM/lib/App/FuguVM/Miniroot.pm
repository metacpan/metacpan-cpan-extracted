# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2024 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::FuguVM::Miniroot;
our $VERSION = '0.2.0';

use Fugu::File;

# App::FuguVM::Miniroot - the OpenBSD miniroot install media.
#
# The miniroot is what the installer boots from. Its concern here is
# the install media: the file name of a version, and the cached copy.
# The mirror object holds the mirror facts: the host, the URL, the
# download and the verification. The miniroot is the boot medium, so
# no code in the guest inspects it before it runs. The host must
# therefore verify it, and the mirror does.
#
# The module caches the install media. App::FuguVM::DiskCache caches
# the disk that the installer produced. Neither is a cache of the
# other.

# $class->new($cache_dir, $proxy, $mirror):
#	The proxy can be undef. The mirror is required: it carries the
#	version, the architecture and the verification switch.
sub new ( $class, $cache_dir, $proxy, $mirror )
{
	die "App::FuguVM::Miniroot needs a mirror\n"
	    if !defined $mirror;

	my $self = bless {
		cache_dir => Fugu::File->expand_tilde($cache_dir),
		proxy     => $proxy,
		mirror    => $mirror,
	}, $class;

	return $self;
}

# $self->path:
#	Return the path to the cached miniroot image of the mirror
#	version. Return undef if the image is not cached.
sub path ($self)
{
	my $path = $self->_image_path;
	return -f $path ? $path : undef;
}

# $self->ensure:
#	Make sure that the image is available. The mirror downloads
#	and verifies it when the cache misses. Return the path on
#	success, or undef on failure with the reason in the mirror
#	error.
sub ensure ($self)
{
	my $path = $self->path;
	return $path if defined $path;

	return $self->{mirror}->ensure( 'release', $self->_image_filename );
}

# $self->url:
#	Return the mirror URL of the miniroot image. The mirror builds
#	it, so the host has one home.
sub url ($self)
{
	return $self->{mirror}->url( $self->_image_filename );
}

# $self->_image_filename:
#	Make the miniroot filename of the mirror version, for example
#	"miniroot78.img". The mirror is the one home of the version,
#	so this module holds no copy.
sub _image_filename ($self)
{
	( my $ver = $self->{mirror}->version ) =~ s/\.//g;
	return "miniroot$ver.img";
}

# $self->_image_path:
#	Return the file that the miniroot lands in.
#
#	The answer comes from the cache, not from a copy of its layout
#	here. A cache that changed where it puts a URL would otherwise
#	leave this module looking in the old place, and every run would
#	download the image again.
sub _image_path ($self)
{
	return $self->_cache->cache_path( $self->url );
}

# $self->_cache:
#	Return the cache to ask. A proxy brings its own; without one,
#	the module builds a cache over the same directory so that a
#	lookup still resolves.
sub _cache ($self)
{
	return $self->{proxy}->cache if defined $self->{proxy};

	require App::FuguVM::Proxy;
	return App::FuguVM::Proxy::Cache->new( $self->{cache_dir} );
}

1;
