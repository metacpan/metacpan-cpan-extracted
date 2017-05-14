package Bot::BasicBot::Pluggable::Module::Translate;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Locale::Language;  
use Lingua::Translate;
use Lingua::Translate::Babelfish;


sub said { 
    my ($self, $mess, $pri) = @_;

    my $sentence = $mess->{body}; 
    my $who      = $mess->{who};

    return unless ($pri == 2);

    my $to;
    my $from;

    return unless ($sentence =~ s!\s*translate to (\w+)(?: from (\w+))?\s*!$to = lc($1); $from = lc($2) || 'english'; ""!ei);

    return "I need a sentence to translate!" if $sentence =~ m!^\s*$!;

    my $to_code    = (length($to)   == 2)? $to   : lc(language2code($to));  
    my $from_code  = (length($from) == 2)? $from : lc(language2code($from));
    

    my $xl8r = Lingua::Translate->new(src => $from_code, dest => $to_code) || 
               return "Can't do $from_code to $to_code"; 
    
    my $return = $xl8r->translate($sentence) || return "Hrmm, I couldn't translate '$sentence'";
    return $return;
    

}

sub help {
    return "translate to <language> [from <other language>] <phrase>";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Translate - do language translations

=head1 SYNOPSIS


=head1 IRC USAGE

    translate to <language> [from <other language>] <phrase>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

