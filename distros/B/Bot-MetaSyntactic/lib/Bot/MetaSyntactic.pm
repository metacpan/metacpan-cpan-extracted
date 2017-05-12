package Bot::MetaSyntactic;
use strict;
use Acme::MetaSyntactic;
use Bot::BasicBot;
use Carp;
use I18N::LangTags qw(extract_language_tags);
use Text::Wrap;

{ no strict;
  $VERSION = '0.0301';
  @ISA = qw(Bot::BasicBot);
}

=head1 NAME

Bot::MetaSyntactic - IRC frontend to Acme::MetaSyntactic

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Bot::MetaSyntactic;

    Bot::MetaSyntactic->new(
        nick => 'meta',
        name => 'Acme::MetaSyntactic IRC frontend',
        server => 'irc.perl.org',
        channels => ['#randomchan']
    )->run

=head1 DESCRIPTION

This module provides the glue for providing an IRC interface to 
the module C<Acme::MetaSyntactic>.

=head1 FUNCTIONS

=over 4

=item init()

Initializes private data.

=cut

sub init {
    my $self = shift;

    $self->{meta} = {
        obj   => undef, 
        limit => 100, 
        wrap  => 256, 
    };
    
    $Text::Wrap::columns = $self->{meta}{wrap};

    $self->{meta}{obj} = Acme::MetaSyntactic->new 
      or carp "fatal: Can't create new Acme::MetaSyntactic object" 
      and return undef;
}

=item said()

Main function for interacting with the bot object. 
It follows the C<Bot::BasicBot> API and expect an hashref as argument. 
See L<"COMMANDS"> for more information on recognized commands. 

=cut

sub said {
    my $self = shift;
    my $args = shift;
    my($number,$theme);

    # don't do anything unless directly addressed
    return undef unless $args->{address} eq $self->nick or $args->{channel} eq 'msg';
    return if $self->ignore_nick($args->{who});

    # ignore karma
    return if index($args->{body}, '++') == 0;
    return if index($args->{body}, '--') == 0;

    my @themes = Acme::MetaSyntactic->themes;

    {
      $args->{body} =~ s/\b(\d+)\b//;
      $number = defined($1) ? $1 : 1;
      $number = $self->{meta}{limit} if $number > $self->{meta}{limit};
    }

    {
      $args->{body} =~ s/(\w+)//;
      $theme = $1 || 'any';
    }

    if ($theme eq 'version') {
        $args->{body} = sprintf "%s IRC bot, using %s", $self->nick, 
            join ', ', map { $_ . ' ' . $_->VERSION } qw(
                Acme::MetaSyntactic  Bot::BasicBot  Bot::MetaSyntactic 
                POE  POE::Component::IRC
            );
        $self->say($args);
        return undef;
    }

    if ($theme eq 'themes') {
        $args->{body} = "Available themes: @themes";
        $self->say($args);
        return undef;
    }
    
    unless (Acme::MetaSyntactic->has_theme($theme)) {
        $args->{body} = "No such theme: $theme";
        $self->say($args);
        return undef;
    }

    my @words = $self->{meta}{obj}->name($theme => $number);
    @words = @words[0..$self->{meta}{limit}] if @words > $self->{meta}{limit};

    $args->{body} = join ' ', wrap('', '', @words);
    $self->say($args);

    return undef
}

=item help()

Prints usage.

=cut

sub help {
    return "usage: meta [theme] [number]\n".
           "  use theme name 'themes' to print all available themes"
}

=back

=head1 COMMANDS

Syntax (assuming the name of the bot is C<meta>): 

    meta [theme] [number]
    meta themes

Called with no argument, print this number of random words from a random theme.

Called with a theme name, print this number of random words from this theme.

Called with C<themes>, print all available themes. 


=head1 DIAGNOSTICS

=over 4

=item Can't create new %s object

B<(F)> Occurs in C<init()>. As the message says, we were unable to create 
a new object of the given class. 

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Bot::BasicBot>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, E<lt>sebastien@aperghis.netE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bot-metasyntactic@rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-MetaSyntactic>. 
I will be notified, and then you'll automatically be notified 
of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Bot::MetaSyntactic
