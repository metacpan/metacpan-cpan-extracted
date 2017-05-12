package Amon2::Plugin::L10N;
use strict;
use warnings;

use 5.008_005;
our $VERSION = 'v0.1.4';

use File::Spec;
use HTTP::AcceptLanguage;

sub init {
    my($class, $c, $conf) = @_;
    die 'before_detection_hook is not code reference'
        if $conf->{before_detection_hook} && ref($conf->{before_detection_hook}) ne 'CODE';
    die 'after_detection_hook is not code reference'
        if $conf->{after_detection_hook} && ref($conf->{after_detection_hook}) ne 'CODE';

    my $default_lang = $conf->{default_lang};
    $default_lang = 'en' unless defined $default_lang;


    my $accept_langs = $conf->{accept_langs} || ['en'];
    die 'accept_langs is not array reference'
        unless ref($accept_langs) eq 'ARRAY';
    my $po_file_langs = $conf->{po_file_langs} || $accept_langs;
    die 'po_file_langs is not array reference'
        unless ref($po_file_langs) eq 'ARRAY';

    $conf->{po_dir}          ||= 'po';
    $conf->{lexicon_options} ||= {};

    my $l10n_class = $conf->{l10n_class};
    unless ($l10n_class) {
        $l10n_class = join '::', $c, 'L10N';
        $class->generate_l10n_class($c, $po_file_langs, $default_lang, $conf->{po_dir}, $conf->{lexicon_options});
    }

    Amon2::Util::add_method($c, l10n_language_detection => sub {
        my $context = shift;
        return $context->{l10n_language_detection} if ref($context) && $context->{l10n_language_detection};
        my $lang;

        if ($conf->{before_detection_hook}) {
            $lang = $conf->{before_detection_hook}->($context);
        }
        if (! defined $lang && ref($context)) {
            $lang = HTTP::AcceptLanguage->new($context->req->header('Accept-Language'))->match(@{ $accept_langs });
        }

        $lang = $default_lang unless defined $lang;
        $lang = $conf->{after_detection_hook}->($context, $lang) if $conf->{after_detection_hook};

        $context->{l10n_language_detection} = $lang if ref($context);
        return $lang;
    });

    my %l10n;
    for my $lang (@{ $po_file_langs }) {
        $l10n{$lang} = $l10n_class->get_handle($lang);
    }
    my $default_l10n = $default_lang ? $l10n{$default_lang} : undef;
    Amon2::Util::add_method($c, loc => sub {
        my $context = shift;
        my $l10n = $l10n{$context->l10n_language_detection} || $default_l10n;
        return join ', ', @_ unless $l10n;
        return $l10n->maketext(@_);
    });
}

sub generate_l10n_class {
    my($class, $klass, $po_file_langs, $default_lang, $po_dir, $lexicon_options) = @_;

    # make package variable
    {
        my %opt = (
            _preload => 1,
            _style   => 'gettext',
            _decode  => 1,
            _auto    => 1,
        );

        for my $lang (@{ $po_file_langs }) {
            if ($lang eq $default_lang) {
                $opt{$lang} = [ 'Auto' ];
            } else {
                $opt{$lang} = [ Gettext => File::Spec->catfile($po_dir, "$lang.po") ];
            }
        }

        no strict 'refs';
        ${"$klass\::L10N::LEXICON_OPTIONS"} = +{ %opt, %{ $lexicon_options } };
    };

    my $code = qq!
package $klass\::L10N;
use parent 'Locale::Maketext';
use Locale::Maketext::Lexicon \$$klass\::L10N::LEXICON_OPTIONS;
1;
!;
    eval $code or die $@;
}

1;
__END__

=encoding utf-8

=head1 NAME

Amon2::Plugin::L10N - L10N support for Amon2

=head1 DESCRIPTION

Amon2::Plugin::L10N is L10N support plugin for Amon2.

=head1 Implementation L10N for your App

=head2 in YourProj.pm

  __PACKAGE__->load_plugins('L10N' => {
      default_lang => 'en',                                  # default is en
      accept_langs => [qw/ en ja zh-tw zh-cn fr /],          # default is ['en']
      po_dir       => 'po',                                  # default is po
  });

=head2 in your YourProj::Web::ViewFunction

  use Text::Xslate ();
  sub l {
      my $string = shift;
      my @args = map { Text::Xslate::html_escape($_) } @_; # escape arguments
      Text::Xslate::mark_raw( YourProj->context->loc($string, @args) );
  }

=head2 in your tmpl/foo.tt

  [% l('Hello! %1', 'username') %]

=head2 in your some class

  package YourProj::M::Foo;
  
  sub bar {
      YourProj->context->loc('hello! %1', $username);
  }

=head2 hook of before language detection

  __PACKAGE__->load_plugins('L10N' => {
      accept_langs          => [qw/ en ja zh-tw zh-cn fr /],
      before_detection_hook => sub {
          my $c = shift;
          return unless ref($c);
  
          my $accept_re = qr/\A(?:en|ja|zh-tw)\z/;
          my $lang = $c->req->param('lang');
          if ($lang && $lang =~ $accept_re) {
              $c->session->set( lang => $lang );
              return $lang;
          } elsif (! defined $lang) {
              $lang = $c->session->get('lang');
              if ($lang && $lang =~ $accept_re) {
                  return $lang;
              }
          }
          $c->session->set( lang => '' );
          return; # through
      },
  });

=head2 hook of after language detection

  __PACKAGE__->load_plugins('L10N' => {
      accept_langs         => [qw/ en ja zh zh-tw zh-cn fr /],
      after_detection_hook => sub {
          my($c, $lang) = shift;
          return 'zh' if $lang =~ /\Azh(?:-.+)\z/;
          return $lang;
      },
  });

=head2 you can customize the po files name

  __PACKAGE__->load_plugins('L10N' => {
      accept_langs         => [qw/ zh-tw zh-cn zh /],
      po_file_langs        => [qw/ zh-tw zh-cn /],    # zh.po is not exists file
      after_detection_hook => sub {
          my($c, $lang) = shift;
          return 'zh-cn' if $lang eq 'zh'; # use zh-cn.po file
          return $lang;
      },
  });

=head2 for your CLI

  __PACKAGE__->load_plugins('L10N' => {
      default_lang          => 'ja',
      accept_langs          => [qw/ en ja /],
      before_detection_hook => sub {
          my $c = shift;
          return unless $NEV{CLI_MODE}; # CLI_MODE is example key
          return 'ja' if $ENV{LANG} =~ /ja/i;
          return 'en' if $ENV{LANG} =~ /en/i;
          return; # use default lang
      },
  });

=head2 you can set L<Locale::Maketext::Lexicon> options

  # in your MyApp.pm
  __PACKAGE__->load_plugins('L10N' => {
      accept_langs   => [qw/ ja /],
      lexicon_options => {
          _auto => 0,
      },
  });

=head2 you can implement L10N class yourself 

  package L10N;
  use strict;
  use warnings;
  use parent 'Locale::Maketext';
  use File::Spec;
  
  use Locale::Maketext::Lexicon +{
      'ja'     => [ Gettext => File::Spec->catfile('t', 'po', 'ja.po') ],
      _preload => 1,
      _style   => 'gettext',
      _decode  => 1,
  };
  
  # in your MyApp.pm
  __PACKAGE__->load_plugins('L10N' => {
      accept_langs => [qw/ ja /],
      l10n_class   => 'L10N',
  });

=head1 Translation Step

=head2 installing dependent module of amon2-xgettext.pl

  $ cpanm --with-suggests Amon2::Plugin::L10N

dependnt module list in the L<cpanfile> file.

=head2 write your application

=head2 run amon2-xgettext.pl

  $ cd your_amon2_proj_base_dir
  $ perl amon2-xgettext.pl en ja fr zh-tw

=head2 edit .po files

  $ vim po/ja.po
  $ vim po/zh-tw.po

=head1 Add Amon2 Context Method

=head2 $c->l10n_language_detection

Language that is detected will return.

=head2 $c->loc($message), $c->loc('foo %1 .. %2 ...', @args);

It will return the text in the appropriate language.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 COPYRIGHT

Copyright 2013- Kazuhiro Osawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Amon2>,
L<Locale::Maketext::Lexicon>,
L<HTTP::AcceptLanguage>,
L<amon2-xgettext.pl>

=cut
