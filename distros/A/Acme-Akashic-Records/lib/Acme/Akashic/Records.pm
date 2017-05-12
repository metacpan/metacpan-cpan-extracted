package Acme::Akashic::Records;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 0.1 $ =~ /(\d+)/g;

my $records;
$records = \$records;
bless $records, __PACKAGE__;

sub AUTOLOAD { $records }

for my $type (qw/ARRAY HASH HANDLE/) {
    no strict 'refs';
    *{ __PACKAGE__ . '::' . $type . '::AUTOLOAD' } = \&AUTOLOAD;
}

use overload
  '@{}' => sub { tie my @records, __PACKAGE__ . '::ARRAY';  \@records },
  '%{}' => sub { tie my %records, __PACKAGE__ . '::HASH';   \%records },
  '*{}' => sub { tie *records,    __PACKAGE__ . '::HANDLE'; \*records },
  '&{}' => sub { sub { $records } },
  fallback => 1;

$records; # End of Acme::Akashic::Records -- or do they ever end?
__END__
=head1 NAME

Acme::Akashic::Records - Access The Akashic Records

=head1 VERSION

$Id: Records.pm,v 0.1 2010/10/02 16:40:12 dankogai Exp dankogai $

=cut

=head1 SYNOPSIS

  use Acme::Akashic::Records;
  my $akashik = new Acme::Akashic::Records;
  # They ALL access the Akashik Records.
  say $akasik;
  say $akasik->first;
  say $akasik->last;
  say $akasik->[0];
  say $akasik->[0+$akashik];
  say $akasik->{''.$akashik};
  say $akasik->($akashik);
  say <$akashik>;

=head1 DESCRIPTION

Acoording to Wikipedia, the akashik records are described as "containing
all knowledge of human experience and the history of the cosmos."

In other words, the akashik records always contain the akashik records
themselves.  This module offers exactly such records.

=head1 SUBROUTINES/METHODS

You can use B<ANY> name for its constructor, accessor, and mutator.

=head1 AUTHOR

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-akashic-records at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Akashic-Records>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Akashic::Records

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Akashic-Records>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Akashic-Records>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Akashic-Records>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Akashic-Records/>

=back

=head1 ACKNOWLEDGEMENTS

L<http://en.wikipedia.org/wiki/Akashic_records>

L<http://q.hatena.ne.jp/1286016172>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Dan Kogai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
