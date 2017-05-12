package Dancer2::Plugin::Locale::Wolowitz;

use 5.010;
use strict;
use warnings;

use Dancer2::FileUtils;
use Dancer2::Plugin;
use I18N::AcceptLanguage;
use Locale::Wolowitz;

our $VERSION = '0.05';

my $wolowitz;

=head1 NAME

Dancer2::Plugin::Locale::Wolowitz - Dancer2's plugin for Locale::Wolowitz

=head1 DESCRIPTION

This plugin give you the L<Locale::Wolowitz> support. It's a blatant copy of
L<Dancer::Plugin::Locale::Wolowitz> and should be a drop in replacement
for Dancer2 projects.

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Locale::Wolowitz;

    # in your templates
    get '/' => sub {
        template 'index';
    }

    # or directly in code
    get '/logout' => sub {
        template 'logout', {
            bye => loc('Bye');
        }
    }

... meanwhile, in a nearby template file called index.tt

    <% l('Welcome') %>

=head1 CONFIGURATION

   plugins:
     Locale::Wolowitz:
       fallback: "en"
       locale_path_directory: "i18n"
       lang_session: "lang"
       lang_available:
         - de
         - en
         - id
         - nl

=cut


on_plugin_import {
    my $dsl = shift;

    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before_template_render',
            code => sub {
                my $tokens = shift;
                $tokens->{l} = sub { _loc($dsl, @_); };
            }
        )
    );
};

=head1 KEYWORDS

=head2 loc

The C<loc> keyword can be used in code to look up the correct translation. In
templates you can use the C<l('')> function

=cut

register loc => \&_loc;

sub _loc {
    my ($dsl, $str, $args, $force_lang) = @_;

    $wolowitz ||= Locale::Wolowitz->new(_path_directory_locale($dsl));
    my $lang    = $force_lang || _lang($dsl);

    return $wolowitz->loc($str, $lang, @$args);
};

sub _path_directory_locale {
    my $dsl = shift;

    my $conf = $dsl->{app}{config}{plugins}{'Locale::Wolowitz'};

    my $dir = $conf->{locale_path_directory} // 'i18n';
    unless (-d $dir) {
        $dir = Dancer2::FileUtils::path($dsl->app->setting('appdir'), $dir);
    }
    return $dir;
}

sub _lang {
    my $dsl = shift;

    my $conf = $dsl->{app}{config}{plugins}{'Locale::Wolowitz'};
    my $lang_session = $conf->{lang_session} || 'lang';

    if( $dsl->app->has_session ) {
        my $session_language = $dsl->app->session->read( $lang_session );

        if( !$session_language ) {
            $session_language = _detect_lang_from_browser($dsl);
        }

        return $session_language;
    } else {
        return _detect_lang_from_browser($dsl);
    }
}

sub _detect_lang_from_browser {
    my $dsl = shift;

    my $conf = $dsl->{app}{config}{plugins}{'Locale::Wolowitz'};
    my $acceptor = I18N::AcceptLanguage->new(defaultLanguage => $conf->{fallback} // "");
    return $acceptor->accepts($dsl->app->request->accept_language, $conf->{lang_available});
}

=head1 AUTHOR

Menno Blom, C<< <blom at cpan.org> >>

=head1 BUGS / CONTRIBUTING

This module is developed on Github at:
L<http://github.com/b10m/p5-Dancer-Plugin-Locale-Wolowitz>

=head1 ACKNOWLEDGEMENTS

Many thanks go out to L<HOBBESTIG|https://metacpan.org/author/HOBBESTIG> for
writing the Dancer 1 version of this plugin (L<Dancer::Plugin::Locale::Wolowitz>).

And obviously thanks to L<IDOPEREL|https://metacpan.org/author/IDOPEREL> for
creating the main code we're using in this plugin! (L<Locale::Wolowitz>).

=head1 COPYRIGHT

Copyright 2014- Menno Blom

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

register_plugin;

1; # End of Dancer2::Plugin::Locale::Wolowitz
