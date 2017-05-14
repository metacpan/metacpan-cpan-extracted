package Bot::BasicBot::Pluggable::Module::Websters;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);


sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);

    return unless $body =~ s!^\s*websters (for )?!!i;
    
    return "You must supply a word" unless $body =~ /\w+/;
    my $q = $body; $q =~ s/\W+/+/g;
    return "$body may be sought at http://www.m-w.com/cgi-bin/dictionary?va=$q";

}

sub help {
    return "Commands: 'websters (for ) <word>'";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Websters - give the url of a word in Websters

=head1 SYNOPSIS

This is almost useless but it's provided as part of Infobot backwards compatability.

=head1 IRC USAGE

    websters (for ) <word>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

