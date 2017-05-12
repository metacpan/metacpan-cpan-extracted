package DBIx::MoCo::MUID;
use strict;
use Exporter qw(import);
our @EXPORT = qw(create_muid);

use Net::Address::Ethernet qw(get_addresses);
use Math::BigInt::Lite;
use Time::HiRes;

my ($ser, $addr);

BEGIN {
    $addr = (get_addresses)[0]->{sIP};
    $addr = substr(join('', map {sprintf('%08b', $_)} split(/\./, $addr)), -20);
}

sub create_muid {
    unless (defined $ser) {
        $ser = int(rand(256));
    }
    # my $time = sprintf('%032b', time());
    Math::BigInt::Lite->new(int(Time::HiRes::time() * 1000))->as_bin =~ /([01]{36})$/o;
    my $time = $1;
    my $serial = sprintf('%08b', $ser++ % 256);
    my $muid = $addr . $time . $serial;
    $muid = Math::BigInt::Lite->new("0b$muid");
    # warn $muid->bstr();
    # warn $muid->as_bin();
    return $muid->bstr();
}

1;

=head1 NAME

DBIx::MoCo::MUID - MUID generator for muid fields

=head1 SYNOPSIS

  my $muid = DBIx::MoCo::MUID->create_muid();

=head1 DESCRIPTION

I<DBIx::MoCo::MUID> provides "almost unique" id for MoCo Unique ID 
(muid) fields.
They are less unique than UUIDs because they only have 64bits long.

They are generated as set of next 3 parts.

20 bits of ip address (last 20 bits)
36 bits of epoch time (lower 36 bits of msec.) (2.179 years)
8 bits of serial

=head1 SEE ALSO

L<DBIx::MoCo>

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
