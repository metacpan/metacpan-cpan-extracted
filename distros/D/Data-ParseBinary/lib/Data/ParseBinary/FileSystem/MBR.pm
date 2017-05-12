package Data::ParseBinary::FileSystem::MBR;
use strict;
use warnings;
use Data::ParseBinary;
#"""
#Master Boot Record
#The first sector on disk, contains the partition table, bootloader, et al.
#
#http://www.win.tue.nl/~aeb/partitions/partition_types-1.html
#"""

our $mbr_parser = Struct("mbr",

	# The first 440 (446) bytes are executable code that is loaded by the 
	# BIOS to boot the system. we use HexDump so it would print out nicely.
    Bytes("bootloader_code", 440),
	# Optional disk signature.
	Array(4, UBInt8('optional_disk_signature')),
	# Usually Nulls; 0x0000.
	Padding(2),

    Array(4,
        Struct("partitions",
            Enum(Byte("state"),
                INACTIVE => 0x00,
                ACTIVE => 0x80,
            ),
            BitStruct("beginning",
                Octet("head"),
                BitField("sect", 6),
                BitField("cyl", 10),
            ),
            Enum(UBInt8("type"),
				'Unused' => 0x00,
				'FAT12' => 0x01,
				'XENIX root fs' => 0x02,
				'XENIX /usr' => 0x03,
				'FAT16 old' => 0x04,
				'Extended_DOS' => 0x05,
				'FAT16' => 0x06,
				'FAT32' => 0x0b,
				'FAT32 (LBA)' => 0x0c,
				'NTFS' => 0x07,
				'FAT16 (LBA)' => 0x0e,
				'LINUX_SWAP' => 0x82,
				'LINUX_NATIVE' => 0x83,
				_default_ => $DefaultPass,
            ),
            BitStruct("ending",
                Octet("head"),
                BitField("sect", 6),
                BitField("cyl", 10),
            ),
            ULInt32("sector_offset"), # offset from MBR in sectors
            ULInt32("size"), # in sectors
        )
    ),
    Magic("\x55\xAA"),
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($mbr_parser);

1;

__END__

=head1 NAME

Data::ParseBinary::FileSystem::MBR - Parsing the partition table

=head1 SYNOPSIS

    use Data::ParseBinary::FileSystem::MBR qw{$mbr_parser};
    my $data = $mbr_parser->parse(CreateStreamReader(File => $fh));

Can parse the binary structure of the MBR. (that is the structure that tells your
computer what partitions exists on the drive) Getting the data from there is your problem.

This is a part of the Data::ParseBinary package, and is just one ready-made parser.
please go to the main page for additional usage info.

=cut
