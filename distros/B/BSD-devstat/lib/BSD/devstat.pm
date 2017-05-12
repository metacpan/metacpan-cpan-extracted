package BSD::devstat;
use strict;
use warnings;
use 5.008;
our $VERSION = '0.02';
our @ISA;

eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    __PACKAGE__->bootstrap($VERSION);
};

1;
__END__

=head1 NAME

BSD::devstat - interface to devstat(3) API

=head1 SYNOPSIS

  use BSD::devstat;

  my $ds = BSD::devstat->new();
  printf "Number of devices: %d\n", $ds->numdevs;

  my $devidx = $ds->numdevs;	# this is last device.

  my $dev = $ds->devices($devidx);
  printf "%s%d block_size=%d\n", $dev->{device_name},
    $dev->{unit_number}, $dev->{block_size};

  # Stat in 2 seconds.
  my $stat = $ds->compute_statistics($devidx, 2.0);
  printf "BUSY_PCT=%.2f\n", $stat->{BUSY_PCT};

=head1 DESCRIPTION

BSD::devstat is interface to devstat(3) API.  You can grab device
statistics information which is provided by devstat(9) kernel interface
via devstat(3) userland interface.

=over

=item new()

Retrieve device statistics and store it as BSD::devstat object.

=item numdevs()

Return the number of devices which devstat(3) API provided.

=item devices($device_index)

$device_index is index for device, which can be from 0 to
($self->numdevs() - 1).
Returns hash reference.  This contains various values described in
devstat(9) manpage.  This method will croak if error occured.

=item compute_statistics($device_index, $elapse_time)

$device_index is index for device, which can be from 0 to
($self->numdevs() - 1).  $elapse_time is second (can be float number)
between two snapshots of statistics and calculation by done with these
statistics.
Returns hash reference.  This contains various values described at
devstat_compute_statistics() function in devstat(3) manpage.
This method will croak if error occured.

=back

=head1 AUTHOR

Jun Kuriyama E<lt>kuriyama@FreeBSD.orgE<gt>

=head1 SEE ALSO

devstat(3), devstat(9).

=head1 BUGS

Currently supports only FreeBSD.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
