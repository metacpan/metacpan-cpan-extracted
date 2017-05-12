package Audio::Ao;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS =	( 'all' => [ qw(initialize_ao shutdown_ao open_live
																		open_file play close_ao
																		driver_id default_driver_id
																		driver_info driver_info_list
																		is_big_endian)
															]
										);

our @EXPORT_OK = qw(initialize_ao shutdown_ao open_live open_file play
										close_ao driver_id default_driver_id driver_info
										driver_info_list is_big_endian);

our $VERSION = '0.01';

use Inline C => 'DATA',
					LIBS => '-lao',
					VERSION => '0.01',
					NAME => 'Audio::Ao';

1;
__DATA__

=head1 NAME

Audio::Ao - A Perl wrapper for the Ao audio library. 

=head1 SYNOPSIS

  use Audio::Ao qw(:all);
  
	initialize_ao;
	my $device = open_live(default_driver_id(), 16, $rate, $channels,
		is_big_endian(), {});
	while (#have data) {
		play($device, $data_buffer, $len_of_buffer);
	}
	close_ao($device($device));
	shutdown_ao;

=head1 DESCRIPTION

Provides access to Libao, "a cross-platform library that allows
programs to output PCM audio data to the native audio devices on a
wide variety of platforms."  Libao currently supports OSS, ESD, ALSA,
Sun audio, and aRts.

=head1 SUBROUTINES

=head2 C<initialize_ao ()>

Initializes the underlying library.  This must be called before any
other Ao operations are performed.

=head2 C<shutdown_ao ()>

Closes down the underlying libraries.  Call this when you're done.

=head2 C<open_live ($driver_id, $bits, $rate, $channels, $byte_format, %options)>

Opens a live playback audio device for output.  Takes driver id number,
bits per sample, sample rate, number of channels, and byte format
(big or little endian).  The options hash is optional, although you must
pass at least and empty hash to the function.  Options differ based on
driver, see http://docs.meg.nu/local-docs/libao/drivers.html for more
information.  Returns C<undef> on failure and a device (passed to
C<play>) on success.

=head2 C<open_file ($driver_id, $filename, $overwrite, $bits, $rate, $channles, $byte_format, %options)>

This function is equivalent to C<open_live> except that it writes to a
file given by C<$filename>.  Set C<$overwrite> to true to automatically
overwrite existing files.

=head2 C<play ($device, $buffer, $length)>

Plays the specified number of bytes from C<$buffer> to the device.
Returns nonzero on success, 0 on failure.

=head2 C<close_ao ($device)>

Closes the given device.  Returns 0 on failure.

=head2 C<driver_id ($short_name)>

Returns the id number of the driver with the given C<$short_name>.
Returns -1 on failure.  Non-negative numbers are driver ids.

=head2 C<default_driver_id ()>

Returns the id number of the default driver on this system.  Returns -1
on failure.

=head2 C<driver_info ($driver_id)>

Returns a hash containing various information about the driver with the
specified id.  An empty hash represents failure.
See http://docs.meg.nu/local-docs/libao/ao_info.html for a list of key
values (same as in the struct).  Note that C<char **options> is held as
a nested array within the hash and the C<int option_count> is ignored.

=head2 C<driver_info_list ()>

Returns an array containing the driver_info hashes for every driver
supported by the system.

=head2 C<is_big_endian ()>

Returns true if the system is big endian, false otherwrise.

=head1 REQUIRES

Inline::C, libao

=head1 AUTHOR

Dan Pemstein E<lt>dan@lcws.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003, Dan Pemstein.  All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at
your option) any later version.  A copy of this license is included
with this module (LICENSE.GPL).

=head1 SEE ALSO

L<Inline::C>. L<libao-perl>

=cut

__C__

#include <ao/ao.h>

void initialize_ao()
{
	ao_initialize();
}

void shutdown_ao()
{
	ao_shutdown();
}

SV *open_live (	int id, int bits, int rate, int channels, int bform,
									void *o)
{
	ao_option *opstruct = NULL;
	ao_sample_format format;
	ao_device *device;
	SV *hval;
	HV *options;
	char **hkey;
	I32 *retlen;
	int ops = 0;
	
	if (o != NULL)
		options = (HV *) o;
	else
		options = newHV();

	hv_iterinit(options);
	while ((hval = hv_iternextsv(options, hkey, retlen)) != NULL) {
		ops = 1;
		if (ao_append_option(&opstruct, *hkey, SvPV_nolen(hval)) != 1) {
			perror("Bad value in options hash, aborting open_live");
			return &PL_sv_undef;
		}
	}

	format.bits = bits;
	format.rate = rate;
	format.channels = channels;
	format.byte_format = bform;

	if (ops > 0)
		device = (ao_device *) ao_open_live(id, &format, opstruct);
	else
		device = (ao_device *) ao_open_live(id, &format, NULL);

	ao_free_options(opstruct);
	
	return newSViv((IV) device);
}

SV *open_file (	int id, char *fname, int overwrite, int bits, int rate,
								int channels, int bform, HV *options)
{
	ao_option *opstruct = NULL;
	ao_sample_format format;
	ao_device *device;
	SV *hval;
	char **hkey;
	I32 *retlen;
	int ops = 0;
	
	hv_iterinit(options);
	while ((hval = hv_iternextsv(options, hkey, retlen)) != NULL) {
		ops = 1;
		if (ao_append_option(&opstruct, *hkey, SvPV_nolen(hval)) != 1) {
			perror("Bad value in options hash, aborting open_file");
			return &PL_sv_undef;
		}
	}

	format.bits = bits;
	format.rate = rate;
	format.channels = channels;
	format.byte_format = bform;

	if (ops > 0)
		device = (ao_device *) ao_open_file(id, fname, overwrite, &format,
																				opstruct);
	else
		device = (ao_device *) ao_open_file(id, fname, overwrite, &format,
																				NULL);

	ao_free_options(opstruct);
	
	return newSViv((IV) device);
}

int play (SV *device, char *buffer, long num_bytes)
{
	ao_device *dev = (ao_device *) SvIV(device);
	return ao_play(dev, (void *) buffer, num_bytes);
}

int close_ao (SV *device)
{
	ao_device *dev = (ao_device *) SvIV(device);
	return ao_close(dev);
}
	
int driver_id(char *short_name)
{
	return ao_driver_id(short_name);
}

int default_driver_id()
{
	return ao_default_driver_id();
}
	
HV *_make_driver_info_hash (ao_info *info)
{
	int i, cnt;
	AV* ops;
	HV *ihash = newHV();

	hv_store(ihash, "type", 4, newSViv((IV) (*info).type), 0);
	hv_store(ihash, "name", 4, newSVpv((*info).name, 0), 0);
	hv_store(ihash, "short_name", 10, newSVpv((*info).short_name, 0), 0);
	hv_store(ihash, "comment", 7, newSVpv((*info).comment, 0), 0);
	hv_store(ihash, "preferred_byte_format", 21, 
		newSViv((IV) (*info).preferred_byte_format), 0);

	cnt = (*info).option_count;
	if (cnt > 0) {
		for (i = 0; i < cnt; ++i) {
			ops = newAV();
			av_push(ops, newSVpv((*info).options[i], 0));
		}
		hv_store(ihash, "options", 7, newRV_inc((SV *) ops), 0);
	}
	
	return ihash;
}

HV *driver_info(int id)
{
	ao_info *info = ao_driver_info(id);
	return _make_driver_info_hash(info);
}

AV *driver_info_list ()
{
	int i, cnt;
	AV *list = newAV();
	ao_info **rlist = ao_driver_info_list(&cnt);
	for (i = 0; i < cnt; ++i)
		av_push(list, newRV_inc((SV *)
				_make_driver_info_hash((ao_info *) rlist[i])));
	
	return list;
}

int is_big_endian ()
{
	return ao_is_big_endian();
}
