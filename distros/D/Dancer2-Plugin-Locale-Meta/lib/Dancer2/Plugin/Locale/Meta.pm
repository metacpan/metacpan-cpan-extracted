package Dancer2::Plugin::Locale::Meta;

# ABSTRACT: Interface to support multilanguage using Locale::Meta package.

use strict;
use warnings;
use Dancer2::Plugin;
use Locale::Meta;

our $VERSION = '0.006';

=head1 NAME

Dancer2::Pluging::Locale::Meta

=head1 DESCRIPTION

This plugin allow Dancer2 developers to use L<Locale::Meta> package.  This Plugin is
based on L<Dancer2::Plugin::Locale::Wolowitz> plugin.

=head1 SYNOPSIS

  use Dancer2;
  use Dancer2::Plugin::Locale::Meta;

  # in your routes

  ## Getting the translation
  get '/' => sub {
    my $greeting = loc("hello");
    template index.tt, { greeting => $greeting }
  }
  
  ## Getting locale_meta attribute
  my $locale_meta = locale_meta;

  # in your template

  <% l('greeting') %>

  # load custom structure on your app


    my $structure = {
      "en" => {
        "goodbye"   => {
          "trans" => "bye",
        }
      },
      "es" => {
        "goodbye"   => {
          "trans" => "chao",
        }
      }
    };

    In order to load the data use the keyword on your routes:

    load_structure($structure);


=head1 CONFIGURATION

  plugins:
    Locale::Meta:
      fallback: "en"
      locale_path_directory: "i18n"
      lang_session: "lang"
=cut

BEGIN{
  has 'fallback' => (
    is => 'ro',
    from_config => 1,
    default => sub {}
  );

  has 'locale_path_directory' => (
    is => 'ro',
    from_config => 1,
    lazy => 1,
    default => sub { 
      './i18n'
    }
  );

  has 'lang_session' => (
    is => 'ro',
    from_config => 1,
    default => sub { 'lang' }
  );

  has 'locale_meta' => (
    is => 'rw',
  );

}


sub BUILD {
  my $plugin = shift;
  #Initialize Locale::Meta module
  my $lm = Locale::Meta->new( $plugin->locale_path_directory );
  #Set the locale::meta module as a variable of the plugin.
  $plugin->locale_meta($lm);
  $plugin->app->add_hook( Dancer2::Core::Hook->new(
    name => 'before_template_render',
    code => sub {
      my $tokens = shift;
      $tokens->{l} = sub { loc($plugin, @_); };
    }
  ));

}

plugin_keywords ('loc','load_structure','locale_meta');
plugin_hooks ('charge');

sub loc{
  my ($self, $str, $args, $force_lang) = @_;
  my $app = $self->app;
  my $lang = $force_lang || $app->session->read($self->lang_session) || $self->fallback;
  my $msg = $self->locale_meta->loc($str,$lang,@$args);
  #trying fallback
  if( $msg eq $str ){
    $msg = $self->locale_meta->loc($str,$self->fallback,@$args);
  }
  return $msg;
}

sub load_structure {
  my ($self, $structure) = @_;
  return $self->locale_meta->charge($structure);
}

1;
