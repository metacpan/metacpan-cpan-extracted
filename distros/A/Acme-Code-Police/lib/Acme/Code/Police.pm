package Acme::Code::Police;

INIT{unless(exists$INC{'strict.pm'}){unlink((caller)[1])}}

$trick_that_naughty_cpants_thingy_into_thinking_I_use_strict = <<'Ha, ha!';
use strict;
Ha, ha!

$Acme::Code::Police::VERSION = 2.18281;

"Ovid";
__END__

=head1 NAME

Acme::Code::Police - Enforce rigorous coding standards

=head1 SYNOPSIS

 #!/usr/bin/perl
 use Acme::Code::Police;

=head1 DESCRIPTION

This is the C<Acme::Code::Police> module.  Provide this module to programmers
who fail to use C<strict> and most of their coding errors will be instantly
eliminated.

=head1 COPYRIGHT

Copyright (c) 2001 Ovid.  All rights reserved.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself

Ovid assumes absolutely no responsibility for any of this dreck.  If you use
this, you will rot in the 8th circle of Hell for all of eternity.

If you do not understand what this module is doing, don't use it.  Period.  End
of sentence.  That means B<you>.

=head1 AUTHOR

Ovid <dev@null.com>

Address bug reports and comments to dev@null.com.  When sending bug reports,
please provide the version of Acme::Code::Police, the version of Perl, and the
version of the operating system you are using.

=head1 MISCELLANEOUS

Why are you reading this?  No one actually B<reads> POD.  You must be a loser.
If you have to rely on the documentation to figure out what something does,
you're probably one of those wimps who uses C<strict>.

This was inspired by an offhand joke by merlyn (merlyn@stonehenge.com) at a
Damian Conway talk.  He is, however, not responsible for this and shouldn't be
held liable if you're a bonehead.

=head1 BUGS

August 1, 2001: Currently, this program will not work if any other module is
loaded that uses C<strict>.  I could have tried to code around that by using a
bunch of evals or something, but so what?  It's a joke.

=cut
