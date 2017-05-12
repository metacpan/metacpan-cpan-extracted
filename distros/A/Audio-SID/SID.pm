package Audio::SID;

require 5;

use Carp;
use strict;
use vars qw($VERSION);
use FileHandle;
use Digest::MD5;
use Encode;

$VERSION = "3.11";

# These are the recognized field names for a SID file. They must appear in
# the order they appear in a SID file.
my (@SIDfieldNames) = qw(magicID version dataOffset loadAddress initAddress
                          playAddress songs startSong speed title author
                          released flags startPage pageLength reserved data);

# Additional data stored in the class that are not part of the SID file
# format are: FILESIZE, FILENAME, and the implicit REAL_LOAD_ADDRESS.
#
# PADDING is used to hold any extra bytes that may be between the standard
# SID header and the data (usually happens when dataOffset is more than
# 0x007C).

# Constants for individual fields inside 'flags'.
my $MUSPLAYER_OFFSET = 0; # Bit 0.
my $PLAYSID_OFFSET   = 1; # Bit 1. (PSID v2NG only)
my $C64BASIC_OFFSET  = 1; # Bit 1. (RSID only)
my $CLOCK_OFFSET     = 2; # Bits 2-3.
my $SIDMODEL_OFFSET  = 4; # Bits 4-5.

sub new {
    my $type = shift;
    my %params = @_;
    my $class = ref($type) || $type;
    my $self = {};

    bless ($self, $class);

    $self->initialize();

    $self->{validateWrite} = 0;

    if (defined($_[0])) {
        # Read errors are taken care of by read().
        return ($self->read(%params) ? $self : undef);
    }

    return $self;
}

sub initialize() {
    my ($self) = $_[0];

    # Initial SID data.
    $self->{SIDdata} = {
        magicID => 'PSID',
        version => 2,
        dataOffset => 0x7C,
        loadAddress => 0,
        initAddress => 0,
        playAddress => 0,
        songs => 1,
        startSong => 1,
        speed => 0,
        title => '<?>',
        author => '<?>',
        released => '20?? <?>',
        flags => 0,
        startPage => 0,
        pageLength => 0,
        reserved => 0,
        data => '',
    };

    $self->{PADDING} = '';

    $self->{FILESIZE} = 0x7C;
    $self->{FILENAME} = '';
}

sub read {
    my $self = shift;
    my $filename;
    my $filedata;
    my $hdr;
    my $i;
    my ($size, $totsize);
    my $data;
    my $FH;
    my ($SID, $version, $dataOffset);
    my @hdr;
    my $hdrlength;

    # Check parameters.

    if (($_[0] =~ /^\-filedata$/i) and defined($_[1])) {
        $filedata = $_[1];
    }
    elsif (($_[0] =~ /^\-file(name)|(handle)$/i) and defined($_[1])) {
        $filename = $_[1];
    }
    elsif (defined($_[0]) and !defined($_[1])) {
        $filename = $_[0];
    }
    elsif (defined($_[0])) {
        confess("Unknown parameter '$_[0]'!");
        $self->initialize();
        return undef;
    }

    unless (defined($filedata)) {
        # Either a scalar filename (or nothing) was passed in, in which case
        # we'll open it, or a filehandle was passed in, in which case we just
        # skip the following step.

        if (ref(\$filename) ne "GLOB") {

            $filename = $self->{FILENAME} unless (defined($filename));

            unless ($filename) {
                confess("No filename was specified");
                $self->initialize();
                return undef;
            }

            unless ($FH = new FileHandle ("< $filename")) {
                confess("Error opening $filename");
                $self->initialize();
                return undef;
            }
        }
        else {
            $FH = $filename;
        }

        # Just to make sure...
        binmode $FH;
        seek($FH,0,0);

        $size = read ($FH, $hdr, 8);
    }
    else {
        $hdr = substr($filedata, 0, 8);
        $size = length($hdr);
    }

    unless ($size) {
#        confess("Error reading $filename");
        $self->initialize();
        return undef;
    }

    $totsize += $size;

    ($SID, $version, $dataOffset) = unpack ("A4nn", $hdr);

    unless ( (($SID eq 'PSID') and (($version == 1) or ($version == 2))) or
            (($SID eq 'RSID') and ($version == 2)) ) {
        # Not a valid SID file recognized by this class.
#        confess("File $filename is not a valid SID file");
        $self->initialize();
        return undef;
    }

    # Valid SID file.

    $self->{SIDdata}{magicID} = $SID;
    $self->{SIDdata}{version} = $version;
    $self->{SIDdata}{dataOffset} = $dataOffset;

    # Slurp up the rest of the header.
    unless (defined($filedata)) {
        $size = read ($FH, $hdr, $dataOffset-8);
    }
    else {
        $hdr = substr($filedata, 8, $dataOffset-8);
        $size = length($hdr);
    }

    # If the header is not as big as indicated by the dataOffset,
    # we have a problem.
    if ($size != ($dataOffset-8)) {
#        confess("Error reading $filename - incorrect header");
        $self->initialize();
        return undef;
    }

    $totsize += $size;

    $hdrlength = 2*5+4+32*3;
    (@hdr) = unpack ("nnnnnNA32A32A32", substr($hdr,0,$hdrlength));

    if ($version > 1) {
        my @temphdr;
        # SID v2 has 4 more fields.
        (@temphdr) = unpack ("nCCn", substr($hdr,$hdrlength,2+1+1+2));
        push (@hdr, @temphdr);
        $hdrlength += 2+1+1+2;
    }
    else {
        # SID v1 doesn't have these fields.
        $self->{SIDdata}{flags} = undef;
        $self->{SIDdata}{startPage} = undef;
        $self->{SIDdata}{pageLength} = undef;
        $self->{SIDdata}{reserved} = undef;
    }

    # Store header info.
    for ($i=0; $i <= $#hdr; $i++) {
        $self->{SIDdata}{$SIDfieldNames[$i+3]} = $hdr[$i];
    }

    # Put the rest into PADDING. This might put nothing in it!
    $self->{PADDING} = substr($hdr,$hdrlength);

    # Read the C64 data - can't be more than 64KB + 2 bytes load address.
    unless (defined($filedata)) {
        $size = read ($FH, $data, 65536+2);
    }
    else {
        $data = substr($filedata, $dataOffset);
        $size = length($data);
    }

    # We allow a 0 length data.
    unless (defined($size)) {
#        confess("Error reading $filename");
        $self->initialize();
        return undef;
    }

    $totsize += $size;

    if ((ref(\$filename) ne "GLOB") and !defined($filedata)) {
        $FH->close();
        $self->{FILENAME} = $filename;
    }

    $self->{SIDdata}{data} = $data;

    $self->{FILESIZE} = $totsize;

    return 1;
}

sub write {
    my $self = shift;
    my $filename;
    my $output;
    my @hdr;
    my $i;
    my $FH;

    # Check parameters.

    if (($_[0] =~ /^\-file(name)|(handle)$/i) and defined($_[1])) {
        $filename = $_[1];
    }
    elsif (defined($_[0]) and !defined($_[1])) {
        $filename = $_[0];
    }
    elsif (defined($_[0])) {
        confess("Unknown parameter '$_[0]'!");
        $self->initialize();
        return undef;
    }

    # Either a scalar filename (or nothing) was passed in, in which case
    # we'll open it, or a filehandle was passed in, in which case we just
    # skip the following step.

    if (ref(\$filename) ne "GLOB") {
        $filename = $self->{FILENAME} unless (defined($filename));

        unless ($filename) {
            confess("No filename was specified");
            return undef;
        }

        unless ($FH = new FileHandle ("> $filename")) {
            confess("Couldn't write $filename");
            return undef;
        }
    }
    else {
        $FH = $filename;
    }

    # Just to make sure...
    binmode $FH;
    seek($FH,0,0);

    if ($self->{validateWrite}) {
        $self->validate();
    }

    # SID files use ISO 8859-1 encoding for textual fields, not Unicode.
    foreach (qw/title author released/) {
        $self->{SIDdata}{$_} = encode("latin1", $self->{SIDdata}{$_});
    }

    for ($i=0; $i <= 11; $i++) {
        $hdr[$i] = $self->{SIDdata}{$SIDfieldNames[$i]};
    }

    $output = pack ("A4nnnnnnnNA32A32A32", @hdr);

    print $FH $output;

    # SID version 2 has 4 more fields.
    if ($self->{SIDdata}{version} > 1) {
        $output = pack ("nCCn", ($self->{SIDdata}{flags}, $self->{SIDdata}{startPage}, $self->{SIDdata}{pageLength}, $self->{SIDdata}{reserved}));
        print $FH $output;
    }

    print $FH $self->{PADDING};

    print $FH $self->{SIDdata}{data};

    if (ref(\$filename) ne "GLOB") {
        $FH->close();
    }
}

# Notice that if no specific fieldname is given and we are in array/hash
# context, all fields are returned!
sub get {
    my ($self, $fieldname) = @_;
    my %SIDhash;
    my $field;

    foreach $field (keys %{$self->{SIDdata}}) {
        $SIDhash{$field} = $self->{SIDdata}{$field};
    }

    # Strip off trailing NULLs.
    $SIDhash{title} =~ s/\x00*$//;
    $SIDhash{author} =~ s/\x00*$//;
    $SIDhash{released} =~ s/\x00*$//;

    return unless (defined(wantarray()));

    unless (defined($fieldname)) {
        # No specific fieldname is given. Assume user wants a hash of
        # field values.
        if (wantarray()) {
            return %SIDhash;
        }
        else {
            confess ("Nothing to get, not in array context");
            return undef;
        }
    }

    # Backwards compatibility.
    $fieldname = "released" if ($fieldname =~ /^copyright$/);
    $fieldname = "title" if ($fieldname =~ /^name$/);

    unless (grep(/^$fieldname$/, @SIDfieldNames)) {
        confess ("No such fieldname: $fieldname");
        return undef;
    }

    return $SIDhash{$fieldname};
}

sub getFileName {
    my $self = shift;

    return $self->{FILENAME};
}

sub getFileSize {
    my $self = shift;

    return $self->{FILESIZE};
}

sub getRealLoadAddress {
    my $self = shift;
    my $REAL_LOAD_ADDRESS;

    # It's a read-only "implicit" field, so we just calculate it
    # on the fly.
    if ($self->{SIDdata}{data} and $self->{SIDdata}{loadAddress} == 0) {
        $REAL_LOAD_ADDRESS = unpack("v", substr($self->{SIDdata}{data}, 0, 2));
    }
    else {
        $REAL_LOAD_ADDRESS = $self->{SIDdata}{loadAddress};
    }

    return $REAL_LOAD_ADDRESS;
}

sub getSpeed($) {
    my ($self, $songnumber) = @_;

    $songnumber = 1 if ((!defined($songnumber)) or ($songnumber < 1));

    if ($songnumber > $self->{SIDdata}{songs}) {
        confess ("Song number '$songnumber' is invalid!");
        return undef;
    }

    $songnumber = 32 if ($songnumber > 32);

    return (($self->{SIDdata}{speed} >> ($songnumber-1)) & 0x1);
}

sub getMUSPlayer {
    my $self = shift;

    return undef unless (defined($self->{SIDdata}{flags}));

    return (($self->{SIDdata}{flags} >> $MUSPLAYER_OFFSET) & 0x1);
}

sub isMUSPlayerRequired {
    my $self = shift;

    return $self->getMUSPlayer();
}

sub getPlaySID {
    my $self = shift;

	# This is a PSID v2NG specific flag.
    return undef unless (defined($self->{SIDdata}{flags}));
    return undef if ($self->isRSID() );

    return (($self->{SIDdata}{flags} >> $PLAYSID_OFFSET) & 0x1);
}

sub isPlaySIDSpecific {
    my $self = shift;

    return $self->getPlaySID();
}

sub isRSID {
    my $self = shift;

    return ($self->{SIDdata}{magicID} eq 'RSID');
}

sub getC64BASIC {
    my $self = shift;

	# This is an RSID specific flag.
    return undef unless (defined($self->{SIDdata}{flags}));
    return undef unless ($self->isRSID() );

    return (($self->{SIDdata}{flags} >> $C64BASIC_OFFSET) & 0x1);
}

sub isC64BASIC {
    my $self = shift;

    return $self->getC64BASIC();
}

sub getClock {
    my $self = shift;

    return undef unless (defined($self->{SIDdata}{flags}));

    return (($self->{SIDdata}{flags} >> $CLOCK_OFFSET) & 0x3);
}

sub getClockByName {
    my $self = shift;
    my $clock;

    return undef unless (defined($self->{SIDdata}{flags}));

    $clock = $self->getClock();

    if ($clock == 0) {
        $clock = 'UNKNOWN';
    }
    elsif ($clock == 1) {
        $clock = 'PAL';
    }
    elsif ($clock == 2) {
        $clock = 'NTSC';
    }
    elsif ($clock == 3) {
        $clock = 'EITHER';
    }

    return $clock;
}

sub getSIDModel {
    my $self = shift;

    return undef unless (defined($self->{SIDdata}{flags}));

    return (($self->{SIDdata}{flags} >> $SIDMODEL_OFFSET) & 0x3);
}

sub getSIDModelByName {
    my $self = shift;
    my $SIDModel;

    return undef unless (defined($self->{SIDdata}{flags}));

    $SIDModel = $self->getSIDModel();

    if ($SIDModel == 0) {
        $SIDModel = 'UNKNOWN';
    }
    elsif ($SIDModel == 1) {
        $SIDModel = '6581';
    }
    elsif ($SIDModel == 2) {
        $SIDModel = '8580';
    }
    elsif ($SIDModel == 3) {
        $SIDModel = 'EITHER';
    }

    return $SIDModel;
}

# Notice that you have to pass in a hash (field-value pairs)!
sub set(@) {
    my ($self, %SIDhash) = @_;
    my $fieldname;
    my $paddinglength;
    my $i;
    my $version;
    my $offset;
	my $changePSIDSpecific = 0;

    foreach $fieldname (keys %SIDhash) {

        # Backwards compatibility.
        $fieldname = "released" if ($fieldname =~ /^copyright$/);
        $fieldname = "title" if ($fieldname =~ /^name$/);

        unless (grep(/^$fieldname$/, @SIDfieldNames)) {
            confess ("No such fieldname: $fieldname");
            next;
        }

        # Do some basic sanity checking.

        if ($fieldname eq 'magicID') {
            if (($SIDhash{$fieldname} ne 'PSID') and ($SIDhash{$fieldname} ne 'RSID')) {
                confess ("Unrecognized magicID: $SIDhash{$fieldname}");
                next;
            }

			if ($SIDhash{$fieldname} ne $self->{SIDdata}{magicID}) {
				$changePSIDSpecific = 1;
			}
        }

        if ($fieldname eq 'version') {
            if (($SIDhash{$fieldname} != 1) and ($SIDhash{$fieldname} != 2)) {
                confess ("Invalid SID version number '$version' - ignored");
                next;
            }
        }

        if (($self->{SIDdata}{version} < 2) and
            (($fieldname eq 'magicID') or ($fieldname eq 'flags') or ($fieldname eq 'reserved') or
             ($fieldname eq 'startPage') or ($fieldname eq 'pageLength'))) {

            confess ("Can't change '$fieldname' when SID version is set to 1");
            next;
        }

        # SID files use ISO 8859-1 encoding for textual fields, not Unicode.
        if (($fieldname eq 'title') or ($fieldname eq 'author') or ($fieldname eq 'released')) {
            $SIDhash{$fieldname} = encode("latin1", $SIDhash{$fieldname});
        }

        $self->{SIDdata}{$fieldname} = $SIDhash{$fieldname};
    }

    if ($self->{SIDdata}{version} == 1) {
        # PSID v1 values are set in stone.
        $self->{SIDdata}{magicID} = 'PSID';
        $self->{SIDdata}{version} = 1;
        $self->{SIDdata}{dataOffset} = 0x76;
        $self->{SIDdata}{flags} = undef;
        $self->{SIDdata}{startPage} = undef;
        $self->{SIDdata}{pageLength} = undef;
        $self->{SIDdata}{reserved} = undef;
        $self->{PADDING} = '';
    }
    elsif ($self->{SIDdata}{version} == 2) {
        # In PSID v2NG/RSID we allow dataOffset to be larger than 0x7C.

        $self->{PADDING} = '';

        if ($self->{SIDdata}{dataOffset} <= 0x7C) {
            $self->{SIDdata}{dataOffset} = 0x7C;
        }
        else {
            $paddinglength = $self->{SIDdata}{dataOffset} - 0x7C;

            # Add as many zeroes as necessary.
            for ($i=1; $i <= $paddinglength; $i++) {
                $self->{PADDING} .= pack("C", 0x00);
            }
        }

        # Make sure these are not undef'd.
        unless (defined($self->{SIDdata}{flags})) {
            $self->{SIDdata}{flags} = 0;
        }

        unless (defined($self->{SIDdata}{startPage})) {
            $self->{SIDdata}{startPage} = 0;
        }

        unless (defined($self->{SIDdata}{pageLength})) {
            $self->{SIDdata}{pageLength} = 0;
        }

        unless (defined($self->{SIDdata}{reserved})) {
            $self->{SIDdata}{reserved} = 0;
        }

		if ($changePSIDSpecific) {
			# Zero this flag only if 'flags' is not explicitly set at the same time.
			if (!$SIDhash{'flags'}) {
				if ($self->isRSID() ) {
	            	$self->setC64BASIC(0);
				}
				else {
	            	$self->setPlaySID(0);
				}
			}
		}

        # RSID values are set in stone.
        if ($self->isRSID() ) {
            $self->{SIDdata}{playAddress} = 0;
            $self->{SIDdata}{speed} = 0;

            # The preferred way is for loadAddress to be 0. The data is
            # prepended by those 2 bytes if it needs to be changed.

            if ($self->{SIDdata}{loadAddress} != 0) {
                $self->{SIDdata}{data} = pack("v", $self->{SIDdata}{loadAddress}) . $self->{SIDdata}{data};
                $self->{SIDdata}{loadAddress} = 0;
            }

			# initAddress must be 0 if the C64 BASIC flag is set.
			if ($self->getC64BASIC() ) {
				$self->{SIDdata}{initAddress} = 0;
			}
        }
    }

    $self->{FILESIZE} = $self->{SIDdata}{dataOffset} + length($self->{PADDING}) +
        length($self->{SIDdata}{data});

    return 1;
}

sub setFileName($) {
    my ($self, $filename) = @_;

    $self->{FILENAME} = $filename;
}

sub setSpeed($$) {
    my ($self, $songnumber, $value) = @_;

    unless (defined($songnumber)) {
        confess ("No song number was specified!");
        return undef;
    }

    unless (defined($value)) {
        confess ("No speed value was specified!");
        return undef;
    }

    if (($songnumber > $self->{SIDdata}{songs}) or ($songnumber < 1)) {
        confess ("Song number '$songnumber' is invalid!");
        return undef;
    }

    if (($value ne 0) and ($value ne 1)) {
        confess ("Specified value '$value' is invalid!");
        return undef;
    }

    $songnumber = 32 if ($songnumber > 32);
    $songnumber = 1 if ($songnumber < 1);

    # First, clear the bit in question.
    $self->{SIDdata}{speed} &= ~(0x1 << ($songnumber-1));

    # Then set it.
    $self->{SIDdata}{speed} |= ($value << ($songnumber-1));
}

sub setMUSPlayer($) {
    my ($self, $MUSplayer) = @_;

    unless (defined($self->{SIDdata}{flags})) {
        confess ("Cannot set this field when SID version is 1!");
        return undef;
    }

    if (($MUSplayer ne 0) and ($MUSplayer ne 1)) {
        confess ("Specified value '$MUSplayer' is invalid!");
        return undef;
    }

    # First, clear the bit in question.
    $self->{SIDdata}{flags} &= ~(0x1 << $MUSPLAYER_OFFSET);

    # Then set it.
    $self->{SIDdata}{flags} |= ($MUSplayer << $MUSPLAYER_OFFSET);
}

sub setPlaySID($) {
    my ($self, $PlaySID) = @_;

    if ($self->isRSID() ) {
        confess ("Cannot set this field for RSID!");
        return undef;
    }

    unless (defined($self->{SIDdata}{flags})) {
        confess ("Cannot set this field when SID version is 1!");
        return undef;
    }

    if (($PlaySID ne 0) and ($PlaySID ne 1)) {
        confess ("Specified value '$PlaySID' is invalid!");
        return undef;
    }

    # First, clear the bit in question.
    $self->{SIDdata}{flags} &= ~(0x1 << $PLAYSID_OFFSET);

    # Then set it.
    $self->{SIDdata}{flags} |= ($PlaySID << $PLAYSID_OFFSET);
}

sub setC64BASIC($) {
    my ($self, $C64BASIC) = @_;

    unless ($self->isRSID() ) {
        confess ("Cannot set this field for PSID!");
        return undef;
    }

    unless (defined($self->{SIDdata}{flags})) {
        confess ("Cannot set this field when SID version is 1!");
        return undef;
    }

    if (($C64BASIC ne 0) and ($C64BASIC ne 1)) {
        confess ("Specified value '$C64BASIC' is invalid!");
        return undef;
    }

    # First, clear the bit in question.
    $self->{SIDdata}{flags} &= ~(0x1 << $C64BASIC_OFFSET);

    # Then set it.
    $self->{SIDdata}{flags} |= ($C64BASIC << $C64BASIC_OFFSET);

	if ($C64BASIC) {
		$self->{SIDdata}{initAddress} = 0;
	}
}

sub setClock($) {
    my ($self, $clock) = @_;

    unless (defined($self->{SIDdata}{flags})) {
        confess ("Cannot set this field when SID version is 1!");
        return undef;
    }

    if (($clock < 0) or ($clock > 3)) {
        confess ("Specified value '$clock' is invalid!");
        return undef;
    }

    # First, clear the bits in question.
    $self->{SIDdata}{flags} &= ~(0x3 << $CLOCK_OFFSET);

    # Then set them.
    $self->{SIDdata}{flags} |= ($clock << $CLOCK_OFFSET);
}

sub setClockByName($) {
    my ($self, $clock) = @_;

    unless (defined($self->{SIDdata}{flags})) {
        confess ("Cannot set this field when SID version is 1!");
        return undef;
    }

    if ($clock =~ /^(unknown|none|neither)$/i) {
        $clock = 0;
    }
    elsif ($clock =~ /^PAL$/i) {
        $clock = 1;
    }
    elsif ($clock =~ /^NTSC$/i) {
        $clock = 2;
    }
    elsif ($clock =~ /^(any|both|either)$/i) {
        $clock = 3;
    }
    else {
        confess ("Specified value '$clock' is invalid!");
        return undef;
    }

    $self->setClock($clock);
}

sub setSIDModel($) {
    my ($self, $SIDModel) = @_;

    unless (defined($self->{SIDdata}{flags})) {
        confess ("Cannot set this field when SID version is 1!");
        return undef;
    }

    if (($SIDModel < 0) or ($SIDModel > 3)) {
        confess ("Specified value '$SIDModel' is invalid!");
        return undef;
    }

    # First, clear the bits in question.
    $self->{SIDdata}{flags} &= ~(0x3 << $SIDMODEL_OFFSET);

    # Then set them.
    $self->{SIDdata}{flags} |= ($SIDModel << $SIDMODEL_OFFSET);
}

sub setSIDModelByName($) {
    my ($self, $SIDModel) = @_;

    unless (defined($self->{SIDdata}{flags})) {
        confess ("Cannot set this field when SID version is 1!");
        return undef;
    }

    if ($SIDModel =~ /^(unknown|none|neither)$/i) {
        $SIDModel = 0;
    }
    elsif (($SIDModel =~ /^6581$/) or ($SIDModel == 6581)) {
        $SIDModel = 1;
    }
    elsif (($SIDModel =~ /^8580$/i) or ($SIDModel == 8580)) {
        $SIDModel = 2;
    }
    elsif ($SIDModel =~ /^(any|both|either)$/i) {
        $SIDModel = 3;
    }
    else {
        confess ("Specified value '$SIDModel' is invalid!");
        return undef;
    }

    $self->setSIDModel($SIDModel);
}

sub getFieldNames {
    my $self = shift;
    my (@SIDfields) = @SIDfieldNames;

    return (@SIDfields);
}

sub getMD5 {
    my ($self, $oldMD5) = @_;

    my $md5 = Digest::MD5->new;

    if (($self->{SIDdata}{loadAddress} == 0) and $self->{SIDdata}{data}) {
        $md5->add(substr($self->{SIDdata}{data},2));
    }
    else {
        $md5->add($self->{SIDdata}{data});
    }

    $md5->add(pack("v", $self->{SIDdata}{initAddress}));
    $md5->add(pack("v", $self->{SIDdata}{playAddress}));

    my $songs = $self->{SIDdata}{songs};
    $md5->add(pack("v", $songs));

    my $speed = $self->{SIDdata}{speed};

    for (my $i=0; $i < $songs; $i++) {
        my $speedFlag;
        if ( (($speed & (1 << $i)) != 0) or ($self->isRSID() ) ) {
            $speedFlag = 60;
        }
        else {
            $speedFlag = 0;
        }
        $md5->add(pack("C",$speedFlag));
    }

    my $clock = $self->getClock();

    if (($self->{SIDdata}{version} > 1) and ($clock == 2) and !$oldMD5) {
        $md5->add(pack("C",$clock));
    }

    return ($md5->hexdigest);
}

sub alwaysValidateWrite($) {
    my ($self, $setting) = @_;

    $self->{validateWrite} = $setting;
}

sub validate {
    my $self = shift;
    my $field;
    my $MUSPlayer;
    my $PlaySID;
	my $C64BASIC;
    my $clock;
    my $SIDModel;

    # Change to version v2.
    if ($self->{SIDdata}{version} < 2) {
#        carp ("Changing SID to v2");
        $self->{SIDdata}{version} = 2;
    }

    if ($self->isRSID() ) {
        $self->{SIDdata}{playAddress} = 0;
        $self->{SIDdata}{speed} = 0;
    }

    if ($self->{SIDdata}{dataOffset} != 0x7C) {
        $self->{SIDdata}{dataOffset} = 0x7C;
#        carp ("'dataOffset' was not 0x007C - set to 0x007C");
    }

    # Sanity check the fields.

    # Textual fields can't be longer than 31 chars.
    foreach $field (qw(title author released)) {

        # Strip trailing whitespace.
        $self->{SIDdata}{$field} =~ s/\s+$//;

        # Convert to ISO 8859-1 ASCII.
        $self->{SIDdata}{$field} = encode("latin1", $self->{SIDdata}{$field});

        # Take off any superfluous null-padding.
        $self->{SIDdata}{$field} =~ s/\x00+$//;

        if (length($self->{SIDdata}{$field}) > 31) {
            $self->{SIDdata}{$field} = substr($self->{SIDdata}{$field}, 0, 31);
#            carp ("'$field' field was longer than 31 chars - chopped to 31");
        }
    }

    # If this is an RSID, initAddress shouldn't be pointing to a ROM memory
    # area, or be outside the load range. Also, if the C64 BASIC flag is set,
	# initAddress must be 0.

    if ( ($self->isRSID() ) and
         ( ((($self->{SIDdata}{initAddress} > 0) and ($self->{SIDdata}{initAddress} < 0x07E8)) or
            (($self->{SIDdata}{initAddress} >= 0xA000) and ($self->{SIDdata}{initAddress} < 0xC000)) or
            (($self->{SIDdata}{initAddress} >= 0xD000) and ($self->{SIDdata}{initAddress} <= 0xFFFF)) or
             ($self->{SIDdata}{initAddress} < $self->getRealLoadAddress()) or
             ($self->{SIDdata}{initAddress} > ($self->getRealLoadAddress() + length($self->{SIDdata}{data}) - 3))
           ) or
		   ($self->getC64BASIC() )
          )
       ) {

        $self->{SIDdata}{initAddress} = 0;

#        carp ("'initAddress' was invalid - set to 0");
    }

    # The preferred way is for loadAddress to be 0. It also shouldn't be less
    # than 0x07E8 in RSID files. The data is prepended by those 2 bytes if it
    # needs to be changed.

    if ($self->{SIDdata}{loadAddress} != 0) {

        # Load address must not be less than 0x07E8 in RSID files.
        if (($self->isRSID() ) and
            ($self->{SIDdata}{loadAddress} < 0x07E8) ) {

            $self->{SIDdata}{loadAddress} = 0x07E8;
        }

        $self->{SIDdata}{data} = pack("v", $self->{SIDdata}{loadAddress}) . $self->{SIDdata}{data};
        $self->{SIDdata}{loadAddress} = 0;
#        carp ("'loadAddress' was non-zero - set to 0");
    }
    elsif (($self->isRSID() ) and
           ($self->getRealLoadAddress() < 0x07E8) ) {

        $self->{SIDdata}{data} = pack("v", 0x07E8) . substr($self->{SIDdata}{data}, 2);
    }

    # If this is a PSID, initAddress shouldn't be outside the load range.

    if ( ($self->isRSID() ) and
         (($self->{SIDdata}{initAddress} < $self->getRealLoadAddress()) or
          ($self->{SIDdata}{initAddress} > ($self->getRealLoadAddress() + length($self->{SIDdata}{data}) - 3))
         )
       ) {

        $self->{SIDdata}{initAddress} = 0;

#        carp ("'initAddress' was invalid - set to 0");
    }

    # These fields should better be in the 0x0000-0xFFFF range!
    foreach $field (qw(loadAddress initAddress playAddress)) {
        if (($self->{SIDdata}{$field} < 0) or ($self->{SIDdata}{$field} > 0xFFFF)) {
#            confess ("'$field' value of $self->{SIDdata}{$field} is out of range");
            $self->{SIDdata}{$field} = 0;
        }
    }

    # These fields should better be in the 0x00-0xFF range!
    foreach $field (qw(startPage pageLength)) {
        if (!defined($self->{SIDdata}{$field}) or ($self->{SIDdata}{$field} < 0) or ($self->{SIDdata}{$field} > 0xFF)) {
#            confess ("'$field' value of $self->{SIDdata}{$field} is out of range");
            $self->{SIDdata}{$field} = 0;
        }
    }

    # This field's max is 256.
    if ($self->{SIDdata}{songs} > 256) {
        $self->{SIDdata}{songs} = 256;
#        carp ("'songs' was more than 256 - set to 256");
    }

    # This field's min is 1.
    if ($self->{SIDdata}{songs} < 1) {
        $self->{SIDdata}{songs} = 1;
#        carp ("'songs' was less than 1 - set to 1");
    }

    # If an invalid startSong is specified, set it to 1.
    if ($self->{SIDdata}{startSong} > $self->{SIDdata}{songs}) {
        $self->{SIDdata}{startSong} = 1;
#        carp ("Invalid 'startSong' field - set to 1");
    }

    unless ($self->isRSID() ) {
    	# Only the relevant fields in 'speed' will be set.
    	my $tempSpeed = 0;
    	my $maxSongs = $self->{SIDdata}{songs};

	    # There are only 32 bits in speed.
	    if ($maxSongs > 32) {
    	    $maxSongs = 32;
    	}

	    for (my $i=0; $i < $maxSongs; $i++) {
    	    $tempSpeed += ($self->{SIDdata}{speed} & (1 << $i));
    	}
    	$self->{SIDdata}{speed} = $tempSpeed;
	}

    unless (defined($self->{SIDdata}{flags})) {
        $self->{SIDdata}{flags} = 0;
    }
    else {
        # Only the relevant fields in 'flags' will be set.
        $MUSPlayer = $self->isMUSPlayerRequired();
        $clock = $self->getClock();
        $SIDModel = $self->getSIDModel();

		unless ($self->isRSID() ) {
        	$PlaySID = $self->isPlaySIDSpecific();
		}
		else {
        	$C64BASIC = $self->isC64BASIC();
		}

        $self->{SIDdata}{flags} = 0;

        $self->setMUSPlayer($MUSPlayer);
        $self->setClock($clock);
        $self->setSIDModel($SIDModel);

		unless ($self->isRSID() ) {
	        $self->setPlaySID($PlaySID);
		}
		else {
	        $self->setC64BASIC($C64BASIC);
		}
    }

    if (($self->{SIDdata}{startPage} == 0) or ($self->{SIDdata}{startPage} == 0xFF)) {
        $self->{SIDdata}{pageLength} = 0;
    }
    elsif ((($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1) > 0xFFFF) {
        $self->{SIDdata}{pageLength} = 0xFF - $self->{SIDdata}{startPage};
    }
    elsif ($self->{SIDdata}{pageLength} == 0) {
        $self->{SIDdata}{pageLength} = 1;
    }

    # Reloc info must not overlap or encompass the ROM/IO and
    # reserved memory areas.

    # Is startPage within the ROM or reserved memory areas?
    if ( (($self->{SIDdata}{startPage} >= 0xA0) and ($self->{SIDdata}{startPage} < 0xC0)) or
         (($self->{SIDdata}{startPage} >= 0xD0) and ($self->{SIDdata}{startPage} < 0xFF)) or
         (($self->{SIDdata}{startPage} > 0x00) and ($self->{SIDdata}{startPage} < 0x04)) ) {

         $self->{SIDdata}{startPage} = 0xFF;
         $self->{SIDdata}{pageLength} = 0x00;
    }

    # Is the end of the relocation range within the ROM or reserved memory areas?
    if ( (( ($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 >= 0xA000) and ( ($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 < 0xC000)) or
         (( ($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 >= 0xD000) and ( ($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 <= 0xFFFF)) or
         (( ($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 > 0x0000) and  ( ($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 < 0x0400)) ) {

         $self->{SIDdata}{startPage} = 0xFF;
         $self->{SIDdata}{pageLength} = 0x00;
    }

    # Does the relocation range encompass a ROM area?
    if ( ($self->{SIDdata}{startPage} < 0xA0) and (($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 >= 0xC000) ) {

         $self->{SIDdata}{startPage} = 0xFF;
         $self->{SIDdata}{pageLength} = 0x00;
    }

    # Relocation range must not overlap or encompass the load range.

    if ( (($self->{SIDdata}{startPage} << 8) >= $self->getRealLoadAddress()) and
         (($self->{SIDdata}{startPage} << 8) <= ($self->getRealLoadAddress() + length($self->{SIDdata}{data}) - 3)
         ) ) {

         $self->{SIDdata}{startPage} = 0xFF;
         $self->{SIDdata}{pageLength} = 0x00;
    }

    if ( (($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 >= $self->getRealLoadAddress()) and
         (($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 <= ($self->getRealLoadAddress() + length($self->{SIDdata}{data}) - 3))
       ) {

         $self->{SIDdata}{startPage} = 0xFF;
         $self->{SIDdata}{pageLength} = 0x00;
    }

    if ( (($self->{SIDdata}{startPage} << 8) < $self->getRealLoadAddress()) and
         (($self->{SIDdata}{startPage} << 8) + ($self->{SIDdata}{pageLength} << 8) - 1 > ($self->getRealLoadAddress() + length($self->{SIDdata}{data}) - 3))
       ) {

         $self->{SIDdata}{startPage} = 0xFF;
         $self->{SIDdata}{pageLength} = 0x00;
    }

    $self->{SIDdata}{reserved} = 0;

    # The preferred way is to have no padding between the v2 header and the
    # C64 data.
    if ($self->{PADDING}) {
        $self->{PADDING} = '';
#        carp ("Invalid bytes were between the header and the data - removed them");
    }

    # Recalculate size.
    $self->{FILESIZE} = $self->{SIDdata}{dataOffset} + length($self->{PADDING}) +
        length($self->{SIDdata}{data});
}

1;

__END__

=pod

=head1 NAME

Audio:PSID - Perl module to handle SID files (Commodore-64 music files).

=head1 SYNOPSIS

    use Audio::SID;

    $mySID = new Audio::SID('-filename' => 'Test.sid') or die "Whoops!";

    print "Title = " . $mySID->get('title') . "\n";

    print "MD5 = " . $mySID->getMD5();

    $mySID->set(author => 'LaLa',
                 title => 'Test2',
                 released => '2001 Hungarian Music Crew');

    $mySID->validate();
    $mySID->write('-filename' => 'Test2.sid') or die "Couldn't write file!";

    @array = $mySID->getFieldNames();
    print "Fieldnames = " . join(' ', @array) . "\n";

=head1 DESCRIPTION

This module is designed to handle SID files (usually bearing a .sid
extension), which are music player and data routines converted from the
Commodore-64 computer with an additional informational header prepended. For
further details about the exact file format, see description of all SID
fields in the SID_file_format.txt file included in the module package. For
information about SID tunes in general, see the excellent SIDPLAY homepage at:

B<http://www.geocities.com/SiliconValley/Lakes/5147/>

For PSID v2NG documentation:

B<http://sidplay2.sourceforge.net>

You can find literally thousands of SID tunes in the High Voltage SID
Collection at:

B<http://www.hvsc.c64.org>

This module can handle PSID version 1, PSID version 2/2NG and RSID files.
(Version 2 files are simply v2NG files where v2NG specific fields are set 0,
RSID (RealSID) files are PSID v2NG files with the I<magicID> set to 'RSID' and
with some additional restrictions on certain field values.) The module was
designed primarily to make it easier to look at and change the SID header
fields, so many of the member function are geared towards that. Use
$OBJECT->I<getFieldNames>() to find out the exact names of the fields
currently recognized by this module. Please note that B<fieldnames are
case-sensitive>!

=head2 Member functions

=over 4

=item B<PACKAGE>->B<new>()

B<Usage:>

B<PACKAGE>->B<new>(SCALAR) or
B<PACKAGE>->B<new>('-filename' => SCALAR) or
B<PACKAGE>->B<new>(FILEHANDLE) or
B<PACKAGE>->B<new>('-filehandle' => FILEHANDLE) or
B<PACKAGE>->B<new>('-filedata' => SCALAR)

Returns a newly created Audio::SID object. If no parameters are specified, the
object is initialized with default values. See $OBJECT->I<initalize>() below
for initialization details.

If SCALAR or FILEHANDLE is specified (with or without a name-value pair), an
attempt is made to open the given file as specified in $OBJECT->I<read>()
below. If SCALAR is specified with '-filedata', SCALAR is assumed to contain
the binary data of a SID file. Upon failure no object is created and B<new>
returns undef.

=item B<OBJECT>->B<initialize>()

Initializes the object with default SID data as follows:

    magicID => 'PSID',
    version => 2,
    dataOffset => 0x7C,
    songs => 1,
    startSong => 1,
    title => '<?>',
    author => '<?>',
    released => '20?? <?>',
    data => '',

Every other SID field (I<loadAddress>, I<initAddress>, I<playAddress>,
I<speed>, I<flags>, I<startPage>, I<pageLength> and I<reserved>) is set to 0.
I<FILENAME> is set to '' and the filesize is set to 0x7C.

=item B<PACKAGE>->B<read>()

B<Usage:>

B<PACKAGE>->B<read>(SCALAR) or
B<PACKAGE>->B<read>('-filename' => SCALAR) or
B<PACKAGE>->B<read>(FILEHANDLE) or
B<PACKAGE>->B<read>('-filehandle' => FILEHANDLE) or
B<PACKAGE>->B<read>('-filedata' => SCALAR)

If SCALAR or FILEHANDLE is specified (with or without a name-value pair), an
attempt is made to open the given file. If SCALAR is specified with
'-filedata', SCALAR is assumed to contain the binary data of a SID file.

If no parameters are specified, the value of I<FILENAME> is used to determine
the name of the input file. If that is not set, either, the module is
initialized with default data and B<read>() returns an undef. Note that SCALAR
and FILEHANDLE here can be different than the value of I<FILENAME>! If SCALAR
is defined, it will overwrite the filename stored in I<FILENAME>, otherwise it
is not modified. So, watch out when passing in a FILEHANDLE, because
I<FILENAME> will not be modified!

If the file turns out to be an invalid SID file, the module is initialized
with default data and B<read>() returns an undef. Valid SID files must have
the ASCII string 'PSID' or 'RSID' as their first 4 bytes, and either 0x0001 or
0x0002 as the next 2 bytes in big-endian format.

If the given file is a PSID version 1 file, the fields of I<flags>,
I<startPage>, I<pageLength> and I<reserved> are set to undef.

=item B<PACKAGE>->B<write>()

B<Usage:>

B<PACKAGE>->B<write>(SCALAR) or
B<PACKAGE>->B<write>('-filename' => SCALAR) or
B<PACKAGE>->B<write>(FILEHANDLE) or
B<PACKAGE>->B<write>('-filehandle' => FILEHANDLE)

Writes the SID file given by the filename SCALAR or by FILEHANDLE to disk. If
neither SCALAR nor FILEHANDLE is specified (with or without a name-value
pair), the value of I<FILENAME> is used to determine the name of the output
file. If that is not set, either, B<write>() returns an undef. Note that
SCALAR and FILEHANDLE here can be different than the value of I<FILENAME>! If
SCALAR is defined, it will not overwrite the filename stored in I<FILENAME>.

I<write> will create a version 1 or version 2/2NG SID file depending on the
value of the I<version> field, and an RSID file if the I<magicID> is set to
'RSID', regardless of whether the other fields are set correctly or not, or
even whether they are undef'd or not. However, if
$OBJECT->I<alwaysValidateWrite>(1) was called beforehand, I<write> will always
write a validated PSID v2NG or RSID SID file. See below.

=item B<$OBJECT>->B<get>([SCALAR])

Retrieves the value of the SID field given by the name SCALAR, or returns a
hash of all the recognized SID fields with their values if called in an
array/hash context.

If the fieldname given by SCALAR is unrecognized, the operation is ignored
and an undef is returned. If SCALAR is not specified and I<get> is not called
from an array context, the same terrible thing will happen. So try not to do
either of these.

For backwards compatibility reasons, "copyright" is always accepted as an
alias for the "released" fieldname and "name" is always accepted as an
alias for "title".

=item B<$OBJECT>->B<getFileName>()

Returns the current I<FILENAME> stored in the object.

=item B<$OBJECT>->B<getFileSize>()

Returns the total size of the SID file that would be written by
$OBJECT->I<write>() if it was called right now. This means that if you read in
a version 1 file and changed the I<version> field to 2 without actually saving
the file, the size returned here will reflect the size of how big the version
2 file would be.

=item B<$OBJECT>->B<getRealLoadAddress>()

The "real load address" indicates what is the actual Commodore-64 memory
location where the SID data is going to be loaded into. If I<loadAddress> is
non-zero, then I<loadAddress> is returned here, otherwise it's the first two
bytes of I<data> (read from there in little-endian format).

=item B<$OBJECT>->B<getSpeed>([SCALAR])

Returns the speed of the song number specified by SCALAR. If no SCALAR is
specified, returns the speed of song #1. Speed can be either 0 (indicating a
vertical blank interrupt (50Hz PAL, 60Hz NTSC)), or 1 (indicating CIA 1 timer
interrupt (default is 60Hz)).

=item B<$OBJECT>->B<getMUSPlayer>()

Returns the value of the 'MUSPlayer' bit of the I<flags> field if I<flags> is
specified (i.e. when I<version> is 2), or undef otherwise. The returned value
is either 0 (indicating a built-in music player) or 1 (indicating that I<data>
is a Compute!'s Sidplayer MUS data and the music player must be merged).

=item B<$OBJECT>->B<isMUSPlayerRequired>()

This is an alias for $OBJECT->I<getMUSPlayer>().

=item B<$OBJECT>->B<getPlaySID>()

Returns the value of the 'psidSpecific' bit of the I<flags> field if I<flags>
is specified (i.e. when I<version> is 2) and the I<magicID> is 'PSID', or
undef otherwise. The returned value is either 0 (indicating that I<data> is
Commodore-64 compatible) or 1 (indicating that I<data> is PlaySID specific).

=item B<$OBJECT>->B<isPlaySIDSpecific>()

This is an alias for $OBJECT->I<getPlaySID>().

=item B<$OBJECT>->B<isRSID>()

Returns 'true' if the I<magicID> is 'RSID', 'false' otherwise.

=item B<$OBJECT>->B<getC64BASIC>()

Returns the value of the 'C64BASIC' bit of the I<flags> field if I<flags>
is specified (i.e. when I<version> is 2) and the I<magicID> is 'RSID', or
undef otherwise. The returned value is either 1 (indicating that I<data>
has a BASIC executable portion, or 0 otherwise.

=item B<$OBJECT>->B<isC64BASIC>()

This is an alias for $OBJECT->I<getC64BASIC>().

=item B<$OBJECT>->B<getClock>()

Returns the value of the 'clock' (video standard) bits of the I<flags> field
if I<flags> is specified (i.e. when I<version> is 2), or undef otherwise. The
returned value is one of 0 (UNKNOWN), 1 (PAL), 2 (NTSC) or 3 (EITHER).

=item B<$OBJECT>->B<getClockByName>()

Returns the textual value of the 'clock' (video standard) bits of the I<flags>
field if I<flags> is specified (i.e. when I<version> is 2), or undef
otherwise. The textual value will be one of UNKNOWN, PAL, NTSC or EITHER.

=item B<$OBJECT>->B<getSIDModel>()

Returns the value of the 'sidModel' bits of the I<flags> field if I<flags> is
specified (i.e. when I<version> is 2), or undef otherwise. The returned value
is one of 0 (UNKNOWN), 1 (6581), 2 (8580) or 3 (EITHER).

=item B<$OBJECT>->B<getSIDModelByName>()

Returns the textual value of the 'sidModel' bits of the I<flags> field if
I<flags> is specified (i.e. when I<version> is 2), or undef otherwise. The
textual value will be one of UNKNOWN, 6581, 8580 or EITHER.

=item B<$OBJECT>->B<set>(field => value [, field => value, ...] )

Given one or more field-value pairs it changes the SID fields given by
I<field> to have I<value>.

If you try to set a field that is unrecognized, that particular field-value
pair will be ignored. Trying to set the I<version> field to anything other
than 1 or 2 will result in criminal prosecution, expulsion, and possibly
death... Actually, it won't harm you, but the invalid value will be ignored.
The same is true for the I<magicID> field if you try to set it to anything
else but 'PSID' or 'RSID'.

Whenever the version number is changed to 1, the I<flags>, I<startPage>,
I<pageLength> and I<reserved> fields are automatically set to be undef'd, the
I<magicID> is set to 'PSID' and the I<dataOffset> field is set to 0x0076.

Whenever the version number is changed to 2, the I<flags>, I<startPage>,
I<pageLength> and I<reserved> fields are zeroed out if they are not set, yet.

Whenever the I<magicID> is changed from 'RSID' to 'PSID' or vice versa and
I<flags> is not specified at the same time, the I<psidSpecific> field for
PSID or the I<C64BASIC> field for RSID is set to 0.

Whenever the I<magicID> is set to 'RSID', the I<loadAddress>, I<playAddress>
and I<speed> fields are set to 0, plus the 'psidspecific' bit in the I<flags>
field is also set to 0. If I<loadAddress> was non-zero before, its value is
prepended to I<data>.

If you try to set I<magicID>, I<flags>, I<startPage>, I<pageLength> or
I<reserved> when I<version> is not 2, the values will be ignored. Trying to
set I<dataOffset> when I<version> is 1 will always reset its value to 0x0076,
and I<dataOffset> can't be set to lower than 0x007C if I<version> is 2. You
can set it higher, though, in which case either the relevant portion of the
original extra padding bytes between the SID header and the I<data> will be
preserved, or additional 0x00 bytes will be added between the SID header and
the I<data> if necessary.

Note that the textual fields (I<title>, I<author>, or I<released>) will
always be converted to ISO 8859-1 ASCII encoding (i.e. single byte ASCII
chars), even if they were Unicode to begin with. This might result in some
Unicode characters without ASCII equivalents getting changed to a
question mark ('?').

For backwards compatibility reasons, "copyright" is always accepted as an
alias for the "released" fieldname and "name" is always accepted as an
alias for "title".

=item B<$OBJECT>->B<setFileName>(SCALAR)

Sets the I<FILENAME> to SCALAR. This filename is used by $OBJECT->I<read>()
and $OBJECT->I<write>() when either one of them is called without any
arguments. SCALAR can specify either a relative or an absolute pathname to the
file - in fact, it can be anything that can be passed to a B<FileHandle>
type object as a filename.

=item B<$OBJECT>->B<setSpeed>(SCALAR1, SCALAR2)

Changes the speed of the song number specified by SCALAR1 to that of SCALAR2.
SCALAR1 has to be more than 1 and less than the value of the I<songs> field.
SCALAR2 can be either 0 (indicating a vertical blank interrupt (50Hz PAL, 60Hz
NTSC)), or 1 (indicating CIA 1 timer interrupt (default is 60Hz)). An undef is
returned if neither was specified.

=item B<$OBJECT>->B<setMUSPlayer>(SCALAR)

Changes the value of the 'MUSPlayer' bit of the I<flags> field to SCALAR if
I<flags> is specified (i.e. when I<version> is 2), returns an undef otherwise.
SCALAR must be either 0 (indicating a built-in music player) or 1 (indicating
that I<data> is a Compute!'s Sidplayer MUS data and the music player must be
merged).

=item B<$OBJECT>->B<setPlaySID>(SCALAR)

Changes the value of the 'psidSpecific' bit of the I<flags> field to SCALAR if
I<flags> is specified (i.e. when I<version> is 2) and the I<magicID> is 'PSID',
returns an undef otherwise. SCALAR must be either 0 (indicating that I<data>
is Commodore-64 compatible) or 1 (indicating that I<data> is PlaySID specific).

=item B<$OBJECT>->B<setC64BASIC>(SCALAR)

Changes the value of the 'C64BASIC' bit of the I<flags> field to SCALAR if
I<flags> is specified (i.e. when I<version> is 2) and the I<magicID> is 'RSID',
returns an undef otherwise. SCALAR must be either 1 (indicating that I<data>
has a C64 BASIC executable portion) or 0 otherwise. Setting this flag to 1
also sets the I<initAddress> field to 0.

=item B<$OBJECT>->B<setClock>(SCALAR)

Changes the value of the 'clock' (video standard) bits of the I<flags> field
to SCALAR if I<flags> is specified (i.e. when I<version> is 2), returns an
undef otherwise. SCALAR must be one of 0 (UNKNOWN), 1 (PAL), 2 (NTSC) or 3
(EITHER).

=item B<$OBJECT>->B<setClockByName>(SCALAR)

Changes the value of the 'clock' (video standard) bits of the I<flags> field
if I<flags> is specified (i.e. when I<version> is 2), returns an undef
otherwise. SCALAR must be be one of UNKNOWN, NONE, NEITHER (all 3 indicating
UNKNOWN), PAL, NTSC or ANY, BOTH, EITHER (all 3 indicating EITHER) and is
case-insensitive.

=item B<$OBJECT>->B<setSIDModel>(SCALAR)

Changes the value of the 'sidModel' bits of the I<flags> field if I<flags> is
specified (i.e. when I<version> is 2), returns an undef otherwise. SCALAR must
be one of 0 (UNKNOWN), 1 (6581), 2 (8580) or 3 (EITHER).

=item B<$OBJECT>->B<setSIDModelByName>(SCALAR)

Changes the value of the 'sidModel' bits of the I<flags> field if I<flags> is
specified (i.e. when I<version> is 2), returns an undef otherwise. SCALAR must
be be one of UNKNOWN, NONE, NEITHER (all 3 indicating UNKNOWN), 6581, 8580 or
ANY, BOTH, EITHER (all 3 indicating EITHER) and is case-insensitive.

=item B<$OBJECT>->B<getFieldNames>()

Returns an array that contains the SID fieldnames recognized by this module,
regardless of the SID version number. All fieldnames are taken from the
standard SID file format specification, but do B<not> include those fields
that are themselves contained in another field, namely any field that is
inside the I<flags> field. The fieldname I<FILENAME> is also B<not> returned
here, since that is considered to be a descriptive parameter of the SID file
and is not part of the SID specification.

=item B<$OBJECT>->B<getMD5>([SCALAR])

Returns a string containing a hexadecimal representation of the 128-bit MD5
fingerprint calculated from the following SID fields: I<data> (excluding the
first 2 bytes if I<loadAddress> is 0), I<initAddress>, I<playAddress>,
I<songs>, the relevant bits of I<speed>, and the value of the I<clock> field
if it's set to NTSC and SCALAR is zero or not defined. If SCALAR is a nonzero
value, the MD5 fingerprint calculation completely ignores the I<clock> field,
which provides backward compatibility with earlier MD5 fingerprints.

The MD5 fingerprint calculated this way is used, for example, to index into
the songlength database, because it provides a way to uniquely identify SID
files even if the textual credit fields of the SID file were changed.

=item B<$OBJECT>->B<alwaysValidateWrite>(SCALAR)

If SCALAR is non-zero, $OBJECT->I<validate>() will always be called before
$OBJECT->I<write>() actually writes a file to disk. If SCALAR is 0, this won't
happen and the stored SID data will be written to disk virtually untouched -
this is also the default behavior.

=item B<$OBJECT>->B<validate>()

Regardless of how the SID fields were populated, this operation will update
the stored SID data to comply with the latest SID version (PSID v2NG or RSID).
Thus, it changes the SID I<version> to 2, and it will also change the other
fields so that they take on their prefered values. Operations done by this
member function include (but are not limited to):

=over 4

=item *

setting the I<version> field to 2,

=item *

if the I<magicID> is 'RSID', setting the I<playAddress> and I<speed> fields,

=item *

setting the I<dataOffset> to 0x007C,

=item *

chopping the textual fields of I<title>, I<author> and I<released> to their
maximum length of 31 characters,

=item *

changing the characters of the textual fields of I<title>, I<author> and
I<released> to ISO 8859-1 ASCII bytes (i.e. NOT Unicode),

=item *

changing the I<initAddress> to a valid non-zero value,

=item *

if the I<magicID> is 'RSID', changing the I<initAddress> to zero if it is
pointing to a ROM/IO area ($0000-$07E8, $A000-$BFFF or $D000-$FFFF), or if
the I<C64BASIC> flag is set to 1,

=item *

changing the I<loadAddress> to 0 if it is non-zero (and also prepending the
I<data> with the non-zero I<loadAddress>)

=item *

changing the actual load address to $07E8 if it is less than $07E8 and the
I<magicID> is RSID,

=item *

making sure that I<loadAddress>, I<initAddress> and I<playAddress> are within
the $0000-$FFFF range (since the Commodore-64 had only 64KB addressable
memory), and setting them to 0 if they aren't,

=item *

making sure that I<startPage> and I<pageLength> are within the 0x00-0xFF
range, and setting them to 0 if they aren't,

=item *

making sure that I<songs> is within the range of [1,256], and changing it to
1 if it less than that or to 256 if it is more than that,

=item *

making sure that I<startSong> is within the range of [1,I<songs>], and changing
it to 1 if it is not,

=item *

setting only the relevant bits in I<speed>, regardless of how many bits were
set before, and setting the rest to 0,

=item *

setting only the recognized bits in I<flags>, namely 'MUSPlayer',
'psidSpecific', 'clock' and 'sidModel' (bits 0-5), and setting the rest to 0,

=item *

setting the I<pageLength> to 0 if I<startPage> is 0 or 0xFF,

=item *

setting the I<startPage> to 0xFF and the I<pageLength> to 0 if the relocation
range indicated by these two fields overlaps or encompasses the load range of
the C64 data,

=item *

setting the I<startPage> to 0xFF and the I<pageLength> to 0 if the relocation
range indicated by these two fields overlaps or encompasses the ROMs
($A000-$BFFF and $D000-$FFFF) or reserved memory ($0000-$03FF) areas,

=item *

removing extra bytes that may have been between the SID header and I<data>
in the file (usually happens when I<dataOffset> is larger than the total size
of the SID header, i.e. larger than 0x007C),

=item *

setting the I<reserved> field to 0,

=back

=back

=head1 BUGS

None is known to exist at this time. If you find any bugs in this module,
report them to the author (see L<"COPYRIGHT"> below).

=head1 TO DO LIST

More or less in order of perceived priority, from most urgent to least urgent.

=over 4

=item *

Add Stefano's SID player engine recognizer code. Didn't somebody else have
something like this, too?

=item *

Overload '=' so two objects can be assigned to each other?

=back

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Audio::SID Perl module - Copyright (C) 1999, 2005 LaLa <LaLa@C64.org>

(Thanks to Adam Lorentzon for showing me how to extract binary data from SID
files! :-)

SID MD5 calculation - Copyright (C) 2001 Michael Schwendt <sidplay@geocities.com>

=head1 VERSION

Version v3.11, released to CPAN on Aug 14, 2005.

First version (then called Audio::PSID) created on June 11, 1999.

=head1 SEE ALSO

the SIDPLAY homepage for the PSID file format documentation:

B<http://www.geocities.com/SiliconValley/Lakes/5147/>

the SIDPLAY2 homepage for documents about the PSID v2NG extensions:

B<http://sidplay2.sourceforge.net>

the High Voltage SID Collection, the most comprehensive archive of SID tunes
for SID files:

B<http://www.hvsc.c64.org>

L<Digest::MD5>

=cut
