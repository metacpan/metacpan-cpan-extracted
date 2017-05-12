package Acme::Morse; $VERSION = 1.0;
my $signed = ".--.-..--..---.-.--."x2;
sub encypher { local $_ = unpack "b*", pop; tr/01/.-/; s/(.{40})/$1\n/g;
		$signed."\n".$_ }
sub decypher { local $_ = pop; s/^$signed|[^.-]//g; tr/.-/01/; pack "b*", $_ }
sub garbled { $_[0] =~ /\S/ }
sub signed { $_[0] =~ /^$signed/ }
open 0 or print "Can't transmit '$0'\n" and exit;
(my $telegram = join "", <0>) =~ s/.*^\s*use\s+Acme::Morse\s*;\n//sm;
local $SIG{__WARN__} = \&garbled;
do {eval decypher $telegram; print STDERR $@ if $@; exit}
	unless garbled $telegram && not signed $telegram;
open 0, ">$0" or print "Cannot encode '$0'\n" and exit;
print {0} "use Acme::Morse;\n", encypher $telegram and exit;
__END__
=head1 NAME

Acme::Morse - Perl programming in morse code

=head1 SYNOPSIS

	use Acme::Morse;

	print "S-O-S\n";

=head1 DESCRIPTION

The first time you run a program under C<use Acme::Morse>, the module converts
your program to Morse code. The code continues to work exactly as it did
before, but now it looks like this:

        use Acme::Morse;
	.--.-..--..---.-.--..--.-..--..---.-.--.
	.-.-........---..-..---.-..-.--..---.--.
	..-.---......-...-...-..--..-.-.-.--.-..
	----..-.-.--.-..--..-.-...---.-..---.--.
	.-...-..--.---...-.-....

=head1 DIAGNOSTICS

=over 4

=item C<Can't encode '%s'>

Acme::Morse could not access the source file to modify it.

=item C<Can't transmit '%s'>

Acme::Morse could not access the source file to execute it.

=back 

=head1 AUTHOR

Damian Conway (as if you couldn't guess)

=head1 COPYRIGHT

   Copyright (c) 2001, Damian Conway. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)
