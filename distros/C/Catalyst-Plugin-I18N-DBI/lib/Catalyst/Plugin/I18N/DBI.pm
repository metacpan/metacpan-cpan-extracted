package Catalyst::Plugin::I18N::DBI;

use strict;
use warnings;

use base qw(Locale::Maketext);

use DBI;
use Moose::Role;
use I18N::LangTags ();
use I18N::LangTags::Detect;
use Scalar::Util ();

use Locale::Maketext::Lexicon v0.2.0;

use version; our $VERSION = qv("0.2.5");

=head1 NAME

Catalyst::Plugin::I18N::DBI - DBI based I18N for Catalyst

=head1 SYNOPSIS

    use Catalyst 'I18N::DBI';

    print $c->loc('Hello Catalyst');

Or in your Mason code:

   <% $c->loc('Hello [_1]', 'Catalyst') %>

Or in your TT code (with macro): 

   [% MACRO l(text, args) BLOCK;
       c.loc(text, args);
   END; %]

   [% l('Hello Catalyst') %]
   [% l('Hello [_1]', 'Catalyst') %]
   [% l('lalala[_1]lalala[_2]', ['test', 'foo']) %]

=head1 DESCRIPTION

Unlike L<Catalyst::Plugin::I18N::DBIC> this plugin isn't based on any other Catalyst plugin.
It makes direct use of L<Locale::Maketext::Lexicon> and L<Locale::Maketext::Lexicon::DBI>.

Lexicon texts are held in a database table where you can have several lexicons
which are separated by the 'lex' column.  See L<Locale::Maketext::Lexicon::DBI> for more
information about the table definition.  All specified lexicons are loaded into memory
at startup, so we don't need to fetch the lexicon entries every time we need them.

Please read this document and L<Catalyst::Plugin::I18N::DBIC>'s POD carefully before
deciding which module to use in your case.

=head2 CONFIGURATION

In order to be able to connect to the database, this plugin needs some configuration,
for example:

    __PACKAGE__->config(
        'I18N::DBI' => {
                         dsn          => 'dbi:Pg:dbname=postgres',
                         user         => 'pgsql',
                         password     => '',
                         languages    => [qw(de en)],
                         lexicons     => [qw(*)],
                         lex_class    => 'DB::Lexicon',
                         default_lang => 'de',
                       },
    );

=over

=item dsn

This is the Data Source Name which will be passed to the C<connect> method of L<DBI>.
See L<DBI> for more information about DSN syntax.

=item user

Name of a database user with read B<and> write access to the lexicon table
and dependent sequences.  (When C<fail_with> is set to C<0>, the user doesn't
need to have write access.)

=item password

The password for the database user.

=item languages

An array reference with language names that shall be loaded into memory.  Basically,
this is the content of the C<lang> column.

=item lex_class

Defines the model for the lexicon table.

=item fail_with

Boolean indicating whether to use the C<fail_with> function or not.  Defaults to true.
See L</FAQ> for details.

=item default_lang

Default language which is chosen when no browser accepted language is available.

=back

=head1 METHODS

=head2 loc

Localize text:

    print $c->loc('Welcome to Catalyst, [_1]', 'Matt');

=cut

sub loc {
    my $c    = shift;
    my $text = shift;
    my $args = shift;

    my $lang_handle;
    my $handles = $c->config->{'I18N::DBI'}->{handles};
    foreach (@{ $c->languages }) {
        if ($lang_handle = $handles->{$_}) {
            last;
        }
    }

    unless ($lang_handle) {
        unless ($lang_handle = $handles->{ $c->config->{'I18N::DBI'}->{default_lang} }) {
            $c->log->fatal("No default language '" . $c->config->{'I18N::DBI'}->{default_lang} . "' available!");
            return $text;
        }
    }

    my $value;
    if (ref $args eq 'ARRAY') {
        $value = $lang_handle->maketext($text, @$args);
    } else {
        $value = $lang_handle->maketext($text, $args, @_);
    }

    utf8::decode($value);
    return $value;
}

=head2 localize

Alias method to L</loc>.

=cut

*localize = \&loc;

=head2 languages

Contains languages.

   $c->languages(['de_DE']);
   print join '', @{ $c->languages };

=cut

sub languages {
    my ($c, $languages) = @_;

    if ($languages) {
        $c->{languages} = $languages;
    } else {
        $c->{languages} ||= [I18N::LangTags::implicate_supers(I18N::LangTags::Detect->http_accept_langs($c->request->header('Accept-Language')))];
    }

    return $c->{languages};
}

=head1 EXTENDED AND INTERNAL METHODS

=head2 setup

=cut

after 'setup_finalize' => sub {
    my $c = shift;

    $c->_init_i18n;
    $c->log->debug("I18N Initialized");
};

sub _init_i18n {
    my $c = shift;

    my $cfg = $c->config->{'I18N::DBI'};
    my $dbh = DBI->connect($cfg->{dsn}, $cfg->{user}, $cfg->{password}, $cfg->{attr});

    my $default_lex = $cfg->{lexicons}->[0];

    my (%handles, %initialized);
    foreach my $lang (@{ $cfg->{languages} }) {
        $lang =~ y/_/-/;

        foreach my $lex (@{ $cfg->{lexicons} }) {

            unless ($initialized{$lang}) {
                eval <<"";
                    package ${c}::${lang};
                    no strict;
                    use base 'Locale::Maketext';
                    # Need a dummy key to overlive the optimizer (or similar)!
                    %Lexicon = (dummy => '1');

                $initialized{$lang} = 1;
            }

            eval <<"";
                package $c;
                use base 'Locale::Maketext';
                Locale::Maketext::Lexicon->import(
                                       { \$lang => ['DBI' => ['lang' => \$lang, 'lex' => \$lex, dbh => \$dbh]] });

            if ($@) {
                $c->log->error(qq|Couldn't initialize I18N for lexicon $lang/$lex, "$@"|);
            } else {
                $c->log->debug(qq|Lexicon $lang/$lex loaded|);
            }
        }

        $handles{$lang} = $c->get_handle($lang);

        if (!defined $cfg->{fail_with} || $cfg->{fail_with}) {
            $handles{$lang}->fail_with(
                sub {
                    my ($flh, $key, @params) = @_;
                    my $value;
                    eval {
                        my $res = $c->model($cfg->{lex_class})->search({ lex_key => $key, lang => $lang, lex => $default_lex })->first;
                        unless ($res) {
                            my $rec = $c->model($cfg->{lex_class})->create(
                                                                                     {
                                                                                       lex       => $default_lex,
                                                                                       lex_key   => $key,
                                                                                       lex_value => '? ' . $key,
                                                                                       lang      => $lang
                                                                                     }
                                                                                    );
                            $value = $rec->lex_value;
                        } else {
                            $value = $res->lex_value;
                        }
                    };
                    $c->log->error("Failed within fail_with(): $@") if $@;

                    return $value;
                }
            );
        }
    }

    $cfg->{handles} = \%handles;

    $dbh->disconnect;
}

=head1 FAQ

=head2 Why use C<C::P::I18N::DBI> instead of C<C::P::I18N::DBIC>?

Sometimes you don't want to select and parse the data from the database each
time you access your lexicon.  Then C<C::P::I18N::DBI> is for you!  It loads the
lexicon into memory at startup instead of fetching it over and over again.
But be careful, as this approach can waste a lot of memory and may slow your
system down (depending of the amount of data in your lexicon).

I recommend to test both modules and decide which one is more suitable
depending on your production environment.

=head2 Why does the database user needs write access?  Or: What's the C<fail_with> function? 

C<C::P::I18N::DBI> implements a C<fail_with> method that attempts to create a new
database entry whenever a lexicon lookup fails.  The value is set to the lexicon
key prefixed with the string C<? >.

Example: you look up C<FooBar>, which doesn't exist.  A new database entry will be
created with that key, the value will be C<? FooBar>.

You can disable this behavior by setting the config key C<fail_with> to zero.

=head1 SEE ALSO

L<Calatyst>, L<Locale::Maketext>, L<Locale::Maketext::Lexicon>, L<Locale::Maketext::Lexicon::DBI>, L<DBI>,
L<Catalyst::Plugin::I18N::DBIC>

=head1 AUTHOR

Matthias Dietrich, C<< <perl@rainboxx.de> >>, http://www.rainboxx.de

=head1 THANKS TO

Rafael Kitover and Octavian Râşniţă for Bugfixes

=head1 COPYRIGHT AND LICENSE

Copyright 2008 - 2009 rainboxx Matthias Dietrich.  All Rights Reserved.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
