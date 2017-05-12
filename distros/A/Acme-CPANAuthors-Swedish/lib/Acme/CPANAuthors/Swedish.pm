package Acme::CPANAuthors::Swedish;

use strict;
use warnings;
use utf8;

our $VERSION = '0.03';

use Acme::CPANAuthors::Register (
  ABERGMAN => 'Artur Bergman',
  CLAESJAC => 'Claes Jakobsson',
  ERWAN    => 'Erwan Lemonnier',
  OLOF     => 'Olof Johansson',
  WOLDRICH => 'Magnus Woldrich',
  ZIBRI    => 'Olof Johansson',
);

1;

__END__

=pod

=head1 NAME

Acme::CPANAuthors::Swedish - We are swedish CPAN authors

Acme::CPANAuthors::Swedish - Vi är svenska kontribuerare till CPAN

=head1 SYNOPSIS

   use Acme::CPANAuthors;
   use Acme::CPANAuthors::Swedish;

   my $authors = Acme::CPANAuthors->new('Swedish');

   my $number   = $authors->count;
   my @ids      = $authors->id;
   my @distros  = $authors->distributions('WOLDRICH');
   my $url      = $authors->avatar_url('OLOF');
   my $kwalitee = $authors->kwalitee('ZIBRI');


=head1 DESCRIPTION

This class is used to provide a hash of Swedish CPAN author's PAUSE id/name to
Acme::CPANAuthors.

=head1 MAINTENANCE

If you are a swedish CPAN author not listed here, please send me your id/name
via email, IRC, github or RT so we can always keep this module up to date.
If there's a mistake and you're listed here but are not swedish (or just don't
want to be listed), sorry for the inconvenience: please contact me and I'll
remove the entry right away.

=head1 SEE ALSO

L<Acme::CPANAuthors> - Main class to manipulate this one

=head1 AUTHOR

    \ \ | / /
     \ \ - /
      \ | /
      (O O)
      ( < )
      (-=-)

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se
  http://github.com/trapd00r

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2011 the B<Acme::CPANAuthors::Swedish> L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=cut
