package Compress::LZMA::Simple;

use strict;
use warnings;

require Exporter;
require XSLoader;
use base qw(Exporter);
our $VERSION = '0.2';
our @EXPORT_OK = qw(compress decompress);
XSLoader::load('Compress::LZMA::Simple', $VERSION);


sub compress {
    my $val = shift;
    if(ref($val) eq ''){
        my $ref = pl_lzma_compress(\$val);
        return defined($ref) ? $$ref : undef;
    }
    return undef if(ref($val) ne 'SCALAR');
    return pl_lzma_compress($val);
}


sub decompress {
    my $val = shift;
    if(ref($val) eq ''){
        my $ref = pl_lzma_decompress(\$val);
        return defined($ref) ? $$ref : undef;
    }
    return undef if(ref($val) ne 'SCALAR');
    return pl_lzma_decompress($val);
}


1;
