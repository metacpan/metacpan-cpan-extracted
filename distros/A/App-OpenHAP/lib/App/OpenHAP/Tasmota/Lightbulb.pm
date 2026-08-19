# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2025 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package App::OpenHAP::Tasmota::Lightbulb;
our $VERSION = '0.1.0';

use Fugu::Log;
require App::OpenHAP::Tasmota::Device;
our @ISA = qw(App::OpenHAP::Tasmota::Device);
use Protocol::HAP::Service;
use Protocol::HAP::Characteristic;

use POSIX qw(fmod);

# Light capabilities
use constant {
	CAP_DIMMER => 1,    # Brightness control
	CAP_COLOR  => 2,    # RGB color control
	CAP_CT     => 4,    # Color temperature control
};

# The Tasmota color-temperature range in mireds (M4)
use constant {
	CT_MIN => 153,
	CT_MAX => 500,
};

sub new ( $class, %args )
{
	my $self = $class->SUPER::new(
		%args,
		model        => 'Tasmota Light',
		manufacturer => 'OpenHAP',
		serial       => $args{serial} // 'LIGHT-001',
	);

	# Light state
	$self->{power_state} = 0;
	$self->{brightness}  = 100;
	$self->{hue}         = 0;
	$self->{saturation}  = 0;
	$self->{ct}          = 370;    # Default warm white (mireds)

	# Capabilities (H2)
	$self->{capabilities} = $args{capabilities} // CAP_DIMMER;

	# Add the Lightbulb service. One row per characteristic:
	# capability mask (0 = always), type, iid, format, and the
	# extra arguments.
	my $lightbulb = Protocol::HAP::Service->new(
		logger  => $self->{logger},
		type    => 'Lightbulb',
		iid     => 10,
		primary => 1,
	);

	my @rows = ( [
			0, 'On', 11, 'bool',
			{
				value  => \$self->{power_state},
				on_set => sub { $self->set_power(@_) },
			},
		],
		[
			CAP_DIMMER,
			'Brightness',
			12, 'int',
			{
				unit   => 'percentage',
				value  => \$self->{brightness},
				min    => 0,
				max    => 100,
				step   => 1,
				on_set => sub { $self->_set_brightness(@_) },
			},
		],
		[
			CAP_COLOR,
			'Hue', 13, 'float',
			{
				unit   => 'arcdegrees',
				value  => \$self->{hue},
				min    => 0,
				max    => 360,
				step   => 1,
				on_set => sub { $self->_set_hue(@_) },
			},
		],
		[
			CAP_COLOR,
			'Saturation',
			14, 'float',
			{
				unit   => 'percentage',
				value  => \$self->{saturation},
				min    => 0,
				max    => 100,
				step   => 1,
				on_set => sub { $self->_set_saturation(@_) },
			},
		],
		[
			CAP_CT,
			'ColorTemperature',
			15, 'uint32',
			{
				value  => \$self->{ct},
				min    => CT_MIN,      # M4: Match Tasmota range
				max    => CT_MAX,
				step   => 1,
				on_set => sub { $self->_set_ct(@_) },
			},
		],
	);

	for my $row (@rows) {
		my ( $cap, $type, $iid, $format, $extra ) = @$row;
		next if $cap && !( $self->{capabilities} & $cap );

		$lightbulb->add_characteristic(
			Protocol::HAP::Characteristic->new(
				logger => $self->{logger},
				type   => $type,
				iid    => $iid,
				format => $format,
				perms  => [ 'pr', 'pw', 'ev' ],
				%$extra,
			) );
	}

	$self->add_service($lightbulb);

	return $self;
}

sub subscribe_mqtt ($self)
{
	# Call the base class to set up the standard subscriptions
	# (C1, C2, C3)
	$self->SUPER::subscribe_mqtt();

	return unless $self->{mqtt_client}->is_connected();

	Fugu::Log->default->debug(
		'Lightbulb %s subscribing to additional MQTT topics',
		$self->{name} );

	# M2: The plain-text POWER response (SetOption4 support)
	$self->_subscribe_plain_power( power_state => 11 );

	# M2: Subscribe to the DIMMER topic for SetOption4 devices
	if ( $self->{capabilities} & CAP_DIMMER ) {
		$self->{mqtt_client}->subscribe(
			$self->_build_topic( 'stat', 'DIMMER' ),
			sub ( $recv_topic, $payload ) {
				if ( $payload =~ /^\d+$/ ) {
					$self->{brightness} = int($payload);
					Fugu::Log->default->debug(
						'Lightbulb %s dimmer: %d',
						$self->{name}, $payload );
					$self->notify_change(12);
				}
			} );
	}

	# M2: Subscribe to the HSBCOLOR topic for SetOption4 devices
	if ( $self->{capabilities} & CAP_COLOR ) {
		$self->{mqtt_client}->subscribe(
			$self->_build_topic( 'stat', 'HSBCOLOR' ),
			sub ( $recv_topic, $payload ) {
				$self->_parse_hsbcolor($payload);
			} );
	}

	# M2: Subscribe to the CT topic for SetOption4 devices
	if ( $self->{capabilities} & CAP_CT ) {
		$self->{mqtt_client}->subscribe(
			$self->_build_topic( 'stat', 'CT' ),
			sub ( $recv_topic, $payload ) {
				if ( $payload =~ /^\d+$/ ) {
					my $ct = _clamp_ct( int($payload) );
					$self->{ct} = $ct;
					Fugu::Log->default->debug(
						'Lightbulb %s CT: %d',
						$self->{name}, $ct );
					$self->notify_change(15);
				}
			} );
	}
}

# Override the base method to process the state data from
# periodic STATE messages
sub _process_state_data ( $self, $data )
{
	$self->SUPER::_process_state_data($data);

	# Extract the light-specific state
	$self->_extract_light_state($data);
}

# Override the base method to process the command results
sub _process_result_data ( $self, $data )
{
	$self->SUPER::_process_result_data($data);

	# Extract the light-specific state
	$self->_extract_light_state($data);
}

# Override _on_power_update to update the power state
sub _on_power_update ( $self, $state )
{
	if ( $self->{power_state} != $state ) {
		$self->{power_state} = $state;
		Fugu::Log->default->debug( 'Lightbulb %s power updated: %s',
			$self->{name}, $state ? 'ON' : 'OFF' );
		$self->notify_change(11);
	}
}

# _clamp_ct($value):
#	Clamp a color temperature to the Tasmota/HomeKit range (M4).
sub _clamp_ct ($value)
{
	return CT_MIN if $value < CT_MIN;
	return CT_MAX if $value > CT_MAX;

	return $value;
}

# $self->_extract_light_state($data):
#	Extract the light state from the JSON data.
sub _extract_light_state ( $self, $data )
{
	# Brightness (Dimmer in Tasmota)
	if ( exists $data->{Dimmer} && $self->{capabilities} & CAP_DIMMER ) {
		my $brightness = $data->{Dimmer};
		if ( $self->{brightness} != $brightness ) {
			$self->{brightness} = $brightness;
			Fugu::Log->default->debug(
				'Lightbulb %s brightness: %d%%',
				$self->{name}, $brightness );
			$self->notify_change(12);
		}
	}

	# HSB Color. The Tasmota HSBColor value is a "h,s,b" string.
	if ( exists $data->{HSBColor} && $self->{capabilities} & CAP_COLOR ) {
		$self->_parse_hsbcolor( $data->{HSBColor} );
	}

	# M3: Process the Color field for the SetOption17 decimal format
	if ( exists $data->{Color} && $self->{capabilities} & CAP_COLOR ) {
		$self->_parse_color( $data->{Color} );
	}

	# Color Temperature (CT in Tasmota)
	if ( exists $data->{CT} && $self->{capabilities} & CAP_CT ) {
		my $ct = _clamp_ct( $data->{CT} );

		if ( $self->{ct} != $ct ) {
			$self->{ct} = $ct;
			Fugu::Log->default->debug( 'Lightbulb %s CT: %d mireds',
				$self->{name}, $ct );
			$self->notify_change(15);
		}
	}
}

# $self->_set_brightness($value):
#	Set the brightness level (0-100).
sub _set_brightness ( $self, $value )
{
	Fugu::Log->default->debug( 'Lightbulb %s brightness set to %d%%',
		$self->{name}, $value );

	$self->{mqtt_client}
	    ->publish( $self->_build_topic( 'cmnd', 'Dimmer' ), "$value" );
}

# $self->_set_hue($value):
#	Set the hue (0-360).
sub _set_hue ( $self, $value )
{
	# Tasmota accepts 0-360 for the hue. The value 360 wraps to 0.
	$value = int($value) % 360;

	Fugu::Log->default->debug( 'Lightbulb %s hue set to %d',
		$self->{name}, $value );

	$self->{mqtt_client}
	    ->publish( $self->_build_topic( 'cmnd', 'HSBColor1' ), "$value" );
}

# $self->_set_saturation($value):
#	Set the saturation (0-100).
sub _set_saturation ( $self, $value )
{
	Fugu::Log->default->debug( 'Lightbulb %s saturation set to %d%%',
		$self->{name}, $value );

	$self->{mqtt_client}
	    ->publish( $self->_build_topic( 'cmnd', 'HSBColor2' ), "$value" );
}

# $self->_set_ct($value):
#	Set the color temperature in mireds (153-500).
sub _set_ct ( $self, $value )
{
	# The Tasmota CT range is 153-500. Clamp the value to it.
	$value = _clamp_ct($value);

	Fugu::Log->default->debug( 'Lightbulb %s CT set to %d mireds',
		$self->{name}, $value );

	$self->{mqtt_client}
	    ->publish( $self->_build_topic( 'cmnd', 'CT' ), "$value" );
}

# $self->_parse_hsbcolor($value):
#	Parse the HSBColor string "h,s,b". Update the state.
sub _parse_hsbcolor ( $self, $value )
{
	return unless $self->{capabilities} & CAP_COLOR;

	my @hsb = split /,/, $value;
	return unless @hsb == 3;

	my ( $h, $s, $b ) = @hsb;

	if ( $self->{hue} != $h ) {
		$self->{hue} = $h;
		$self->notify_change(13);
	}

	if ( $self->{saturation} != $s ) {
		$self->{saturation} = $s;
		$self->notify_change(14);
	}

	# The brightness value from HSB also updates the Dimmer
	if (       $self->{capabilities} & CAP_DIMMER
		&& $self->{brightness} != $b )
	{
		$self->{brightness} = $b;
		$self->notify_change(12);
	}
}

# $self->_parse_color($value):
#	Parse the Color field (M3: SetOption17 support).
#	The method accepts the hex (FF5500) and decimal (255,85,0)
#	formats.
sub _parse_color ( $self, $value )
{
	return unless $self->{capabilities} & CAP_COLOR;

	my ( $r, $g, $b );

	# M3: Decimal format (SetOption17 1): "r,g,b"
	if ( $value =~ /^(\d+),(\d+),(\d+)/ ) {
		( $r, $g, $b ) = ( $1, $2, $3 );
	}

	# Hex format (default): "RRGGBB" or "RRGGBBWW"
	elsif ( $value =~ /^([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})/ )
	{
		( $r, $g, $b ) = ( hex($1), hex($2), hex($3) );
	}
	else {
		return;    # Unknown format
	}

	# Convert RGB to HSB
	my ( $h, $s, $br ) = $self->_rgb_to_hsb( $r, $g, $b );

	if ( $self->{hue} != $h ) {
		$self->{hue} = $h;
		$self->notify_change(13);
	}

	if ( $self->{saturation} != $s ) {
		$self->{saturation} = $s;
		$self->notify_change(14);
	}
}

# $self->_rgb_to_hsb($r, $g, $b):
#	Convert RGB (0-255) to HSB (h: 0-360, s: 0-100, b: 0-100).
sub _rgb_to_hsb ( $self, $r, $g, $b )
{
	# Normalize the values to 0-1
	my ( $rn, $gn, $bn ) = ( $r / 255, $g / 255, $b / 255 );

	my $max =
	      ( $rn > $gn )
	    ? ( $rn > $bn ? $rn : $bn )
	    : ( $gn > $bn ? $gn : $bn );
	my $min =
	      ( $rn < $gn )
	    ? ( $rn < $bn ? $rn : $bn )
	    : ( $gn < $bn ? $gn : $bn );
	my $delta = $max - $min;

	# Brightness
	my $br = int( $max * 100 );

	# Saturation
	my $s = ( $max == 0 ) ? 0 : int( ( $delta / $max ) * 100 );

	# Hue. The sector arithmetic is floating-point: Perl's % would
	# truncate the red sector's fraction to 0 and report hue 0 for
	# every red-dominant color, so the wrap uses fmod.
	my $h = 0;
	if ( $delta != 0 ) {
		if ( $max == $rn ) {
			$h = 60 * fmod( ( $gn - $bn ) / $delta, 6 );
		}
		elsif ( $max == $gn ) {
			$h = 60 * ( ( ( $bn - $rn ) / $delta ) + 2 );
		}
		else {
			$h = 60 * ( ( ( $rn - $gn ) / $delta ) + 4 );
		}
	}
	$h = int($h);
	$h += 360 if $h < 0;

	return ( $h, $s, $br );
}

1;
