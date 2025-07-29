package Android::ElectricSheep::Automator::ADB::Device;

use 5.014000;
use strict;
use warnings;

use parent qw/Class::Accessor::Fast/;

our $VERSION = '0.005';

sub new {
	my ($class, $serial, $state, @attrs) = @_;
	my %attrs = map { split ':', $_, 2 } @attrs;
	bless { serial => $serial, state => $state, %attrs }, $class
}

__PACKAGE__->mk_ro_accessors(qw/serial state usb product model device/);

1;
__END__

=encoding utf-8

=head1 NAME

Android::ElectricSheep::Automator::ADB::Device - information about an Android device

=head1 SYNOPSIS

  use Android::ElectricSheep::Automator::ADB;
  my @devices = $adb->devices;
  say $devices[0]->serial;
  say $devices[0]->state; # e.g. offline, bootloader, sideload, or device

  # The available attributes depend on your device
  say $devices[0]->usb;     # e.g. 2-1
  say $devices[0]->product; # e.g. angler
  say $devices[0]->model;   # e.g. MI_MAX
  say $devices[0]->device;  # e.g. angler

=head1 DESCRIPTION

Information about an Android device in form of a blessed hash with a
few accessors. See SYNPOSIS for a list of accessors.

=head1 SEE ALSO

L<Android::ElectricSheep::Automator::ADB>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
