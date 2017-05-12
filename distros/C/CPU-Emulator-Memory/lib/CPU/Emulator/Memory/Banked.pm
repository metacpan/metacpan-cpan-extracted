package CPU::Emulator::Memory::Banked;

use strict;
use warnings;

use base qw(CPU::Emulator::Memory);
use Scalar::Util qw(reftype);

use vars qw($VERSION);

$VERSION = '1.1002';

=head1 NAME

CPU::Emulator::Memory::Banked - banked memory for a CPU emulator

=head1 SYNOPSIS

    my $memory = CPU::Emulator::Memory::Banked->new();
    $memory->poke(0xBEEF, ord('s'));
    
    my $value = $memory->peek(0xBEEF); # 115 == ord('s')

    $memory->bank(
        address      => 0x8000,
        size         => 0x4000,
        type         => 'ROM',
        file         => '.../somerom.rom',
        writethrough => 1
    );

    my $value = $memory->peek(0xBEEF); # read from ROM instead
    $memory->poke(0xBEEF, 0);          # write to underlying RAM

=head1 DESCRIPTION

This class adds multiple memory banks to the flat memory space provided
by CPU::Emulator::Memory.  These
temporarily replace chunks of memory with other chunk, to
simulate bank-switching.  Those chunks can be of arbitrary size,
and can be either RAM, ROM, or 'dynamic', meaning that instead
of being just dumb storage, when you read or write them perl code
gets run.

=head1 METHODS

It inherits all the methods from CPU::Emulator::Memory, including the
constructor, and also implements ...

=head2 bank

This method performs a bank switch.  This changes your view of
the memory, mapping another block of memory in place of part of the
main RAM.  The main RAM's contents are preserved (although see
below for an exception).  It takes several named parameters, three
of which are compulsory:

=over

=item address

The base address at which to swap in the extra bank of memory.

=item size

The size of the bank to swap.  This means that you'll be swapping
addresses $base_address to $base_address + $size - 1.  
This defaults to the size of the given C<file>, if supplied.

=item type

Either 'ROM' (for read-only memory), or 'RAM' to swap in a block of
RAM.  Support will be added in the future for type 'dynamic' which
will let you run arbitrary perl code for reads and writes to/from
the memory.

=back

When you change memory banks, any banks already loaded which would
overlap are unloaded.

The following optional parameters are also supported:

=over

=item file

A file which backs the memory.  For ROM memory this is compulsory,
for RAM it is optional.

Note, however, that for RAM it must be a read/writeable *file* which
will be created if necessary, whereas
for ROM it must be a readable file or a readable *file handle*.  It is
envisioned that ROMs will often be initialised from data embedded in
your program.  You can turn a string into a filehandle using IO::Scalar -
there's an example of this in the tests.

=item writethrough

This is only meaningful for ROM.  If set, then any writes to the
addresses affected will be directed through to the underlying main
RAM.  Otherwise writes will be ignored.

=item function_read and function_write

Coderefs which will be called when 'dynamic' memory is read/written.
Both are compulsory for 'dynamic' memory.  They are called with a
reference to the memory object, the address being accessed, and
(for function_write) the byte to be written.  function_read should
return a byte.  function_write's return value is ignored.

=back

=cut

sub bank {
    my($self, %params) = @_;
    
    # init size from file
    if(
        !exists($params{size}) &&  # no size given
         exists($params{file}) &&  # but a file given
        !ref($params{file}) &&     # file is not filehandle
         -s $params{file}          # file exists and has size > 0
    ) {
        $params{size} = -s $params{file};
    }

    my($address, $size, $type) = @params{qw(address size type)};
    foreach (qw(address size type)) {
        die("bank: No $_ specified\n")
            if(!exists($params{$_}));
    }
    die("bank: address and size is out of range\n")
        if($address < 0 || $address + $size - 1 > $self->{size} - 1);

    my $contents ='';
    if($type eq 'ROM') {
        die("For ROM banks you need to specify a file\n")
            unless(exists($params{file}));
        $contents = $self->_readROM($params{file}, $size);
    } elsif($type eq 'RAM') {
        $contents = (exists($params{file}))
            ? $self->_readRAM($params{file}, $size)
            : chr(0) x $size;
    } elsif($type eq 'dynamic') {
        die("For dynamic banks you need to specify function_read and function_write\n")
            unless(exists($params{function_read}) && exists($params{function_write}));
    }
    foreach my $bank (@{$self->{overlays}}) {
        if(
            (      # does an older bank start in the middle of this one?
                $bank->{address} >= $address &&
                $bank->{address} < $address + $size
            ) || ( # does this start in the middle of an older bank?
                $address >=  $bank->{address} &&
                $address < $bank->{address} + $bank->{size}
            )
        ) { $self->unbank(address => $bank->{address}) }
    }
    push @{$self->{overlays}}, {
        address  => $address,
        size     => $size,
        type     => $type,
        (length($contents) ? (contents => $contents) : ()),
        (exists($params{file}) ? (file => $params{file}) : ()),
        (exists($params{writethrough}) ? (writethrough => $params{writethrough}) : ()),
        (exists($params{function_read}) ? (function_read => $params{function_read}) : ()),
        (exists($params{function_write}) ? (function_write => $params{function_write}) : ())
    };
}

=head2 unbank

This method unloads a bank of memory, making the main RAM visible
again at the affected addresses.  It takes a single named parameter
'address' to tell which bank to switch.

=cut

sub unbank {
    my($self, %params) = @_;
    die("unbank: No address specified\n") unless(exists($params{address}));
    $self->{overlays} = [
        grep { $_->{address} != $params{address} }
        @{$self->{overlays}}
    ];
}

=head2 peek

This is replaced by a version that is aware of memory banks but has the
same interface.  peek8
and peek16 are wrappers around it and so are unchanged.

=cut

sub peek {
    my($self, $addr) = @_;
    die("Address $addr out of range") if($addr< 0 || $addr > $self->{size} - 1);
    foreach my $bank (@{$self->{overlays}}) {
        if(
            $bank->{address} <= $addr &&
            $bank->{address} + $bank->{size} > $addr
        ) {
            if($bank->{type} eq 'dynamic') {
                return $bank->{function_read}->($self, $addr);
            } else {
                return ord(substr($bank->{contents}, $addr - $bank->{address}, 1));
            }
        }
    }
    return ord(substr($self->{contents}, $addr, 1));
}

=head2 poke

This method is replaced by a bank-aware version with the same interface.
poke8 and poke16 are wrappers around it and so are unchanged.

=cut

sub poke {
    my($self, $addr, $value) = @_;
    die("Value $value out of range") if($value < 0 || $value > 255);
    die("Address $addr out of range") if($addr< 0 || $addr > $self->{size} - 1);
    $value = chr($value);
    foreach my $bank (@{$self->{overlays}}) {
        if(
            $bank->{address} <= $addr &&
            $bank->{address} + $bank->{size} > $addr
        ) {
            if($bank->{type} eq 'RAM') {
                substr($bank->{contents}, $addr - $bank->{address}, 1) = $value;
                $self->_writeRAM($bank->{file}, $bank->{contents})
                    if(exists($bank->{file}));
                return 1;
            } elsif($bank->{type} eq 'ROM' && $bank->{writethrough}) {
                substr($self->{contents}, $addr, 1) = $value;
                $self->_writeRAM($self->{file}, $self->{contents})
                    if(exists($self->{file}));
                return 1;
            } elsif($bank->{type} eq 'ROM') {
                return 0;
            } elsif($bank->{type} eq 'dynamic') {
                return $bank->{function_write}->($self, $addr, ord($value));
            } else {
                die("Type ".$bank->{type}." NYI");
            }
        }
    }
    substr($self->{contents}, $addr, 1) = $value;
    $self->_writeRAM($self->{file}, $self->{contents})
        if(exists($self->{file}));
    return 1;
}

sub _readROM {
    my($self, $file, $size) = @_;
    if(!ref($file)) { return $self->_read_file($file, $size); }

    if(reftype($file) eq 'GLOB') {
        local $/ = undef;
        # Win32 is stupid, see RT 62379
        if (eval {$file->can('binmode')}) {
            $file->binmode; # IO::HANDLE
        } else {
            binmode $file;  # file handle
        }
        my $contents = <$file>;
        die("data in filehandle is wrong size (got ".length($contents).", expected $size)\n") unless(length($contents) == $size);
        return $contents;
    } else {
        die("file mustn't be a ".reftype($file)."-ref");
    }
}

=head1 SUBCLASSING

The private method _readROM may be useful for subclasses.  If passed
a filename, it is just a wrapper around the parent class's _read_file.
If passed a reference to a filehandle, it reads from that.

=head1 BUGS/WARNINGS/LIMITATIONS

All those inherited from the parent class.

No others known.

=head1 FEEDBACK

I welcome feedback about my code, including constructive criticism
and bug reports.  The best bug reports include files that I can add
to the test suite, which fail with the current code and will
pass once I've fixed the bug.

Feature requests are far more likely to get implemented if you submit
a patch yourself.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-CPU-Emulator-Memory.git>

=head1 AUTHOR, LICENCE and COPYRIGHT

Copyright 2008 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This module is free-as-in-speech software, and may be used,
distributed, and modified under the same terms as Perl itself.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
