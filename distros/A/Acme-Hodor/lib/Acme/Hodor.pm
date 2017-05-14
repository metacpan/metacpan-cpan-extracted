package Acme::Hodor; $VERSION = 1.00;
my $signed = "HODOR hodor hodor HODOR "x2;
sub encypher { 
  local $_ = unpack "b*", pop;
  s/0/HODOR /g;
  s/1/hodor /g;
  s/(.{48})/$1\n/g;
  $signed."\n".$_
}
sub decypher { 
  local $_ = pop;
  s/^$signed|[^HODOR hodor ]//g;
  s/HODOR /0/g;
  s/hodor /1/g;
  pack "b*", $_
}
sub garbled {
  $_[0] =~ /\S/
}
sub signed { 
  $_[0] =~ /^$signed/
}
open 0 or print "Can't transmit '$0'\n" and exit;
(my $telegram = join "", <0>) =~ s/.*^\s*use\s+Acme::Hodor\s*;\n//sm;
local $SIG{__WARN__} = \&garbled;
do {eval decypher $telegram; print STDERR $@ if $@; exit}
	unless garbled $telegram && not signed $telegram;
open 0, ">$0" or print "Cannot encode '$0'\n" and exit;
print {0} "use Acme::Hodor;\n", encypher $telegram and exit;
__END__
=head1 NAME

Acme::Hodor - For programs that I<really> need to hold the door

=head1 SYNOPSIS

        use Acme::Hodor;
        
        print "Hold the DOOR!\n";

=head1 DESCRIPTION

The first time you run a program under C<use Acme::Hodor>, the module converts
your program to Hodor code. The code continues to work exactly as it did
before, but now it looks like this:

        use Acme::Hodor;
        HODOR hodor hodor HODOR HODOR hodor hodor HODOR 
        HODOR hodor HODOR hodor HODOR HODOR HODOR HODOR 
        HODOR HODOR HODOR HODOR hodor hodor hodor HODOR 
        HODOR hodor HODOR HODOR hodor hodor hodor HODOR 
        hodor HODOR HODOR hodor HODOR hodor hodor HODOR 
        HODOR hodor hodor hodor HODOR hodor hodor HODOR 
        HODOR HODOR hodor HODOR hodor hodor hodor HODOR 
        HODOR HODOR HODOR HODOR HODOR hodor HODOR HODOR 
        HODOR hodor HODOR HODOR HODOR hodor HODOR HODOR 
        HODOR HODOR HODOR hodor HODOR HODOR hodor HODOR 
        hodor hodor hodor hodor HODOR hodor hodor HODOR 
        HODOR HODOR hodor hodor HODOR hodor hodor HODOR 
        HODOR HODOR hodor HODOR HODOR hodor hodor HODOR 
        HODOR HODOR HODOR HODOR HODOR hodor HODOR HODOR 
        HODOR HODOR hodor HODOR hodor hodor hodor HODOR 
        HODOR HODOR HODOR hodor HODOR hodor hodor HODOR 
        hodor HODOR hodor HODOR HODOR hodor hodor HODOR 
        HODOR HODOR HODOR HODOR HODOR hodor HODOR HODOR 
        HODOR HODOR hodor HODOR HODOR HODOR hodor HODOR 
        hodor hodor hodor hodor HODOR HODOR hodor HODOR 
        hodor hodor hodor hodor HODOR HODOR hodor HODOR 
        HODOR hodor HODOR HODOR hodor HODOR hodor HODOR 
        hodor HODOR HODOR HODOR HODOR hodor HODOR HODOR 
        HODOR HODOR hodor hodor hodor HODOR hodor HODOR 
        HODOR hodor hodor hodor HODOR hodor hodor HODOR 
        HODOR hodor HODOR HODOR HODOR hodor HODOR HODOR 
        hodor hodor HODOR hodor hodor hodor HODOR HODOR 
        HODOR hodor HODOR hodor HODOR HODOR HODOR HODOR 

=head1 DIAGNOSTICS

=over 4

=item C<Can't encode '%s'>

Acme::Hodor could not access the source file to modify it.

=item C<Can't transmit '%s'>

Acme::Hodor could not access the source file to execute it.

=back 

=head1 AUTHOR

Jesse Thompson <zjt@cpan.org> with much inspiration from Damian Conway; this module is a complete rip off of Acme::Bleach and Acme::Morse

=head1 COPYRIGHT

   Copyright (c) 2016, Jesse Thompson. All Rights Reserved.
 This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
     (see http://www.perl.com/perl/misc/Artistic.html)
