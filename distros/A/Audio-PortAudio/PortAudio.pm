# Audio::PortAudio perl modules for portable audio I/O
# Copyright (C) 2007  Joost Diepenmaat.
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
# See the COPYING file for more information.



package Audio::PortAudio;
use strict;
use base qw(DynaLoader);
our $VERSION = 0.03;

__PACKAGE__->bootstrap($VERSION);

initialize();

sub host_apis {
    my $count = host_api_count();
    return if $count < 1;
    return map { host_api($_) } 0 .. $count -1;
}

sub open_read_stream {
    my ($streamparameters, $sample_rate, $frames_per_buffer, $stream_flags) = @_;
    open_stream($streamparameters,undef,$sample_rate, $frames_per_buffer, $stream_flags);
}

sub open_write_stream {
    my ($streamparameters, $sample_rate, $frames_per_buffer, $stream_flags) = @_;
    open_stream(undef,$streamparameters,$sample_rate, $frames_per_buffer, $stream_flags);
}


*open_rw_stream = \&open_stream;

END {
    terminate();
}

package Audio::PortAudio::HostAPI;

sub devices {
    my ($self) = @_;
    my $count = $self->device_count();
    return if $count < 1;
    return map { $self->device($_) } 0 .. $count - 1;
}

package Audio::PortAudio::Stream;
use Config;

my %closed;
my %started;
my %stream_typesize_in;
my %stream_typesize_out;
my %channels_in;
my %channels_out;

sub DESTROY {
    my ($self) = @_;
    $self->stop;
    delete $stream_typesize_in{$self};
    delete $stream_typesize_out{$self};
    delete $channels_in{$self};
    delete $channels_out{$self};
}

sub start {
    my ($self) = @_;
    if (!$started{$self}++) {
        $self->_start;
    }
}

sub stop {
    my ($self) = @_;
    if ($started{$self}) {
        $self->_stop;
        delete $started{$self};
    }
}

sub close {
    my ($self) = @_;
    if (!$closed{$self}++) {
        $self->_close;
    }
    $self->stop;
}

my %typesize = (
    float32() => 4,
    int16()   => $Config{u16size},
    int32()   => $Config{u32size},
    int24()   => $Config{u32size},   # not sure, but probably
    int8()    => $Config{charsize},
    uint8()   => $Config{charsize},
);

my %typevalue = (
    float32 => float32(),
    int16   => int16(),
    int32   => int32(),
    int24   => int24(),
    int8    => int8(),
    uint8   => int8(),
);

sub read {
    my ($self, undef, $frames) = @_;
    $self->start unless ($started{$self});
    $self->_internal_read_stream($_[1],$frames,$stream_typesize_in{$self},$self->input_channels);    
}

sub write {
    my ($self) = @_;
    $self->start unless ($started{$self});
#    warn "(buffer),$stream_typesize_out{$self})",$self->output_channels;
    $self->_internal_write_stream($_[1],$stream_typesize_out{$self},$self->output_channels);

}

sub input_channels {
  $channels_in{$_[0]} || 0;
}

sub output_channels {
  $channels_out{$_[0]} || 0;
}



package Audio::PortAudio;

sub open_stream {
    my ($iargs,$oargs) = splice @_,0,2;
    if ($iargs) {
        $iargs->{sample_format} = $typevalue{$iargs->{sample_format} || "float32"} || $iargs->{sample_format};
    }
    if ($oargs) {
        $oargs->{sample_format} = $typevalue{$oargs->{sample_format} || "float32"} || $oargs->{sample_format};
    }
    my $stream = _open_stream($iargs,$oargs,@_);
    $stream_typesize_in{$stream} = $typesize{$iargs->{sample_format}} if $iargs;
    $stream_typesize_out{$stream} = $typesize{$oargs->{sample_format}} if $oargs;
    $channels_in{$stream} =  $iargs->{channel_count} if $iargs;
    $channels_out{$stream} = $oargs->{channel_count} if $oargs;

    return $stream;
}


package Audio::PortAudio::Device;

sub open_read_stream {
    my ($self,$streamparameters, $sample_rate, $frames_per_buffer, $stream_flags) = @_;
    $self->open_stream($streamparameters,undef,$sample_rate, $frames_per_buffer, $stream_flags);
}

sub open_write_stream {
    my ($self,$streamparameters, $sample_rate, $frames_per_buffer, $stream_flags) = @_;
    $self->open_stream(undef,$streamparameters,$sample_rate, $frames_per_buffer, $stream_flags);
}


sub open_stream {
    my ($self,$inparameters, $outparameters, $sample_rate, $frames_per_buffer, $stream_flags) = @_;
    $inparameters->{device} = $self if $inparameters;
    $outparameters->{device} = $self if $outparameters;
    Audio::PortAudio::open_stream($inparameters, $outparameters, $sample_rate, $frames_per_buffer, $stream_flags);
}

*open_rw_stream = \&open_stream;





1;
