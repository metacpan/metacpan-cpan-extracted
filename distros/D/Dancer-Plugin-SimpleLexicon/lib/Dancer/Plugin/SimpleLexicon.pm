package Dancer::Plugin::SimpleLexicon::Handler;
use 5.010001;
use strict;
use warnings;
use base 'Locale::Maketext';
use Locale::Maketext::Lexicon;

sub import_po_file {
    my ($self, $lang, $pofile) = @_;
    # warn "$self, $lang, $pofile";
    Locale::Maketext::Lexicon->import({
                                       $lang => [Gettext => $pofile],
                                      });
}

1;


package Dancer::Plugin::SimpleLexicon;

use 5.010001;
use strict;
use warnings;

=head1 NAME

Dancer::Plugin::SimpleLexicon - Tiny Dancer interface to Locale::Maketext::Lexicon

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

In your configuration:

  plugins:
    SimpleLexicon:
      path: languages
      session_name:   lang
      param_name:     lang
      var_name:       lang
      default:        en
      encoding: UTF-8
      langs:
        en:    "US English"
        de:       "Deutsch"
        nl:       "Netherlands"
        se:       "Sweden"
        it:       "Italiano"

In your module

    use Dancer ':syntax';
    use Dancer::Plugin::SimpleLexicon;
    var lang => 'it';
    my $string = l('Hello %s', 'Marco');
    # assuming languages/it.po have a translation for this, will return "Ciao Marco"

=head1 SETTINGS

This module is a tiny alternative to L<Dancer::Plugin::Lexicon>. See
what it works best for you.

Explanation of the settings.

=head2 path

The path, absolute or relative, to the C<.po> files. The C<.po> files
must be named as the defined language tags (see below).

=head2 langs

An array of keys/values with the language tag and the full name on the
language.

Please note that if you define a language "it", the file
C<languages/it.po> B<must be present>.

=head2 param_name

If specified, when determining the language, the module will try to
lookup the key in the request parameters (C<param>).

=head2 session_name

The key of the C<session> where to read and store the current language.
If not specified, the session is not touched.

=head2 var_name

The name of the Dancer C<var> to read when determining the current language.

=head2 default

The value of the default language. If not specified, and the looking up
in the above values fails, no translation will be done.

=head2 encoding

The string returned by maketext will be decoded using
this encoding. By default is C<UTF-8>.

To disable the decoding, set it to C<raw>.

=head1 EXPORT

=head2 l($string, @args)

Return the translation for $string. If optional arguments are
provided, pass the string to sprintf with the arguments.

=head2 language

Return the current language used, returning the long name of the
language as defined in the configuration.

The priority set is follow: param, session, var, default. The first
wins, assuming it was defined in the config. Unclear if it's the right
thing to do. TODO: make this configurable or at runtime.

=head2 set_language($language_tag)

Set the current language to $language_tag, writing it into the
session, using the key specified in the C<session_name> value.

=head1 Dancer::Template::TemplateFlute integration

In the configuration:

  engines:
    template_flute:
      i18n:
        class: My::Lexicon
        method: localize
  plugins:
    SimpleLexicon:
      path: languages
      session_name:   lang
      param_name:     lang
      var_name:       lang
      default:        en
      encoding: UTF-8
      langs:
        en:    "US English"
        de:    "Deutsch"
        nl:    "Netherlands"
        se:    "Sweden"

And write the tiny class My::Lexicon wit the following content:

  package My::Lexicon;
  use Dancer ':syntax';
  use Dancer::Plugin::SimpleLexicon;
  use Encode;
  
  sub new {
      my $class = shift;
      my $self = {};
      bless $self, $class;
  }
  
  sub localize {
      my ($self, $string) = @_;
      my $translated = l($string);
      return $translated;
  }
  
  1;


=cut

package Dancer::Plugin::SimpleLexicon;


use strict;
use warnings;
use Dancer::Plugin;
use Dancer ':syntax';
use File::Spec::Functions qw/catfile/;
use Encode;

my $Handlers;

register l => \&_localize;

register language => sub {
    my $lang = _determine_language();
    return 'none found' unless $lang;
    return plugin_setting->{langs}->{$lang};
};

register set_language => sub {
    my ($lang) = @_;
    return unless $lang;
    unless (plugin_setting->{langs}->{$lang}) {
        error "Unknown language tag $lang";
        return;
    }
    if (my $sn = plugin_setting->{session_name}) {
        session $sn => $lang;
    }
    else {
        error "No session_name specified in the configuration, couldn't set $lang";
    }
};

register_plugin;

sub _init_handlers {
    my $settings = plugin_setting;
    my %handlers;
    # debug to_dumper($settings);
    if ($settings && $settings->{langs} && $settings->{path}) {
        foreach my $lang (keys %{$settings->{langs}}) {
            my $path = catfile($settings->{path}, $lang . ".po");
            unless (-f $path) {
                die "You defined the language $lang, but $path was not found!";
            }
            Dancer::Plugin::SimpleLexicon::Handler->import_po_file($lang, $path);
            my $handler = Dancer::Plugin::SimpleLexicon::Handler->get_handle($lang);
            die "Couldn't get an handler out of $path!" unless $handler;
            $handlers{$lang} = $handler;
        }
    }
    else {
        error "Missing configuration 'langs' or 'path' for " . __PACKAGE__; 
    }
    $Handlers = \%handlers;
}

sub _determine_language {
    my $settings = plugin_setting;

    # try to see which language to use, starting from the more
    # specific one to the more general one;

    my $lang;

    if ($settings->{param_name}) {
        # wrap in eval, if we're out of a rout would crash
        eval {
            $lang = param($settings->{param_name});
            # debug "Found $lang found in param";
        }
    }

    if (!$lang && $settings->{session_name}) {
        $lang = session($settings->{session_name});
        # debug "Found $lang found in session";
    }

    if (!$lang && $settings->{var_name}) {
        $lang = var($settings->{var_name});
        # debug "Found $lang found in var";
    }

    if (!$lang && $settings->{default}) {
        $lang = $settings->{default};
        # debug "using default";
    }

    return $lang;
}


sub _localize {
    my ($string, @args) = @_;

    # initialize if not alredy done
    unless ($Handlers) {
        _init_handlers();
    }

    my $settings = plugin_setting;
    my $lang = _determine_language();

    my $default_string = $string;
    if (@args) {
        $default_string = sprintf($default_string, @args);
    }

    unless ($lang) {
        info "No valid configuration find for " . __PACKAGE__;
        return $default_string;
    }

    # get the handler
    my $h = $Handlers->{$lang};
    unless ($h) {
        # warn "Couldn't get an handler for $lang!";
        return $default_string;
    }
     

    # try to translate. If not so, return the string
    my $translation;
    eval { $translation = $h->maketext($string) };
    unless (defined $translation and $translation =~ /\S/) {
        return $default_string;
    }

    # decode the string
    my $enc = $settings->{encoding} || 'UTF-8';
    unless ($enc eq 'raw') {
        $translation = decode($enc, $translation);
    }

    if (@args) {
        return sprintf($translation, @args);
    }
    else {
        return $translation;
    }
}


=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-simplelexicon at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-SimpleLexicon>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::SimpleLexicon


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-SimpleLexicon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-SimpleLexicon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-SimpleLexicon>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-SimpleLexicon/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Dancer::Plugin::SimpleLexicon
