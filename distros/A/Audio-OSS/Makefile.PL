# -*- cperl -*-

# Makefile.PL - tastes great, less filling (than h2ph)
#
# Copyright (c) 2000 Cepstral LLC. All rights Reserved.
#
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Written by David Huggins-Daines <dhd@cepstral.com>

use ExtUtils::MakeMaker;
use Getopt::Long;
use strict;

my %constants =
    (ioctls => [qw(
		   SNDCTL_DSP_RESET
		   SNDCTL_DSP_SYNC
		   SNDCTL_DSP_SPEED
		   SNDCTL_DSP_STEREO
		   SNDCTL_DSP_GETBLKSIZE
		   SNDCTL_DSP_SAMPLESIZE
		   SNDCTL_DSP_CHANNELS
		   SNDCTL_DSP_POST
		   SNDCTL_DSP_SUBDIVIDE
		   SNDCTL_DSP_SETFRAGMENT
		   SNDCTL_DSP_GETOSPACE
		   SNDCTL_DSP_GETISPACE
		   SNDCTL_DSP_NONBLOCK
		   SNDCTL_DSP_GETCAPS
		   SNDCTL_DSP_GETFMTS
		   SNDCTL_DSP_SETFMT
		   SNDCTL_DSP_GETTRIGGER
		   SNDCTL_DSP_SETTRIGGER
		   SNDCTL_DSP_GETIPTR
		   SNDCTL_DSP_GETOPTR
		   SNDCTL_DSP_MAPINBUF
		   SNDCTL_DSP_MAPOUTBUF
		   SNDCTL_DSP_SETSYNCRO
		   SNDCTL_DSP_SETDUPLEX
		   SNDCTL_DSP_GETODELAY

		   SNDCTL_DSP_GETCHANNELMASK
		   SNDCTL_DSP_BIND_CHANNEL
		   SNDCTL_DSP_PROFILE

		   SOUND_PCM_READ_RATE
		   SOUND_PCM_READ_CHANNELS
		   SOUND_PCM_READ_BITS
		   SOUND_PCM_READ_FILTER

		   SOUND_MIXER_READ_VOLUME
		   SOUND_MIXER_READ_RECSRC
		   SOUND_MIXER_READ_DEVMASK
		   SOUND_MIXER_READ_RECMASK
		   SOUND_MIXER_READ_STEREODEVS
		   SOUND_MIXER_READ_CAPS

		   SOUND_MIXER_WRITE_VOLUME
		   SOUND_MIXER_WRITE_RECSRC

                   SOUND_MIXER_INFO
		   SOUND_MIXER_AGC
		   SOUND_MIXER_3DSE
		   SOUND_MIXER_PRIVATE1
		   SOUND_MIXER_PRIVATE2
		   SOUND_MIXER_PRIVATE3
		   SOUND_MIXER_PRIVATE4
		   SOUND_MIXER_PRIVATE5
		   SOUND_MIXER_GETLEVELS
		   SOUND_MIXER_SETLEVELS

		   OSS_GETVERSION
		  )],

     mixer => [qw(
		  SOUND_MIXER_NRDEVICES
		  SOUND_MIXER_VOLUME
		  SOUND_MIXER_BASS
		  SOUND_MIXER_TREBLE
		  SOUND_MIXER_SYNTH
		  SOUND_MIXER_PCM
		  SOUND_MIXER_SPEAKER
		  SOUND_MIXER_LINE
		  SOUND_MIXER_MIC
		  SOUND_MIXER_CD
		  SOUND_MIXER_IMIX
		  SOUND_MIXER_ALTPCM
		  SOUND_MIXER_RECLEV
		  SOUND_MIXER_IGAIN
		  SOUND_MIXER_OGAIN
		  SOUND_MIXER_LINE1
		  SOUND_MIXER_LINE2
		  SOUND_MIXER_LINE3
		  SOUND_MIXER_DIGITAL1
		  SOUND_MIXER_DIGITAL2
		  SOUND_MIXER_DIGITAL3
		  SOUND_MIXER_PHONEIN
		  SOUND_MIXER_PHONEOUT
		  SOUND_MIXER_VIDEO
		  SOUND_MIXER_RADIO
		  SOUND_MIXER_MONITOR
		  SOUND_MIXER_NONE
		  SOUND_ONOFF_MIN
		  SOUND_ONOFF_MAX

		  SOUND_MIXER_RECSRC
		  SOUND_MIXER_DEVMASK
		  SOUND_MIXER_RECMASK
		  SOUND_MIXER_CAPS
		  SOUND_CAP_EXCL_INPUT
		  SOUND_MIXER_STEREODEVS
		  SOUND_MIXER_OUTSRC
		  SOUND_MIXER_OUTMASK
		 )],

     formats => [qw(
		   AFMT_QUERY
		   AFMT_MU_LAW
		   AFMT_A_LAW
		   AFMT_IMA_ADPCM
		   AFMT_U8
		   AFMT_S16_LE
		   AFMT_S16_BE
		   AFMT_S16_NE
		   AFMT_S8
		   AFMT_U16_LE
		   AFMT_U16_BE
		   AFMT_MPEG
		   AFMT_AC3
		)],

     caps => [qw(
		 DSP_CAP_REVISION
		 DSP_CAP_DUPLEX
		 DSP_CAP_REALTIME
		 DSP_CAP_BATCH
		 DSP_CAP_COPROC
		 DSP_CAP_TRIGGER
		 DSP_CAP_MMAP
		 DSP_CAP_MULTI
		 DSP_CAP_BIND
		)],

     bind => [qw(
		   DSP_BIND_QUERY
		   DSP_BIND_FRONT
		   DSP_BIND_SURR
		   DSP_BIND_CENTER_LFE
		   DSP_BIND_HANDSET
		   DSP_BIND_MIC
		   DSP_BIND_MODEM1
		   DSP_BIND_MODEM2
		   DSP_BIND_I2S
		   DSP_BIND_SPDIF
		)],

     misc => [qw(
		   PCM_ENABLE_INPUT
		   PCM_ENABLE_OUTPUT
		   APF_NORMAL
		   APF_NETWORK
		   APF_CPUINTENS)],
    );

my ($khdrs, $ohdrs);
GetOptions('kernel-headers=s' => \$khdrs, 'oss-headers=s' => \$ohdrs);

my @possible_hdrdirs;
if (defined $khdrs or defined $ohdrs) {
    @possible_hdrdirs = ((defined $khdrs ? "$khdrs/linux"  : ()), $ohdrs);
} else {
    @possible_hdrdirs = qw(/usr/local/include
			   /usr/local/include/sys
			   /usr/include
			   /usr/include/sys
			   /usr/include/linux
			   /usr/src/linux/include/linux);
}

use vars qw($SOUNDCARD_H);
foreach my $dir (@possible_hdrdirs) {
    if (-r "$dir/soundcard.h") {
	$SOUNDCARD_H = "$dir/soundcard.h";
	last;
    }
}

unless (defined($SOUNDCARD_H)) {
    local $" = "\n";
    print <<"EOF";
No OSS header files could be found in any of the following
directories:

@possible_hdrdirs

You can use the --kernel-headers option to specify the location of
your Linux kernel header files (e.g. /home/foo/linux/include), or
the --oss-headers option to specify a directory containing Open
Sound System header files.
EOF
    exit 1;
}

print "Finding constants and values, this may take a while...\n";

use vars qw($CC $NO_DASH_INCLUDE);
$CC = $ENV{CC} || 'cc';
$NO_DASH_INCLUDE = 0;

unlink 'conftest';
if (system($CC, '-include', $SOUNDCARD_H, 'conftest.c', '-o', 'conftest') != 0) {
    $NO_DASH_INCLUDE = 1;
    if (system($CC, 'conftest.c', '-o', 'conftest') != 0) {
	# Give up
	print <<"EOF";
Compiling test program:

$CC -i $SOUNDCARD_H conftest.c -o conftest
$CC conftest.c -o conftest

Failed with status $?.  You can change the default compiler by
setting the \$CC environment variable in your shell.
EOF
	exit 1;
    }
}
unlink 'conftest';

sub check_const {
    my @cmd;
    unlink 'get-constants.c';
    open TEMPL, "<get-constants.c.in" or die "Could not open get-constants.c.in: $!";
    open TEST, ">get-constants.c" or die "Could not open get-constants.c: $!";
    if ($NO_DASH_INCLUDE) {
	open H, "<$SOUNDCARD_H" or die "Could not open $SOUNDCARD_H: $!";
	while (<H>) {
	    print TEST $_;
	}
	close H;
	@cmd = ($CC, 'get-constants.c', '-o', 'get-constants');
    } else {
	@cmd = ($CC, '-include', $SOUNDCARD_H, 'get-constants.c',
		'-o', 'get-constants');
    }
    while (<TEMPL>) {
	if (m,/\* INSERT CONSTANTS HERE \*/,) {
	    foreach my $const (@_) {
		print TEST qq/{ "$const", $const },\n/;
	    }
	} else {
	    print TEST $_;
	}
    }
    close TEMPL;
    close TEST;

    if (my $pid = fork) {
	waitpid $pid, 0;
	if ($?) {
	    unlink 'get-constants.c', 'get-constants';
	    return undef;
	}
    } else {
	close STDERR;
	exec @cmd
	    or die "exec failed: $!";
    }

    my @ret;
    open PROG, './get-constants|' or die "Could not open pipe: $! $?";
    while (<PROG>) {
	chomp;
	my ($const, $val) = split /:/;
	push @ret, $val;
    }

    unlink 'get-constants.c', 'get-constants';
    return (@ret == 1) ? $ret[0] : @ret;
}

my (@constmap, %valid);
foreach my $t (keys %constants) {
    foreach my $c (@{$constants{$t}}) {
	{
	    print "Checking for $c... ";
	    local $|=1;
	}
	my $val = check_const($c);
	if (defined $val) {
	    print "$val.\n";
	    push @constmap, [$c => $val];
	    $valid{$t}{$c} = 1;
	} else {
	    print "not found.\n";
	}
    }
}

unlink 'OSS/Constants.pm';
mkdir 'OSS', 0755;
open CONFMOD, '>OSS/Constants.pm'
    or die "Could not open OSS/Constants.pm: $!";

# Random header stuff
print CONFMOD <<'EOP';
package Audio::OSS;
use strict;
use vars qw(@EXPORT_OK %EXPORT_TAGS @CONSTANTS);
push @EXPORT_OK, qw(
EOP

# Now the constant names
foreach (@constmap) {
    print CONFMOD "\t$_->[0]\n";
}

print CONFMOD <<'EOP';
	);
EOP

foreach my $t (keys %constants) {
    print CONFMOD "\$EXPORT_TAGS{'$t'} = [qw(\n";
    foreach my $c (@{$constants{$t}}) {
	print CONFMOD "\t$c\n" if $valid{$t}{$c};
    }
    print CONFMOD "\t)];\n";
}

print CONFMOD <<'EOP';
@CONSTANTS = (
EOP

# And their values
foreach (@constmap) {
    print CONFMOD "\t[ $_->[0] => $_->[1] ],\n";
}

# And some cruft to define them for us
print CONFMOD <<'EOP';
    );

sub make_const {
    my ($const, $val) = @_;

    no strict 'refs';
    *$const = sub () { $val };
}

foreach (@CONSTANTS) {
    make_const(@$_);
}
1;
EOP
close CONFMOD;

WriteMakefile(
	      NAME	   => 'Audio::OSS',
	      VERSION_FROM => 'OSS.pm',
	      C            => [], # NO MAKEMAKER, THAT'S WRONG
	      clean        => { FILES => 'conftest get-constants.c get-constants OSS/Constants.pm' },
	     );
