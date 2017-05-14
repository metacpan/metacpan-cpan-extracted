package Bot::BasicBot::Pluggable::Module::Foldoc;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);


sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);

    return unless $body =~ m!^\s*foldoc(?: for)?\s+(.*)!i;

    my ($terms) = $1;
    $terms =~ s/\?\W*$//;

    my $key= $terms;
    $key =~ s/\s+$//;
    $key =~ s/^\s+//;
    $key =~ s/\W+/+/g;

    return "$terms may be sought in foldoc at http://foldoc.org/?$key";

}

sub help {
    return "Commands: 'websters (for ) <word>'";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Foldoc - give the url of a word in Foldoc

=head1 SYNOPSIS

This is almost useless but it's provided as part of Infobot backwards compatability.

=head1 IRC USAGE

    foldoc (for ) <word>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO


=cut 

