package Acme::CPANAuthors::GeekHouse;
use strict;
use warnings;

our $VERSION = '0.02';

use Acme::CPANAuthors::Register (
    KENTARO => 'Kentaro Kuribayashi',
);

1;

__END__

=head1 NAME

Acme::CPANAuthors::GeekHouse - We're CPAN Authors in The Geek House

=head1 SYNOPSIS

  use Acme::CPANAuthors;
  use Acme::CPANAuthors::GeekHouse;

  my $authors  = Acme::CPANAuthors->new('GeekHouse');

  my $number   = $authors->count;
  my @ids      = $authors->id;
  my @distros  = $authors->distributions('KENTARO');
  my $url      = $authors->avatar_url('KENTARO');
  my $kwalitee = $authors->kwalitee('KENTARO');

=head1 DESCRIPTION

This class provides a hash of Pause ID/name of CPAN authors who have
visited The Geek Hose ever.

=head1 MAINTENANCE

The source code of this module is freely shared using CodeRepos. Feel
free to add your name into the code if you have visited The Geek House
and let me know it.

=head1 SEE ALSO

=over 4

=item * The Geek House

http://ghp.g.hatena.ne.jp/

=item * Acme::CPANAuthors

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=head1 SEE ALSO

=head1 COPYRIGHT AND LICENSE (The MIT License)

Copyright (c) Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
