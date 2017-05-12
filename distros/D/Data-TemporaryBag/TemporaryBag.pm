package Data::TemporaryBag;

use strict;

use Fcntl qw/:DEFAULT :seek/;
use Carp;
use File::Temp 'tempfile';

use overload '""' => \&value, '.=' => \&add, '=' => \&clone, fallback => 1;
use constant BUFFER      => 0;
use constant FILENAME    => 1;
use constant FILEHANDLE  => 2;
use constant STARTPOS    => 3;
use constant RECENTNESS  => 4;
use constant FINGERPRINT => 4;
use constant LENGTH      => 5;

our ($VERSION, $Threshold, $TempPath, $MaxOpen);

$VERSION = '0.09';

$Threshold = 10; # KB
#$TempPath  = $::ENV{'TEMP'}||$::ENV{'TMP'}||'.';
$TempPath = '';
$MaxOpen = 10;

my %OpenFiles;

sub new {
    my $class = shift;
    my $self = [''];
    
    bless $self, ref($class)||$class;
    
    $self->[LENGTH] = 0;
    $self->add(@_) if @_;
    $self;
}

sub clear {
    my $self = $_[0];

    &_clear_buffer;
    $self->[LENGTH] = 0;
}

sub _clear_buffer {
    my $self = shift;
    my $fn = $self->[FILENAME];

    if ($fn) {
	$self->_close if $self->[FILEHANDLE];
	unlink $fn; 
	@{$self}[FILENAME..FINGERPRINT] = ();
    }
    $self->[BUFFER] = '';
}

sub add {
    my ($self, $data) = @_;
    my $buf = \$$self[BUFFER];

    $data = '' unless defined $data;
    $self->[LENGTH] += CORE::length($data);

    if ($self->[FILENAME]) {
	my $fh = $self->_open;
	seek $fh, 0, SEEK_END;
	print $fh $data;
    } else {
	if (CORE::length($data) + CORE::length($$buf) > $Threshold * 1024) {
	    my $fh = $self->_open;
	    seek $fh, 0, SEEK_END;
	    print $fh $$buf, $data;
	} else {
	    $$buf .= $data;
	}
    }
    $self;
}

sub substr {
    my ($self, $pos, $size, $replace) = @_;
    my $len = $self->[LENGTH];
   
    $pos  = $len + $pos  if $pos  < 0;
    if (not defined $size or $size+$pos > $len) {
	$size = $len - $pos;
    } elsif ($size < 0) { 
	$size = $len + $size;
    }
    my $rsize = defined($replace) ? CORE::length($replace) : 0;
    my $offset = $size - $rsize;
    my $newlen = $len - $offset;

    if ($self->[FILENAME]) {
	my $data;
	my $fh = $self->_open;
	my $startpos = $self->[STARTPOS];

	return '' if $pos >= $len;
	seek($fh, $startpos+$pos, SEEK_SET);
	read($fh, $data, $size);
	if (defined $replace) {

	    if ($offset == 0) {
		my $fh = $self->_open;
		seek($fh, $pos + $startpos, SEEK_SET);
		print $fh $replace;
	    } elsif ($newlen < $Threshold * 800) {
		my $data1 = $self->substr(0, $pos);
		my $data2 = $self->substr($pos + $size);
		$self->_clear_buffer;
		$self->[BUFFER] = $data1.$replace.$data2;
		$self->[LENGTH] = $newlen;
	    } elsif ($pos == 0 and $startpos >= -$offset) {
		$self->[STARTPOS] += $offset;
		if ($rsize>0) {
		    seek($fh, $self->[STARTPOS], SEEK_SET);
		    print $fh $replace;
		}
	    } elsif ($pos+$size == $len) {
		seek($fh, $startpos+$pos, SEEK_SET);
		print $fh $replace;
		truncate($fh, $startpos+$newlen) if $newlen<$len;
	    } elsif ($offset > 0) {
		my ($data, $pos2);

		if ($pos < $len - $pos - $size) {
		    seek($fh, $startpos+$pos+$offset, SEEK_SET);
		    print $fh $replace;
		    _blktf_fw($fh, $startpos, $pos, $offset);
		    $self->[STARTPOS] += $offset;
		} else {
		    seek($fh, $startpos+$pos, SEEK_SET);
		    print $fh $replace;
		    my $start = $startpos+$pos+$size;
		    _blktf_bw($fh, $startpos+$pos+$size, $len-$pos-$size, $offset);
		    truncate($fh, $startpos+$newlen);
		}
	    } else {
		my $offset = $rsize-$size;
		my ($data, $pos2);

		if ($startpos >= $offset) {
		    _blktf_bw($fh, $startpos, $pos, $offset);
		    seek($fh, $startpos+$pos-$offset, SEEK_SET);
		    print $fh $replace;
		    $self->[STARTPOS] -= $offset;
		} else {
		    _blktf_fw($fh, $startpos+$pos+$size, $len-$pos-$size, $offset);
		    seek($fh, $startpos+$pos, SEEK_SET);
		    print $fh $replace;
		}
	    }
	    $self->[LENGTH] = $newlen;
	}
	return $data;
    } else {
	if (defined $replace) {
	    $self->[LENGTH] = $newlen;
	    substr($self->[BUFFER], $pos, $size, $replace);
	} else {
	    substr($self->[BUFFER], $pos, $size);
	}
    }
}

sub _blktf_fw {
    my ($fh, $start, $size, $offset) = @_;
    my ($pos2, $data);

    for ($pos2 = $start + $size-1024; $pos2 > $start; $pos2-=1024) {
	seek($fh, $pos2, SEEK_SET);
	read($fh, $data, 1024);
	seek($fh, $pos2+$offset, SEEK_SET);
	print $fh $data;
    }
    seek($fh, $start, SEEK_SET);
    read($fh, $data, $pos2 - $start+1024);
    seek($fh, $start+$offset, SEEK_SET);
    print $fh $data;
}

sub _blktf_bw {
    my ($fh, $start, $size, $offset) = @_;
    my ($pos2, $data);

    for($pos2 = $start; $pos2 < $start+$size-1024; $pos2+=1024) {
	seek($fh, $pos2, SEEK_SET);
	read($fh, $data, 1024);
	seek($fh, $pos2-$offset, SEEK_SET);
	print $fh $data;
    }
    seek($fh, $pos2, SEEK_SET);
    read($fh, $data, $start+$size-$pos2);
    seek($fh, $pos2-$offset, SEEK_SET);
    print $fh $data;
}


sub clone {
    my ($self, $stream)=@_;
    my $size = $self->[LENGTH];
    my $pos = 0;
    my $new = $self->new;

    while ($size > $pos) {
	$new->add($self->substr($pos, 1024));
	$pos += 1024;
    }
    $new->[LENGTH] = $size;
    $new;
}

sub value {
    my ($self, $stream)=@_;
    my $size = $self->length;
    my $pos = 0;
    my $data = '';

    while ($size > $pos) {
	$data .= $self->substr($pos, 1024);
	$pos += 1024;
    }
    $data;
}

sub length {
    shift->[LENGTH];

=pod

    my $self = shift;
    my $fn = $self->[FILENAME];
    my $fh = $self->[FILEHANDLE];

    if ($fh) {
	seek $fh, 0, SEEK_END;
	return tell($fh)- $self->[STARTPOS];
    } elsif ($fn) {
	return (-s $fn) - $self->[STARTPOS];
    } else {
	return length($self->[BUFFER]);
    }

=cut

}

sub defined {
    defined shift->[BUFFER];
}

sub _open {
    my ($self, $mode) = @_;
    my ($fh, $fn);

    if (defined ($fh = $self->[FILEHANDLE])) {
	my $recent = $self->[RECENTNESS];
	return $fh if $recent == 1;
	$self->[RECENTNESS] = 0;
	while(my (undef, $obj) = each %OpenFiles) {
	    if ($obj->[RECENTNESS] <= $recent) {
		$obj->[RECENTNESS]++;
	    }
	}
	return $fh;
    }
    if (defined ($fn = $self->[FILENAME])) {
	croak "TemporaryBag object seems to be collapsed " if (!-e $fn) or (!-f _);
	sysopen($fh, $fn, O_RDWR) or croak "TemporaryBag object seems to be collapsed OP";
	croak "TemporaryBag object seems to be collapsed " if (-l $fn);
	binmode $fh;
	$self->[FILEHANDLE] = $fh;
	$self->_check_fingerprint or croak "TemporaryBag object seems to be collapsed CH";
    } else {
	($fh, $fn) = tempfile();
	$self->[STARTPOS] = 0;
	croak "TemporaryBag object seems to be collapsed CR" unless defined $fh;
	binmode $fh;
	$self->[FILEHANDLE] = $fh;
	$self->[FILENAME] = $fn;
    }

    while(my (undef, $obj) = each %OpenFiles) {
	++$obj->[RECENTNESS];
    }
    
    if (keys %OpenFiles >= $MaxOpen) {
	my $to_close;
	while(my (undef, $obj) = each %OpenFiles) {
	    if ($obj->[RECENTNESS] > $MaxOpen) {
		$to_close = $obj;
		last;
	    }
	}
	$to_close->_close;
    }

    $self->[RECENTNESS] = 1;
    $OpenFiles{overload::StrVal($self)} = $self;
    return $fh;
}

sub _close {
    my $self = shift;
    my $recent = $self->[RECENTNESS];
    my $fh = $self->[FILEHANDLE];
    my $i;

    delete $OpenFiles{overload::StrVal($self)};

    while(my (undef, $obj) = each %OpenFiles) {
	if (defined $obj and $obj->[RECENTNESS] > $recent) {
	    $obj->[RECENTNESS]--;
	}
    }
    $self->_set_fingerprint;
    undef $self->[FILEHANDLE];
    close $fh or croak "TemporaryBag object seems to be collapsed CL";
}


sub is_saved {
    return shift->[FILENAME];
}

sub _set_fingerprint {
    my $self = shift;
    my $fingerprint;
    my $fh =  $self->[FILEHANDLE];
    seek $fh, 0, SEEK_END;
    my $range = tell($fh) - $self->[STARTPOS] - 1024;

    for (1..3) {
	my $r = int(rand($range))+1024;
	my $data;
	seek $fh, -$r, SEEK_END;
	read($fh, $data, 1024);
	$fingerprint .= "[$r]".unpack('%32C*',$data);
    }
    $self->[FINGERPRINT] = $fingerprint;
}

sub _check_fingerprint {
    my $self = shift;
    my $fh =  $self->[FILEHANDLE];
    my $fingerprint = $self->[FINGERPRINT];
    my $flag = 1;

    while($fingerprint=~/\[([^]]+)\]([^[]+)/g) {
	my $pos = $1;
	my $sum = $2;
	my $data;

	seek $fh, -$pos, SEEK_END;
	read($fh, $data, 1024);
	$flag &&= (unpack('%32C*',$data) == $sum);
    }
    return $flag;
}



sub DESTROY {
    my $self = shift;
#    close $self->[FILEHANDLE] if defined $self->[FILEHANDLE];
    $self->_close if defined $self->[FILEHANDLE];
    unlink $self->[FILENAME] if defined $self->[FILENAME];
}



1;
__END__

=head1 NAME

Data::TemporaryBag - Handle long size data using temporary file .

=head1 SYNOPSIS

  use Data::TemporaryBag;

  $data = Data::TemporaryBag->new;
  # add long string
  $data->add('ABC' x 1000);
  # You can use an overridden operator
  $data .= 'DEF' x 1000;
  ...
  $substr = $data->substr(2997, 6);  # ABCDEF

=head1 DESCRIPTION

I<Data::TemporaryBag> module provides a I<bag> object class handling long size 
data.  The short size data are kept on memory.  When the data size becomes 
over I<$Threshold> size, they are saved into a temporary file internally.

=head2 METHOD

=over 4

=item Data::TemporaryBag->new( [$data] )

Creates a I<bag> object.

=item $bag->clear

Clears I<$bag>.

=item $bag->add( $data )

Adds I<$data> to I<$bag>.
You can use an assignment operator '.=' instead.

=item $bag->substr( $offset, $length, $replace )

Extracts a substring out of I<$bag>.  It behaves similar to 
CORE::substr except that it can't be an lvalue.

=item $bag->clone

Creates a clone of I<$bag>.

=item $bag->value

Gets data of I<$bag> as a string.  It is possible that the string is 
extremely long.

=item $bag->length

Gets length of data.

=item $bag->defined

Returns if the data in I<$bag> are defined or not.

=item $bag->is_saved

Returns the file name if I<$bag> is saved in a temporary file.

=back

=head2 GLOBAL VARIABLES

=over 4

=item $Data::TemporaryBag::Threshold

The threshold of the data size in kilobytes whether saved into file or not.
Default is 10.

=item $data::TemporaryBag::MaxOpen

The maximum number of the opened temporary files.
Default is 10.

=back

=head1 COPYRIGHT

Copyright 2001 Yasuhiro Sasama (ySas), <ysas@nmt.ne.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
