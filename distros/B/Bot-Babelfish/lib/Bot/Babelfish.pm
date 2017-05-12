package Bot::Babelfish;
use strict;
use Bot::BasicBot;
use Carp;
use Encode;
use I18N::LangTags qw(extract_language_tags is_language_tag);
use I18N::LangTags::List;
use Lingua::Translate;
use Text::Unidecode;

{ no strict;
  $VERSION = '0.04';
  @ISA = qw(Bot::BasicBot);
}

=head1 NAME

Bot::Babelfish - Provides Babelfish translation services via an IRC bot

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    use Bot::Babelfish;

    my $bot = Bot::Babel->new(
        nick => 'babel',  name => 'Babelfish bot', 
        server => 'irc.perl.org', channels => [ '#mychannel' ]
    )->run

=head1 DESCRIPTION

This module provides the backend for an IRC bot which can be used as an 
interface for translation services using Babelfish. 

=head1 METHODS

=over 4

=item init()

Initializes private data. 

=cut

sub init {
    my $self = shift;
    
    $self->{babel} = {
        cache       => {}, 
    };

    return 1
}

=item said()

Main function for interacting with the bot object. 
It follows the C<Bot::BasicBot> API and expect an hashref as argument. 
See L<"COMMANDS"> for more information on recognized commands. 

=cut

sub said {
    my $self = shift;
    my $args = shift;

    # don't do anything unless directly addressed
    return undef unless $args->{address} eq $self->nick or $args->{channel} eq 'msg';
    return if $self->ignore_nick($args->{who});

    # ignore karma
    return if index($args->{body}, '++') == 0;
    return if index($args->{body}, '--') == 0;

    if($args->{body} =~ /^ *version/) {
        $args->{body} = sprintf "%s IRC bot, using %s", $self->nick, 
            join ', ', map { $_ . ' ' . $_->VERSION } qw(
                Bot::BasicBot  Bot::Babelfish  Encode  Lingua::Translate 
                POE  POE::Component::IRC
            );
        $self->say($args);
        return undef;
    }

    #print STDERR $/, $args->{body}, $/;
    my ($from, $to) = extract_language_tags($args->{body} );
    $from ||= 'en';
    $to   ||= 'fr';
    #print STDERR " $from -> $to : ", $args->{body}, $/;

    unless(is_language_tag($from)) {
        $args->{body} = "Unrecognized language tag '$from'";
        $self->say($args);
        return undef
    }

    unless(is_language_tag($to)) {
        $args->{body} = "Unrecognized language tag '$to'";
        $self->say($args);
        return undef
    }

    my $from_to = "$from>$to";
    my($from_lang,$to_lang) = map { I18N::LangTags::List::name($_) } $from, $to;

    my $translator = new Lingua::Translate src => $from, dest => $to;
    unless(defined $translator) {
        $args->{body} = "Can't translate from $from_lang to $to_lang";
        $self->say($args);
        return undef
    }

    my $text = encode('utf-8', decode('iso-8859-1', $args->{body}));
    my $result = $self->{babel}{cache}{$from_to}{$text};

    unless($result) {
        eval { $result = decode('utf-8', $translator->translate($text)) };
        $self->{babel}{cache}{$from_to}{$text} = $result unless $@;
    }
    #print STDERR " ($@) result = $result\n";

    $text = non_unicode_version(decode('utf-8', $text));
    $result = non_unicode_version($result);

    $args->{body} = defined($result) ? qq|$to_lang for "$text" => "$result"| : "error: $@";
    $self->say($args);
    
    return $args
}

=item help()

Prints usage.

=cut

sub help {
    return "usage: babel: from to: text to translate\n".
           "  where 'from' and 'to' are two-letters codes of source and destination languages\n".
           "  see http://babelfish.altavista.com/ for the list of supported languages.\n".
           "  example:    babel: fr en: ceci n'est pas une pipe"
}

=item non_unicode_version()

This function returns a printable version of the given string 
(with a European value of "printable" C<:-)>. More precisely, 
if the string only contains Latin-1 characters, it is returned 
decoded from internal Perl format. If the string contains 
others characters outside Latin-1, it's converted using 
C<Text::Unidecode>. 

=cut

sub non_unicode_version {
    my $text = shift;
    my $wide = 0;
    ord($_) > 255 and $wide++ for split //, $text;
    return $wide ? unidecode($text) : encode('iso-8859-1', $text)
}

=back


=head1 COMMANDS

=over 4

=item translation

    babel from to: some text to translate

Where C<from> and C<to> are ISO-639 two-letters codes representing the languages. 
See L<http://babelfish.altavista.com/> for the list of supported languages. 

B<Examples>

    babel: fr en: ceci n'est pas une pipe
    <babel> English for "ceci n'est pas une pipe" => "this is not a pipe"

=item help

    babel help

Shows how to use this bot. 

=item version

    babel version

Prints the version of this module and its dependencies. 

=back

=head1 DIAGNOSTICS

=over 4

=item Can't create new %s object

B<(F)> Occurs in C<init()>. As the message says, we were unable to create 
a new object of the given class. 

=back

=head1 SEE ALSO

L<Bot::BasicBot>, L<Text::Unidecode>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to 
C<bug-bot-babel@rt.cpan.org>, or through the web interface at 
L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-Babelfish>. 
I will be notified, and then you'll automatically be notified 
of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Bot::Babelfish
