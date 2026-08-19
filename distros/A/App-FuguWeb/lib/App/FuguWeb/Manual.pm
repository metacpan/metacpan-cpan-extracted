# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
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

package App::FuguWeb::Manual;
our $VERSION = '0.1.1';

use Fugu::File;

# App::FuguWeb::Manual - one manual source.
#
# A manual is an mdoc(7) page or a POD sidecar. The class answers the
# five questions that the build and the index ask about one: where it
# is, what it is called, which section it belongs to, which page it
# becomes, and what it is for.
#
# The class never retypes a description. The source page is the only
# copy, and the method reads it.

# The section of a POD sidecar. A Perl module manual is 3p everywhere.
use constant POD_SECTION => '3p';

# $class->from_mdoc($path, $group):
#	One mdoc source. The file extension gives the section, and the
#	group namespace prefixes the name: man/fugu/Daemon.3p is the
#	source of Fugu::Daemon(3p).
sub from_mdoc ( $class, $path, $group )
{
	my $base = $path =~ s{^.*/}{}r;
	my ( $stem, $section ) = $base =~ /^(.*)\.([^.]+)$/;

	my $namespace = defined $group ? $group->namespace : undef;

	return bless {
		path    => $path,
		name    => ( $namespace // '' ) . ( $stem // $base ),
		section => $section // '',
		group   => $group,
	}, $class;
}

# $class->from_pod($path, $group, $module_root):
#	One POD sidecar. The name is the path below the module root,
#	with the separators turned into the Perl ones:
#	lib/App/OpenHAP/Tasmota/Heater.pod is the source of
#	App::OpenHAP::Tasmota::Heater(3p).
sub from_pod ( $class, $path, $group, $module_root )
{
	my $name = $path;
	$name =~ s{^\Q$module_root\E/}{} if defined $module_root;
	$name =~ s/\.pod$//;
	$name =~ s{/}{::}g;

	return bless {
		path    => $path,
		name    => $name,
		section => POD_SECTION,
		group   => $group,
	}, $class;
}

# $self->path, $self->name, $self->section:
#	The source, the manual name, and its section.
sub path    ($self) { return $self->{path}; }
sub name    ($self) { return $self->{name}; }
sub section ($self) { return $self->{section}; }

# $self->is_pod:
#	Report whether the source is a POD sidecar. A sidecar goes
#	through pod2man first; an mdoc source does not.
sub is_pod ($self)
{
	return $self->{path} =~ /\.pod$/ ? 1 : 0;
}

# $self->page:
#	The name of the page in the output directory.
sub page ($self)
{
	return "$self->{name}.$self->{section}.html";
}

# $self->staged_name:
#	The name that the mdoc staging directory needs. mandoc reads a
#	.Xr target as a local link only when a file named %N.%S sits in
#	its working directory, so man/fugu/Daemon.3p stages as
#	Fugu::Daemon.3p.
sub staged_name ($self)
{
	return "$self->{name}.$self->{section}";
}

# $self->description:
#	The one-line description, read from the source. An mdoc page
#	gives the argument of its first .Nd macro. A POD sidecar gives
#	the text after "Module - " on the first non-blank line below
#	=head1 NAME. The method returns undef when the source carries
#	neither.
sub description ($self)
{
	return $self->{description} if exists $self->{description};

	my $text = Fugu::File->read( $self->{path} );
	$self->{description} =
	      !defined $text ? undef
	    : $self->is_pod  ? _pod_description($text)
	    :                  _mdoc_description($text);

	return $self->{description};
}

# _mdoc_description($text):
#	The argument of the first .Nd macro.
sub _mdoc_description ($text)
{
	for my $line ( split /\n/, $text ) {
		next unless $line =~ /^\.Nd\s+(.*\S)/;
		return $1;
	}

	return;
}

# _pod_description($text):
#	The text after "Module - " on the first non-blank line below
#	=head1 NAME.
sub _pod_description ($text)
{
	my $in_name = 0;
	for my $line ( split /\n/, $text ) {
		if ( !$in_name ) {
			$in_name = 1 if $line =~ /^=head1\s+NAME\s*$/;
			next;
		}
		next unless $line =~ /\S/;

		# The dash carries a space on each side. A name that
		# holds one, such as a hyphenated word, therefore does
		# not end the name early.
		return $line =~ /^\S+\s+-\s+(.*\S)/ ? $1 : undef;
	}

	return;
}

1;
