package Bot::BasicBot::Pluggable::Module::Dice;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Games::Dice 'roll';

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);
    return unless $body =~ /roll (\d+d\d+)/i;

    return roll(lc($1));
}

sub help {
    return "Commands: 'roll <dice>'";
}

1;

__END__


=head1 NAME

Bot::BasicBot::Pluggable::Module::Dice - roll some dice

=head1 SYNOPSIS

Allows you to roll D&D style dice commands such as 1d6;

=head1 IRC USAGE

    roll <dice>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

=cut 

