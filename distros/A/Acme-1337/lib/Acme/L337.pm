package L337;

use strict;

sub translate($string) {
   # Common leet
   my $tempstring;
   $tempstring =~ "tr/[i,I]/!";
   $tempstring =~ "tr/[t,T]/7";
   $tempstring =~ "tr/[e,E]/3";
   $tempstring =~ "tr/[S,s]/5";
   $tempstring =~ "tr/[l,L]/1";
   $tempstring =~ "tr/[B,b]/8";
   $tempstring =~ "tr/[Z,z]/2";
   $tempstring =~ "tr/[A,a]/4";
   $tempstring =~ "tr/[G,g]/9";
   $tempstring =~ "tr/[O,o]/0";
   return $tempstring;
}

1;

__END__

=head1 NAME

Acme::L337 - translate text to leet speak (Perl is funny about versions)

=head1 DESCRIPTION

Acme::L337 is a perl module to translate any string to leet speak.

=head1 FUNCTIONS

=item $leetspeaktranslator->translate($string)

Translates the $string and returns the translated string.
