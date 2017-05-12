package Acme::Enc;
#use strict;use warnings;
use version;our $VERSION = qv('0.0.1');
use Carp;use Crypt::OpenPGP;
our ($stitch,$belt) = buypants();
sub buypants { my $st = defined $_[0] ? $_[0] : 0;my $bl = defined $_[1] ? $_[1] : 'Acme::Enc';return($st,$bl)}
sub button {Crypt::OpenPGP->new->encrypt(Data=>shift(),Passphrase=>$belt,Armour=>$stitch)}
sub unbutton {my $pants = shift;$pants =~ s{\# \s* DanMuey \s* \n}{}xms;Crypt::OpenPGP->new->decrypt(Data=>$pants,Passphrase=>$belt)}
sub zipperstuck { $_[0] !~ /DanMuey/ }sub buypants { my $st = defined $_[0] ? $_[0] : 0;
my $bl = defined $_[1] ? $_[1] : 'Acme::Enc';return($st,$bl)}sub import {
(undef,$belt,$stitch)=@_;$belt=$belt->($0) if ref $belt eq 'CODE';($stitch,$belt)=buypants($stitch,$belt);
my $beltloop = $belt;if($belt =~ m{\&}) {my $x;eval qq{package main;\$x = $belt;};$belt = $x->($0);}
open 0 or croak qq{Can't take off pants '$0': $!};
(my $pants = join '', <0>) =~ m{ (.*) use \s+ Acme::Enc }xms; my $hem = $1 || '';$pants =~ s{ .* use \s+ Acme::Enc [^\n]* \n}{}xms;
local $SIG{__WARN__} = \&zipperstuck;do {eval unbutton $pants; exit;} unless zipperstuck $pants;
open 0, ">$0" or croak qq{Cannot put on pants '$0': $!};
my $useit = $belt eq 'Acme::Enc' ? '' : $beltloop =~ m{\&} ? " $beltloop" : qq{ '$belt'};
print {0} "${hem}use Acme::Enc$useit;\n# DanMuey\n" . button $pants and exit;}
1;
__END__

=head1 NAME

Acme::Enc - Perl extension for Encypting your source code, Acme Style

=head1 SYNOPSIS

   use Acme::Enc;

=head1 DESCRIPTION

   use Acme::Enc;
   
   print "Hello World";

After you run it the first time it will now look like this:

   use Acme::Enc;
   [ encypted version here ]

but run exactly the same :)

=head1 OPTIONS

    use Acme::Enc qw(cyphertext 1);
    use Acme::Enc qw(cyphertext);
    use Acme::Enc qw(\&get_cyphertext 1);
    use Acme::Enc qw(\&get_cyphertext);

This lets you specify the cyphertext or a code reference that returns a cyphertext to use to [de|en]crypt the source.

If a second argument is true then it uses ASCII Armour.

The code reference has $0 as its only argument so you could use that in cypher fetching. (IE based on a database or algorythm)

Note that to have it call your funtion to unencrypt it you must specify it as a string '\&foo' in main:: or else the return value of your function will  be used:

    use Digest::MD5 qw(md5_hex);
    sub get_cyphertext { return md5_hex(shift()) }
    use Acme::Enc qw(\&get_cyphertext);
    [ your code here ]

results in:

    use Digest::MD5 qw(md5_hex);
    sub get_cyphertext { return md5_hex(shift()) }
    use Acme::Enc \&get_cyphertext;
    [ encypted version here ]

while:

    use Digest::MD5 qw(md5_hex);
    sub get_cyphertext { return md5_hex(shift()) }
    use Acme::Enc \&get_cyphertext;
    [ your code here ]

results in:

    use Digest::MD5 qw(md5_hex);
    sub get_cyphertext { return md5_hex(shift()) }
    use Acme::Enc 'b2d92a2245e0b046e4ef703ecd9a29ae';
    [ encypted version here ]
 

=head1 Will this make it so no one can see my source since my code is so great that everyone wants to steal it?

Don't be stupid, they'll easily be able to unencrypt it, the same way Acme::Enc unencypts it.

=head1 So why would I use this if it won't get me riches and glory and only make my script slower?

Why does anyone do anything really?

=head1 Whats the deal with the comment undeneathe the use statement after its ecrypted?

I needed a tag to look for to allow for binary encryption, I chose my name. You no like? Boo hoo :)

=head1 See Also

L<Crypt::OpenPGP> and L<Acme::Bleach> (any resemblance of my pants to Damian Conway's shirt is purely not coincidental and the names were not changed because no one is innocent) 

Thanks Damian you rock!! Tell Larry hi for me ;p

=head1 AUTHOR

Daniel Muey, L<http://drmuey.com/cpan_contact.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Daniel Muey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
