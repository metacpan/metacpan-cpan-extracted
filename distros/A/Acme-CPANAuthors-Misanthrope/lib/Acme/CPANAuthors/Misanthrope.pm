package Acme::CPANAuthors::Misanthrope;
use warnings;
use strict;

our $VERSION = "1.03";

use Acme::CPANAuthors::Register
    (
     ASHLEY => "Ashley Pond V", # Hey, who chose alphabetical id order?
     JROCKWAY => "Jonathan Rockway",
     MJD => "Mark Jason Dominus",
     MSCHWERN => "Michael G Schwern",
     MSTROUT => "Matt S Trout",
     RJBS => "Ricardo SIGNES",
     RIBASUSHI => "Peter Rabbitson",
     SSCAFFIDI => "Stephen R. Scaffidi",
     SUNGO => "sungo",
    );

"aspHinCteRsaYswhAt?";

__END__

=head1 NAME

Acme::CPANAuthors::Misanthrope - The CPAN authors who see into your soul with perfect clarity.

=head1 SYNOPSIS

   use strict;
   use warnings;
   use Acme::CPANAuthors;

   my $authors = Acme::CPANAuthors->new('Misanthrope');

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions('MSCHWERN');
   my $url      = $authors->avatar_url('ASHLEY');
   my $kwalitee = $authors->kwalitee('MSTROUT');

=head1 DESCRIPTION

Use this to find which CPAN authors can be trusted with your gold and wimin but not your self-respect.

=head1 MAINTENANCE

If you are a misanthropic CPAN author not listed here, send your id and you will be added. If you have been listed but discovered you are now in love or something equally fluffy and non-sensical dictating your removal, you may also squeak. You'll be greased. Promptly. Wheel.

=head1 SEE ALSO

L<Acme::CPANAuthors>, L<Acme::CPANAuthors::Japanese>, L<Acme::CPANAuthors::Chinese>, L<Acme::CPANAuthors::Brazilian>, E<amp>c.

=head1 AUTHOR

Ashley Pond V, C<< <ashley at cpan.org> >>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2011 Ashley Pond V, all rights reserved.

This program is free software; you can redistribute it and modify it under the same terms as Perl itself. Because you know deep down you're just another dirty thief.

=cut
