package App::LXC::Container::Texts;

# Author, Copyright and License: see end of file

=head1 NAME

App::LXC::Container::Texts - text functions of L<App::LXC::Container>

=head1 SYNOPSIS

    # This module should never be used directly!
    # It is used indirectly by the main modules of App::LXC::Container

=head1 ABSTRACT

This module contains helper functions for the L<App::LXC::Container> package
to deal with texts and support different languages.

=head1 DESCRIPTION

The documentation of this module is mainly intended for developers of the
package itself.

Basically the module is a singleton providing a set of functions to be used
by the other modules of L<App::LXC::Container>.

=cut

#########################################################################

use v5.14;
use strictures;
no indirect 'fatal';
no multidimensional;
use warnings 'once';

use Carp;

our $VERSION = '0.40';

use App::LXC::Container::Texts::en;

#########################################################################

=head1 EXPORT

all functions of this module except L<language|/language - get or set
currently used language> (only used in exactly one location) are exported

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(language fatal error warning info message debug txt tabify);

#########################################################################
#
# internal constants and data:

use constant _ROOT_PACKAGE_ => substr(__PACKAGE__, 0, rindex(__PACKAGE__, "::"));

use constant MAIN_MODULES => qw(Data Mounts Run Setup Texts Update);
use constant DATA_MODULES => qw(common Debian Ubuntu);

our @CARP_NOT =
    (   _ROOT_PACKAGE_,
        map {( _ROOT_PACKAGE_ . '::' . $_ )} (MAIN_MODULES,
					      map {("Data::$_")} DATA_MODULES
					     ));

# currently supported languages:
use constant LANGUAGES => qw(en de);

# reference to all text strings of the currently used language:
my $_text_en = \%App::LXC::Container::Texts::en::T;
my $_text = $_text_en;

#########################################################################
#########################################################################

=head1 FUNCTIONS

=cut

#########################################################################

=head2 B<language> - get or set currently used language

    $language = language($new_language);

=head3 example:

    language(substr($ENV{LANG}, 0, 2));

=head3 parameters:

    $language           optional new language to be used

=head3 description:

This function returns the currently used language.  If the optional
parameter C<$new_language> is set and a supported language, the language is
first changed to that.

=head3 returns:

currently used language

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BEGIN {				# uncoverable statement
    my $re_languages = '^' . join('|', LANGUAGES) . '$';

    sub language($)
    {
	my ($new_language) = @_;

	if ($new_language !~ m/$re_languages/o)
	{
	    error('unsupported_language__1', $new_language);
	    $new_language = 'en';
	}
	local $_ = __PACKAGE__ . '::' . $new_language;
	eval "require $_";	# require with variable needs eval!
	$_ .= '::T';
	no strict 'refs';
	$_text = \%$_;
    }
}

#########################################################################

=head2 B<fatal> - abort with error message

    fatal($message_id, @message_data);

=head3 example:

    fatal('unsupported_language__1', $new_language);
    fatal('bad_container_name');

=head3 parameters:

    $message_id         ID of the text or format string in language module
    @message_data       optional additional text data for format string

=head3 description:

This function looks up the format (or simple) string passed in
C<$message_id> in the text hash of the currently used language, formats it
together with the C<@message_data> with sprintf and passes it on to
C<L<croak|Carp>>.

=head3 returns:

never

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub fatal($;@)
{
    my $message_id = shift;
    local $_ = sprintf(txt($message_id), @_); # using $_ to allow debugging
    croak($_);
}

#########################################################################

=head2 B<error> / B<warning> / B<info> - print error / warning / info message

    error($message_id, @message_data);
    warning($message_id, @message_data);
    info($message_id, @message_data);

=head3 example:

    warning('message__1_missing_en', $message_id);

=head3 parameters:

    $message_id         ID of the text or format string in language module
    @message_data       optional additional text data for format string

=head3 description:

This function looks up the format (or simple) string passed in
C<$message_id> in the text hash of the currently used language, formats it
together with the C<@message_data> with sprintf and passes it on to
C<L<carp|Carp>> (in case of errors or warnings) or C<L<warn|perlfunc/warn>>
(in case of informational messages).

Note that currently the first two functions only differ semantically.  (This
may or may not change in the future.)

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub error($;@)   {   carp message(@_);   }
sub warning($;@) {   carp message(@_);   }
sub info($;@)    {   warn message(@_);   }

#########################################################################

=head2 B<message> - return formatted message

    $string = message($message_id, @message_data);

=head3 example:

    $_ = message('can_t_open__1__2', $_, $!);

=head3 parameters:

    $message_id         ID of the text or format string in language module
    @message_data       optional additional text data for format string

=head3 description:

This function just returns the formatted message for the given
C<$message_id> and C<@message_data>, e.g. to be used within a compound
widget.

=head3 returns:

the formatted message as string

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub message($;@)
{
    my $message_id = shift;
    local $_ = txt($message_id);
    $_ = sprintf($_, @_);
    return $_;
}

#########################################################################

=head2 B<debug> - set debugging level or print debugging message

    debug($level);		# sets debugging level
    debug($level, @message);	# prints message

=head3 example:

    debug(2);
    debug(1, __PACKAGE__, '::new');

=head3 parameters:

    $level              debugging level to be set (>= 0)  or
                        debug-level of the message (>= 1)
    @message            the text to be printed

=head3 description:

If only the debugging level (numeric value >= 0) is passed, the debugging
level is changed to the given value.

Otherwise the given message is printed on STDERR if the debug-level of the
message is less or equal than the previously set debugging level.  All
messages are prefixed with C<DEBUG> and some blanks according to the
debug-level.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BEGIN {				# uncoverable statement
    my $debugging_level = 0;

    sub debug($;$@)
    {
	my $level = shift;
	unless ($level =~ m/^\d$/)
	{
	    error('bad_debug_level__1', $level);
	    return;
	}

	if (0 == @_)
	{   $debugging_level = $level;   }
	else
	{
	    if ($level == 0)
	    {
		error('bad_debug_level__1', $level);
		return;
	    }
	    return if $debugging_level < $level;
	    local $_ = '  ' x --$level;
	    my $message = join('', @_);
	    $message =~ s/\n\z//;
	    $message =~ s/\n/\n\t$_/g;
	    warn "DEBUG\t", $_, $message, "\n";
	}
    }
}

#########################################################################

=head2 B<txt> - look-up text for currently used language

    $message = txt($message_id);

=head3 example:

    $_ = sprintf(txt($message_id), @_);

=head3 parameters:

    $message_id         ID of the text or format string in language module

=head3 description:

This function looks up the format (or simple) string passed in its parameter
C<$message_id> in the text hash of the currently used language and returns
it.

=head3 returns:

looked up string

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub txt($)
{
    my ($message_id) = @_;

    if (defined $_text->{$message_id}  and  $_text->{$message_id} ne '')
    {
	return $_text->{$message_id};
    }
    # for missing message we try a fallback to English, if possible:
    if ($_text  ne  $_text_en)
    {
	warning('message__1_missing_en', $message_id);
	defined $_text_en->{$message_id}
	    and  return $_text_en->{$message_id};
    }
    error('message__1_missing', $message_id);
    return $message_id;
}

#########################################################################

=head2 B<tabify> - replace spaces with tabulators, if feasible

    $string = tabify($string);

=head3 parameters:

    $string             input string

=head3 description:

This function replaces multiple spaces in a string with a tabulator,
whenever this matches a tabulator position (multiple of 8).  It then returns
the modified string.

=head3 returns:

modified string

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub tabify($)
{
    my @strings = split /\n/, shift;
    local $_;
    foreach (@strings)
    {
	my $l = int(length($_) / 8) * 8;
	while ($l > 0)
	{
	    my $tail = substr($_, $l);
	    $_ = substr($_, 0, $l);
	    s/( {2,8})$/\t/;
	    $_ .= $tail;
	    $l -= 8;
	}
    }
    return join("\n", @strings);
}

1;

#########################################################################
#########################################################################

=head1 SEE ALSO

L<App::LXC::Container>

=head1 LICENSE

Copyright (C) Thomas Dorner.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.  See LICENSE file for more details.

=head1 AUTHOR

Thomas Dorner E<lt>dorner (at) cpan (dot) orgE<gt>

=cut
