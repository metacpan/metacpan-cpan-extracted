#---------------------------------------------------------------------
package AppleII::ProDOS;
#
# Copyright 1996-2006 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 26 Jul 1996
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Access files on Apple II ProDOS disk images
#---------------------------------------------------------------------

use 5.006;
use AppleII::Disk 0.09;
use Carp;
use POSIX 'mktime';
use bytes;
use strict;
use warnings;

use Exporter 5.57 'import';     # exported import method
our @ISA = qw(AppleII::ProDOS::Members);
our @EXPORT = qw();
our @EXPORT_OK = qw(
    pack_date pack_name parse_date parse_name parse_type shell_wc
    short_date unpack_date valid_date valid_name a2_croak
);

my %vol_fields = (
    bitmap   => undef,
    disk     => undef,
    diskSize => undef,
    name     => undef,
);

# Methods to be passed along to the current directory:
my %dir_methods = (
    catalog  => undef,
    get_file => undef,
    new_dir  => undef,
    put_file => undef,
);

#=====================================================================
# Package Global Variables:

our $VERSION = '0.201';
# This file is part of AppleII-LibA2 0.201 (September 12, 2015)

# Filetype list from About Apple II File Type Notes -- June 1992
my @filetypes = qw(
    NON BAD PCD PTX TXT PDA BIN FNT FOT BA3 DA3 WPF SOS $0D $0E DIR
    RPD RPI AFD AFM AFR SCL PFS $17 $18 ADB AWP ASP $1C $1D $1E $1F
    TDM $21 $22 $23 $24 $25 $26 $27 $28 $29 8SC 8OB 8IC 8LD P8C $2F
    $30 $31 $32 $33 $34 $35 $36 $37 $38 $39 $3A $3B $3C $3D $3E $3F
    DIC $41 FTD $43 $44 $45 $46 $47 $48 $49 $4A $4B $4C $4D $4E $4F
    GWP GSS GDB DRW GDP HMD EDU STN HLP COM CFG ANM MUM ENT DVU FIN
    $60 $61 $62 $63 $64 $65 $66 $67 $68 $69 $6A BIO $6C TDR PRE HDV
    $70 $71 $72 $73 $74 $75 $76 $77 $78 $79 $7A $7B $7C $7D $7E $7F
    $80 $81 $82 $83 $84 $85 $86 $87 $88 $89 $8A $8B $8C $8D $8E $8F
    $90 $91 $92 $93 $94 $95 $96 $97 $98 $99 $9A $9B $9C $9D $9E $9F
    WP  $A1 $A2 $A3 $A4 $A5 $A6 $A7 $A8 $A9 $AA GSB TDF BDF $AE $AF
    SRC OBJ LIB S16 RTL EXE PIF TIF NDA CDA TOL DVR LDF FST $BE DOC
    PNT PIC ANI PAL $C4 OOG SCR CDV FON FND ICN $CB $CC $CD $CE $CF
    $D0 $D1 $D2 $D3 $D4 MUS INS MDI SND $D9 $DA DBM $DC $DD $DE $DF
    LBR $E1 ATK $E3 $E4 $E5 $E6 $E7 $E8 $E9 $EA $EB $EC $ED R16 PAS
    CMD $F1 $F2 $F3 $F4 $F5 $F6 $F7 $F8 OS  INT IVR BAS VAR REL SYS
); # end filetypes

#=====================================================================
# package AppleII::ProDOS:
#
# Member Variables:
#   bitmap:
#     An AppleII::ProDOS::Bitmap containing the volume bitmap
#   directories:
#     Array of AppleII::ProDOS::Directory starting with the volume dir
#   disk:
#     The AppleII::Disk we are accessing
#   diskSize:
#     The number of blocks on the disk
#   name:
#     The volume name of the disk
#---------------------------------------------------------------------
# Constructor for creating a new disk:
#
# Input:
#   name:
#     The volume name for the new disk
#   diskSize:
#     The size of the disk in blocks
#   filename:
#     The pathname of the image file you want to open
#   mode: (optional)
#     A string indicating how the image should be opened
#     See AppleII::Disk::new for details.
#     'rw' is always appended to the mode

sub new
{
    my ($type, $name, $diskSize, $filename, $mode) = @_;

    a2_croak("Invalid name `$name'") unless valid_name($name);
    $name = uc $name;

    my $disk = AppleII::Disk->new($filename, ($mode || '') . 'rw');
    $disk->blocks($diskSize);

    my $bitmap = AppleII::ProDOS::Bitmap->new($disk,6,$diskSize);

    my $self = {
        bitmap      => $bitmap,
        directories => [ AppleII::ProDOS::Directory->new(
            $name, $disk, [2 .. 5], $bitmap
        ) ],
        disk   => $disk,
        name   => $name,
        _dir_methods => \%dir_methods,
        _permitted => \%vol_fields,
    };

    $bitmap->write_disk;
    $self->{directories}[0]->write_disk;

    bless $self, $type;
} # end AppleII::ProDOS::new

#---------------------------------------------------------------------
# Constructor for opening an existing disk:
#
# There are two forms:
#   open(disk); or
#   open(filename, mode);
#
# Input:
#   disk:
#     The AppleII::Disk to use
#   filename:
#     The pathname of the image file you want to open
#   mode:
#     A string indicating how the image should be opened
#     May contain any of the following characters (case sensitive):
#       r  Allow reads (this is actually ignored; you can always read)
#       w  Allow writes

sub open
{
    my ($type, $disk, $mode) = @_;
    my $self = {
        _dir_methods => \%dir_methods,
        _permitted   => \%vol_fields,
    };
    $disk = AppleII::Disk->new($disk, $mode) unless ref $disk;
    $self->{disk} = $disk;

    my $volDir = $disk->read_block(2);

    my $storageType;
    ($storageType, $self->{name}) = parse_name(substr($volDir,0x04,16));
    croak('This is not a ProDOS disk') unless $storageType == 0xF;

    my ($startBlock, $diskSize) = unpack('x39v2',$volDir);
    $disk->blocks($diskSize);

    $self->{bitmap} =
      AppleII::ProDOS::Bitmap->open($disk,$startBlock,$diskSize);

    $self->{directories} = [
        AppleII::ProDOS::Directory->open($disk, 2, $self->{bitmap})
    ];
    $self->{diskSize} = $diskSize;

    bless $self, $type;
} # end AppleII::ProDOS::open

#---------------------------------------------------------------------
# Return the current directory:
#
# Returns:
#   The current AppleII::ProDOS::Directory

sub dir {
    shift->{directories}[-1];
} # end AppleII::ProDOS::dir

#---------------------------------------------------------------------
# Return or change the current path:
#
# Input:
#   newpath:  The path to change to
#
# Returns:
#   The current path (begins and ends with '/')

sub path
{
    my ($self, $newpath) = @_;

    if ($newpath) {
        # Change directory:
        my @directories = @{$self->{directories}};
        $#directories = 0 if $newpath =~ s!^/\Q$self->{name}\E/?!!i;
        pop @directories
            while $#directories and $newpath =~ s'^\.\.(?:/|$)''; #'
        my $dir;
        foreach $dir (split(/\//, $newpath)) {
            eval { push @directories, $directories[-1]->open_dir($dir) };
            a2_croak("No such directory `$_[1]'")
                if $@ =~ /^LibA2: No such directory/;
            die $@ if $@;
        }
        $self->{directories} = \@directories;
    } # end if changing path

    '/'.join('/',map { $_->{name} } @{$self->{directories}}).'/';
} # end AppleII::ProDOS::path

#---------------------------------------------------------------------
# Pass method calls along to the current directory:

sub AUTOLOAD
{
    my $self = $_[0];
    my $name = our $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
    unless (ref($self) and exists $self->{'_dir_methods'}{$name}) {
        # Try to access a field by that name:
        $AppleII::ProDOS::Members::AUTOLOAD = $AUTOLOAD;
        goto &AppleII::ProDOS::Members::AUTOLOAD;
    }

    shift @_; # Remove self
    $self->{directories}[-1]->$name(@_);
} # end AppleII::ProDOS::AUTOLOAD

#---------------------------------------------------------------------
# Like croak, but get out of all AppleII::ProDOS classes:

sub a2_croak
{
    local $Carp::CarpLevel = $Carp::CarpLevel;
    while ((caller $Carp::CarpLevel)[0] =~ /^AppleII::ProDOS/) {
        ++$Carp::CarpLevel;
    }
    croak("LibA2: " . $_[0]);
} # end AppleII::ProDOS::a2_croak

#---------------------------------------------------------------------
# Convert a time to ProDOS format:
#
# This is NOT a method; it's just a regular subroutine.
#
# Input:
#   time:  The time to convert
#
# Returns:
#   Packed string

sub pack_date
{
  if (@_ == 1) { # Unix timestamp
    @_ = (localtime($_[0]))[5,4,3,2,1];
    ++$_[1];
  } elsif (@_ == 3) { # Year, Month, Day
    push @_, 0, 0;              # Hour, Minute
  } elsif (@_ < 5) {
    croak "Usage: pack_date(TIMESTAMP | Y,M,D | Y,M,D,H,M)";
  }

  pack('vC2', (($_[0]%100)<<9) + ($_[1]<<5) + $_[2], @_[4,3]);
} # end AppleII::ProDOS::pack_date

#---------------------------------------------------------------------
# Convert a filename to ProDOS format (length nibble):
#
# This is NOT a method; it's just a regular subroutine.
#
# Input:
#   type:  The high nibble of the type/length byte
#   name:  The name
#
# Returns:
#   Packed string

sub pack_name
{
    pack('Ca15',($_[0] << 4) + length($_[1]), uc $_[1]);
} # end AppleII::ProDOS::pack_name

#---------------------------------------------------------------------
# Extract a date & time:
#
# This is NOT a method; it's just a regular subroutine.
#
# Input:
#   dateField:  The date/time field
#
# Returns:
#   Standard time for use with gmtime (not localtime)
#   undef if no date

sub parse_date
{
    my ($date, $minute, $hour) = unpack('vC2', $_[0]);
    return undef unless $date;
    my ($year, $month, $day) = ($date>>9, (($date>>5) & 0x0F), $date & 0x1F);
    mktime(0, $minute, $hour, $day, $month-1, $year);
} # end AppleII::ProDOS::parse_date

#---------------------------------------------------------------------
# Extract a filename:
#
# This is NOT a method; it's just a regular subroutine.
#
# Input:
#   nameField:  The type/length byte followed by the name
#
# Returns:
#   (type, name)

sub parse_name
{
    my $typeLen = ord $_[0];
    ($typeLen >> 4, substr($_[0],1,$typeLen & 0x0F));
} # end AppleII::ProDOS::parse_name

#---------------------------------------------------------------------
# Convert a filetype to its abbreviation:
#
# This is NOT a method; it's just a regular subroutine.
#
# Input:
#   type:  The filetype to convert (0-255)
#
# Returns:
#   The abbreviation for the filetype

sub parse_type
{
    $filetypes[$_[0]];
} # end AppleII::ProDOS::parse_type

#---------------------------------------------------------------------
# Convert shell-type wildcards to Perl regexps:
#
# This is NOT a method; it's just a regular subroutine.
#
# Input:
#   The filename with optional wildcards
#
# Returns:
#   A Perl regexp

sub shell_wc
{
    '^' .
    join('',
         map { if (/\?/) {'.'} elsif (/\*/) {'.*'} else {quotemeta $_}}
         split(//,$_[0]));
} # end AppleII::ProDOS::shell_wc

#---------------------------------------------------------------------
# Convert a date & time to a short string:
#
# This is NOT a method; it's just a regular subroutine.
#
# Input:
#   dateField:  The date/time field
#
# Returns:
#   "dd-Mmm-yy hh:mm" or "<No Date>      "

my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

sub short_date
{
    my ($date, $minute, $hour) = unpack('vC2', $_[0]);
    return "<No Date>      " unless $date;
    my ($year, $month, $day) = ($date>>9, (($date>>5) & 0x0F), $date & 0x1F);
    sprintf('%2d-%s-%02d %2d:%02d',$day,$months[$month-1],$year,$hour,$minute);
} # end AppleII::ProDOS::short_date

#---------------------------------------------------------------------
# Convert a date & time to Date::Calc format:
#
# This is NOT a method; it's just a regular subroutine.
#
# Input:
#   dateField:  The date/time field
#
# Returns:
#   (YEAR, MONTH, DAY, HOUR, MINUTE)
#   The empty list if the date is null

sub unpack_date
{
    my ($date, $minute, $hour) = unpack('vC2', $_[0]);
    return unless $date;

    my $year = $date >> 9;

    return ((($year < 77) ? $year + 2000 : $year + 1900),
            (($date>>5) & 0x0F), $date & 0x1F, $hour, $minute);
} # end AppleII::ProDOS::unpack_date

#---------------------------------------------------------------------
# Determine if a date is valid:
#
# May be called as a method or a normal subroutine.
#
# This is not a very strenuous check; it doesn't know that not all
# months have 31 days.  [FIXME]
#
# Input:
#   The date to check in ProDOS format (4 byte packed string)
#
# Returns:
#   0 if the date is invalid
#   1 if the date is zero (no date)
#   2 if the date is valid

sub valid_date
{
    return 1 if $_[-1] eq "\0\0\0\0"; # No date
    my ($date, $minute, $hour) = unpack('vC2', $_[-1]);
    my ($year, $month, $day) = ($date>>9, (($date>>5) & 0x0F), $date & 0x1F);
    return 0 if $minute > 59 or $hour > 23 or $year > 99
             or $month  > 12 or $month < 1 or $day  > 31 or $day < 1;
    2;                          # Valid date
} # end AppleII::ProDOS::valid_date

#---------------------------------------------------------------------
# Determine if a filename is valid:
#
# May be called as a method or a normal subroutine.
#
# Input:
#   The file to check
#
# Returns:
#   True if the filename is valid

sub valid_name
{
    $_[-1] =~ /\A[a-z][a-z0-9.]{0,14}\Z(?!\n)/i;
} # end AppleII::ProDOS::valid_name

#=====================================================================
package AppleII::ProDOS::Bitmap;
#
# Member Variables:
#   bitmap:    The volume bitmap itself
#   blocks:    An array of the block numbers where the bitmap is stored
#   disk:      An AppleII::Disk
#   diskSize:  The number of blocks on the disk
#   free:      The number of free blocks
#---------------------------------------------------------------------

use Carp;
use bytes;
use strict;
use warnings;

our @ISA = 'AppleII::ProDOS::Members';

# Map ProDOS bit order to Perl's vec():
my @adjust = (7, 5, 3, 1, -1, -3, -5, -7);

my %bit_fields = (
    diskSize => undef,
    free     => undef,
);

#---------------------------------------------------------------------
# Constructor for creating a new bitmap:
#
# All blocks are marked free, except for blocks 0 thru the end of the
# bitmap, which are marked used.
#
# Input:
#   disk:        The AppleII::Disk to use
#   startBlock:  The block number where the volume bitmap begins
#   diskSize:    The size of the disk in blocks

sub new
{
    my ($type, $disk, $startBlock, $diskSize) = @_;
    my $self = {
        bitmap     => ("\xFF" x int($diskSize / 8)),
        disk       => $disk,
        diskSize   => $diskSize,
        free       => $diskSize,
        _permitted => \%bit_fields,
    };
    bless $self, $type;
    $self->mark([ $diskSize-8 .. $diskSize-1], 1); # Mark odd blocks at end

    my @blocks;
    do {
        push @blocks, $startBlock++;
    } while ($diskSize -= 0x1000) > 0;

    $self->mark([ 0 .. $blocks[-1] ], 0); # Mark initial blocks as used

    $self->{bitmap} =
        AppleII::Disk::pad_block($self->{bitmap},"\0",($#blocks+1) * 0x200);
    $self->{blocks} = \@blocks;
    $self->{free} = unpack('%32b*', $self->{bitmap});

    $self;
} # end AppleII::ProDOS::Bitmap::new

#---------------------------------------------------------------------
# Constructor for reading an existing bitmap:
#
# Input:
#   disk:        The AppleII::Disk to use
#   startBlock:  The block number where the volume bitmap begins
#   diskSize:    The size of the disk in blocks
#     STARTBLOCK & BLOCKS are optional.  If they are omitted, we get
#     the information from the volume directory.

sub open
{
    my ($type, $disk, $startBlock, $diskSize) = @_;
    my $self = {};
    $self->{disk} = $disk;
    $self->{'_permitted'} = \%bit_fields;
    unless ($startBlock and $diskSize) {
        my $volDir = $disk->read_block(2);
        ($startBlock, $diskSize) = unpack('v2',substr($volDir,0x27,4));
    }
    $self->{diskSize} = $diskSize;
    do {
        push @{$self->{blocks}}, $startBlock++;
    } while ($diskSize -= 0x1000) > 0;

    bless $self, $type;
    $self->read_disk;
    $self;
} # end AppleII::ProDOS::Bitmap::open

#---------------------------------------------------------------------
# Get some free blocks:
#
# Input:
#   count:  The number of blocks requested
#
# Returns:
#   A list of block numbers (which have been marked as used)
#   The empty list if there aren't enough free blocks

sub get_blocks
{
    my ($self, $count) = @_;
    return () if $count > $self->{free};
    my @blocks;
    my $bitmap = $self->{bitmap};
  BLOCK:
    while ($bitmap =~ m/([^\0])/g) {
        my ($offset, $byte) = (8*pos($bitmap)-9, unpack('B8',$1));
        while ($byte =~ m/1/g) {
            push @blocks, $offset + pos($byte);
            last BLOCK unless --$count;
        }
    } # end while BLOCK
    return () if $count;        # We couldn't find enough
    $self->mark(\@blocks,0);    # Mark blocks as in use
    @blocks;
} # end AppleII::ProDOS::Bitmap::get_blocks

#---------------------------------------------------------------------
# See if a block is free:
#
# This method is not currently used and may be removed.
#
# Input:
#   block:  The block number to check
#
# Returns:
#   True if the block is free

sub is_free
{
    my ($self, $block) = @_;
    croak("No block $block") if $block < 0 or $block >= $self->{diskSize};
    vec($self->{bitmap}, $block + $adjust[$block % 8],1);
} # end AppleII::ProDOS::Bitmap::is_free

#---------------------------------------------------------------------
# Mark blocks as free or used:
#
# Input:
#   blocks:  A block number or list of block numbers to mark
#   mark:    1 for Free, 0 for Used

sub mark
{
    my ($self, $blocks, $mark) = @_;
    my $diskSize = $self->{diskSize};
    $blocks = [ $blocks ] unless ref $blocks;

    my $block;
    foreach $block (@$blocks) {
        croak("No block $block") if $block < 0 or $block >= $diskSize;
        vec($self->{bitmap}, $block + $adjust[$block % 8],1) = $mark;
    }
    $self->{free} += ($mark ? 1 : -1) * ($#$blocks + 1);
} # end AppleII::ProDOS::Bitmap::mark

#---------------------------------------------------------------------
# Read bitmap from disk:

sub read_disk
{
    my $self = shift;
    $self->{bitmap} = $self->{disk}->read_blocks($self->{blocks});
    $self->{free}   = unpack('%32b*', $self->{bitmap});
} # end AppleII::ProDOS::Bitmap::read_disk

#---------------------------------------------------------------------
# Return the block number where the bitmap begins:

sub start_block
{
    shift->{blocks}[0];
} # end AppleII::ProDOS::Bitmap::start_block

#---------------------------------------------------------------------
# Write bitmap to disk:

sub write_disk
{
    my $self = shift;
    $self->{disk}->write_blocks($self->{blocks}, $self->{bitmap});
} # end AppleII::ProDOS::Bitmap::write_disk

#=====================================================================
package AppleII::ProDOS::Directory;
#
# Member Variables:
#   access:
#     The access attributes for this directory
#   bitmap:
#     The AppleII::ProDOS::Bitmap for the disk
#   blocks:
#     The list of blocks used by this directory
#   disk:
#     An AppleII::Disk
#   entries:
#     The list of directory entries
#   name:
#     The directory name
#   created:
#     The date/time the directory was created
#   reserved:
#     The contents of the reserved section (8 byte string)
#   type:
#     0xF for a volume directory, 0xE for a subdirectory
#   version:
#     The contents of the VERSION & MIN_VERSION (2 byte string)
#
# For subdirectories:
#   parent:     The block number in the parent directory where our entry is
#   parentNum:  Our entry number within that block of the parent directory
#   fixParent:  True means our parent entry needs to be updated
#
# We also use the os_openDirs field of the disk to keep track of open
# directories.  It contains a hash of Directory objects indexed by key
# block.  The constructors automatically add the new objects to the
# hash, and the destructor removes them.
#---------------------------------------------------------------------

AppleII::ProDOS->import(qw(a2_croak pack_date pack_name parse_name
                           short_date valid_date valid_name));
use Carp;
use bytes;
use strict;
use warnings;

our @ISA = 'AppleII::ProDOS::Members';

my %dir_fields = (
    access      => 0xFF,
    created     => \&valid_date,
    name        => \&valid_name,
    type        => undef,
    version     => undef,
);

#---------------------------------------------------------------------
# Constructor for creating a new directory:
#
# You must supply parent & parentNum when creating a subdirectory.
#
# Input:
#   name:       The name of the new directory
#   disk:       An AppleII::Disk
#   blocks:     A block number or array of block numbers for the directory
#   bitmap:     The AppleII::ProDOS::Bitmap for the disk
#   parent:     The block number in the parent directory where our entry is
#   parentNum:  Our entry number within that block of the parent directory

sub new
{
    my ($type, $name, $disk, $blocks, $bitmap, $parent, $parentNum) = @_;

    a2_croak("Invalid name `$name'") unless valid_name($name);

    my $self = {
        access  => 0xE3,
        bitmap  => $bitmap,
        blocks  => $blocks,
        disk    => $disk,
        entries => [],
        name    => uc $name,
        version => "\0\0",
        created => pack_date(time),
        _permitted => \%dir_fields,
    };

    if ($parent) {
        $self->{type}      = 0xE; # Subdirectory
        $self->{parent}    = $parent;
        $self->{parentNum} = $parentNum;
        $self->{reserved}  = "\x75\x23\x00\xC3\x27\x0D\x00\x00";
    } else {
        $self->{type} = 0xF;    # Volume directory
        $self->{reserved} = "\0" x 8; # 8 bytes reserved
    } # end else volume directory

    bless $self, $type;
    $disk->{os_openDirs}{$blocks->[0]} = $self;
    $self;
} # end AppleII::ProDOS::Directory::new

#---------------------------------------------------------------------
# Constructor for reading an existing directory:
#
# Input:
#   disk:       An AppleII::Disk
#   block:      The block number where the directory begins
#   bitmap:     The AppleII::ProDOS::Bitmap for the disk

sub open
{
    my ($type, $disk, $block, $bitmap) = @_;
    my $self = {
        bitmap     => $bitmap,
        disk       => $disk,
        _permitted => \%dir_fields,
    };

    bless $self, $type;
    $disk->{os_openDirs}{$block} = $self;
    $self->read_disk($block);
    $self;
} # end AppleII::ProDOS::Directory::open

#---------------------------------------------------------------------
# Destructor:
#
# Removes the directory from the hash of open directories.

sub DESTROY
{
    my $self = shift;
    delete $self->{disk}{os_openDirs}{$self->{blocks}[0]};
} # end AppleII::ProDOS::Directory::DESTROY

#---------------------------------------------------------------------
# Add entry:
#
# Dies if the entry can't be added.
#
# Input:
#   entry:  An AppleII::ProDOS::DirEntry

sub add_entry
{
    my ($self,$entry) = @_;

    a2_croak($entry->name . ' already exists')
        if $self->find_entry($entry->name);

    my $entries = $self->{entries};

    my $i;
    for ($i=0; $i <= $#$entries; ++$i) {
        last if $entries->[$i]{num} > $i+1;
    }

    if ($i+1 >= 0xD * scalar @{$self->{blocks}}) {
        a2_croak('Volume full') unless $self->{type} == 0xE; # Subdirectory
        my @blocks = $self->{bitmap}->get_blocks(1);
        a2_croak('Volume full') unless @blocks;
        push @{$self->{blocks}}, @blocks;
        $self->{fixParent} = 1;
    } # end if directory full

    $entry->{num} = $i+1;
    splice @$entries, $i, 0, $entry;
} # end AppleII::ProDOS::Directory::add_entry

#---------------------------------------------------------------------
# Return the directory listing and free space information:
#
# Returns:
#   A string containing the catalog in ProDOS format

sub catalog
{
    my $self = shift;
    my $result =
        sprintf("%-15s%s %s  %-14s  %-14s %8s %s\n",
                qw(Name Type Blocks Modified Created Size Subtype));
    my $entry;
    foreach $entry (@{$self->{entries}}) {
        $result .= sprintf("%-15s %-3s %5d  %s %s %8d  \$%04X\n",
                           $entry->name, $entry->short_type, $entry->blksUsed,
                           short_date($entry->modified),
                           short_date($entry->created),
                           $entry->size, $entry->auxtype);
    } # end foreach entry

    my $bitmap = $self->{bitmap};
    my ($free, $total, $used) = ($bitmap->free, $bitmap->diskSize);
    $used = $total - $free;

    $result .
        "Blocks free: $free     Blocks used: $used     Total blocks: $total\n";
} # end AppleII::ProDOS::Directory::catalog

#---------------------------------------------------------------------
# Return the list of entries:
#
# Returns:
#   A list of AppleII::ProDOS::DirEntry objects

sub entries
{
    @{shift->{entries}};
} # end AppleII::ProDOS::Directory::entries

#---------------------------------------------------------------------
# Find an entry:
#
# Input:
#   filename:  The filename to match
#
# Returns:
#   The entry representing that filename

sub find_entry
{
    my ($self, $filename) = @_;
    $filename = uc $filename;
    (grep {uc($_->name) eq $filename} @{$self->{'entries'}})[0];
} # end AppleII::ProDOS::Directory::find_entry

#---------------------------------------------------------------------
# Read a file:
#
# Input:
#   file:
#     The name of the file to read, OR
#     an AppleII::ProDOS::DirEntry object representing a file
#
# Returns:
#   A new AppleII::ProDOS::File object for the file

sub get_file
{
    my ($self, $filename) = @_;

    my $entry = (ref($filename)
                 ? $filename
                 : ($self->find_entry($filename)
                    or a2_croak("No such file `$filename'")));

    AppleII::ProDOS::File->open($self->{disk}, $entry);
} # end AppleII::ProDOS::Directory::get_file

#---------------------------------------------------------------------
# List files matching a regexp:
#
# Input:
#   pattern:
#     The Perl regexp to match
#     (AppleII::ProDOS::shell_wc converts shell-type wildcards to regexps)
#   filter: (optional)
#     A subroutine to run against the entries
#     It must return a true value for the file to be accepted.
#     There are three special values:
#       undef   Match anything
#       'DIR'   Match only directories
#       '!DIR'  Match anything but directories
#
# Returns:
#   A list of filenames matching the pattern

sub list_matches
{
    my ($self, $pattern, $filter) = @_;
    $filter = \&is_dir   if $filter eq 'DIR';
    $filter = \&isnt_dir if $filter eq '!DIR';
    $filter = \&true     unless $filter;
    map { ($_->name =~ /$pattern/i and &$filter($_))
          ? $_->name
          : () }
        @{$self->{'entries'}};
} # end AppleII::ProDOS::Directory::list_matches

sub is_dir   { $_[0]->type == 0x0F } # True if entry is directory
sub isnt_dir { $_[0]->type != 0x0F } # True if entry is not directory
sub true     { 1 }                   # Accept anything

#---------------------------------------------------------------------
# Create a subdirectory:
#
# Input:
#   dir:     The name of the subdirectory to create
#   size:    The number of entries the directory should hold
#            The default is to create a 1 block directory
#
# Returns:
#   The DirEntry object for the new directory

sub new_dir
{
    my ($self, $dir, $size) = @_;

    a2_croak("Invalid name `$dir'") unless valid_name($dir);
    $dir = uc $dir;

    $size = 1 unless $size;
    $size = int(($size + 0xD) / 0xD); # Compute # of blocks (+ dir header)

    my @blocks = $self->{bitmap}->get_blocks($size)
        or a2_croak("Not enough free space");

    my $entry = AppleII::ProDOS::DirEntry->new;

    eval {
        $entry->storage(0xD);   # Directory
        $entry->name($dir);
        $entry->type(0x0F);     # Directory
        $entry->block($blocks[0]);
        $entry->blksUsed($#blocks + 1);
        $entry->size(0x200 * ($#blocks + 1));

        $self->add_entry($entry);
        my $subdir = AppleII::ProDOS::Directory->new(
            $dir, $self->{disk}, \@blocks, $self->{bitmap},
            $self->{blocks}[int($entry->num / 0xD)], int($entry->num % 0xD)+1
        );

        $subdir->write_disk;
        $self->write_disk;
        $self->{bitmap}->write_disk;
    }; # end eval
    if ($@) {
        my $error = $@;         # Clean up after error
        $self->read_disk;
        $self->{bitmap}->read_disk;
        die $error;
    } # end if error while creating directory

    $entry;
} # end AppleII::ProDOS::Directory::new_dir

#---------------------------------------------------------------------
# Open a subdirectory:
#
# Input:
#   dir:  The name of the subdirectory to open, OR
#         an AppleII::ProDOS::DirEntry object representing the directory
#
# Returns:
#   A new AppleII::ProDOS::Directory object for the subdirectory

sub open_dir
{
    my ($self, $dir) = @_;

    my $entry = (ref($dir)
                 ? $dir
                 : ($self->find_entry($dir)
                    or a2_croak("No such directory `$dir'")));

    a2_croak('`' . $entry->name . "' is not a directory")
        unless $entry->type == 0x0F;

    AppleII::ProDOS::Directory->open($self->{disk}, $entry->block,
                                     $self->{bitmap});
} # end AppleII::ProDOS::Directory::open_dir

#---------------------------------------------------------------------
# Add a new file to the directory:
#
# Input:
#   file:    The AppleII::ProDOS::File to add

sub put_file
{
    my ($self, $file) = @_;

    eval {
        $file->allocate_space($self->{bitmap});
        $self->add_entry($file);
        $file->write_disk($self->{disk});
        $self->write_disk;
        $self->{bitmap}->write_disk;
    };
    if ($@) {
        my $error = $@;
        # Clean up after failure:
        $self->read_disk;
        $self->{bitmap}->read_disk;
        die $error;
    }
} # end AppleII::ProDOS::Directory::put_file

#---------------------------------------------------------------------
# Read directory from disk:

sub read_disk
{
    my ($self, $block) = @_;
    $block = $self->{blocks}[0] unless $block;

    my (@blocks,@entries);
    my $disk = $self->{disk};
    my $entry = 0;
    while ($block) {
        push @blocks, $block;
        my $data = $disk->read_block($block);
        $block = unpack('v',substr($data,0x02,2)); # Pointer to next block
        substr($data,0,4) = '';                    # Remove block pointers
        while ($data) {
            my ($type, $name) = parse_name($data);
            if (($type & 0xE) == 0xE) {
                # Directory header
                $self->{name} = $name;
                $self->{type} = $type;
                $self->{reserved} = substr($data, 0x14-4,8);
                $self->{created} = substr($data, 0x1C-4,4);
                $self->{version} = substr($data, 0x20-4,2);
                $self->{access}  = ord substr($data, 0x22-4,1);
                if ($type == 0xE) {
                    # For subdirectory, read parent pointers
                    @{$self}{qw(parent parentNum)} =
                        unpack('vC',substr($data,0x27-4,3));
                } # end if subdirectory
            } elsif ($type) {
                # File entry
                push @entries, AppleII::ProDOS::DirEntry->new($entry, $data);
            }
            substr($data,0,0x27) = ''; # Remove record
            ++$entry;
        } # end while more records
    } # end if rebuilding block list

    @{$self}{qw(blocks entries)}  = (\@blocks, \@entries);
} # end AppleII::ProDOS::Directory::read_disk

#---------------------------------------------------------------------
# Write directory to disk:

sub write_disk
{
    my ($self) = @_;

    my $disk    = $self->{disk};
    my @blocks  = @{$self->{blocks}};
    my @entries = @{$self->{'entries'}};
    my $keyBlock = $blocks[0];

    if ($self->{fixParent}) {
        delete $self->{fixParent};
        my $data = $disk->read_block($self->{parent});
        my $entry = 4 + 0x27*($self->{parentNum}-1);
        substr($data, $entry + 0x11, 7) =
            pack('v2VX', $keyBlock, scalar(@blocks), 0x200 * scalar(@blocks));
        # FIXME update modified date?
        $disk->write_block($self->{parent}, $data);
        my $parentBlock = unpack('v', substr($data,$entry + 0x25, 2));
        $disk->{os_openDirs}{$parentBlock}->read_disk
            if $disk->{os_openDirs}{$parentBlock};
    } # end if parent entry needs updating

    push    @blocks, 0;         # Add marker at beginning and end
    unshift @blocks, 0;
    my ($i, $entry);
    for ($i=1, $entry=0; $i < $#blocks; $i++) {
        my $data = pack('v2',$blocks[$i-1],$blocks[$i+1]); # Block pointers
        while (length($data) < 0x1FF) {
            if ($entry) {
                # Add a file entry:
                if (@entries and $entries[0]{num} == $entry) {
                    $data .= $entries[0]->packed($keyBlock); shift @entries;
                } else {
                    $data .= "\0" x 0x27;
                }
            } else {
                # Add the directory header:
                $data .= pack_name(@{$self}{'type','name'});
                $data .= $self->{reserved};
                $data .= $self->{created};
                $data .= $self->{version};
                $data .= chr $self->{access};
                $data .= "\x27\x0D"; # Entry length, entries per block
                $data .= pack('v',$#entries+1);
                if ($self->{type} == 0xF) {
                    my $bitmap = $self->{bitmap};
                    $data .= pack('v2',$bitmap->start_block,$bitmap->diskSize);
                } else {
                    $data .= pack('vCC',@{$self}{'parent','parentNum'},
                                  0x27); # Parent entry length
                } # end else subdirectory
            } # end else if directory header
            ++$entry;
        } # end while more room in block
        $disk->write_block($blocks[$i],$data."\0");
    } # end for each directory block
} # end AppleII::ProDOS::Directory::write_disk

#=====================================================================
package AppleII::ProDOS::DirEntry;
#
# Member Variables:
#   access:   The access attributes
#   auxtype:  The auxiliary type
#   block:    The key block for this file
#   blksUsed: The number of blocks used by this file
#   created:  The creation date/time
#   modified: The date/time of last modification
#   name:     The filename
#   num:      The entry number of this entry
#   size:     The file size in bytes
#   storage:  The storage type
#   type:     The file type
#   version:  The contents of the VERSION & MIN_VERSION (2 byte string)
#---------------------------------------------------------------------
AppleII::ProDOS->import(qw(pack_date pack_name parse_name parse_type
                           valid_date valid_name));
use integer;
use bytes;
use strict;
use warnings;

our @ISA = 'AppleII::ProDOS::Members';

my %de_fields = (
    access      => 0xFF,
    auxtype     => 0xFFFF,
    block       => sub { not defined $_[0]{block}    },
    blksUsed    => sub { not defined $_[0]{blksUsed} },
    created     => \&valid_date,
    modified    => \&valid_date,
    name        => \&valid_name,
    num         => sub { not defined $_[0]{num}     },
    size        => sub { not defined $_[0]{size}    },
    storage     => sub { not defined $_[0]{storage} },
    type        => 0xFF,
);

#---------------------------------------------------------------------
# Constructor:
#
# Input:
#   number:  The entry number
#   entry:   The directory entry

sub new
{
    my ($type, $number, $entry) = @_;
    my $self = {};

    $self->{'_permitted'} = \%de_fields;
    if ($entry) {
        $self->{num} = $number;
        @{$self}{'storage', 'name'} = parse_name($entry);
        @{$self}{qw(type block blksUsed size)} = unpack('x16Cv2V',$entry);
        $self->{size} &= 0xFFFFFF;  # Size is only 3 bytes long
        @{$self}{qw(access auxtype)} = unpack('x30Cv',$entry);

        $self->{created}  = substr($entry,0x18,4);
        $self->{modified} = substr($entry,0x21,4);
        $self->{version}  = substr($entry,0x1C,2);
    } else {
        # Blank entry:
        $self->{created} = $self->{modified} = pack_date(time);
        @{$self}{qw(access auxtype type version)} =
            (0xE3, 0x0000, 0x00, "\0\0");
    }
    bless $self, $type;
} # end AppleII::ProDOS::DirEntry::new

#---------------------------------------------------------------------
# Return the entry as a packed string:
#
# Input:
#   keyBlock:  The block number of the beginning of the directory
#
# Returns:
#   A directory entry ready to put in a ProDOS directory

sub packed
{
    my ($self, $keyBlock) = @_;
    my $data = pack_name(@{$self}{'storage', 'name'});
    $data .= pack('Cv2VX',@{$self}{qw(type block blksUsed size)});
    $data .= $self->{created} . $self->{version};
    $data .= pack('Cv',@{$self}{qw(access auxtype)});
    $data .= $self->{modified};
    $data .= pack('v',$keyBlock);
} # end AppleII::ProDOS::DirEntry::packed

#---------------------------------------------------------------------
# Return the filetype as a string:

sub short_type
{
    parse_type(shift->{type});
} # end AppleII::ProDOS::DirEntry::short_type

#=====================================================================
package AppleII::ProDOS::File;
#
# Member Variables:
#   data:         The contents of the file
#   indexBlocks:  For tree files, the number of subindex blocks needed
#
# Private Members (for communication between allocate_space & write_disk):
#   blocks:       The list of data blocks allocated for this file
#   indexBlocks:  For tree files, the list of subindex blocks
#---------------------------------------------------------------------

AppleII::ProDOS->import(qw(a2_croak valid_date valid_name));
use Carp;
use bytes;
use strict;
use warnings;

our @ISA = 'AppleII::ProDOS::DirEntry';

my %fil_fields = (
    access      => 0xFF,
    auxtype     => 0xFFFF,
    blksUsed    => undef,
    created     => \&valid_date,
    data        => undef,
    modified    => \&valid_date,
    name        => \&valid_name,
    size        => undef,
    type        => 0xFF,
);

#---------------------------------------------------------------------
# Constructor for creating a new file:
#
# Input:
#   name:  The filename
#   data:  The contents of the file

sub new
{
    my ($type, $name, $data) = @_;
    a2_croak("Invalid name `$name'") unless valid_name($name);

    my $self = {
        access     => 0xE3,
        auxtype    => 0,
        created    => "\0\0\0\0",
        data       => $data,
        modified   => "\0\0\0\0",
        name       => uc $name,
        size       => length($data),
        type       => 0,
        version    => "\0\0",
        _permitted => \%fil_fields
    };

    bless $self, $type;
} # end AppleII::ProDOS::File::new

#---------------------------------------------------------------------
# Open a file:
#
# Input:
#   disk:   The disk to read
#   entry:  The AppleII::ProDOS::DirEntry that describes the file

sub open
{
    my ($type, $disk, $entry) = @_;
    my $self = { _permitted => \%fil_fields };
    my @fields = qw(access auxtype blksUsed created modified name size
                    storage type version);
    @{$self}{@fields} = @{$entry}{@fields};

    my ($storage, $keyBlock, $size) =
        @{$entry}{qw(storage block size)};

    my $data;
    if ($storage == 1) {
        $data = $disk->read_block($keyBlock);
    } else {
      # Calculate the number of data blocks:
      #   (In a sparse file, not all these blocks
      #    are actually allocated.)
      my $blksUsed = int(($size + 0x1FF) / 0x200);

      if ($storage == 2) {
        my $index = AppleII::ProDOS::Index->open($disk,$keyBlock,$blksUsed);
        $data = $disk->read_blocks($index->blocks);
      } elsif ($storage == 3) {
        my $indexBlocks = int(($blksUsed + 0xFF) / 0x100);
        my $index = AppleII::ProDOS::Index->open($disk,$keyBlock,$indexBlocks);
        my (@blocks,$block);
        foreach $block (@{$index->blocks}) {
          if ($block) {
            my $subindex = AppleII::ProDOS::Index->open($disk,$block);
            push @blocks,@{$subindex->blocks};
          } else {
            push @blocks, (0) x 0x100; # Sparse index block
          }
        } # end foreach subindex block
        $#blocks = $blksUsed-1; # Use only the first $blksUsed blocks
        $data = $disk->read_blocks(\@blocks);
        $self->{indexBlocks} = $indexBlocks;
      } else {
        croak("Unsupported storage type $storage");
      }
    } # end else not a seedling file

    substr($data, $size) = '' if length($data) > $size;
    $self->{'data'} = $data;

    bless $self, $type;
} # end AppleII::ProDOS::File::open

#---------------------------------------------------------------------
# Allocate space for the file:
#
# Input:
#   bitmap:  The AppleII::ProDOS::Bitmap we should use
#
# Input Variables:
#   data:         The data we're trying to store
#
# Output Variables:
#   blksUsed:     The number of blocks used by the file (including indexes)
#   blocks:       The list of data blocks allocated
#   indexBlocks:  The list of subindex blocks allocated
#   storage:      The storage type of the file

sub allocate_space
{
  my ($self, $bitmap) = @_;

  # Decide which storage type this file requires:
  my $dataRef = \$self->{data};

  my @dataBlks = (1) x int((length($$dataRef) + 0x1FF) / 0x200);
  my @subindexBlks;
  my $storage;

  if (@dataBlks > 0x100) {
    $storage      = 3;          # > 128KB = Tree
    @subindexBlks = (1) x int((@dataBlks + 0xFF) / 0x100);
  } elsif (@dataBlks > 1) {
    $storage      = 2;          # 513 bytes - 128KB = Sapling
  } else {
    $storage      = 1;          # 0 - 512 bytes = Seedling
    @dataBlks     = (1);        # Even empty files need one block
  }

  # Calculate how many blocks the file will occupy:
  my $blksUsed = scalar @dataBlks;

  if ($storage > 1) {
    $blksUsed += 1 + @subindexBlks; # Add in the index blocks

    # Check to see if this file is sparse:
    my $index = 0;
    foreach (@dataBlks) {
      unless (substr($$dataRef, $index, 0x200) =~ /[^\0]/) {
        $_ = 0;         # This data block doesn't need to be allocated
        --$blksUsed;
      } # end unless this block contains data
      $index += 0x200;          # 512 bytes per data block
    } # end foreach data block

    # For tree files, figure out which subindex blocks are needed:
    if (@subindexBlks) {
      my @blocks = @dataBlks;
      foreach my $ib (@subindexBlks) {
        unless (grep { $_ } splice @blocks, 0, 0x100) {
          $ib = 0;  # This subindex block doesn't need to be allocated
          --$blksUsed;
        } # end unless this subindex block is required
      } # end foreach subindex block
    } # end if tree file
  } # end if not seedling

  $self->{storage}  = $storage;
  $self->{blksUsed} = $blksUsed;

  # Now allocate the blocks and record them:
  my @blocks = $bitmap->get_blocks($blksUsed)
      or a2_croak("Not enough free space");

  $self->{block} = $blocks[0];

  shift @blocks if $storage > 1; # Remove index block from list

  foreach (@subindexBlks, @dataBlks) {
    # If this block needs to be allocated, assign it one of our blocks:
    $_ = shift @blocks if $_;
  }

  if ($storage == 3) {
    $self->{indexBlocks} = \@subindexBlks;
  } else {
    delete $self->{indexBlocks}; # Just in case
  }

  $self->{blocks} = \@dataBlks;
} # end AppleII::ProDOS::File::allocate_space

#---------------------------------------------------------------------
# Return the file's contents as text:
#
# Returns:
#   The file's contents with hi bits stripped and CRs converted to \n

sub as_text
{
    my $self = shift;
    my $data = $self->{data};
    $data =~ tr/\x0D\x8D\x80-\xFF/\n\n\x00-\x7F/;
    $data;
} # end AppleII::ProDOS::File::as_text

#---------------------------------------------------------------------
# Write the file to disk:
#
# You must have already called allocate_space.
#
# Input:
#   disk:  The disk to write to
#
# Input Variables:
#   blocks:       The list of data blocks allocated
#   indexBlocks:  The list of subindex blocks allocated
#
# Output Variables:
#   indexBlocks:  The number of subindex blocks needed

sub write_disk
{
    my ($self, $disk) = @_;

    $disk->write_blocks($self->{blocks}, $self->{'data'}, "\0");

    my $storage = $self->{storage};
    if ($storage == 2) {
        my $index = AppleII::ProDOS::Index->new($disk,
                                                @{$self}{qw(block blocks)});
        $index->write_disk;
    } elsif ($storage == 3) {
        my $index =
          AppleII::ProDOS::Index->new($disk, @{$self}{qw(block indexBlocks)});
        $index->write_disk;
        my @blocks = @{$self->{blocks}};
        my $block;
        foreach $block (@{$self->{indexBlocks}}) {
          if ($block) {
            $index = AppleII::ProDOS::Index->new($disk, $block,
                                                 [splice(@blocks,0,0x100)]);
            $index->write_disk;
          } else {
            splice(@blocks,0,0x100);
          } # end else sparse index block is not actually allocated
        } # end for each subindex block
        $self->{indexBlocks} = scalar @{$self->{indexBlocks}};
    } # end elsif tree file

    delete $self->{blocks};
} # end AppleII::ProDOS::File::write_disk

#=====================================================================
package AppleII::ProDOS::Index;
#
# Member Variables:
#   block:   The block number of the index block
#   blocks:  The list of blocks pointed to by this index block
#   disk:    An AppleII::Disk
#---------------------------------------------------------------------

use integer;
use bytes;
use strict;
use warnings;

our @ISA = 'AppleII::ProDOS::Members';

my %in_fields = (
    blocks => undef,
);

#---------------------------------------------------------------------
# Constructor for creating a new index block:
#
# Input:
#   disk:    An AppleII::Disk
#   block:   The block number of the index block
#   blocks:  The list of blocks that are pointed to by this block

sub new
{
    my ($type, $disk, $block, $blocks) = @_;
    my $self = {
        disk       => $disk,
        block      => $block,
        blocks     => $blocks,
        _permitted => \%in_fields,
    };

    bless $self, $type;
} # end AppleII::ProDOS::Index::new

#---------------------------------------------------------------------
# Constructor for reading an existing index block:
#
# Input:
#   disk:   An AppleII::Disk
#   block:  The block number to read
#   count:  The number of blocks that are pointed to by this block
#           (optional; default is 256)

sub open
{
    my ($type, $disk, $block, $count) = @_;
    my $self = {};
    $self->{disk} = $disk;
    $self->{block} = $block;
    $self->{'_permitted'} = \%in_fields;

    bless $self, $type;
    $self->read_disk($count);
    $self;
} # end AppleII::ProDOS::Index::open

#---------------------------------------------------------------------
# Read contents of index block from disk:
#
# Input:
#   count:
#     The number of blocks that are pointed to by this block
#     (optional; default is 256)

sub read_disk
{
    my ($self, $count) = @_;
    $count = 0x100 unless $count;
    my @dataLo = unpack('C*',$self->{disk}->read_block($self->{block}));
    my @dataHi = splice @dataLo, 0x100;
    my @blocks;

    while (--$count >= 0) {
        push @blocks, shift(@dataLo) + 0x100 * shift(@dataHi);
    }

    $self->{blocks} = \@blocks;
} # end AppleII::ProDOS::Index::read_disk

#---------------------------------------------------------------------
# Write index block to disk:

sub write_disk
{
    my $self = shift;
    my $disk = $self->{disk};

    my ($dataLo, $dataHi);
    $dataLo = $dataHi = pack('v*',@{$self->{blocks}});
    $dataLo =~ s/(.)./$1/gs;    # Keep just the low byte
    $dataHi =~ s/.(.)/$1/gs;    # Keep just the high byte

    $disk->write_block($self->{block},
                       AppleII::Disk::pad_block($dataLo,"\0",0x100) . $dataHi,
                       "\0");
} # end AppleII::ProDOS::Index::write_disk

#=====================================================================
package AppleII::ProDOS::Members;
#
# Provides access functions for member variables.  This class is based
# on code from Tom Christiansen's FMTEYEWTK on OO Perl vs. C++.
#
# Only those member variables whose names are listed in the _permitted
# hash may be accessed.
#
# The value in the _permitted hash is used for validating the new
# value of a field.  The possible values are:
#   undef     No changes allowed (read-only)
#   CODE ref  Call CODE with our @_.  It returns true if OK.
#   scalar    New value must be an integer between 0 and _permitted
#---------------------------------------------------------------------

use Carp;

sub AUTOLOAD
{
    my $self = $_[0];
    my $type = ref($self) or croak("$self is not an object");
    my $name = our $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
    my $field = $name;
    $field =~ s/_([a-z])/\u$1/g; # squash underlines into mixed case
    unless (exists $self->{'_permitted'}{$field}) {
        # Ignore special methods like DESTROY:
        return undef if $name =~ /^[A-Z]+$/;
        croak("Can't access `$name' field in object of class $type");
    }
    if ($#_) {
        my $check = $self->{'_permitted'}{$field};
        my $ok;
        if (ref($check) eq 'CODE') {
            $ok = &$check;      # Pass our @_ to validator
        } elsif ($check) {
            $ok = ($_[1] =~ /^[0-9]+$/ and $_[1] >= 0 and $_[1] <= $check);
        } else {
            croak("Field `$name' of class $type is read-only");
        }
        return $self->{$field} = $_[1] if $ok;
        croak("Invalid value `$_[1]' for field `$name' of class $type");
    }
    return $self->{$field};
} # end AppleII::ProDOS::Members::AUTOLOAD

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

AppleII::ProDOS - Access files on Apple II ProDOS disk images

=head1 VERSION

This document describes version 0.201 of
AppleII::ProDOS, released September 12, 2015
as part of AppleII-LibA2 version 0.201.

=head1 SYNOPSIS

    use AppleII::ProDOS;
    my $vol = AppleII::ProDOS->open('image.dsk'); # Open an existing disk
    print $vol->catalog;                  # List files in volume directory
    my $file = $vol->get_file('Startup'); # Read file from disk
    $vol->path('Subdir');                 # Move into a subdirectory
    $vol->put_file($file);                # And write it back there

=head1 DESCRIPTION

C<AppleII::ProDOS> provides high-level access to ProDOS volumes stored
in the disk image files used by most Apple II emulators.  (For
information about Apple II emulators, try the Apple II Emulator Page
at L<http://www.ecnet.net/users/mumbv/pages/apple2.shtml>.)  It uses
the L<AppleII::Disk> module to handle low-level access to image files.

All the following classes have two constructors.  Constructors named
C<open> are for creating an object to represent existing data in the
image file.  Constructors named C<new> are for creating a new object
to be added to an image file.

=head2 C<AppleII::ProDOS>

C<AppleII::ProDOS> is the primary interface to ProDOS volumes.  It
provides the following methods:

=over 4

=item $vol = AppleII::ProDOS->new($volume, $size, $filename, [$mode])

Constructs a new image file and an C<AppleII::ProDOS> object to access
it.  C<$volume> is the volume name.  C<$size> is the size in blocks.
C<$filename> is the name of the image file.  The optional C<$mode> is
a string specifying how to open the image (see the C<open> method for
details).  You always receive read and write access.

=item $vol = AppleII::ProDOS->open($filename, [$mode])

Constructs an C<AppleII::ProDOS> object to access an existing image file.
C<$filename> is the name of the image file.  The optional C<$mode> is
a string specifying how to open the image.  It can consist of the
following characters (I<case sensitive>):

    r  Allow reads (this is actually ignored; you can always read)
    w  Allow writes
    d  Disk image is in DOS 3.3 order
    p  Disk image is in ProDOS order

=item $vol = AppleII::ProDOS->open($disk)

Constructs an C<AppleII::ProDOS> object to access an existing image file.
C<$disk> is the C<AppleII::Disk> object representing the image file.

=item $bitmap = $vol->bitmap

Returns the volume bitmap as an C<AppleII::ProDOS::Bitmap> object.

=item $dir = $vol->dir

Returns the current directory as an AppleII::ProDOS::Directory object.

=item $disk = $vol->disk

Returns the C<AppleII::ProDOS::Disk> object which represents the image
file.

=item $disk = $vol->disk_size

Returns the size of the volume in blocks.  This is the logical size of
the ProDOS volume, which is not necessarily the same as the actual
size of the image file.

=item $name = $vol->name

Returns the volume name.

=item $path = $vol->path([$newpath])

Gets or sets the current path.  C<$newpath> is the new pathname, which
may be either relative or absolute.  `..' may be used to specify the
parent directory, but this must occur at the beginning of the path
(`../../dir' is valid, but `../dir/..' is not).
If C<$newpath> is omitted, then the current path is not changed.
Returns the current path as a string beginning and ending with C</>.

=item $catalog = $vol->catalog

=item $file = $vol->get_file($filename)

=item $entry = $vol->new_dir($name)

=item $vol->put_file($file)

These methods are passed to the current directory.  See
C<AppleII::ProDOS::Directory> for details.

=back

=head2 C<AppleII::ProDOS::Directory>

C<AppleII::ProDOS::Directory> represents a ProDOS directory. It
provides the following methods:

=over 4

=item $dir = AppleII::ProDOS::Directory->new($name, $disk, $blocks, $bitmap, [$parent, $parentNum])

Constructs a new C<AppleII::ProDOS::Directory> object.
C<$name> is the name of the directory.  C<$disk> is the
C<AppleII::Disk> to create it on.  C<$blocks> is a block number or an
array of block numbers to store the directory in.  C<$bitmap> is the
C<AppleII::ProDOS::Bitmap> representing the volume bitmap.  For a
subdirectory, C<$parent> must be the block number in the parent
directory where the subdirectory is listed, and C<$parentNum> is the
entry number in that block (with 1 being the first entry).

=item $dir = AppleII::ProDOS->open($disk, $block, $bitmap)

Constructs an C<AppleII::ProDOS::Directory> object to access an
existing directory in the image file.  C<$disk> is the
C<AppleII::Disk> object representing the image file.  C<$block> is the
block number where the directory begins.  C<$bitmap> is the
C<AppleII::ProDOS::Bitmap> representing the volume bitmap.

=item $catalog = $dir->catalog

Returns the directory listing in ProDOS format with free space information.

=item @entries = $dir->entries

Returns the contents of the directory as a list of
C<AppleII::ProDOS::DirEntry> objects.

=item $entry = $dir->find_entry($filename)

Returns the C<AppleII::ProDOS::DirEntry> object for C<$filename>, or
undef if the specified file does not exist.

=item $file = $dir->get_file($filename)

Retrieves a file from the directory.  C<$filename> may be either a
filename or an C<AppleII::ProDOS::DirEntry> object.  Returns a new
C<AppleII::ProDOS::File> object.

=item @entries = $dir->list_matches($pattern, [$filter])

Returns a list of the C<AppleII::ProDOS::DirEntry> objects matching
the regexp C<$pattern>.  If C<$filter> is specified, it is either a
subroutine reference or one of the strings 'DIR' or '!DIR'.  'DIR'
matches only directories, and '!DIR' matches only regular files.  If
C<$filter> is a subroutine, it is called (as C<\&$filter($entry)>) for
each entry.  It should return true if the entry is acceptable (the
entry's name must still match C<$pattern>).  Returns the null list if
there are no matching entries.

=item $entry = $dir->new_dir($name)

Creates a new subdirectory in the directory.  C<$name> is the name of
the new subdirectory.  Returns the C<AppleII::ProDOS::DirEntry> object
representing the new subdirectory entry.

=item $entry = $dir->open_dir($dirname)

Opens a subdirectory of the directory.  C<$dirname> may be either a
subdirectory name or an C<AppleII::ProDOS::DirEntry> object.  Returns
a new C<AppleII::ProDOS::Directory> object.

=item $dir->put_file($file)

Stores a file in the directory.  C<$file> must be an
C<AppleII::ProDOS::File> object.

=item $dir->add_entry($entry)

Adds a new entry to the directory.  C<$entry> is an
C<AppleII::ProDOS::DirEntry> object.

=item $dir->read_disk

Rereads the directory contents from the image file.  You can use this
to undo changes to a directory before they have been written to the
image file.

=item $dir->write_disk

Writes the current directory contents to the image file.  You must use
this if you alter the directory contents in any way except the
high-level methods C<new_dir> and C<put_file>, which do this
automatically.

=back

=head2 C<AppleII::ProDOS::DirEntry>

C<AppleII::ProDOS::DirEntry> provides access to directory entries.
It provides the following methods:

=over 4

=item $entry = AppleII::ProDOS::DirEntry->new([$num, $entry])

Constructs a new C<AppleII::ProDOS::DirEntry> object.
C<$num> is the entry number in the directory, and C<$entry> is the
packed directory entry.  If C<$num> and C<$entry> are omitted, then a
blank directory entry is created.  This is a low-level function; you
shouldn't need to explicitly construct DirEntry objects.

=item $packed_entry = $entry->packed($key_block)

Return the directory entry in packed format.  C<$key_block> is the
starting block number of the directory containing this entry.

=item $access = $entry->access([$new])

Gets or sets the access attributes.  This is a bitfield with the
following entries:

    0x80  File can be deleted
    0x40  File can be renamed
    0x20  File has changed since last backup
    0x02  File can be written to
    0x01  File can be read

Normal values are 0xC3 or 0xE3 for an unlocked file, and 0x01 for a
locked file.

=item $auxtype = $entry->auxtype([$new])

Gets or sets the auxiliary type.  This is a number between 0x0000 and
0xFFFF.  Its meaning depends on the filetype.

=item $creation_date = $entry->created([$date])

Gets or sets the creation date and time in ProDOS format.

=item $modification_date = $entry->modified([$date])

Gets or sets the modification date and time in ProDOS format.

=item $name = $entry->name([$new])

Gets or sets the filename.

=item $type = $entry->type([$new])

Gets or sets the filetype.  This is a number between 0x00 and 0xFF.
Use C<parse_type> to convert it to a more meaningful abbreviation.

=item $type = $entry->short_type
Returns the standard abbreviation for the filetype.  It is equivalent
to calling C<AppleII::ProDOS::parse_type($entry-E<gt>type)>.

=back

The following methods allow access to read-only fields.  They can be
used to initialize a DirEntry object created with C<new>, but raise an
exception if the field already has a value.

=over 4

=item $block = $entry->block([$new])

Gets or sets the key block for the file.

=item $used = $entry->blks_used([$new])

Gets or sets the number of blocks used by the file.

=item $entry_num = $entry->num([$new])

Gets or sets the entry number in the directory.

=item $size = $entry->size([$new])

Gets or sets the size of the file in bytes.

=item $storage = $entry->storage([$new])

Gets or sets the storage type.

=back

=head1 NOTE

This is the point where I ran out of steam in documentation
writing. :-)  If I get at least one email from someone who'd actually
read the rest of this documentation, I'll try to finish it.

=head2 C<AppleII::ProDOS::File>

C<AppleII::ProDOS::File> represents a file's data and other attributes.

=head2 C<AppleII::ProDOS::Bitmap>

C<AppleII::ProDOS::Bitmap> represents the volume bitmap.

=head2 C<AppleII::ProDOS::Index>

C<AppleII::ProDOS::Index> represents an index block.

=head1 CONFIGURATION AND ENVIRONMENT

AppleII::ProDOS requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

=over 4

=item *

This document isn't finished yet.  I haven't been working on it
recently, so I decided I might as well just release what I have.  If
somebody writes me, I'm more likely to finish.  (That's a hint, folks.)

=item *

Mixed case filenames (ala GS/OS) are not supported.  All filenames are
converted to upper case.

=back

=for Pod::Coverage
^a2_croak$
TODO: documentation unfinished
^pack_date$
^pack_name$
^parse_date$
^parse_name$
^parse_type$
^shell_wc$
^short_date$
^unpack_date$
^valid_date$
^valid_name$

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-AppleII-LibA2 AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=AppleII-LibA2 >>.

You can follow or contribute to AppleII-LibA2's development at
L<< https://github.com/madsen/perl-libA2 >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
