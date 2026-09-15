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

package App::FuguBench::Checkout;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use File::Basename qw(basename dirname);
use File::Spec     ();

use Fugu::File;

# App::FuguBench::Checkout - the checkout walk and the configuration
# reader.
#
# The walk has two stops. The first stop is the nearest directory
# with .toolingrc, and that directory is the root. The second stop is
# the nearest .toolingrc on the walk that holds a key. The directory
# of that file is the home of the key, and a verb anchors a relative
# value at a home or at the root.
#
# A clone under Projects/ holds its own .toolingrc without a
# wiki.origin key, so the walk for the library reaches the workspace.

use constant CONFIG_FILE => '.toolingrc';

# The keys of CLI-CONFIG, with the default of each one. The default
# is a code reference, because wiki.project reads the root. A key
# outside the table belongs to another tool, and config() gives
# nothing for it. A key with no default stops the verb that needs it.
my %KEY = (
	'wiki.dir'      => sub ($) { return 'Wiki' },
	'wiki.origin'   => sub ($) { return },
	'wiki.project'  => sub ($self) { return basename( $self->root ) },
	'wiki.projects' => sub ($) { return 'Projects' },
	'worktree.base' => sub ($) { return '.claude/worktrees' },
);

# App::FuguBench::Checkout->new(start => $dir):
#	Walk up from the start and record each directory that holds a
#	.toolingrc, nearest first. The method returns undef when the
#	walk reaches the filesystem root with none.
sub new ( $class, %args )
{
	my $dir = File::Spec->canonpath(
		File::Spec->rel2abs( $args{start} // q{.} ) );

	my @walk;
	while (1) {

		# The file name goes in a variable first. On perl 5.34 a
		# file test reads the class name of a method call as a
		# bareword filehandle.
		my $file = File::Spec->catfile( $dir, CONFIG_FILE );
		push @walk, $dir if -f $file;

		my $parent = dirname($dir);
		last if $parent eq $dir;
		$dir = $parent;
	}
	return unless @walk;

	return bless {
		root   => $walk[0],
		walk   => \@walk,
		values => {},
		error  => undef,
	}, $class;
}

# $self->root:
#	The directory of the first .toolingrc on the walk.
sub root ($self)
{
	return $self->{root};
}

# $self->error:
#	The reason of the last failed shape check, or undef.
sub error ($self)
{
	return $self->{error};
}

# $self->config($key):
#	The value of one key and its home, as a two-element list. The
#	value comes from the nearest .toolingrc on the walk that holds
#	the key, and the home is the directory of that file. A key
#	that no file holds takes its default, with the root as its
#	home. A key with no default, and a key of another tool, give
#	the empty list.
sub config ( $self, $key )
{
	my $default = $KEY{$key} or return;

	for my $dir ( @{ $self->{walk} } ) {
		my $values = $self->_values($dir);
		next unless exists $values->{$key};
		return ( $values->{$key}, $dir );
	}

	my $value = $default->($self);
	return unless defined $value;

	return ( $value, $self->{root} );
}

# $self->_values($dir):
#	The keys of the .toolingrc of one directory. A line holds a
#	key, whitespace, and a value. A line that starts with # is a
#	comment, and a line with no value holds no key.
sub _values ( $self, $dir )
{
	return $self->{values}{$dir} if $self->{values}{$dir};

	my $text = Fugu::File->read( File::Spec->catfile( $dir, CONFIG_FILE ) );

	my %values;
	for my $line ( split /\n/, $text // q{} ) {
		my $trimmed = $line =~ s/^\s+|\s+\z//gr;
		next if $trimmed eq q{} || $trimmed =~ /^#/;

		my ( $key, $value ) = split /\s+/, $trimmed, 2;
		next unless defined $value && $value ne q{};
		$values{$key} //= $value;
	}

	return $self->{values}{$dir} = \%values;
}

# $self->dir_value($value):
#	The shape check of a directory value: a relative path with no
#	parent segment. A value that fails gives undef with the reason
#	in error().
sub dir_value ( $self, $value )
{
	$self->{error} = undef;

	unless ( defined $value && $value ne q{} ) {
		$self->{error} = 'the directory is empty';
		return;
	}
	if ( File::Spec->file_name_is_absolute($value) ) {
		$self->{error} = "the directory is absolute: $value";
		return;
	}
	if ( grep { $_ eq '..' } split m{/}, $value ) {
		$self->{error} = "the directory leaves the tree: $value";
		return;
	}

	return $value;
}

# $self->url_value($value):
#	The shape check of a URL value: a scheme and an authority. A
#	value that fails gives undef with the reason in error().
sub url_value ( $self, $value )
{
	$self->{error} = undef;

	unless ( defined $value && $value ne q{} ) {
		$self->{error} = 'the URL is empty';
		return;
	}
	unless ( $value =~ m{\A[A-Za-z][A-Za-z0-9+.-]*://\S} ) {
		$self->{error} = "the URL holds no scheme: $value";
		return;
	}

	return $value;
}

1;
