package Archive::Rgssad::Keygen;

use Exporter 'import';
our @EXPORT_OK = qw(keygen);

use 5.010;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Archive::Rgssad::Keygen - Internal utilities to generate magickeys.

=cut

our $VERSION = '0.1';

=head1 SYNOPSIS

    use Archive::Rgssad::Keygen qw(keygen);

    my $seed = 0xDEADCAFE;
    my $key = keygen($seed);        # get next key
    my @keys = keygen($seed, 10);   # get next 10 keys


=head1 DESCRIPTION

=over 4

=item keygen $key

=item keygen $key, $num

Uses KEY as seed, generates NUM keys, and stores the new seed back to KEY.
If NUM is omitted, it generates 1 key, which is exactly KEY.
In scalar context, returns the last keys generated.

=cut

sub keygen (\$;$) {
  use integer;
  my $key = shift;
  my $num = shift || 1;
  my @ret = ();
  for (1 .. $num) {
    push @ret, $$key;
    $$key = ($$key * 7 + 3) & 0xFFFFFFFF;
  }
  return wantarray ? @ret : $ret[-1];
}

=back

=head1 AUTHOR

Zejun Wu, C<< <watashi at watashi.ws> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Archive::Rgssad::Keygen


You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/watashi/perl-archive-rgssad>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Zejun Wu.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Archive::Rgssad::Keygen
