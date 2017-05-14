package Bot::BasicBot::Pluggable::Module::Spell;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);


sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);
    return unless $body =~ s/^spell(ing)?\s+(?:of |for )?\s+//i;

    # h-h-h-hack
    use Lingua::Ispell qw( :all );
    Lingua::Ispell::allow_compounds(1);

    my ($r) = spellcheck($body);

    return "$body is probably spelt correctly" unless $r;


    return "$1 is spelt correctly"                        if ($r->{type} eq 'ok');
    return "$1 can be formed from the root ".$r->{'root'} if ($r->{type} eq 'root');
    return "$1 is a valid compund word"                   if ($r->{'type'} eq 'compound' );
    return "Near misses: ".join(", ",@{$r->{'misses'}})   if ($r->{'type'} eq 'miss' );
    return "Suggestions: ".join(", ", @{$r->{'guesses'}}) if ($r->{type} eq 'guess');

    return "I have no idea, sorry";
}

sub help {
    return "Commands: 'spell <word>'";
}

1;

__END__


=head1 NAME

Bot::BasicBot::Pluggable::Module::Spell - check your spelling

=head1 IRC USAGE

    spell <word>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

=cut 

