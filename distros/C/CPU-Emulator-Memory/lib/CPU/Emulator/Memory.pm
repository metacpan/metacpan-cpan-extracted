package CPU::Emulator::Memory;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '1.1005';

=head1 NAME

CPU::Emulator::Memory - memory for a CPU emulator

=head1 SYNOPSIS

    my $memory = CPU::Emulator::Memory->new();
    $memory->poke(0xBEEF, ord('s'));
    
    my $value = $memory->peek(0xBEEF); # 115 == ord('s')

=head1 DESCRIPTION

This class provides a flat array of values which you can 'peek'
and 'poke'.

=head1 METHODS

=head2 new

The constructor returns an object representing a flat memory
space addressable by byte.  It takes four optional named parameters:

=over

=item file

if provided, will provide a disc-based backup of the
RAM represented.  This file will be read when the object is created
(if it exists) and written whenever anything is altered.  If no
file exists or no filename is provided, then memory is initialised
to all zeroes.  If the file exists it must be writeable and of the
correct size.

=item endianness

defaults to LITTLE, can be set to BIG.  This matters for the peek16
and poke16 methods.

=item size

the size of the memory to emulate.  This defaults to 64K (65536 bytes), 
or to the length of the string passed to C<bytes> (plus C<org> if
applicable).
.
Note that this does *not* have to be a power of two. 

=item bytes

A string of characters with which to initialise the memory.  Note that
the length must match the size parameter.

=item org

an integer, Used in conjunction with C<bytes>, load the data at the specified
offset in bytes

=back

=cut

sub new {
    my($class, %params) = @_;
    if(exists($params{bytes}) && exists($params{org})) {
        $params{bytes} = (chr(0) x $params{org}).$params{bytes};
    }

    if(!exists($params{size})) {
        if(exists($params{bytes})) {
            $params{size} = length($params{bytes});
        } else {
            $params{size} = 0x10000;
        }
    }
    if(!exists($params{bytes})) {
        $params{bytes} = chr(0) x $params{size};
    }
    die("bytes and size don't match\n")
        if(length($params{bytes}) != $params{size});

    if(exists($params{file})) {
        if(-e $params{file}) {
            $params{bytes} = $class->_readRAM($params{file}, $params{size});
        } else {
            $class->_writeRAM($params{file}, $params{bytes})
        }
    }
    return bless(
        {
            contents => $params{bytes},
            size     => $params{size},
            ($params{file} ? (file => $params{file}) : ()),
            endianness => $params{endianness} || 'LITTLE'
        },
        $class
    );
}

=head2 peek, peek8

This method takes a single parameter, an address from 0 the memory size - 1.
It returns the value stored at that address, taking account of what
secondary memory banks are active.  'peek8' is simply another name
for the same function, the suffix indicating that it returns an 8
bit (ie one byte) value.

=head2 peek16

As peek and peek8, except it returns a 16 bit value.  This is where
endianness matters.

=cut

sub peek8 {
    my($self, $addr) = @_;
    $self->peek($addr);
}
sub peek16 {
    my($self, $address) = @_;
    # assume little-endian
    my $r = $self->peek($address) + 256 * $self->peek($address + 1);
    # swap bytes if necessary
    if($self->{endianness} eq 'BIG') {
        $r = (($r & 0xFF) << 8) + int($r / 256);
    }
    return $r;
}
sub peek {
    my($self, $addr) = @_;
    die("Address $addr out of range") if($addr< 0 || $addr > $self->{size} - 1);
    return ord(substr($self->{contents}, $addr, 1));
}

=head2 poke, poke8

This method takes two parameters, an address and a byte value.
The value is written to the address.

It returns 1 if something was written, or 0 if nothing was written.

=head2 poke16

This method takes two parameters, an address and a 16-bit value.
The value is written to memory as two bytes at the address specified
and the following one.  This is where endianness matters.

Return values are undefined.

=cut

sub poke8 {
    my($self, $addr, $value) = @_;
    $self->poke($addr, $value);
}
sub poke16 {
    my($self, $addr, $value) = @_;
    # if BIGendian, swap bytes, ...
    if($self->{endianness} eq 'BIG') {
        $value = (($value & 0xFF) << 8) + int($value / 256);
    }
    # write in little-endian order
    $self->poke($addr, $value & 0xFF);
    $self->poke($addr + 1, ($value >> 8));
}
sub poke {
    my($self, $addr, $value) = @_;
    die("Value $value out of range") if($value < 0 || $value > 255);
    die("Address $addr out of range") if($addr< 0 || $addr > $self->{size} - 1);
    $value = chr($value);
    substr($self->{contents}, $addr, 1) = $value;
    $self->_writeRAM($self->{file}, $self->{contents})
        if(exists($self->{file}));
    return 1;
}

# input: filename, required size
# output: file contents, or fatal error
sub _read_file { 
    my($self, $file, $size) = @_;
    local $/ = undef;
    open(my $fh, $file) || die("Couldn't read $file\n");
    # Win32 is stupid, see RT 62379
    binmode($fh);
    my $contents = <$fh>;
    die("$file is wrong size\n") unless(length($contents) == $size);
    close($fh);
    return $contents;
}

# input: filename, required size
# output: file contents, or fatal error
sub _readRAM {
    my($self, $file, $size) = @_;
    my $contents = $self->_read_file($file, $size);
    $self->_writeRAM($file, $contents);
    return $contents;
}

# input: filename, data
# output: none, fatal on error
sub _writeRAM {
    my($self, $file, $contents) = @_;
    open(my $fh, '>', $file) || die("Can't write $file\n");
    binmode($fh);
    print $fh $contents || die("Can't write $file\n");
    close($fh);
}

=head1 SUBCLASSING

Most useful emulators will need a subclass of this module.  For an example,
look at the CPU::Emulator::Memory::Banked module bundled with it, which
adds some methods of its own, and overrides the peek and poke methods.
Note that {peek,poke}{8,16} are *not* overridden but still get all the
extra magic, as they are simple wrappers around the peek and poke methods.

You may use the _readRAM and _writeRAM methods for disk-backed RAM, and
_read_file may be useful for ROM.  These
are only useful for subclasses:

=over

=item _read_file

Takes a filename and the required size, returns the file's contents

=item _readRAM

Takes a filename and the required size, returns the file's contents and
checks that the file is writeable.

=item _writeRAM

Takes a filename and a chunk of data, writes the data to the file.

=back

=head1 BUGS/WARNINGS/LIMITATIONS

It is assumed that the emulated memory will fit in the host's memory.

When memory is disk-backed, the entire memory is written to disk on each
poke().

The size of a byte in the emulated memory is the same as that of a char
on the host machine.  Perl only runs on machines with 8 bit bytes.

Bug reports should be made on Github or by email.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism
and bug reports.  The best bug reports include files that I can add
to the test suite, which fail with the current code in CVS and will
pass once I've fixed the bug.

Feature requests are far more likely to get implemented if you submit
a patch yourself.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-CPU-Emulator-Memory.git>

=head1 THANKS TO

Paulo Custodio for finding and fixing some bugs on Win32, see RT 62375,
62379

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2008 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This module is free-as-in-speech software, and may be used,
distributed, and modified under the same terms as Perl itself.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
