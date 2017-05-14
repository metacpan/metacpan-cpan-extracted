package Bot::BasicBot::Pluggable::Module::Hyperarchive;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);


sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);

    return unless $body =~ s!^\s*hyperarchive (for )?!!i;
    
    return "You must supply a word" unless $body =~ /\w+/;
    my $q = $body; $q =~ s/\W+/+/g;
    return "$body may be sought at http://hyperarchive.lcs.mit.edu/cgi-bin/NewSearch?key=$q";

}

sub help {
    return "Commands: 'hyperarchive (for ) <word>'";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Hyperarchive - give the url of search on Hyperarchive

=head1 SYNOPSIS

This is almost useless but it's provided as part of Infobot backwards compatability.

=head1 IRC USAGE

    hyperarchive (for ) <word>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

