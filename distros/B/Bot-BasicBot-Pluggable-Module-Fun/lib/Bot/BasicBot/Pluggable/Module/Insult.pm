package Bot::BasicBot::Pluggable::Module::Insult;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

#use Net::Telnet;
use Lingua::Translate;


our %languages = (
                  'english'    => 'en',
                  'chinese'    => 'zh',
                  'french'     => 'fr',
                  'german'     => 'de',
                  'italian'    => 'it',
                  'japanese'   => 'ja',
                  'korean'     => 'ko',
                  'portuguese' => 'pt',
                  'spanish'    => 'es'
);

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);


    return unless $body =~ /^\s*insult (.*)\s*$/;
    my $person   = $1;
    my $language = "english";

    if ($person =~ s/ in ([a-z]+)\s*\w*\s*//i) {
        $language = lc($1);
    }
    
    $person = $who if $person =~ /^\s*me\s*$/i;

    my $insultgenerator = Acme::Scurvy::Whoreson::BilgeRat->new( language => 'insultserver' );

    my $insult = "$insultgenerator";    


    return "Errk, the insult code is mysteriously not working" unless defined $insult;

    $insult =~ s/^\s*You are/$person is/i if ($person ne $who);  


    return $insult if $language eq 'english';

    my $xl8r = Lingua::Translate->new(src => "en", dest => $languages{$language})
         or return $insult;

    my $translated_insult; 
    eval {  
            $translated_insult = $xl8r->translate($insult);
    };
    $translated_insult = $insult if $@;

    return $translated_insult;

}

sub help {
    return "Commands: 'insult <who> [in <language>]'";
}

1;


__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Insult - insult people (in a variety of languages)

=head1 SYNOPSIS


=head1 IRC USAGE

    insult <who> [in <language>]

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Math::Units>

=cut 

