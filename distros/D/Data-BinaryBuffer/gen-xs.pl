#!perl
use strict;
use warnings;

my $xs_file = 'BinaryBuffer.xs';

my @APIDEF = (
    [ 'int',      "size" ],
    [ 'uint8_t',  "read_uint8 -> read_integral<uint8_t>" ],
    [ 'uint16_t', "read_uint16be -> read_integral_be<uint16_t>" ],
    [ 'uint16_t', "read_uint16le -> read_integral_le<uint16_t>" ],
    [ 'uint32_t', "read_uint32be -> read_integral_be<uint32_t>" ],
    [ 'uint32_t', "read_uint32le -> read_integral_le<uint32_t>" ],
    [ 'int8_t',   "read_int8 -> read_integral<int8_t>" ],
    [ 'int16_t',  "read_int16be -> read_integral_be<int16_t>" ],
    [ 'int16_t',  "read_int16le -> read_integral_le<int16_t>" ],
    [ 'uint32_t', "read_int32be -> read_integral_be<int32_t>" ],
    [ 'uint32_t', "read_int32le -> read_integral_le<int32_t>" ],
    [ 'void', "write_uint8 -> write_integral",    'uint8_t' ],
    [ 'void', "write_uint16be -> write_integral_be", 'uint16_t' ],
    [ 'void', "write_uint16le -> write_integral_le", 'uint16_t' ],
    [ 'void', "write_uint32be -> write_integral_be", 'uint32_t' ],
    [ 'void', "write_uint32le -> write_integral_le", 'uint32_t' ],
    [ 'void', "write_int8 -> write_integral",     'int8_t' ],
    [ 'void', "write_int16be -> write_integral_be",  'int16_t' ],
    [ 'void', "write_int16le -> write_integral_le",  'int16_t' ],
    [ 'void', "write_int32be -> write_integral_be",  'int32_t' ],
    [ 'void', "write_int32le -> write_integral_le",  'int32_t' ]
);

open my $fh, '>', $xs_file or die "Can't open file $xs_file for write: $!";
print $fh <<ENDXS;
#define PERL_NO_GET_CONTEXT

extern "C" {
#include "EXTERN.h"
#include "perl.h"
}

#include "XSUB.h"
#include "binbuffer.h"

MODULE = Data::BinaryBuffer       PACKAGE = Data::BinaryBuffer

BinaryBuffer*
BinaryBuffer::new();

void
BinaryBuffer::DESTROY();

BinaryBuffer*
read_buffer(BinaryBuffer* THIS, int len)
CODE:
    RETVAL = THIS->read_buffer(len);
    const char* CLASS = "Data::BinaryBuffer";
OUTPUT:
    RETVAL

SV*
read(BinaryBuffer* THIS, int len)
CODE:
    RETVAL = newSV(len);
    SvUPGRADE(RETVAL, SVt_PV);
    int actual_len = THIS->read(SvPVX(RETVAL), len);
    SvCUR_set(RETVAL, actual_len);
    SvPOK_only(RETVAL);
    *SvEND(RETVAL) = (char)0;
OUTPUT:
    RETVAL

void
write(BinaryBuffer* THIS, SV* sv)
CODE:
    STRLEN len;
    const char* src = SvPVbyte(sv, len);
    THIS->write(src, len);

ENDXS

foreach my $def (@APIDEF) {
    my ( $ret_type, $meth, @args ) = @$def;
    my $c_meth;
    if ($meth =~ /(\S+)\s*->\s*(\S+)/) {
        $meth = $1;
        $c_meth = $2;
    }
    else {
        $c_meth = $meth;
    }
    unshift @args, 'BinaryBuffer* THIS' unless @args && $args[0] =~ /THIS/;
    my ( @arg_names, @xs_args );
    for ( my $i = 0 ; $i < @args ; $i++ ) {
        my ( $type, $name );
        if ( $args[$i] =~ /^(.+)\s(\S+)$/ ) {
            $type = $1;
            $name = $2;
        }
        else {
            $type = $args[$i];
            $name = 'arg' . ( $i + 1 );
        }
        push @arg_names, $name;
        push @xs_args,   $type . ' ' . $name;
    }
    my $xs_args_l = join( ',', @xs_args );
    my $c_args_l  = join( ',', @arg_names[ 1 .. $#arg_names ] );
    my ( $code_section, $output_section );
    if ( $ret_type eq 'void' ) {
        $code_section = <<ENDXS;
CODE:
    THIS->$c_meth($c_args_l);
ENDXS
            $output_section = "";
    }
    else {
        $code_section = <<ENDXS;
CODE:
    RETVAL = THIS->$c_meth($c_args_l);
ENDXS
            $output_section = <<ENDXS;
OUTPUT:
    RETVAL
ENDXS
    }
    my $xs = <<ENDXS;
$ret_type
$meth($xs_args_l)
$code_section$output_section

ENDXS
    print $fh $xs;
}

close $fh;
