package Database::BI::I18N;

use strict;
use warnings;

our $VERSION = '0.023.1';

use Carp qw(croak);
use Readonly;

# Which language a message is given in, and the text it is given as.
#
# Every module keeps its messages in British English, in its own %MESSAGES.
# Another language is a module of its own, Database::BI::I18N::<code>, holding
# for each package only the messages that read differently; a message it does
# not list is the British one.  American English (en_us) differs in a handful
# of spellings, so that is all it holds.
#
# The language is chosen by CGI::Lingua, in choose(), from an Accept-Language
# header or, on the command line, the locale (from_locale()).  A request sets
# $LANGUAGE for as long as it is being answered (Database::BI's around_dispatch
# hook, with local), so a message raised anywhere under it - a model's croak
# included - is in the reader's language without the language being passed
# down.  A script sets it from the locale when it starts.  Nothing else does:
# a module called from other code gives its messages in British English, so
# what it croaks with does not depend on the environment it happens to run in
# (a test suite run under LANG=en_US.UTF-8 matches the British messages).

# The language the messages are written in, and the ones a module adds.
Readonly my $BASE      => 'en';
Readonly my @LANGUAGES => ('en', 'en-us');

# The language of the request being answered, or the script's; undef
# (British) otherwise.
our $LANGUAGE;

my %TABLE;		# language => { package => { key => text } }, loaded on first use
my %FROM_LOCALE;	# locale string => language, so a script asks CGI::Lingua once

# languages() -> @codes
sub languages { return @LANGUAGES }

# choose(%args) -> $code
#
# accept  => an Accept-Language value (optional)
# default => the answer when it names nothing supported (default 'en')
#
# The supported language that suits it best: 'en-us' for en-US, 'en' for every
# other English.  CGI::Lingua answers the language and the region apart, and
# names a region only when that variant is supported.
sub choose {
	my (%args) = @_;

	my $default = $args{default};
	$default = $BASE unless defined $default && grep { $_ eq $default } @LANGUAGES;

	my $accept = $args{accept};
	return $default unless defined $accept && length $accept;

	return lingua_choice($accept, [ @LANGUAGES ]) // $default;
}

# lingua_choice($accept, \@supported) -> $code | undef
#
# What CGI::Lingua picks from @supported for an Accept-Language value: the
# language's code, or "<code>-<region>" when the value names a region that is
# in @supported.  undef when it names nothing supported, or CGI::Lingua fails.
# The template directories are chosen by this too (Dashboard's
# _resolve_language), so pages and messages agree.
sub lingua_choice {
	my ($accept, $supported) = @_;

	return undef unless defined $accept && length $accept;	## no critic (ProhibitExplicitReturnUndef)

	local $ENV{HTTP_ACCEPT_LANGUAGE} = $accept;
	return _lingua($supported);
}

# _lingua(\@supported) -> $code | undef
#
# CGI::Lingua's choice from @supported, from whatever it reads: the
# Accept-Language header when there is one, else (0.88 and later) the locale.
# "<code>-<region>" when the region is offered, else the language's code.
sub _lingua {
	my ($supported) = @_;

	my %offered = map { lc($_) => 1 } @{$supported};
	local ($@, $!);
	my $code = eval {
		require CGI::Lingua;
		my $lingua = CGI::Lingua->new(supported => $supported, dont_use_ip => 1);
		my $language = $lingua->language_code_alpha2();
		my $region   = defined $language ? $lingua->sublanguage_code_alpha2() : undef;
		(defined $region && $offered{ lc "$language-$region" }) ? lc "$language-$region" : $language;
	};
	return $code;
}

# language() -> $code
#
# The language to give messages in: $LANGUAGE, else British.
sub language {
	return $LANGUAGE // $BASE;
}

# from_locale() -> $code
#
# The language the locale names, for a script to set $LANGUAGE from.
# CGI::Lingua (0.88 and later) reads the locale itself, as POSIX does: LC_ALL,
# then LC_MESSAGES, then LANG, so en_US.UTF-8 is en-us and LC_ALL=C names no
# language whatever LANG says.  No request header is consulted: one left in
# the environment by a CGI caller would otherwise win.  Remembered per locale.
sub from_locale {
	my $locale = join "\0", map { $_ // '' } @ENV{qw(LC_ALL LC_MESSAGES LANG)};
	return $FROM_LOCALE{$locale} //= do {
		delete local $ENV{HTTP_ACCEPT_LANGUAGE};
		_lingua([ @LANGUAGES ]) // $BASE;
	};
}

# text($package, \%messages, $key) -> $template | undef
#
# The template for $key in the current language: the language's own text for
# that package, else the British one in \%messages (undef when that has none).
sub text {
	my ($package, $messages, $key) = @_;

	return undef unless defined $key;	## no critic (ProhibitExplicitReturnUndef)

	my $language = language();
	if ($language ne $BASE) {
		my $table = $TABLE{$language} //= _load($language);
		my $own   = $table->{$package};
		return $own->{$key} if $own && defined $own->{$key};
	}
	return $messages->{$key};
}

# _load($language) -> \%table
#
# Database::BI::I18N::en_us for 'en-us'.  A language with no module is
# {}: its messages are the British ones.
sub _load {
	my ($language) = @_;

	(my $name = $language) =~ tr/-/_/;
	croak "Unsafe language name '$language'" unless $name =~ /\A[a-z]{2,3}(?:_[a-z0-9]{2,8})?\z/;
	my $module = "Database::BI::I18N::$name";

	local ($@, $!);
	my $table = eval "require $module; \\%${module}::MESSAGES";	## no critic (ProhibitStringyEval): the name is checked above
	return $table || {};
}

1;

__END__

=head1 NAME

Database::BI::I18N - Choose the language of messages, and give them in it

=head1 VERSION

0.023.1

=head1 SYNOPSIS

    use Database::BI::I18N;

    # Per request (Database::BI does this in an around_dispatch hook):
    local $Database::BI::I18N::LANGUAGE =
        Database::BI::I18N::choose(accept => 'en-US,en;q=0.9');   # 'en-us'

    # In a module:
    my $template = Database::BI::I18N::text(__PACKAGE__, \%MESSAGES, 'error_x');

=head1 DESCRIPTION

Every module keeps its messages, in British English, in its own C<%MESSAGES>.
A translation is a module C<Database::BI::I18N::E<lt>codeE<gt>> whose
C<%MESSAGES> maps each package to the messages that read differently in that
language; anything it leaves out is given in British English.
L<Database::BI::I18N::en_us> is American English.

The language comes from L<CGI::Lingua>: from the request's C<Accept-Language>
while a request is answered, and for the command-line scripts from the locale
(C<LC_ALL>, C<LC_MESSAGES>, C<LANG>), which each sets when it starts.  English
(United States) is C<en-us>; every other English is C<en>.  Anything else -
code calling a module directly, a test - gets British English.

=head1 FUNCTIONS

=head2 languages

    my @codes = Database::BI::I18N::languages();   # ('en', 'en-us')

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

The language codes messages can be given in, British English first.

=head2 choose

    my $code = Database::BI::I18N::choose(accept => $header, default => 'en');

=head3 API SPECIFICATION

=head4 INPUT

    accept:  string, optional; an Accept-Language value
    default: string, optional; returned when accept names nothing supported
             (used only when it is one of languages(), else 'en')

=head4 OUTPUT

One of C<languages()>: C<en-us> when the header's best supported choice is
English with the United States region, C<en> for other English.

=head2 lingua_choice

    my $code = Database::BI::I18N::lingua_choice($accept, ['en', 'en-us', 'fr']);

=head3 API SPECIFICATION

=head4 INPUT

    $accept:    string; an Accept-Language value
    \@supported: arrayref of language codes, each optionally with a region

=head4 OUTPUT

What L<CGI::Lingua> picks from the list: a two-letter code, or
C<code-region> (lower case) when the header names a region the list holds.
C<undef> when it picks nothing, or the header is empty.

=head2 language

    my $code = Database::BI::I18N::language();

=head3 API SPECIFICATION

=head4 INPUT

None.  Reads C<$Database::BI::I18N::LANGUAGE>.

=head4 OUTPUT

The code messages are given in now: the request's language (or the one a
script set), else C<en>.  The environment is not read: code that calls a
module directly gets British English whatever the locale.

=head2 from_locale

    local $Database::BI::I18N::LANGUAGE = Database::BI::I18N::from_locale();

=head3 API SPECIFICATION

=head4 INPUT

None.  L<CGI::Lingua> (0.88 and later) reads C<LC_ALL>, then C<LC_MESSAGES>,
then C<LANG>, as POSIX does; C<LC_ALL=C> names no language whatever C<LANG>
says.  C<HTTP_ACCEPT_LANGUAGE> is ignored here, even when set.

=head4 OUTPUT

One of C<languages()>: the language the locale names, through L<CGI::Lingua>
(C<en_US.UTF-8> is C<en-us>; C<en_GB.UTF-8>, C<C>, C<POSIX> and an unset
locale are C<en>).  The scripts set C<$LANGUAGE> from it when they start.

=head2 text

    my $template = Database::BI::I18N::text($package, \%messages, $key);

=head3 API SPECIFICATION

=head4 INPUT

    $package:  string; the package whose message it is
    \%messages: hashref; that package's %MESSAGES (British English)
    $key:      string; the message key

=head4 OUTPUT

The message template (a C<sprintf> format) in the current language: the
translation's text for that package and key, else C<< $messages->{$key} >>.
C<undef> when neither has the key.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
