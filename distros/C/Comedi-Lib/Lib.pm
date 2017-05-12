package Comedi::Lib;

use warnings;
use strict;

use Carp qw( croak );

require DynaLoader;

$Comedi::Lib::VERSION = '0.24';

DynaLoader::bootstrap Comedi::Lib $Comedi::Lib::VERSION;

sub dl_load_flags { 0 } # Prevent DynaLoader from complaining and croaking

=head1 NAME

Comedi::Lib - Perl API for Comedilib (C<NEW version>)

=head1 VERSION

Version 0.24

=cut

our $VERSION = '0.24';

=head1 SYNOPSIS

C<Comedi::Lib> provides a Perl wrapper around the C<Comedilib> library.
This supports Perl code controlling and accessing control and measurement
devices.

   use Comedi::Lib;

   # Create a Comedi::Lib object and open the Comedi device
   my $cref = Comedi::Lib->new(device => '/dev/comedi0', open_flag => 1);

   # Get the driver and board name of the device
   my $dname = $cref->get_driver_name();
   my $bname = $cref->get_board_name();
   ...
   ...
   ...
   # Close the Comedi device (optional)
   $cref->close();

=head1 DESCRIPTION

This module provides a Perl API for C<Comedilib>. C<Comedilib> is a
separately distributed package containing a user-space library that
provides a developer-friendly interface to the Comedi devices.
This module consists of the functions that the C<Comedilib> library
provides.

=head2 TODO

I don't use C<XS>, C<C::Scan> or something like that, to export constants
and macros to the callers name-space, as long as it's not clarified which
constants and macros used for C<Comedilib> and which for 'pure' Comedi
(driver development). Both the documentation and the source code couldn't
help me at all to resolve that problem.

=head2 NOTE

This module does _not_ support any C<ALPHA> constants, macros or functions.
This will be done by a separately module, anytime soon.

=head1 DEPENDENCIES

C<Comedi::Lib> is dependent on the C<Comedilib> library. Please download
and install the latest version at L<http://www.comedi.org/>.
The C<Comedilib> library _must_ be found in your C<library path> when using
this module. The library is defaultly installed in C</usr/local/lib> - in this
case, be sure that the C</usr/local/lib> path is in your C</etc/ld.so.conf>.

C<Comedi::Lib> also depends on the L<InlineX::C2XS>, L<define> and L<enum>
modules, as well as the L<Test::More>, L<POSIX> and L<Carp> core modules, and
the L<strict> and L<warnings> pragmas.

=head1 EXPORT

None, this is an object-oriented Perl module.

=head1 USAGE

=head2 CONSTANTS

This class provides a set of constants . The constants defined at this time are:

   # Comedi's major device number
   COMEDI_MAJOR

   # Maximum number of minor devices (this can be increased)
   COMEDI_NDEVICES
   
   # Number of config options in the config structure
   COMEDI_NDEVCONFOPTS

   # Length of nth chunk of firmware data
   COMEDI_DEVCONF_AUX_DATA3_LENGTH  
   COMEDI_DEVCONF_AUX_DATA2_LENGTH  
   COMEDI_DEVCONF_AUX_DATA1_LENGTH  
   COMEDI_DEVCONF_AUX_DATA0_LENGTH  
   COMEDI_DEVCONF_AUX_DATA_HI  
   COMEDI_DEVCONF_AUX_DATA_LO 
   COMEDI_DEVCONF_AUX_DATA_LENGTH

   # Max length of device and driver names
   COMEDI_NAMELEN

   # Packs and unpacks a channel/range number (see also macro section)
   CR_FLAGS_MASK
   CR_ALT_FILTER
   CR_DITHER
   CR_DEGLITCH
   CR_ALT_SOURCE
   CR_EDGE
   CR_INVERT

   # Analog ref
   AREF_GROUND
   AREF_COMMON
   AREF_DIFF
   AREF_OTHER

   # Counters
   GPCT_RESET
   GPCT_SET_SOURCE
   GPCT_SET_GATE
   GPCT_SET_DIRECTION
   GPCT_SET_OPERATION
   GPCT_ARM
   GPCT_DISARM
   GPCT_GET_INT_CLK_FRQ
   GPCT_INT_CLOCK
   GPCT_EXT_PIN
   GPCT_NO_GATE
   GPCT_UP
   GPCT_DOWN
   GPCT_HWUD
   GPCT_SIMPLE_EVENT
   GPCT_SINGLE_PERIOD
   GPCT_SINGLE_PW
   GPCT_CONT_PULSE_OUT
   GPCT_SINGLE_PULSE_OUT
   
   # Instructions
   INSN_MASK_WRITE
   INSN_MASK_READ
   INSN_MASK_SPECIAL

   INSN_READ
   INSN_WRITE
   INSN_BITS
   INSN_CONFIG
   INSN_GTOD
   INSN_WAIT
   INSN_INTTRIG

   # Trigger flags, used in comedi_trig structures
   TRIG_BOGUS
   TRIG_DITHER
   TRIG_DEGLITCH
   TRIG_CONFIG
   TRIG_WAKE_EOS
   
   # Command flags, used in comedi_cmd structures
   CMDF_PRIORITY
   TRIG_RT
   CMDF_WRITE
   TRIG_WRITE
   CMDF_RAWDATA

   COMEDI_EV_START
   COMEDI_EV_SCAN_BEGIN
   COMEDI_EV_CONVERT
   COMEDI_EV_SCAN_END
   COMEDI_EV_STOP
   TRIG_ROUND_MASK
   TRIG_ROUND_NEAREST
   TRIG_ROUND_DOWN
   TRIG_ROUND_UP
   TRIG_ROUND_UP_NEXT

   # Trigger sources
   TRIG_ANY
   TRIG_INVALID
   TRIG_NONE
   TRIG_NOW
   TRIG_FOLLOW
   TRIG_TIME
   TRIG_TIMER
   TRIG_COUNT
   TRIG_EXT
   TRIG_INT
   TRIG_OTHER

   # Subdevice flags
   SDF_BUSY
   SDF_BUSY_OWNER
   SDF_LOCKED
   SDF_LOCK_OWNER
   SDF_MAXDATA
   SDF_FLAGS
   SDF_RANGETYPE
   SDF_MODE0
   SDF_MODE1
   SDF_MODE2
   SDF_MODE3
   SDF_MODE4
   SDF_CMD
   SDF_SOFT_CALIBRATED
   SDF_CMD_WRITE
   SDF_CMD_READ
   SDF_READABLE
   SDF_WRITABLE
   SDF_WRITEABLE
   SDF_INTERNAL
   SDF_RT
   SDF_GROUND
   SDF_COMMON
   SDF_DIFF
   SDF_OTHER
   SDF_DITHER
   SDF_DEGLITCH
   SDF_MMAP
   SDF_RUNNING
   SDF_LSAMPL
   SDF_PACKED
   SDF_PWM_COUNTER
   SDF_PWM_HBRIDGE

   # Subdevice types
   COMEDI_SUBD_UNUSED
   COMEDI_SUBD_AI
   COMEDI_SUBD_AO
   COMEDI_SUBD_DI
   COMEDI_SUBD_DO
   COMEDI_SUBD_DIO
   COMEDI_SUBD_COUNTER
   COMEDI_SUBD_TIMER
   COMEDI_SUBD_MEMORY
   COMEDI_SUBD_CALIB
   COMEDI_SUBD_PROC
   COMEDI_SUBD_SERIAL
   COMEDI_SUBD_PWM

   # Configuration instructions
   INSN_CONFIG_DIO_INPUT
   INSN_CONFIG_DIO_OUTPUT
   INSN_CONFIG_DIO_OPENDRAIN
   INSN_CONFIG_ANALOG_TRIG
   INSN_CONFIG_ALT_SOURCE
   INSN_CONFIG_DIGITAL_TRIG
   INSN_CONFIG_BLOCK_SIZE
   INSN_CONFIG_TIMER_1
   INSN_CONFIG_FILTER
   INSN_CONFIG_CHANGE_NOTIFY

   COMEDI_INPUT
   COMEDI_OUTPUT
   COMEDI_OPENDRAIN

   COMEDI_UNKNOWN_SUPPORT
   COMEDI_SUPPORTED
   COMEDI_UNSUPPORTED

   # Range stuff (see also macro section)
   RF_EXTERNAL

   # Units
   UNIT_volt
   UNIT_mA
   UNIT_none

   COMEDI_MIN_SPEED

=cut

# Comedi's major device number
use define COMEDI_MAJOR => 98;

# Maximum number of minor devices (this can be increased)
use define COMEDI_NDEVICES => 16;

# Number of config options in the config structure
use define COMEDI_NDEVCONFOPTS => 32;

# Length of nth chunk of firmware data
use define COMEDI_DEVCONF_AUX_DATA3_LENGTH => 25;
use define COMEDI_DEVCONF_AUX_DATA2_LENGTH => 26;
use define COMEDI_DEVCONF_AUX_DATA1_LENGTH => 27;
use define COMEDI_DEVCONF_AUX_DATA0_LENGTH => 28;
use define COMEDI_DEVCONF_AUX_DATA_HI      => 29;
use define COMEDI_DEVCONF_AUX_DATA_LO      => 30;
use define COMEDI_DEVCONF_AUX_DATA_LENGTH  => 31;

# Max length of device and driver names
use define COMEDI_NAMELEN => 20;

# Packs and unpacks a channel/range number (see also macro section)
use define CR_FLAGS_MASK => 0xfc000000; # Required for CR_PACK_FLAGS
use define CR_ALT_FILTER => (1 << 26);
use define CR_DITHER     => CR_ALT_FILTER;
use define CR_DEGLITCH   => CR_ALT_FILTER;
use define CR_ALT_SOURCE => (1 << 27);
use define CR_EDGE       => (1 << 30);
use define CR_INVERT     => (1 << 31);

# Analog ref
use define AREF_GROUND => 0x00;
use define AREF_COMMON => 0x01;
use define AREF_DIFF   => 0x02;
use define AREF_OTHER  => 0x03;

# Counters - These are arbitrary values
use define GPCT_RESET            => 0x0001;
use define GPCT_SET_SOURCE       => 0x0002;
use define GPCT_SET_GATE         => 0x0004;
use define GPCT_SET_DIRECTION    => 0x0008;
use define GPCT_SET_OPERATION    => 0x0010;
use define GPCT_ARM              => 0x0020;
use define GPCT_DISARM           => 0x0040;
use define GPCT_GET_INT_CLK_FRQ  => 0x0080;
use define GPCT_INT_CLOCK        => 0x0001;
use define GPCT_EXT_PIN          => 0x0002;
use define GPCT_NO_GATE          => 0x0004;
use define GPCT_UP               => 0x0008;
use define GPCT_DOWN             => 0x0010;
use define GPCT_HWUD             => 0x0020;
use define GPCT_SIMPLE_EVENT     => 0x0040;
use define GPCT_SINGLE_PERIOD    => 0x0080;
use define GPCT_SINGLE_PW        => 0x0100;
use define GPCT_CONT_PULSE_OUT   => 0x0200;
use define GPCT_SINGLE_PULSE_OUT => 0x0400;

# Instructions
use define INSN_MASK_WRITE   => 0x8000000;
use define INSN_MASK_READ    => 0x4000000;
use define INSN_MASK_SPECIAL => 0x2000000;

use define INSN_READ    => (0 | INSN_MASK_READ);
use define INSN_WRITE   => (1 | INSN_MASK_WRITE);
use define INSN_BITS    => (2 | INSN_MASK_READ | INSN_MASK_WRITE);
use define INSN_CONFIG  => (3 | INSN_MASK_READ | INSN_MASK_WRITE);
use define INSN_GTOD    => (4 | INSN_MASK_READ | INSN_MASK_SPECIAL);
use define INSN_WAIT    => (5 | INSN_MASK_WRITE | INSN_MASK_SPECIAL);
use define INSN_INTTRIG => (6 | INSN_MASK_WRITE | INSN_MASK_SPECIAL);

# Trigger flags, used in comedi_trig structures
# FIXME: Do I need that? comedi_trig should be deprecated! (see docu)
# But in a few demo sources, TRIG_WAKE_EOS is commonly used.
use define TRIG_BOGUS    => 0x0001;
use define TRIG_DITHER   => 0x0002;
use define TRIG_DEGLITCH => 0x0004;
use define TRIG_CONFIG   => 0x0010;
use define TRIG_WAKE_EOS => 0x0020;

# Command flags, used in comedi_cmd structures
use define CMDF_PRIORITY => 0x00000008;
use define TRIG_RT       => CMDF_PRIORITY; # compatibility definition
use define CMDF_WRITE    => 0x00000040;
use define TRIG_WRITE    => CMDF_WRITE; # compatibility definition
use define CMDF_RAWDATA  => 0x00000080;

use define COMEDI_EV_START      => 0x00040000;
use define COMEDI_EV_SCAN_BEGIN => 0x00080000;
use define COMEDI_EV_CONVERT    => 0x00100000;
use define COMEDI_EV_SCAN_END   => 0x00200000;
use define COMEDI_EV_STOP       => 0x00400000;
use define TRIG_ROUND_MASK      => 0x00030000;
use define TRIG_ROUND_NEAREST   => 0x00000000;
use define TRIG_ROUND_DOWN      => 0x00010000;
use define TRIG_ROUND_UP        => 0x00020000;
use define TRIG_ROUND_UP_NEXT   => 0x00030000;

# Trigger sources
use define TRIG_ANY     => 0xffffffff;
use define TRIG_INVALID => 0x00000000;
use define TRIG_NONE    => 0x00000001;
use define TRIG_NOW     => 0x00000002;
use define TRIG_FOLLOW  => 0x00000004;
use define TRIG_TIME    => 0x00000008;
use define TRIG_TIMER   => 0x00000010;
use define TRIG_COUNT   => 0x00000020;
use define TRIG_EXT     => 0x00000040;
use define TRIG_INT     => 0x00000080;
use define TRIG_OTHER   => 0x00000100;

# Subdevice flags
use define SDF_BUSY            => 0x0001;
use define SDF_BUSY_OWNER      => 0x0002;
use define SDF_LOCKED          => 0x0004;
use define SDF_LOCK_OWNER      => 0x0008;
use define SDF_MAXDATA	       => 0x0010;
use define SDF_FLAGS	          => 0x0020;
use define SDF_RANGETYPE       => 0x0040;
use define SDF_MODE0           => 0x0080;
use define SDF_MODE1           => 0x0100;
use define SDF_MODE2           => 0x0200;
use define SDF_MODE3           => 0x0400;
use define SDF_MODE4           => 0x0800;
use define SDF_CMD             => 0x1000; # FIXME: DEPRECATED must be removed?
use define SDF_SOFT_CALIBRATED => 0x2000;
use define SDF_CMD_WRITE       => 0x4000;
use define SDF_CMD_READ        => 0x8000;
use define SDF_READABLE        => 0x00010000;
use define SDF_WRITABLE        => 0x00020000;
use define SDF_WRITEABLE       => SDF_WRITABLE;
use define SDF_INTERNAL        => 0x00040000;
use define SDF_RT              => 0x00080000; # FIXME: see above statement
use define SDF_GROUND          => 0x00100000;
use define SDF_COMMON          => 0x00200000;
use define SDF_DIFF            => 0x00400000;
use define SDF_OTHER           => 0x00800000;
use define SDF_DITHER          => 0x01000000;
use define SDF_DEGLITCH        => 0x02000000;
use define SDF_MMAP            => 0x04000000;
use define SDF_RUNNING         => 0x08000000;
use define SDF_LSAMPL          => 0x10000000;
use define SDF_PACKED          => 0x20000000;
use define SDF_PWM_COUNTER     => SDF_MODE0;
use define SDF_PWM_HBRIDGE     => SDF_MODE1;

# Subdevice types
use enum qw(
   COMEDI_SUBD_UNUSED
   COMEDI_SUBD_AI
   COMEDI_SUBD_AO
   COMEDI_SUBD_DI
   COMEDI_SUBD_DO
   COMEDI_SUBD_DIO
   COMEDI_SUBD_COUNTER
   COMEDI_SUBD_TIMER
   COMEDI_SUBD_MEMORY
   COMEDI_SUBD_CALIB
   COMEDI_SUBD_PROC
   COMEDI_SUBD_SERIAL
   COMEDI_SUBD_PWM
);

# Configuration instructions
use enum qw(
   INSN_CONFIG_DIO_INPUT=0
   INSN_CONFIG_DIO_OUTPUT=1
   INSN_CONFIG_DIO_OPENDRAIN=2
   INSN_CONFIG_ANALOG_TRIG=16
   INSN_CONFIG_ALT_SOURCE=20
   INSN_CONFIG_DIGITAL_TRIG=21
   INSN_CONFIG_BLOCK_SIZE=22
   INSN_CONFIG_TIMER_1=23
   INSN_CONFIG_FILTER=24
   INSN_CONFIG_CHANGE_NOTIFY=25
);

use enum qw(
   COMEDI_INPUT
   COMEDI_OUTPUT
   COMEDI_OPENDRAIN
);

use enum qw(
   COMEDI_UNKNOWN_SUPPORT
   COMEDI_SUPPORTED
   COMEDI_UNSUPPORTED
);

# Range stuff (see also macro section)
use define RF_EXTERNAL => (1 << 8);

use define UNIT_volt => 0;
use define UNIT_mA   => 1;
use define UNIT_none => 2;

use define COMEDI_MIN_SPEED => 0xffffffff;

=head2 MACROS

This class provides also a set of (C<pseudo>-)macros (implemented as a
method). The macros defined at this time are:

   # Packs and unpacks a channel/range number
   CR_PACK($chan, $rng, $aref)
   CR_PACK_FLAGS($chan, $rng, $aref, $flags)
   
   # Intended only for driver development work?
   CR_CHAN($a)
   CR_RANGE($a)
   CR_AREF($a)

   # Range stuff   
   # Intended only for driver development work?
   RANGE_OFFSET($a)
   RANGE_LENGTH($a)
   
   # Intended only for driver development work?
   RF_UNIT($flags)   

Example code,
   
   my $chanspec = $cref->CR_PACK($chan, $rng, $aref);

=cut

sub CR_PACK {
   my $self = shift;
   my $chan = shift;
   my $rng  = shift;
   my $aref = shift;

   return (((($aref) & 0x3) << 24) |
           ((($rng) & 0xff) << 16) |
             ($chan));
}

sub CR_PACK_FLAGS {
   my $self  = shift;
   my $chan  = shift;
   my $rng   = shift;
   my $aref  = shift;
   my $flags = shift;

   return (CR_PACK($chan, $rng, $aref) |
          (($flags) & CR_FLAGS_MASK));
}

sub CR_CHAN      {   (($_[0])        & 0xffff) }
sub CR_RANGE     {  ((($_[0]) >> 16) & 0xff00) }
sub CR_AREF      {  ((($_[0]) >> 24) & 0x0300) }
sub RANGE_OFFSET {  ((($_[0]) >> 16) & 0xffff) }
sub RANGE_LENGTH {   (($_[0])        & 0xffff) }
sub RF_UNIT      {   (($_[0])        & 0xff00) }

=head2 FUNCTIONS

=over 4

=item DESTROY

Close the Comedi device connected to the object.

=cut

sub DESTROY {
   my $self = shift;
   lib_close($self->{handle}) if $self->{handle};
}

# Make certain the device is open.
sub _assert_open {
   my $self = shift;

   unless ($self->{handle}) {
      croak __PACKAGE__, "::_assert_open(): Couldn't open the Comedi device"
         unless defined $self->open();
   }
}

=item new

Create a new C<Comedi::Lib> object for accessing the library.

Example code,

   my $cref = Comedi::Lib->new(device => '/dev/comedi0', open_flag => 1);

=cut

sub new {
   my ($class, %arg) = @_;
   my $self  = { };

   bless($self, $class);

   $self->{device} = $arg{device};
   $self->{open_flag} = $arg{open_flag};
   
   croak "Missing 'device' arg inside new constructor"
      unless exists $self->{device};

   croak "Missing 'open_flag' arg inside new constructor"
      unless exists $self->{open_flag};

   if ($self->{open_flag}) {
      croak __PACKAGE__, "::new(): Couldn't open the Comedi device"
         unless defined $self->open();
   }   

   return $self;
}

=item close

Close a Comedi device.

Example code,

   my $retval = $cref->close();
     
   if ($retval != 0) {
      croak "Couldn't close the Comedi device";
   }
   
If successful, C<close()> returns 0. On failure, -1 is returned.

=cut

sub close { ## no critic <Prohibit Builtin Homonyms>
   my $self = shift;
   my $ret  = -1;
   return 0 unless $self->{handle};
   $ret = lib_close($self->{handle});
   $self->{handle} = undef;
   return $ret;
}

=item open

Trigger an explicit C<open()> call to open the Comedi device. If the device
is already open, close and reopen it.

You _need_ to be root to open a Comedi device. C<Comedi::Lib> checks that.

Example code,

   # Create a new object (don't open the device yet).
   my $cref = Comedi::Lib->new(device => "/dev/comedi1", open_flag => 0);
   ...
   ...
   ...
   # Now open the Comedi device
   $cref->open();

If successful, C<open()> returns defined. On failure, undef is returned.

=cut

sub open { ## no critic <Prohibit Builtin Homonyms>
   require POSIX;
   my $self = shift;
   
   # Don't terminate the process. It isn't our job!
   print STDERR "You need to be root to open the Comedi device\n"
      unless POSIX::getuid() == 0;
   
   $self->close();  
   $self->{handle} = lib_open($self->{device});

   return undef unless $self->{handle};

   return defined;
}

=item loglevel

Change C<Comedilib> logging properties.

The default loglevel can be set by using the environment variable
C<COMEDILIB_LOGLEVEL>. The default loglevel is 1.

The meaning of the loglevels is as follows:

=over 4

=item COMEDI_LOGLEVEL = 0

-- C<Comedilib> prints nothing.

=item COMEDI_LOGLEVEL = 1

-- C<Comedilib> prints error messages when there is a self-consistency
error. (i.e., an internal bug)

=item COMEDI_LOGLEVEL = 2

-- C<Comedilib> prints an error message when an invalid parameter is
passed.

=item COMEDI_LOGLEVEL = 3

-- C<Comedilib> prints an error message whenever an error is generated
in the C<Comedilib> library or in the C<C> library, when called by
C<Comedilib>.

=item COMEDI_LOGLEVEL = 4

-- C<Comedilib> prints a lot of junk.

=back

Example code,

   my $previous_loglevel = $cref->loglevel($new_loglevel);
   print "Changed loglevel from $previous_loglevel to $new_loglevel\n";

This class method returns the previous loglevel.

Note: C<Comedilib> evaluates the C<COMEDILIB_LOGLEVEL> environment variable
during C<open()> is called. The C<Comedi::Lib> implementation of this
function allows you to set the above variable once the Comedi device is
already opened.

=cut

sub loglevel {
   my $self  = shift;
   my $level = shift;

   $level = $ENV{COMEDILIB_LOGLEVEL}
      unless defined $level;

   # Comedilib doesn't support error handling for this
   # function, so I'll implement that to let the user
   # know if anything goes wrong.
   croak "Loglevel must be a non-negative integer"
      unless $level =~ /^\d+$/;

   croak "Loglevel must lie between 0 and 4."
      unless $level < 4;

   return lib_loglevel($level);
}

=item perror

Print a C<Comedilib> error message. 

Example code,

   unless ($cref->open()) {
      $cref->perror($device);
      croak "Terminating...";
   }

The class method C<perror()> prints an error message to C<stderr>. The error
message consists of the argument string, a colon, a space, a description
of the error condition, and a new line.

=cut

sub perror {
   my $self = shift;
   my $str  = shift;
   lib_perror($str);
}

=item strerror

Return string describing C<Comedilib> error code.

Example code,

   unless ($cref->open()) {
      my $errnum = $cref->errno();
      my $errmsg = $cref->strerror($errnum);
      croak "An error has occurred - $errmsg";
   }

The class method C<strerror()> returns a character string describing the
C<Comedilib> error errnum. An unrecognized error number will return a
string "undefined error", or similar.

=cut

sub strerror {
   my $self   = shift;
   my $errnum = shift;
   return lib_strerror($errnum);
}

=item errno

Number of the last C<Comedilib> error. This error number can be converted
to a human-readable form by the methods C<perror()> and C<strerror()>.

Example code,

   # See strerror()

The C<errno()> class method returns an integer describing the most recent
C<Comedilib> error. This integer my be used as the errnum argument for
C<strerror()>.

=cut

sub errno {
   my $self = shift;
   return lib_errno();
}

=item fileno

Integer descriptor of the Comedi device.

   my $fileno = $cref->fileno();
   print "File # of Comedi device - $fileno\n";

If successful, C<fileno()> returns a file descriptor, or -1 on error.

=cut

sub fileno {
   my $self = shift;
   $self->_assert_open();
   return lib_fileno($self->{handle});
}

=item get_n_subdevices

Number of subdevices

Example code,

   my $n_subdevices = $cref->get_n_subdevices();
   print "# of subdevices - $n_subdevices\n";

The class method C<get_n_subdevices()> returns the number of subdevices
belonging to the Comedi device previously opened during the Object
creation or explicitly by an C<open()> call.

=cut

sub get_n_subdevices {
   my $self = shift;
   $self->_assert_open();
   return lib_get_n_subdevices($self->{handle});
}

=item get_version_code

Comedi version code.

Example code,

   my @version_code = $cref->get_version_code();
   printf("Comedi version code - %d.%d.%d\n", @version_code);

Returns the Comedi kernel module version code, or -1 on error.

=cut

sub get_version_code {
   my $self = shift;
   $self->_assert_open();
   
   my $code = lib_get_version_code($self->{handle});
   return $code if $code == -1;

   return wantarray ? ((($code & 0xff0000) >> 16,
                        ($code & 0x00ff00) >>  8,
                        ($code & 0x0000ff))) : $code;
}

=item get_driver_name

Comedi driver name.

Example code,

   my $driver_name = $cref->get_driver_name();
   print "Comedi driver name - $driver_name\n";

Returns a character string containing the name of the driver. This
class method returns undef if there is an error.

=cut

sub get_driver_name {
   my $self = shift;
   $self->_assert_open();
   return lib_get_driver_name($self->{handle});
}

=item get_board_name

Comedi device name.

Example code,

   my $board_name = $cref->get_board_name();
   print "Comedi board/device name - $board_name\n";

Returns a character string containing the name of the device. This
class method returns undef if there is an error.

=cut

sub get_board_name {
   my $self = shift;
   $self->_assert_open();
   return lib_get_board_name($self->{handle});
}

=item get_subdevice_type

Type of subdevice.

Example code,

   my $subdev_type = $cref->get_subdevice_type($subdev);
   
   if ($subdev_type == Comedi::Lib::COMEDI_SUBD_AI) {
      print "We've an analog input subdevice\n";
   }

This class method returns the subdevice type, or -1 if there is an error.

=cut

sub get_subdevice_type {
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_get_subdevice_type($self->{handle}, $subdev);
}

=item find_subdevice_by_type

Search for subdevice type.

Example code,

   my $idx = $cref->find_sundevice_by_type(Comedi::Lib::COMEDI_SUBD_DO, 0);
   croak "No digital output subdevice found\n" if $idx == -1;
   
   print "Found digital output subdevice at index - $idx\n";

If it finds a subdevice with the requested type, C<find_subdevice_by_type()>
returns its index. If there is an error, the method returns -1 and sets the
appropriate error.

=cut

sub find_subdevice_by_type {
   my $self  = shift;
   my $type  = shift;
   my $start = shift;
   $self->_assert_open();
   return lib_find_subdevice_by_type($self->{handle}, $type, $start);
}

=item get_read_subdevice

Find streaming input subdevice.

Example code,

   my $streaming_input_support = $cref->get_read_subdevice();

   if ($streaming_input_support == -1) {
      print "No streaming input support available\n";
   }
   else {
      print "Comedi subdevice no. $streaming_input_support ",
            "allows streaming input\n";
   }

This class method returns the subdevice whose streaming input buffer is
accessible through the previous opened device. If there is no such subdevice,
-1 is returned.

=cut

sub get_read_subdevice {
   my $self = shift;
   $self->_assert_open();
   return lib_get_read_subdevice($self->{handle});
}

=item get_write_subdevice

Find streaming output subdevice.

Example code,

   my $streaming_output_support = $cref->get_write_subdevice();

   if ($streaming_output_support == -1) {
      print "No streaming output support available\n";
   }
   else {
      print "Comedi subdevice no. $streaming_output_support ",
            "allows streaming output\n";
   }

This class method returns the subdevice whose streaming output buffer is
accessible through the previous opened device. If there is no such subdevice,
-1 is returned.

=cut

sub get_write_subdevice {
   my $self = shift;
   $self->_assert_open();
   return lib_get_write_subdevice($self->{handle});
}

=item get_subdevice_flags

Properties of subdevice.

Example code,

   my $subdev_flags = $cref->get_subdevice_flags($subdev);

   if ($subdev_flags & Comedi::Lib::SDF_READABLE) {
      print "The subdevice can be read\n";
   }
   else {
      print "The subdevice can't be read\n";
   }

   if ($subdev_flags & Comedi::Lib::SDF_WRITEABLE) {
      print "The subdevice can be written\n";
   }
   else {
      print "The subdevice can't be written\n";
   }

This method returns a bitfield describing the capabilities of the specified
subdevice. If there is an error, -1 is returned, and the C<Comedilib> error
value is set.

=cut

sub get_subdevice_flags {
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_get_subdevice_flags($self->{handle}, $subdev);
}

=item get_n_channels

Number of subdevice channels.

Example code,

   my $n_channels = $cref->get_n_channels($subdev);
   print "Analog input no. of channels - $n_channels\n";

Returns the number of channels of the subdevice with the index subdev. This
method returns -1 on error.

=cut

sub get_n_channels {
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_get_n_channels($self->{handle}, $subdev);
}

=item range_is_chan_specific

Range information depends on channel.

Example code,

   my $retval = $cref->range_is_chan_specific($subdev);
   croak "An error has occurred" if $retval == -1;

   unless($retval) {
      print "The channels of the subdevice hasn't different ",
            "range information\n";
   }
   else {
      print "Each channel of the subdevice has different ",
            "range information\n";
   }

If each channel of the specified subdevice has different range information,
this method returns 1. Otherwise, this method returns 0. If there is an error,
-1 is returned.

=cut

sub range_is_chan_specific {
   my $self   = shift;
   my $subdev = shift;
   return lib_range_is_chan_specific($self->{handle}, $subdev);
}

=item maxdata_is_chan_specific

Maximum sample depends on channnel.

Example code,

   my $retval = $cref->maxdata_is_chan_specific($subdev);
   croak "An error has occurred" if $retval == -1;

   unless($retval) {
      print "The channels of the subdevice hasn't different ",
            "maximum sample values\n";
   }
   else {
      print "Each channel of the subdevice has different ",
            "maximum sample values\n";
   }
   
If each channel of the specified subdevice has different maximum sample
values, this method returns 1. Otherwise, this method returns 0. If there
is an error, -1 is returned.

=cut

sub maxdata_is_chan_specific {
   my $self   = shift;
   my $subdev = shift;
   return lib_maxdata_is_chan_specific($self->{handle}, $subdev);
}

=item get_maxdata

Maximum sample of channel.

Example code,

   # Read maxdata of analog input channel $chan
   my $maxdata = $cref->get_maxdata($subdev, $chan);
   croak "An error has occurred" unless $maxdata;

   print "Maximum data value for analog input channel $chan - $maxdata\n";

Returns the maximum valid sample value, or 0 on error.

=cut

sub get_maxdata {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   $self->_assert_open();
   return lib_get_maxdata($self->{handle}, $subdev, $chan);
}

=item get_n_ranges

Number of ranges of channel.

Example code,

   # Read number of ranges for analog input channel $chan
   my $n_ranges = $cref->get_n_ranges($subdev, $chan);

   if ($n_ranges == -1) {
      croak "An error has occurred";
   }

   print "Number of ranges for analog input channel $chan - $n_ranges\n";

Returns the number of ranges of the subdevice with the index subdev and
the chan channel. This method returns -1 on error.

=cut

sub get_n_ranges {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   $self->_assert_open();
   return lib_get_n_ranges($self->{handle}, $subdev, $chan);
}

=item get_range

Range information of channel.

Example code,

   # Read the range specification of the analog input channel $chan
   my $range = $cref->get_range($subdev, $chan, $rng);
   croak "Cannot read range specification" unless defined $range->{min};

   # Print the minimal sample value of the given analog input channel
   print "Analog input channel $chan min sample value - $range->{min}\n";
   
The class method C<get_range()> returns a hash reference that contains
information that can be used to convert sample values to or from physical
units. If there is an error, undef is returned.

=cut

sub get_range {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $rng    = shift;
   $self->_assert_open();
   return lib_get_range($self->{handle}, $subdev, $chan, $rng); 
}

=item find_range

Search for range.

Example code,

   my $rng_idx = $cref->find_range($subdev, $chan, $unit, $min, $max);
   
   if ($rng_idx == -1) {
      print "No matching range available\n"
   }
   else {
      print "Found a matching range for channel $chan at index $rng_idx\n";
   }

If a matching range is found, the index of the matching range is returned.
If no matching range is available, the class method returns -1.

=cut

sub find_range {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $unit   = shift;
   my $min    = shift;
   my $max    = shift;
   $self->_assert_open();
   return lib_find_range($self->{handle}, $subdev, $chan, $unit, $min, $max);
}

=item get_buffer_size

Streaming buffer size of subdevice.

Example code,

   my $buf_size = $cref->get_buffer_size($subdev);
   croak "An error has occurred" if $buf_size == -1;

   print "Streaming buffer size for the subdevice - $buf_size Bytes\n";
    
This class method returns the size -in Bytes- of the streaming buffer for the
specified subdevice. On error, -1 is returned.

=cut

sub get_buffer_size {
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_get_buffer_size($self->{handle}, $subdev);
}

=item get_max_buffer_size

Maximum streaming buffer size.

Example code,

   my $max_size = $cref->get_max_buffer_size($subdev);
   croak "An error has occurred" if $max_size == -1;

   print "Max. streaming buffer size for the subdevice - $max_size Bytes\n";

This class method returns the maximum allowable size -in Bytes- of the
streaming buffer for the specified subdevice. On error, -1 is returned.

=cut

sub get_max_buffer_size {
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_get_max_buffer_size($self->{handle}, $subdev);
}

=item set_buffer_size

Streaming buffer size of subdevice.

Example code,

   # First, determine the virtual memory page size (look at the Comedi docu)
   require POSIX;

   my $vmps = POSIX::sysconf(&POSIX::_SC_PAGESIZE);
   $vmps   *= 2;

   print "Trying to set the streaming buffer size to $vmps\n";

   if ($cref->set_buffer_size($subdev, $vmps) == -1) {
      print "Warning: Couldn't set new streaming buffer size\n";
   }

The C<set_buffer_size()> class method returns the new buffer size in Bytes.
On error, -1 is returned.

=cut

sub set_buffer_size {
   my $self   = shift;
   my $subdev = shift;
   my $size   = shift;
   $self->_assert_open();
   return lib_set_buffer_size($self->{handle}, $subdev, $size);
}

=item do_insnlist

Perform multible instructions.

Example code,

   my @insn_arr = ({
      insn      => Comedi::Lib::INSN_READ,
      n         => 2,
      data      => [0, 0],
      subdev    => 0,
      chanspec  => $cref->CR_PACK($chan, $rng, $aref)
   }, {
      insn      => Comedi::Lib::INSN_WRITE,
      n         => 1,
      data      => [255],
      subdev    => 1,
      chanspec  => $cref->CR_PACK($chan, $rng, $aref)
   });

   # Now, create a comedi_insnlist like hash reference
   my $comedi_insnlist = {
      n_insns => 2,
      insns   => [@insn_arr]
   };

   my $retval = $cref->do_insnlist($comedi_insnlist);
   croak "An error has occurred" if $retval == -1;

   print "[<1>] data (AI) - ", $insn_arr[0]->{data}[0], "\n";
   print "[<2>] data (AI) - ", $insn_arr[0]->{data}[1], "\n";

This class method returns the number of successfully completed instructions.
If there is an error before the first instruction can be executed, -1 is
returned.   

=cut

sub do_insnlist {
   my $self     = shift;
   my $insnlist = shift;
   $self->_assert_open();
   return lib_do_insnlist($self->{handle}, $insnlist);
}

=item do_insn

Perform an instruction.

Example code,

   # First, create a comedi_insn like hash reference
   my $comedi_insn = {
      insn     => Comedi::Lib::INSN_READ,
      n        => 2,
      data     => [0, 0], 
      subdev   => 0,
      chanspec => $cref->CR_PACK($chan, $rng, $aref)
   };

   my $retval = $cref->do_insn($comedi_insn);
   croak "An error has occured" if $retval == -1;

   print "[<1>] data (AI) - ", $comedi_insn->{data}[0], "\n";
   print "[<2>] data (AI) - ", $comedi_insn->{data}[1], "\n";

This class method returns the number of samples measured, which may be less
than the number of requested samples. If there is an error before the first
instruction can be executed, -1 is returned.

=cut

sub do_insn {
   my $self = shift;
   my $insn = shift;
   $self->_assert_open();
   return lib_do_insn($self->{handle}, $insn);
}

=item lock

Subdevice reservation.

Example code,

   my $retval = $cref->lock($subdev);
   croak "An error has occurred" if $retval == -1;

If successful, C<lock()> returns 0. If there is an error, -1 is returned.

=cut

sub lock {
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_lock($self->{handle}, $subdev);
}

=item unlock

Subdevice reservation.

Example code,

   my $retval = $cref->unlock($subdev);
   croak "An error has occurred" if $retval == -1;
   
If successful, C<unlock()> returns 0. If there is an error, -1 is returned.

=cut

sub unlock {
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_unlock($self->{handle}, $subdev);
}

=item data_read

Read single sample from channel.

Example code,

   my $retval = $cref->data_read($subdev, $chan, $rng, $aref, \$data);
   croak "An error hash occurred" if $retval == -1;

   print "Have read a single sample value of $data\n";

On success, C<data_read()> returns 1 (the number of samples read). If there
is an error, -1 is returned.

=cut

sub data_read {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $rng    = shift;
   my $aref   = shift;
   my $data   = shift;
   $self->_assert_open();
   return lib_data_read($self->{handle}, $subdev, $chan, $rng, $aref, $data);
}

=item data_read_delayed

Read single sample from channel after delaying for specified time.

Example code,

   my $ret = $cref->data_read_delayed($subd, $chan, $rng, $aref, \$data, $ns);
   croak "An error hash occurred" if $retval == -1;

   print "Have read a single sample value of $data\n";

The return value of this class method is identical to the C<data_read()>
function.

=cut

sub data_read_delayed {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $rng    = shift;
   my $aref   = shift;
   my $data   = shift;
   my $ns     = shift;
   $self->_assert_open();
   return lib_data_read_delayed($self->{handle}, $subdev, $chan, $rng, $aref,
                                $data, $ns);
}

=item data_read_hint

Tell driver which channel/range/aref you're going to read from next.

Example code

   my $retval = $cref->data_read_hint($subdev, $chan, $rng, $aref);
   croak "An error hash occurred" if $retval == -1;

The return value of this class method is identical to the C<data_read()>
function.

=cut

sub data_read_hint {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $rng    = shift;
   my $aref   = shift;
   $self->_assert_open();
   return lib_data_read_hint($self->{handle}, $subdev, $chan, $rng, $aref);
}

=item data_write

Write single sample to channel.

Example code,

   my $retval = $cref->data_write($subdev, $chan, $rng, $aref, $data);
   croak "An error hash occurred" if $retval == -1;
   
On success, C<data_write()> returns 1 (the number of samples read). If there
is an error, -1 is returned.

=cut

sub data_write {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $rng    = shift;
   my $aref   = shift;
   my $data   = shift;
   $self->_assert_open();
   return lib_data_write($self->{handle}, $subdev, $chan, $rng, $aref, $data);
}

=item dio_config

Change input/output properties of channel.

Example code,

   # For input
   my $retval = $cref->dio_config($subdev, $chan, Comedi::Lib::COMEDI_INPUT);
   croak "An error hash occurred" if $retval == -1;

   # For output
   my $retval = $cref->dio_config($subdev, $chan, Comedi::Lib::COMEDI_INPUT);
   croak "An error hash occurred" if $retval == -1;
   
If successful, 1 is returned, otherwise -1.

=cut

sub dio_config {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $dir    = shift;
   $self->_assert_open();
   return lib_dio_config($self->{handle}, $subdev, $chan, $dir);
}

=item dio_get_config

Query input/output properties of channel.

Example code,

   my $retval = $cref->dio_get_config($subdev, $chan, \$dir);
   croak "An error hash occurred" if $retval == -1;

   if ($dir == Comedi::Lib::COMEDI_INPUT) {
      print "Input direction\n";
   }
   else { # Comedi::Lib::COMEDI_OUTPUT
      print "Output direction\n";
   }

If successful, 0 is returned, otherwise -1.

=cut

sub dio_get_config {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $dir    = shift;
   $self->_assert_open();
   return lib_dio_get_config($self->{handle}, $subdev, $chan, $dir);
}

=item dio_read

Read single bit from digital channel.

Example code,

   my $retval = $cref->data_read($subdev, $chan, \$bit);
   croak "An error has occurred" if $retval == -1;
   
   print "Have read a data value of $bit\n";

Return values and errors are the same as C<data_read()>.

=cut

sub dio_read {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $bit    = shift;
   $self->_assert_open();
   return lib_dio_read($self->{handle}, $subdev, $chan, $bit);
}

=item dio_write

Write single bit to digital channel.

Example code,

   my $retval = $cref->data_write($subdev, $chan, $bit);
   croak "An error has occurred" if $retval == -1;

Return values and errors are the same as C<data_write()>.

=cut

sub dio_write {
   my $self   = shift;
   my $subdev = shift;
   my $chan   = shift;
   my $bit    = shift;
   $self->_assert_open();
   return lib_dio_write($self->{handle}, $subdev, $chan, $bit);
}

=item dio_bitfield2

Read/Write multible digital channels.

Example code,

   my $retval = $cref->dio_bitfield2($subdev, $write_mask, \$bits, $base_ch);
   croak "An error has occurred" if $retval == -1;

   # Evaluate the $bits variable...

If successful, C<dio_bitfield2()> returns 0. If there is an error, -1 is
returned.

=cut

sub dio_bitfield2 {
   my $self       = shift;
   my $subdev     = shift;
   my $write_mask = shift;
   my $bits       = shift;
   my $base_ch    = shift;
   $self->_assert_open();
   return lib_dio_bitfield2($self->{handle}, $subdev, $write_mask, $bits,
                           $base_ch);
}

=item get_cmd_src_mask

Streaming input/output capabilities.

Note that this subroutine has no functionality as long as I have no testing
device with the associated driver.

Patches or suggestions are welcome, send me an email (Subject: Comedi::Lib).

=cut

sub get_cmd_src_mask {
   print STDERR __PACKAGE__, '::',
         "get_cmd_src_mask: Sorry, I've no functionality at this time!\n";
   return;
}

=item get_cmd_generic_timed

Streaming input/output capabilities.

Note that this subroutine has no functionality as long as I have no testing
device with the associated driver.

Patches or suggestions are welcome, send me an email (Subject: Comedi::Lib).

=cut

sub get_cmd_generic_timed {
   print STDERR __PACKAGE__, '::',
         "get_cmd_generic_timed: Sorry, I've no functionality at this time\n";
   return;
}

=item cancel

Stop streaming input/output in progress.

Example code,

   # This class method is useful in combination with command()
   # and this class method is not completely implemented yet.

If successful, C<cancel()> returns 0, otherwise -1.

=cut

sub cancel {
   print STDERR __PACKAGE__, '::',
         "cancel: U use me at your own _risk_\n";
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_cancel($self->{handle}, $subdev);
}

=item command

Start streaming input/output.

Note that this subroutine has no functionality as long as I have no testing
device with the associated driver.

Patches or suggestions are welcome, send me an email (Subject: Comedi::Lib).

=cut

sub command {
   print STDERR __PACKAGE__, '::',
         "command: Sorry, I've no functionality at this time\n";
   return;
}

=item command_test

Test streaming input/output configuration.

Note that this subroutine has no functionality as long as I have no testing
device with the associated driver.

Patches or suggestions are welcome, send me an email (Subject: Comedi::Lib).

=cut

sub command_test {
   print STDERR __PACKAGE__, '::',
         "command: Sorry, I've no functionality at this time\n";
   return;
}

=item poll

Force updating of streaming buffer.

Example code,

   my $retval = $cref->poll($subdev);
   croak "An error has occurred" if $retval == -1;

If successful, this class method returns the number of additional bytes
available. If there is an error, -1 is returned.

=cut

sub poll {
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_poll($self->{handle}, $subdev);
}

=item set_max_buffer_size

Streaming buffer size of subdevice.

Example code,

   my $old_buf_size = $cref->set_max_buffer_size($subdev, $max_size);
   
   if ($old_buf_size == -1) {
      croak "An error has occurred";
   }
   else {
      print "Buffer size changed from $old_buf_size to $max_size.\n";
   }

If successful, the old buffer size is returned. On error, -1 is returned.

=cut

sub set_max_buffer_size {
   my $self     = shift;
   my $subdev   = shift;
   my $max_size = shift;
   $self->_assert_open();
   return lib_set_max_buffer_size($self->{handle}, $subdev, $max_size);
}

=item get_buffer_contents

Streaming buffer status.

Example code,

   # This class method is useful in combination with command()
   # and this class method is not completely implemented yet.
   
This class method returns the number of bytes that are available in the
streaming buffer. If there is an error, -1 is returned.

=cut

sub get_buffer_contents {
   print STDERR __PACKAGE__, '::',
         "get_buffer_contents: U use me at your own _risk_\n";
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_get_buffer_contents($self->{handle}, $subdev);
}

=item mark_buffer_read

Streaming buffer control.

Example code,

   # This class method is useful in combination with command()
   # and this class method is not completely implemented yet.

The C<mark_buffer_read()> class method returns the number of bytes
successfully marked as read, or -1 on error.

=cut

sub mark_buffer_read {
   print STDERR __PACKAGE__, '::',
         "mark_buffer_read: U use me at your own _risk_\n";
   my $self      = shift;
   my $subdev    = shift;
   my $num_bytes = shift;
   $self->_assert_open();
   return lib_mark_buffer_read($self->{handle}, $subdev, $num_bytes);
}

=item mark_buffer_written

Streaming buffer control.

Example code,

   # This class method is useful in combination with command()
   # and this class method is not completely implemented yet.

The C<mark_buffer_written()> class method returns the number of bytes
successfully marked as written, or -1 on error.

=cut

sub mark_buffer_written {
   print STDERR __PACKAGE__, '::',
         "mark_buffer_written: U use me at your own _risk_\n";
   my $self      = shift;
   my $subdev    = shift;
   my $num_bytes = shift;
   $self->_assert_open();
   return lib_mark_buffer_written($self->{handle}, $subdev, $num_bytes);
}

=item get_buffer_offset

Streaming buffer status.

Example code,

   # This class method is useful in combination with command()
   # and this class method is not completely implemented yet.

This class method returns the offset in bytes of the read pointer in the
streaming buffer. If there is an error, -1 is returned.

=cut

sub get_buffer_offset {
   print STDERR __PACKAGE__, '::',
         "get_buffer_offset: U use me at your own _risk_\n";
   my $self   = shift;
   my $subdev = shift;
   $self->_assert_open();
   return lib_get_buffer_offset($self->{handle}, $subdev);
}

=back

=head1 AUTHOR

Manuel Gebele <forensixs[at]gmx.de>

=head1 SEE ALSO

The linux control and measurement device interface project at
L<http://www.comedi.org>.

=head1 SUPPORT & DOCUMENTATION

After installing, you can find documentation for this module with the perldoc command

   perldoc Comedi::Lib

or use the man command

   man Comedi::Lib

You can also look for information at:

   Search CPAN
      http://search.cpan.org/dist/Comedi-Lib

   CPAN Request Tracker
      http://rt.cpan.org/NoAuth/Bugs.html?Dist=Comedi-Lib

   AnnoCPAN, annotated CPAN documentation
      http://annocpan.org/dist/Comedi-Lib

   CPAN Ratings
      http://cpanratings.perl.org/d/Comedi-Lib

   Comedi
      http://www.comedi.org

=head1 BUGS

Please report any bugs or feature request to my email address, or through the
web interface at http://rt.cpan.org/Public/Bug/Report.html?Queue=Comedi::Lib.
I'll be notified, and then you'll automatically be notified of progess on your
bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2009 Manuel Gebele

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # End of Comedi::Lib
