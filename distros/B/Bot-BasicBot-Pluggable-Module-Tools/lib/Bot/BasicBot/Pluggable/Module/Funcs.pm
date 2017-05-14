package Bot::BasicBot::Pluggable::Module::Funcs;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);


sub said { 
    my ($self, $mess, $pri) = @_;

    my $body = $mess->{body}; 
    my $who  = $mess->{who};

    return unless ($pri == 2);

    if ($body =~ /^\s*(asci*|chr) (\d+)\s*$/) {
        my $res;
        my $num = $2;
        if ($num < 32) {
            $num += 64;
            $res = "^".chr($num);
        } else {
            $res = chr($2);
        }
        if ($num == 0) { $res = "NULL"; } ;
        return "ascii $2 is $res";
    }

    if ($body =~ /^\s*ord (.)\s*$/) {
        my $res = $1;
        if (ord($res) < 32) {
            $res = chr(ord($res) + 64);
            if ($res eq chr(64)) {
                $res = 'NULL';
            } else {
               $res = '^'.$res;
             }
         }
         return "$res is ascii ".ord($1);
     }

    if ($body =~ /^\s*crypt\s+(\S+)\s+(\S+)/) {
        return crypt($1, $2);
    }

    if ($body =~ /^rot13\s+(.*)/i) {
        # rot13 it
        my $reply = $1;
        $reply =~ y/A-Za-z/N-ZA-Mn-za-m/;
        return $reply;
    }



}

sub help {
    return "Commands: '(chr|ascii) <number>', 'ord <char>', 'rot13 <string>', 'crypt <PLAINTEXT> <SALT>' ";
}

1;

__END__


=head1 NAME

Bot::BasicBot::Pluggable::Module::Funcs - various functions put here for inforbot compatability completeness

=head1 IRC USAGE

    (chr|ascii) <number>
    ord <char>
    rot13 <string>
    crypt <PLAINTEXT> <SALT>

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

=cut 

