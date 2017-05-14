package Bot::BasicBot::Pluggable::Module::Magic8Ball;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

use Acme::Magic8Ball;

sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);
    return unless $body =~ /^\s*(8-?ball|divine)\s+(.*)/i;
    
    my $question = $2;
    return Acme::Magic8Ball::ask($question);

}

sub help {
    return "Commands: '8-ball <word>', 'divine <word>'";
}

1;

__END__


=head1 NAME

Bot::BasicBot::Pluggable::Module::Magic8Ball - the answer to all life's little problems

=head1 IRC USAGE

    8-ball <question>
    divine <question>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

=cut 

