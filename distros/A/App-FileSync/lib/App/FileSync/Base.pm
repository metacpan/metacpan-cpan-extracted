package App::FileSync::Base;

# The few behaviours every App::FileSync object shares: rendering catalogued
# messages in the object's own language, and raising them.  Kept tiny on
# purpose; it is a mixin for i18n, not a framework.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Sub::Protected;

use App::FileSync::I18N ();

use version; our $VERSION = version->declare('0.001.2');

# Raising through _throw should report the subclass's caller, not this file.
$Carp::Internal{ (__PACKAGE__) }++;

=encoding utf8

=head1 NAME

App::FileSync::Base - shared i18n behaviour for App::FileSync objects

=head1 SYNOPSIS

	package App::FileSync::Something;
	use parent -norequire, 'App::FileSync::Base';

	sub check {
		my ($self, $path) = @_;
		$self->_throw('path.empty') unless length $path;
		return $self->i18n('client.verbose_action', { verb => 'push', path => $path });
	}

=head1 DESCRIPTION

Objects carry an optional C<language> (a code such as C<de> or a locale name
such as C<de_DE.UTF-8>).  Two objects with different languages render their
messages independently, so a server can answer in its own language while a
client in the same process uses another.

=head1 METHODS

=head2 i18n

Purpose: render a catalogued message in this object's language.

Args: C<$key>, optional C<\%args>.

Returns: the rendered string, without a trailing newline.

Side Effects: none.

Usage:

	my $text = $self->i18n('cli.sync.summary', { repo => $name, dry => '', pulled => 3, pushed => 0, deleted => 0, conflicts => 0 });

=head3 EXAMPLE

	my $client = App::FileSync::Client->new(config => $c, name => 'docs', language => 'en');
	print $client->i18n('word.file', { count => 2 }), "\n";	# 2 files

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self', type => 'object', can => 'i18n' },
		{ name => 'key',  type => 'string', min => 1 },
		{ name => 'args', type => 'hashref', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None; it renders them.

=head3 FORMAL SPECIFICATION

	i18n(self, k, a) = message(k, a, self.language)

=cut

sub i18n {
	my ($self, $key, $args) = @_;

	return App::FileSync::I18N::message($key, $args, $self->{language});
}

=head2 language

Purpose: the language this object renders messages in.

Args: none.

Returns: the configured language or locale, or C<undef> for the process default.

Side Effects: none.

Usage:

	my $language = $object->language;

=head3 EXAMPLE

	print $admin->language // 'process default', "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	language(self) = self.language

=cut

sub language {
	my ($self) = @_;

	return $self->{language};
}

# _throw
# Purpose:     raise a catalogued error in this object's language.
# Entry:       $key names a catalogue entry; $args fills its placeholders.
# Exit:        never returns.
# Side effects: croaks (see App::FileSync::I18N::throw).  Protected: only
#              this class and its subclasses may call it.
sub _throw :Protected {
	my ($self, $key, $args) = @_;

	App::FileSync::I18N::throw($key, $args, $self->{language});
}

1;

__END__

=head1 LIMITATIONS

C<_throw> is C<:Protected> (L<Sub::Protected>), so only subclasses may raise
through it.  Like every Sub::Protected check it is bypassed while
C<HARNESS_ACTIVE> is set, so tests see the same behaviour as production only
when they turn the bypass off.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
