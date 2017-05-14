package Bot::BasicBot::Pluggable::Module::Maths;

use strict;
use Bot::BasicBot::Pluggable::Module; 
use base qw(Bot::BasicBot::Pluggable::Module);

our %digits = (
               "first", "1",
               "second", "2",
               "third", "3",
               "fourth", "4",
               "fifth", "5",
               "sixth", "6",
               "seventh", "7",
               "eighth", "8",
               "ninth", "9",
               "tenth", "10",
               "one", "1",
               "two", "2",
               "three", "3",
               "four", "4",
               "five", "5",
               "six", "6",
               "seven", "7",
               "eight", "8",
               "nine", "9",
               "ten", "10"
               );



sub told { 
    my ($self, $mess, $pri) = @_;

    my $in   = $mess->{body}; 
    my $orig = $in;
    $in =~ s/\?$//; # trailing ?

    foreach my $x (keys %digits) {
        $in =~ s/\b$x\b/$digits{$x}/g;
    }

    return if $in =~ /^\s*$/;
    return if $in =~ /(\d+\.){2,}/;

    my $loc = $in;
    while ($loc =~ /(exp ([\w\d]+))/) {
           my $exp = $1;
           my $val = exp($2);
           $loc =~ s/$exp/+$val/g;
    }

    while ($loc =~ /(hex2dec\s*([0-9A-Fa-f]+))/) {
            my $exp = $1;
            my $val = hex($2);
            $loc =~ s/$exp/+$val/g;
    }
        
    if ($loc =~ /^\s*(dec2hex\s*(\d+))\s*\?*/) {
            my $exp = $1;
            my $val = sprintf("%x", "$2");
            $loc =~ s/$exp/+$val/g;
     }
    my $e = exp(1);
    $loc =~ s/\be\b/$e/;

    while ($loc =~ /(log\s*((\d+\.?\d*)|\d*\.?\d+))\s*/) {
            my $exp = $1;
            my $res = $2;
            my $val;
            if ($res == 0) { 
                $val = "Infinity";
            } else { 
                $val = log($res); 
            }
            $loc =~ s/$exp/+$val/g;
     }

     while ($loc =~ /(bin2dec ([01]+))/) {
             my $exp = $1;
             my $val = join ('', unpack ("B*", $2)) ;
             $loc =~ s/$exp/+$val/g;
     }

     while ($loc =~ /(dec2bin (\d+))/) {
             my $exp = $1;
             my $val = join('', unpack('B*', pack('N', $2)));
             $val =~ s/^0+//;
             $loc =~ s/$exp/+$val/g;
     }

     $loc =~ s/ to the / ** /g;
     $loc =~ s/\btimes\b/\*/g;
     $loc =~ s/\bdiv(ided by)? /\/ /g;
     $loc =~ s/\bover /\/ /g;
     $loc =~ s/\bsquared/\*\*2 /g;
     $loc =~ s/\bcubed/\*\*3 /g;
     $loc =~ s/\bto\s+(\d+)(r?st|nd|rd|th)?( power)?/\*\*$1 /ig;
     $loc =~ s/\bpercent of/*0.01*/ig;
     $loc =~ s/\bpercent/*0.01/ig;
     $loc =~ s/\% of\b/*0.01*/g;
     $loc =~ s/\%/*0.01/g;
     $loc =~ s/\bsquare root of (\d+)/$1 ** 0.5 /ig;
     $loc =~ s/\bcubed? root of (\d+)/$1 **(1.0\/3.0) /ig;
     $loc =~ s/ of / * /;
     $loc =~ s/(bit(-| )?)?xor(\'?e?d( with))?/\^/g;
     $loc =~ s/(bit(-| )?)?or(\'?e?d( with))?/\|/g;
     $loc =~ s/bit(-| )?and(\'?e?d( with))?/\& /g;
     $loc =~ s/(plus|and)/+/ig;

     return if $loc !~ /^\s*[-\d*+\s()\/^\.\|\&\*\!]+\s*$/;
     return if $loc =~ /^\s*\(?\d+\.?\d*\)?\s*$/;
     return if $loc =~  /^\s*$/;
     return if $loc =~ /^\s*[( )]+\s*$/;
    
     $loc = eval($loc);
     # I just realised that I could have done this with Maths::Expression and these checks
     return unless  $loc =~ /^[-+\de\.]+$/;

     $loc =~ s/\.0+$//;
     $loc =~ s/(\.\d+)000\d+/$1/;
     $loc = "a number with quite a few digits..." if (length($loc) > 30);
     $orig =~ s!(^\s*|\s*$)!!g;
     return if ($orig eq $loc) || ($orig == $loc); 
     return $loc;
}

sub help {
    return "Commands: a maths expression";
}

1;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Maths - evaluate arbitary maths expressions

=head1 SYNOPSIS

Does everything that C<Math::Expression> does;

=head1 AUTHOR

Simon Wistow, <simon@thegestalt.org>

based on code by Kevin Lenzo

=head1 COPYRIGHT

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Math::Expression>

=cut 

