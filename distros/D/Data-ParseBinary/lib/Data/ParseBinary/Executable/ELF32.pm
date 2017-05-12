package Data::ParseBinary::Executable::ELF32;
use strict;
use warnings;
use Data::ParseBinary;

#"""
#Executable and Linkable Format (ELF), 32 bit, little endian
#Used on *nix systems as a replacement of the older a.out format
#"""

my $elf32_program_header = Struct("program_header",
    Enum(ULInt32("type"),
        NULL => 0,
        LOAD => 1,
        DYNAMIC => 2,
        INTERP => 3,
        NOTE => 4,
        SHLIB => 5,
        PHDR => 6,
        _default_ => $DefaultPass,
    ),
    ULInt32("offset"),
    ULInt32("vaddr"),
    ULInt32("paddr"),
    ULInt32("file_size"),
    ULInt32("mem_size"),
    ULInt32("flags"),
    ULInt32("align"),
);

my $elf32_section_header = Struct("section_header",
    ULInt32("name_offset"),
    Pointer(sub { $_->ctx(2)->{strtab_data_offset} + $_->ctx->{name_offset} },
        CString("name")
    ),
    Enum(ULInt32("type"), 
        NULL => 0,
        PROGBITS => 1,
        SYMTAB => 2,
        STRTAB => 3,
        RELA => 4,
        HASH => 5,
        DYNAMIC => 6,
        NOTE => 7,
        NOBITS => 8,
        REL => 9,
        SHLIB => 10,
        DYNSYM => 11,
        _default_ => $DefaultPass,
    ),
    ULInt32("flags"),
    ULInt32("addr"),
    ULInt32("offset"),
    ULInt32("size"),
    ULInt32("link"),
    ULInt32("info"),
    ULInt32("align"),
    ULInt32("entry_size"),
    Pointer(sub { $_->ctx->{offset} },
        Field("data", sub { $_->ctx->{size} })
    ),
);

our $elf32_parser = Struct("elf32_file",
    Struct("identifier",
        Const(Bytes("magic", 4), "\x7fELF"),
        Enum(Byte("file_class"),
            NONE => 0,
            CLASS32 => 1,
            CLASS64 => 2,
        ),
        Enum(Byte("encoding"),
            NONE => 0,
            LSB => 1,
            MSB => 2,            
        ),
        Byte("version"),
        Padding(9),
    ),
    Enum(ULInt16("type"),
        NONE => 0,
        RELOCATABLE => 1,
        EXECUTABLE => 2,
        SHARED => 3,
        CORE => 4,
    ),
    Enum(ULInt16("machine"),
        NONE => 0,
        M32 => 1,
        SPARC => 2,
        I386 => 3,
        Motorolla68K => 4,
        Motorolla88K => 5,
        Intel860 => 7,
        MIPS => 8,
    ),
    ULInt32("version"),
    ULInt32("entry"),
    ULInt32("ph_offset"),
    ULInt32("sh_offset"),
    ULInt32("flags"),
    ULInt16("header_size"),
    ULInt16("ph_entry_size"),
    ULInt16("ph_count"),
    ULInt16("sh_entry_size"),
    ULInt16("sh_count"),
    ULInt16("strtab_section_index"),
    
    # calculate the string table data offset (pointer arithmetics)
    # ugh... anyway, we need it in order to read the section names, later on
    Pointer(sub { $_->ctx->{sh_offset} + $_->ctx->{strtab_section_index} * $_->ctx->{sh_entry_size} + 16 },
        ULInt32("strtab_data_offset"),
    ),
    
    # program header table
    Pointer(sub { $_->ctx->{ph_offset} },
        Array(sub { $_->ctx->{ph_count} },
            $elf32_program_header
        )
    ),
    
    # section table
    Pointer(sub { $_->ctx->{sh_offset} },
        Array(sub { $_->ctx->{sh_count} },
            $elf32_section_header
        )
    ),
);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($elf32_parser);


1;

__END__

=head1 NAME

Data::ParseBinary::Executable::ELF32 - Parsing UNIX's SO files

=head1 SYNOPSIS

    use Data::ParseBinary::Executable::ELF32 qw{$elf32_parser};
    my $data = $elf32_parser->parse(CreateStreamReader(File => $fh));

Can parse and re-build UNIX "so" files.

This is a part of the Data::ParseBinary package, and is just one ready-made parser.
please go to the main page for additional usage info.

No known issues

=cut
