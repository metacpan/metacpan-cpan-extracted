package Catalyst::Plugin::I18N;

use strict;
use warnings;

use MRO::Compat;
use I18N::LangTags ();
use I18N::LangTags::Detect;
use I18N::LangTags::List;

require Locale::Maketext::Simple;

our $VERSION = '0.10';
our %options = ( Export => '_loc', Decode => 1 );

=head1 NAME

Catalyst::Plugin::I18N - I18N for Catalyst

=head1 SYNOPSIS

    use Catalyst 'I18N';

    print join ' ', @{ $c->languages };
    $c->languages( ['de'] );
    print $c->localize('Hello Catalyst');

Use a macro if you're lazy:

   [% MACRO l(text, args) BLOCK;
       c.localize(text, args);
   END; %]

   [% l('Hello Catalyst') %]
   [% l('Hello [_1]', 'Catalyst') %]
   [% l('lalala[_1]lalala[_2]', ['test', 'foo']) %]
   [% l('messages.hello.catalyst') %]

=head1 DESCRIPTION

Supports mo/po files and Maketext classes under your application's I18N
namespace.

   # MyApp/I18N/de.po
   msgid "Hello Catalyst"
   msgstr "Hallo Katalysator"

   # MyApp/I18N/i_default.po
   msgid "messages.hello.catalyst"
   msgstr "Hello Catalyst - fallback translation"

   # MyApp/I18N/de.pm
   package MyApp::I18N::de;
   use base 'MyApp::I18N';
   our %Lexicon = ( 'Hello Catalyst' => 'Hallo Katalysator' );
   1;

=head2 CONFIGURATION

You can override any parameter sent to L<Locale::Maketext::Simple> by specifying
a C<maketext_options> hashref to the C<Plugin::I18N> config section. For
example, the following configuration will override the C<Decode> parameter which
normally defaults to C<1>:

    __PACKAGE__->config(
        'Plugin::I18N' =>
            maketext_options => {
                Decode => 0
            }
    );

All languages fallback to MyApp::I18N which is mapped onto the i-default
language tag. If you use arbitrary message keys, use i_default.po to translate
into English, otherwise the message key itself is returned.

=head2 EXTENDED METHODS

=head3 setup

=cut

sub setup {
    my $self = shift;
    $self->next::method(@_);
    my $calldir = $self;
    $calldir =~ s{::}{/}g;
    my $file = "$calldir.pm";
    my $path = $INC{$file};
    $path =~ s{\.pm$}{/I18N};

    my $user_opts = $self->config->{ 'Plugin::I18N' }->{ maketext_options } || {};
    local %options = ( %options, Path => $path, %$user_opts );

    eval <<"";
        package $self;
        Locale::Maketext::Simple->import( \%Catalyst\::Plugin\::I18N\::options );


    if ($@) {
        $self->log->error(qq/Couldn't initialize i18n "$self\::I18N", "$@"/);
    }
    else {
        $self->log->debug(qq/Initialized i18n "$self\::I18N"/) if $self->debug;
    }

    if (! $self->config->{ 'Plugin::I18N' }->{installed_languages}) {
        my $languages_list = {};
        # We re-read the list of files in $path
        # Originally tried to detect via namespaces, but this lists the currently set LANG envvar, which may not
        # be a supported language. Also misses out .pm files
        # Is acceptable to re-read this directory once on setup
        if (opendir my $langdir, $path) {
            foreach my $entry (readdir $langdir) {
                next unless $entry =~ m/\A (\w+)\.(?:pm|po|mo) \z/xms;
                my $langtag = $1;
                next if $langtag eq "i_default";
                my $language_tag = $langtag;
                #my $language_tag = "$class\::I18N"->get_handle( $langtag )->language_tag;
                # Did use the get_handle, but that caused problems because en became "Default (Fallthru) Language"
                # Just do a simple convert instead
                $language_tag =~ s/_/-/g;
                $languages_list->{ $langtag } = I18N::LangTags::List::name( $language_tag );
            }
            closedir $langdir;
        }
        $self->config->{ 'Plugin::I18N' }->{installed_languages} = $languages_list;
    }
}

=head2 METHODS

=head3 languages

Contains languages.

   $c->languages(['de_DE']);
   print join '', @{ $c->languages };

=cut

sub languages {
    my ( $c, $languages ) = @_;
    if ($languages) { $c->{languages} = $languages }
    else {
        $c->{languages} ||= [
            I18N::LangTags::implicate_supers(
                I18N::LangTags::Detect->http_accept_langs(
                    $c->request->header('Accept-Language')
                )
            ),
            'i-default'
        ];
    }
    no strict 'refs';
    &{ ref($c) . '::_loc_lang' }( @{ $c->{languages} } );
    return $c->{languages};
}

=head3 language

return selected locale in your locales list.

=cut

sub language {
    my $c = shift;
    my $class = ref $c || $c;

    my $lang = ref "$class\::I18N"->get_handle( @{ $c->languages } );
    $lang =~ s/.*:://;

    return $lang;
}

=head3 language_tag

return language tag for current locale. The most notable difference from this
method in comparison to C<language()> is typically that languages and regions
are joined with a dash and not an underscore.

    $c->language(); # en_us
    $c->language_tag(); # en-us

=cut

sub language_tag {
    my $c = shift;
    my $class = ref $c || $c;

    return "$class\::I18N"->get_handle( @{ $c->languages } )->language_tag;
}

=head3 installed_languages

Returns a hash of { langtag => "descriptive name for language" } based on language files
in your application's I18N directory. The descriptive name is based on I18N::LangTags::List information.
If the descriptive name is not available, will be undef.

=cut

sub installed_languages {
    my $c = shift;
    return $c->config->{ 'Plugin::I18N' }->{installed_languages};
}

=head3 loc

=head3 localize

Localize text.

    print $c->localize( 'Welcome to Catalyst, [_1]', 'sri' );

=cut

*loc = \&localize;

sub localize {
    my $c = shift;
    $c->languages;
    no strict 'refs';
    return &{ ref($c) . '::_loc' }( $_[0], @{ $_[1] } )
      if ( ref $_[1] eq 'ARRAY' );
    return &{ ref($c) . '::_loc' }(@_);
}

=head1 SEE ALSO

L<Catalyst>

=head1 AUTHORS

Sebastian Riedel E<lt>sri@cpan.orgE<gt>

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

Christian Hansen E<lt>chansen@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 - 2009
the Catalyst::Plugin::I18N L</AUTHORS>
as listed above.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
