package Acme::AirRead;

use strict;
use warnings;
no strict 'refs';
our $VERSION = '0.05';
our $NO_READ = qr{air|luft};

sub import {
    my ($pkg) = caller(0);
    *{ $pkg . '::read_air' } = \&read_air;
    *{ $pkg . '::write_air' } = \&write_air;
    *{ $pkg . '::empty_air' } = \&empty_air;
}

sub read_air {
    my ($pkg) = caller(0);
    my $key = lc $_[0];
    return if $key =~ $NO_READ;
    my $namespace = $pkg . '::AirRead::attr';
    if ( $namespace->can($_[0]) ) {
        return *{ $pkg . '::AirRead::attr::' . $_[0] }->();
    }
    else {
        return;
    }
}

sub write_air {
    my ($pkg) = caller(0);
    return unless scalar @_;
    my %args = @_;
    foreach my $key ( sort keys %args ) {
        my $val = $args{$key};
        *{ $pkg . '::AirRead::attr::' . $key } = sub { $val };
    }
}

sub empty_air {
    my ($pkg) = caller(0);
    my $symbol_tbl = $pkg . '::AirRead::attr::';
    foreach my $symbol ( keys %$symbol_tbl ) {
        delete $symbol_tbl->{$symbol};
    }
}

1;
__END__

=head1 NAME

Acme::AirRead - accessor for reading air.

=head1 SYNOPSIS

  use Acme::AirRead;

  write_air(
      air     => 'cant read air',
      declair => 'cant read near air',
      kuki    => 'can read',
  );

  $air     = read_air('air');     # undef
  $declair = read_air('declair'); # undef
  $kuki    = read_air('kuki');    # can read

=head1 DESCRIPTION

Acme::AirRead is accessor for reading air.

If you set key like 'air' and any value, this value will be not set and can't read.

detail is reading air.

=head1 AUTHOR

Koji Takiguchi E<lt>kojiel {at} gmail.comE<gt>

=head1 SEE ALSO

Class::Accessor::Lite

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
