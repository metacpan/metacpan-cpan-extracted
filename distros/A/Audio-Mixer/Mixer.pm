package Audio::Mixer;

#
# Library to query / set various sound mixer parameters.
# See POD documentation below for more info.
#
# Copyright (c) 2000 Sergey Gribov <sergey@sergey.com>
# This is free software with ABSOLUTELY NO WARRANTY.
# You can redistribute and modify it freely, but please leave
# this message attached to this file.
#
# Subject to terms of GNU General Public License (www.gnu.org)
#
# Last update: $Date: 2002/04/30 00:48:21 $ by $Author: sergey $
# Revision: $Revision: 1.4 $

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(
	MIXER
);
$VERSION = '0.7';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Audio::Mixer macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Audio::Mixer $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.


sub get_cval {
  my $channel = shift;
  my ($val, $lcval, $rcval);
  $val = get_param_val($channel);
  $lcval = $val & 0xff;
  $rcval = $val & 0x10000 ? ($val & 0xff00) >> 8 : $lcval;
  return wantarray ? ($lcval, $rcval) : $val;
}

sub set_cval {
  my ($channel, $lcval, $rcval) = @_;
  $lcval = 0 unless $lcval;
  $rcval = $lcval unless $rcval;
  return set_param_val($channel, $lcval, $rcval);
}

sub get_mixer_params {
  return(split(/ /, get_params_list()));
}

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Audio::Mixer - Perl extension for Sound Mixer control

=head1 SYNOPSIS

  use Audio::Mixer;
  $volume = Audio::Mixer::get_cval('vol');
  if (Audio::Mixer::set_cval('vol', 50, 40)) {
    die("Can't set volume...");
  }

=head1 DESCRIPTION

Library to query / set various sound mixer parameters.

This is just a very simple Perl interface which allows to
set various sound mixer parameters. The most important
probably 'vol' (volume). The list of all mixer parameters
can be obtained using get_mixer_params() function.

All values (lcval, rcval) are numbers in 0-100 range.

=head1 FUNCTIONS

get_cval(cntrl) - Get parameter value
Parameters:
    cntrl - name of parameter
Returns:
    in array context: (lcval, rcval), where:
      lcval - left channel value
      rcval - right channel value
    in scalar context returns value of get_param_val() (see below)

set_cval(cntrl, lcval, rcval) - Set parameter value
Parameters:
    cntrl - name of parameter
    lcval - left channel value
    rcval - right channel value (optional, if not supplied
      will be equal to lcval)
Returns: 0 if Ok, -1 if failed

set_source(cntrl) - set record source
Parameters:
    cntrl - name of channel to record from
Returns: 0 if Ok, -1 if failed

get_source(cntrl) - get record source
Returns:
    name of channel to record from

set_mixer_dev(fname) - Set mixer device name (optional),
    /dev/mixer is used by default
    fname - device name
Returns: 0 if Ok
    
init_mixer() - Initialize mixer (open it)
    set_cval() / get_cval() opens / closes the mixer each
    time they called unless init_mixer() called before.
    In case if init_mixer() called before all other
    functions will use already opened device instead of
    opening it each time.

close_mixer() - Close device.
    Should be called only if init_mixer() was used.

get_mixer_params() - Get list of mixer parameters
Returns: list of parameters names.

LOW LEVEL FUNCTIONS:

get_param_val(cntrl) - Get parameter value
Parameter:
    cntrl - name of parameter
Returns:
    integer value, which will be constructed as follows:
      lower byte (x & 0xff) - value of the left channel
        (or whole value)
      next byte  (x & 0xff00) - value of the right channel
      third byte (x & 0xff0000) - flags (if x & 0x10000 then
	 2 channels exist)
    or -1 in case of failure.

set_param_val(cntrl, lcval, rcval) - Set parameter value.
    Here all parameters are mandatory (in contrast to set_cval()).
Parameters:
    cntrl - name of parameter
    lcval - left channel value
    rcval - right channel value
Returns: 0 if Ok, -1 if failed

=head1 AUTHOR

Sergey Gribov, sergey@sergey.com

=head1 LICENSE

Copyright (c) 2001 Sergey Gribov. All rights
reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as
Perl itself.

=head1 SEE ALSO

perl(1).

=cut
