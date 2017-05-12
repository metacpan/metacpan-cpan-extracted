package Captive::Portal::Role::I18N;

use strict;
use warnings;

=head1 NAME

Captive::Portal::Role::I18N - utils for internationalization

=cut

our $VERSION = '4.10';

use Log::Log4perl qw(:easy);
use Scalar::Util qw(looks_like_number);

use Role::Basic;
requires qw(cfg);

=head1 ROLES

=over 4

=item $capo->choose_language()

Parses the HTTP header 'Accept-Language' and returns an appropriate language from the configured languages or the fallback language in config file.

    I18N_LANGUAGES     => [ 'en', 'de', ],  
    I18N_FALLBACK_LANG => 'en',

=cut

sub choose_language {
    my $self  = shift;
    my $query = $self->{CTX}{QUERY};

    my $http_accept_language = $query->http('HTTP_ACCEPT_LANGUAGE')
      || '';
    DEBUG("HTTP-Accept-Language is: $http_accept_language");

    ###
    # parse the HTTP header
    #
    # Example header: de-de,de;q=0.8,en-us;q=0.5,en;q=0.3
    #
    my $default_quant = 1;
    my %languages;

    foreach my $item ( split( /,/, $http_accept_language ) ) {
        $item =~ s/\s//g;    #strip spaces

        my ( $lang, $quant ) = split( /;q=/, $item );

        # don't use fine-granular language subtags for CaPo
        # cutoff the language subtags: de-AT => de
        $lang =~ s/-.*//;

        # skip silently the wildcard '*'
        next if $lang eq '*';

        # parse error, silently skip this language item
        next if defined $quant && ( not looks_like_number($quant) );

        # set the default language quantifier
        unless ( defined $quant ) {

            # give the first one a quant of 1
            $quant = $default_quant;

            # and the next without quantification .001 less
            $default_quant -= 0.001;
        }

        # first language entry
        unless ( $languages{$lang} ) {
            $languages{$lang} = $quant;
            next;
        }

        # override language entry with higher quant
        if ( $quant > $languages{$lang} ) {
            $languages{$lang} = $quant;
            next;
        }

    }

    # sort in descending quantification order
    my @accept_languages_sorted =
      sort { $languages{$b} <=> $languages{$a} } keys %languages;

    DEBUG( 'language prefered order is: '
          . join( ' > ', @accept_languages_sorted ) );

    DEBUG( 'configured languages: '
          . join( ' ', @{ $self->cfg->{I18N_LANGUAGES} } ) );

    # look for accepted language in configured languages
    my $choosen_language;
    foreach my $lang (@accept_languages_sorted) {
        if ( grep m/\A\Q$lang\E\Z/, @{ $self->cfg->{I18N_LANGUAGES} } ) {
	    DEBUG "prefered language is: $lang";
	    return $lang;
        }
    }

    DEBUG 'take fallback language';
    return $self->cfg->{I18N_FALLBACK_LANG};
}

=item $capo->gettext($msg_nr)

Poor mans gettext. Retrieve i18n system message from message catalog in config file. The default mesage catalog looks like:

    I18N_MSG_CATALOG => {
      msg_001 => {
        en => 'last session state was:',
        de => 'Status der letzten Sitzung war:',
      },

      msg_002 => {
        en => 'username or password is missing',
        de => 'Username oder Passwort fehlt',
      },

      msg_003 => {
        en => 'username or password is wrong',
        de => 'Username oder Passwort ist falsch',
      },

      msg_004 => {
        en => 'successfull logout',
        de => 'erfolgreich abgemeldet',
      },

      msg_005 => {
        en => 'admin_secret is wrong',
        de => 'Admin-Passwort ist falsch',
      },

      msg_006 => {
        en => 'Idle-session reestablished due to valid cookie.',
        de => 'Abgelaufene Sitzung durch gueltiges Cookie erneuert.',
      },
  },

Add your own translation to the conig hash.

=cut

sub gettext {
    my $self = shift;
    my $text = shift
      or LOGDIE 'missing param text';

    my $i18n_text =
      $self->cfg->{I18N_MSG_CATALOG}{$text}{ $self->{CTX}{LANG} };

    unless ($i18n_text) {
        ERROR "missing I18N text for '$text' in lang: $self->{CTX}{LANG}";
        $i18n_text = "missing '$text' for lang '$self->{CTX}{LANG}'";
    }

    return $i18n_text;
}

1;

=back

=head1 AUTHOR

Karl Gaissmaier, C<< <gaissmai at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2013 Karl Gaissmaier, all rights reserved.

This distribution is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version, or

b) the Artistic License version 2.0.

=cut

# vim: sw=4

