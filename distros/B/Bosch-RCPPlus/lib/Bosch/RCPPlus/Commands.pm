package Bosch::RCPPlus::Commands;
use strict;

use POSIX qw(floor);
use Bosch::RCPPlus::Utils qw(bytes2int);

our %Type = (
	flag => 'F_FLAG',
	unicode => 'P_UNICODE',
	octect => 'P_OCTET',
	word => 'T_DWORD',
);

our %Direction = (
	read => 'READ',
	write => 'WRITE',
);

sub ptz_available
{
	my ($num) = @_;

	return (
		command => '0x0a51',
		type => $Type{flag},
		drection => $Direction{read},
		num => $num || 1,
	);
}

sub name
{
	my ($num) = @_;

	return (
		command => '0x0019',
		type => $Type{unicode},
		drection => $Direction{read},
		num => $num || 1,
	);
}

##*
# -1 <= evt.pan <= 1
# -1 <= evt.tilt <= 1
# Zoom: -1 / +1
#
# See code from Js UI:
# - function sendPTZCommand()
# - PTZControllerEventTransmitter::sendPTZ
sub ptz
{
	my ($pan, $tilt, $zoom, $num) = @_;

	# BicomPTZController.alignPTZ = function (evt) {
	#    // -1 <= evt.pan <= 1
	#    // -1 <= evt.tilt <= 1
	#    // Zoom: -1 / +1
	#    var p = (-1 * Math.round(evt.pan * 15));
	#    var t = Math.round(evt.tilt * 15);
	#    var z = -1 * Math.round(evt.zoom * 7);
	#    if (evt.zoom === -999) {
	#        z = -999;
	#    }
	#    return new PTZObject(p, t, z);
	#};
	$pan = int(sprintf("%.0f", $pan * 15));
	$tilt = int(sprintf("%.0f", $tilt * 15));
	$zoom = -1 * int(sprintf("%.0f", $zoom * 7));

	# BicomPTZController.prototype.sendPTZ
	$pan = abs($pan) + 0x80 if ($pan < 0);
	$tilt = abs($tilt) + 0x80 if ($tilt < 0);
	$zoom = abs($zoom) + 0x80 if ($zoom < 0);

	return (
		num => $num || 1,
		direction => $Direction{write},
		command => '0x09A5',
		type => $Type{octect},
		# nbrArrayToString
		payload => '0x80' . '0006' . '0110' . '85' . sprintf("%02X%02X%02X", $pan, $tilt, $zoom),
	);
}

sub zoom_in
{
	my ($num) = @_;
	return ptz(0, 0, 1, $num);
}

sub zoom_out
{
	my ($num) = @_;
	return ptz(0, 0, -1, $num);
}

sub ptz_stop
{
	my ($num) = @_;
	return ptz(0, 0, 0, $num);
}

##*
# 1 <= $preset <= 6
#
# See code from Js UI:
# - PresetSupport::checkPreset2
# - RCP.readBicom(0x6, 0x2001 + ((preset - 1) << 4), { bicomtype: 'NUMBER' })
#
sub check_preset
{
	my ($preset, $num) = @_;
	# RCP.readBicom(0x6, 0x2001 + ((preset - 1) << 4), { bicomtype: 'NUMBER' })
	my $bitcom_obj_id = sprintf('%04X', 0x2001 + (($preset - 1) << 4));

	return (
		num => $num || 0,
		direction => $Direction{write},
		command => '0x09A5',
		type => $Type{octect},
		payload => '0x85' . '0006' . $bitcom_obj_id . '01',
		format => sub {
			# var processAnswer = function(res, conf) { // type: NUMBER
			my @payload = @{(shift)};

			# payload.splice(1, 6) //leasetime
			splice @payload, 1, 6 if (($payload[0] & 0x08) > 0);

			if ($payload[5] == 0x6f) {
				# payload.splice(0, 6);
				# ERROR
				# return error;
				return undef;
			}

			splice @payload, 0, 6;

			# val = DataHelper.nbrArrayToNbr(a, false);
			my $back = 0;
			for (my $i; $i <= $#payload; $i++) {
				my $idx = (scalar @payload) - 1 - $i;
				my $val = $payload[$idx];

				# back += val<<(i*8)
				$back += $val * (256 ** $i);
			}

			if (($payload[0] & 0x80) > 0) {
				# 1st bit is set --> negative number
				my $intMax = (2 ** (scalar @payload) * 8) - 1;
				$back = ($intMax - $back + 1) * (-1);
			}

			return $back;
		},
	);
}

##*
# 1 <= $preset <= 6
#
# See code from Js UI:
# - PresetSupport::isPresetMapped
#
sub is_preset_mapped
{
	my ($preset, $num) = @_;
	# RCP.readBicom(0x6, 0x0212, { rcpnum: data.rcpnum, sessionid: data.sessionid, bicomtype: "BYTES" })

	return (
		num => $num || 0,
		direction => $Direction{write},
		command => '0x09A5',
		type => $Type{octect},
		payload => '0x85' . '0006' . '0212' . '01',
		format => sub {
			# -> fixByteOrderForMapping
			# function fixByteOrderForMapping(b) {
			#     var back = [], pos = 0;
			#     while(b.length>=pos+4) {
			#         back.push(b[pos+3]);
			#         back.push(b[pos+2]);
			#         back.push(b[pos+1]);
			#         back.push(b[pos]);
			#         pos += 4;
			#     }
			#     return back;
			# }
			my @payload = @{(shift)};
			my $length = scalar @payload;
			my @bytes;
			my $pos = 0;

			while ($length >= $pos + 4) {
				push @bytes, $payload[$pos + 3];
				push @bytes, $payload[$pos + 2];
				push @bytes, $payload[$pos + 1];
				push @bytes, $payload[$pos];
				$pos += 4;
			}

			# idx - 1
			# (bytes[Math.floor(idx / 8)] & Math.pow(2, idx % 8)) > 0
			if ($preset) {
				my $idx = $preset - 1;
				return $bytes[floor($idx / 8)] & (2 ** ($idx % 8));
			}
			return \@bytes;
		},
	);
}

##*
# 1 <= $preset <= 6
#
# See code from Js UI:
# - PresetSupport::setScene
#
sub set_scene
{
	my ($preset, $num) = @_;
	# $.rcp.doRequest(PRESET, { // { bicomflags: 128, bicomserver: 6, noglobalfinish: true }
	# 	bicomobjid: 0x2000 + ((num - 1) << 4),
	# 	bicomaction: 0x80,
	# 	idstring: 'setScene' + num,
	# 	rcpnum: sessionid > 0 ? 0 : getNum(),
	# 	sessionid: sessionid > 0 ? sessionid : null,
	# 	callback: function(val, conf, error) {
	# 		if (error) {
	# 			printError(conf, error);
	# 		}
	# 	}
	# });
	my $bitcom_obj_id = sprintf('%04X', 0x2000 + (($preset - 1) << 4));

	return (
		num => $num || 0,
		direction => $Direction{write},
		command => '0x09A5',
		type => $Type{octect},
		idstring => 'setScene' . $preset,
		payload => '0x80' . '0006' . $bitcom_obj_id . '80',
	);
}

##*
# 1 <= $preset <= 6
#
# See code from Js UI:
# - PresetSupport::showScene
#
sub show_scene
{
	my ($preset, $num) = @_;
	# bicomobjid: 0x2000 + ((num - 1) << 4)
	my $bitcom_obj_id = sprintf('%04X', 0x2000 + (($preset - 1) << 4));

	return (
		num => $num || 0,
		direction => $Direction{write},
		command => '0x09A5',
		type => $Type{octect},
		payload => '0x80' . '0006' . $bitcom_obj_id . '81',
		idstring => 'setScene' . $preset,
	);
}


##*
# This command is used on the UI to check AUTH
# (aparently there are different users levels)
#
sub one
{
	my ($num) = @_;

	return (
		num => $num || 1,
		direction => $Direction{read},
		command => '0x0001',
		type => $Type{word},
	);
}

##*
#
# See code from Js UI:
# - PresetSupport::getAvailableScenes
#
sub available_scenes
{
	my ($num) = @_;

	return (
		num => $num || 1,
		direction => $Direction{write},
		command => '0x09A5',
		type => $Type{octect},
		payload => '0x85' . '0006' . '2000' . '84',
		idstring => 'availableScenes',
		format => sub {
			my @payload = @{(shift)};

			# payload.splice(1, 6) //leasetime
			splice @payload, 1, 6 if (($payload[0] & 0x08) > 0);

			if ($payload[5] == 0x6f) {
				# payload.splice(0, 6);
				# ERROR
				# return error;
				return undef;
			}

			splice @payload, 0, 6;

			# Implemented for 0x84 bitcom action (might be used for 0x82 too)
			my $is82 = 0;
			my @b;
			my @available;
			my $l = $is82 ? 16 : 32;

			if ((scalar @payload) >= $l) {
				my $length = $is82 ? 4 : 8;
				for (my $i = 0; $i < $length; $i++) {
					my @current = @payload[($i * 4) .. ($i * 4 + 3)];

					$b[$i] = bytes2int(\@current, 1);
					my $offset = ($is82 && $i == 0) ? 1 : 0; # 1st bit of 1st byte is never set for bicom action 82

					for (my $j = 0; ($j + $offset) < 32; $j++) {
						if ($b[$i] & (1 << ($j + $offset))) {
							my $idx = ($i * 32) + $j;
							$idx++ if (!$is82 || $i == 0);
							push @available, $idx;
						}
					}
				}
			}

			return \@available;
		},
	);
}

1;
