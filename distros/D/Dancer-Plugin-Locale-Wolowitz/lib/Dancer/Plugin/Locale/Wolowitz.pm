#
# This file is part of Dancer-Plugin-Locale-Wolowitz
#
# This software is copyright (c) 2016 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dancer::Plugin::Locale::Wolowitz;
$Dancer::Plugin::Locale::Wolowitz::VERSION = '0.160190';
use strict;
use warnings;

use 5.010;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Exception qw(:all);

use Locale::Wolowitz;

#ABSTRACT: Internationalization for Dancer

my $w;

#Register exception
register_exception('DirectoryNotFound',
    message_pattern => "Wolowitz internationalization directory not found: %s"
);


add_hook(
    before_template => sub {
        $_[0]->{l} = sub { _loc(@_); };
    }
);

register loc => sub {
    _loc(@_);
};

sub _loc {
#   my ( $str, $args, $force_lang ) = @_;

    $w       = Locale::Wolowitz->new(_path_directory_locale()) unless defined($w);
    my $lang = $_[2] || _lang();

    # return early if no args array-ref given
    !$_[1] and return $w->loc($_[0], $lang); # was: !$args and return $w->loc($str, $lang);

    return $w->loc($_[0], $lang, map($w->loc($_, $lang), @{$_[1]}));
}

sub _path_directory_locale {
    my $path     = plugin_setting()->{locale_path_directory}
        // Dancer::FileUtils::path(setting('appdir'), 'i18n');

    if ( ! -d $path ) {
        raise DirectoryNotFound => $path;
    }

    return $path;
}

sub _lang {
    my $lang;
    # don't force the user to store lang in a session
    if ( setting('session') ) {
        my $lang_session = plugin_setting()->{lang_session} || 'lang';
        my $session_language = session $lang_session;
        return $session_language if $session_language;

        $lang = _detect_lang_from_browser();
        session $lang_session => $lang;
        return $lang;
    }

    $lang = _detect_lang_from_browser();

    return $lang;
}

sub _detect_lang_from_browser {
    # a rude shortcut, for no-session contexts, so multiple loc() calls within the
    # same request don't trigger regex matching/string munging over and over
    return request->{__dancer_plugin_locale_wolowitz_detected_language} if request->{__dancer_plugin_locale_wolowitz_detected_language};

    my $lang = request->accept_language;
    return unless $lang;

    $lang =~ s/-\w+//g;
    $lang = (split(/,\s*/,$lang))[0] if index($lang,',');

    request->{__dancer_plugin_locale_wolowitz_detected_language} = $lang; # this is a bit rude, but it saves us from detecting lang over and over (with regex and all) within the same request
    return $lang;
}

register_plugin;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::Locale::Wolowitz - Internationalization for Dancer

=head1 VERSION

version 0.160190

=head1 SYNOPSIS

    use Dancer ':syntax';
    use Dancer::Plugin::Locale::Wolowitz;

    get '/' => sub {
        template index;
    }

=head1 DESCRIPTION

Provides an easy way to translate your application. This module relies on L<Locale::Wolowitz>, please consult the documentation of Locale::Wolowitz.

=head1 METHODS

=head2 loc

    loc('Welcome');
    loc('View %1', ['Country'])
    loc('View %1', ['Country'], $language)
or in templates
    <% l('Welcome') %>
    <% l('View %1', ['Country']) %>
    <% l('View %1', ['Country'], 'fr') %>

Translated to the requested language, if such a translation exists, otherwise
no translation occurs. Just like in L<Locale::Wolowitz>, with the difference that
auto-detection is the default, hence an optional passed language is the third,
instead of the the second argument.

    input: (Str): Key translate
           (Arrayref): Arguments are injected to the placeholders in the string
           (Str): Language code, to circumvent auto-detection from browser header
    output: (Str): Translated to the requested language

=head1 CONFIGURATION

  plugins:
    Locale::Wolowitz:
      lang_session: "lang"
      locale_path_directory: "i18n"

=head1 CONTRIBUTING

This module is developed on Github at:

L<http://github.com/hobbestigrou/Dancer-Plugin-Locale-Wolowitz>

=head1 ACKNOWLEDGEMENTS

Thanks to Ido Perlmuter for Locale::Wolowitz

=head1 BUGS

Please report any bugs or feature requests via github issue tracker.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Locale::Wolowitz

=head1 SEE ALSO

L<Dancer>
L<Locale::Wolowitz>

=head1 AUTHOR

Natal Ngétal

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Natal Ngétal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
