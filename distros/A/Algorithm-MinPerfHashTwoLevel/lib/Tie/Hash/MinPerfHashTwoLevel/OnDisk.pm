package Tie::Hash::MinPerfHashTwoLevel::OnDisk;
use strict;
use warnings;
our $VERSION = '0.10';

# this also installs the XS routines we use into our namespace.
use Algorithm::MinPerfHashTwoLevel ( 'hash_with_state', ':utf8_flags', ':uint_max', '$DEFAULT_VARIANT' );
use Exporter qw(import);
use constant MAGIC_STR => "PH2L";
use Carp;

our %EXPORT_TAGS = ( 'all' => [ qw(
    unmount_file
    mount_file
    num_buckets
    fetch_by_index
    fetch_by_key

    _test_debug
    MAGIC_STR
) ] );
my $scalar_has_slash= scalar(%EXPORT_TAGS)=~m!/!;

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();


sub TIEHASH {
    my ($class,$file,$flags)= @_;
    $flags ||= 0;
    my $error;
    my $mount= mount_file($file,$error,$flags);
    if (!defined($mount)) {
        die "Error in TIEHASH: $error";
    }
    my %perl_obj= (
        mount => $mount,
        file => $file,
    );
    return bless \%perl_obj, $class;
}

sub FETCH {
    my ($self, $key)= @_;
    my $value;
    fetch_by_key($self->{mount},$key,$value)
        or return;
    return $value;
}

sub EXISTS {
    my ($self, $key)= @_;
    return fetch_by_key($self->{mount},$key);
}

sub FIRSTKEY {
    my ($self)= @_;
    $self->{iter_idx}= 0;
    return $self->NEXTKEY();
}

sub NEXTKEY {
    my ($self, $lastkey)= @_;
    fetch_by_index($self->{mount},$self->{iter_idx}++,my $key);
    return $key;
}

sub SCALAR {
    my ($self)= @_;
    if ($scalar_has_slash) {
        return num_buckets($self->{mount})."/".num_buckets($self->{mount});
    } else {
        return num_buckets($self->{mount});
    }
}

sub UNTIE {
    my ($self)= @_;
}

sub DESTROY {
    my ($self)= @_;
    unmount_file($self->{mount}) if $self->{mount};
}

sub STORE {
    my ($self, $key, $value)= @_;
    confess __PACKAGE__ . " is readonly, STORE operations are not supported";
}

sub DELETE {
    my ($self, $key)= @_;
    confess __PACKAGE__ . " is readonly, DELETE operations are not supported";
}

sub CLEAR {
    my ($self)= @_;
    confess __PACKAGE__ . " is readonly, CLEAR operations are not supported";
}


sub _append_ofs {
    my $ofs = length($_[0]);
    $_[1] .= "\0" while length($_[1]) % 16;
    $_[0] .= $_[1];
    return $ofs;
}

sub _bytes {
    my ($n, $bits)= @_;
    return int( ( $n + ( $bits - 1 ) ) / $bits );
}

sub make_file {
    my ($class, %opts)= @_;

    my $ofile= $opts{file} 
        or die "file is a mandatory option to make_file";
    my $source_hash= $opts{source_hash}
        or die "source_hash is a mandatory option to make_file";
    $opts{comment}= "" unless defined $opts{comment};
    $opts{variant}= $DEFAULT_VARIANT unless defined $opts{variant};
    
    my $comment= $opts{comment};
    my $debug= $opts{debug} || 0;
    my $variant= int($opts{variant});
    die "Unknown file variant $variant" if $variant > 2 or $variant < 0;

    die "comment cannot contain null"
        if index($comment,"\0") >= 0;

    my $hasher= Algorithm::MinPerfHashTwoLevel->new(
        debug => $debug,
        seed => $opts{seed},
        variant => $variant,
    );
    my $buckets= $hasher->compute($source_hash);
    my $buf_length= $hasher->{buf_length};
    my $state= $hasher->{state};
    my $flags= 0;
    $flags += (1<<2) if delete $opts{no_dedupe};
    my $buf= packed($variant,$buf_length,$state,$comment,$flags,@$buckets);

    my $tmp_file= "$ofile.$$";
    open my $ofh, ">", $tmp_file
        or die "Failed to open $tmp_file for output";
    print $ofh $buf
        or die "failed to print to '$tmp_file': $!";
    close $ofh
        or die "failed to close '$tmp_file': $!";
    rename $tmp_file, $ofile
        or die "failed to rename '$tmp_file' to '$ofile': $!";
    return $ofile;
}

sub validate_file {
    my ($class, %opts)= @_;
    my $file= $opts{file}
        or die "file is a mandatory option to validate_file";
    my $verbose= $opts{verbose};
    my ($variant,$msg)= $class->_validate_file(%opts);
    if ($verbose) {
        if (defined $variant) {
            print $msg;
        } else {
            die $msg."\n";
        }
    }
    return ($variant,$msg);
}

sub _validate_file {
    my ($class, %opts)= @_;
    my $file= $opts{file}
        or die "file is a mandatory option to validate_file";

    open my $fh, "<", $file
        or die "cannot read '$file' for validation: $!";
    my $fixed_header_size= (4 * 8 + 2 * 8);
    my $file_size= -s $fh;
    if ($file_size < $fixed_header_size) {
        return(undef, "file '$file' cannot be a valid '" . MAGIC_STR . "' file - too small to be valid.");
    }
    local $/= \$fixed_header_size;
    my $head= scalar <$fh>;
    
    if (substr($head,0,4) ne MAGIC_STR) {
        return(undef, "file '$file' is not a valid '" . MAGIC_STR . "' file - missing magic header.");
    }

    my ( $magic_num, $variant,       $num_buckets,      $state_ofs,
         $table_ofs, $key_flags_ofs, $val_flags_ofs,    $str_buf_ofs,
         $table_checksum, $str_buf_checksum )= unpack "V8Q2", $head;

    if ( $variant > 2 ) {
        return(undef,"file '$file' is an unknown '" . MAGIC_STR . "' variant $variant");
    }
    
    $/= \($table_ofs - $state_ofs);
    my $state= scalar <$fh>;

    $/= \($str_buf_ofs - $table_ofs);
    my $table_and_flags= scalar <$fh>;

    undef $/;
    my $str_buf= <$fh>;

    my $got_table_checksum= hash_with_state($table_and_flags, $state);
    my $got_str_buf_checksum= hash_with_state($str_buf, $state);
    
    if ($got_table_checksum != $table_checksum) {
        return(undef, MAGIC_STR . " file '$file' has a corrupted table");
    }
    if ($got_str_buf_checksum != $str_buf_checksum) {
        return(undef, MAGIC_STR . " file '$file' has a corrupted string buffer");
    }

    my $comment= substr($str_buf,1,index($str_buf,"\0",1));
    my $ok_msg= sprintf "file '%s' is a valid '%s' file\n"
         . "  variant: %d\n"
         . "  keys: %d\n"
         . "  hash-state: %s\n"
         . "  table  checksum: %016x\n"
         . "  string checksum: %016x\n"
         . "  comment: %s"
         , $file,
            MAGIC_STR,
            $variant,
            $num_buckets,
            unpack("h*",$state),
            $got_table_checksum,
            $got_str_buf_checksum,
            $comment
    ;
    return ($variant,$ok_msg);
}

1;
__END__

=head1 NAME

Tie::Hash::MinPerfHashTwoLevel::OnDisk - construct or tie a "two level" minimal perfect hash based on disk

=head1 SYNOPSIS

  use Tie::Hash::MinPerfHashTwoLevel::OnDisk;

  Tie::Hash::MinPerfHashTwoLevel::OnDisk->make_file(
    file => $some_file,
    source_hash => $some_hash,
    comment => "this is a comment",
    debug => 0,
  );

  my %hash;
  tie %hash, "Tie::Hash::MinPerfHashTwoLevel::OnDisk", $some_file;

=head1 DESCRIPTION

This module allows one to either construct, or use a precomputed minimal
perfect hash on disk via tied interface. The disk image of the hash is
loaded by using mmap, which means that multiple processes may use the
same disk image at the same time without memory duplication. The hash
is readonly, and may only contain string values.

=head2 METHODS

=over 4

=item make_file

Construct a new file from a given 'source_hash' argument. The constructed
buffer is written to the file specified by the 'file' argument. A comment
may be added to the file via the 'comment' argument, note that comments
may not contain null characters, although keys and value may. A predetermined
seed may be provided to the hash function (16 bytes) via the 'seed' argument,
however note that if it does not produce hash values that allow for the
construction of a valid two level perfect hash then a different seed will
be automatically selected (this will not affect the ability to use the
constructed hash, it just may not be deterministic). The 'debug' argument
outputs some basic status infromation about the construction process.

=item validate_file

Validate the file specified by the 'file' argument. Returns a list of
two values, 'variant' and 'message'. If the file fails validation the 'variant'
will be undef and the 'message' will contain an error message. If the file
passes validation the 'variant' will specify the variant of the file
(currently only 0 is valid), and 'message' will contain some basic information
about the file, such as how many keys it contains, the comment it was
created with, etc.

=back

=head2 FILE FORMAT

Currently there is only one file format, variant 0.

The file structure consists of a header, followed by a byte vector of seed/state
data for the hash function, followed by a bucket table with records of a fixed size,
followed by a bitvector of the flags for the keys with two bits per key,
followed by a bitvector of flags for values with one bit per value, followed by a
string table containing the comment for the file and the strings it contains.
The key flags may be 0 for "latin-1/not-utf8", 1 for "is-utf8", and 2 for "was-utf8"
which is used for keys which can be represented as latin-1, but should be restored
as unicode/utf8. The val flags are similar but do not (need to) support "was-utf8".

Structure:

    Header
    Hash-state
    Bucket-table
    Key flags
    Val flags
    Strings

Header:

    U32 magic_num       -> 1278363728 -> "PH2L"
    U32 variant         -> 0
    U32 num_buckets     -> number of buckets/keys in hash
    U32 state_ofs       -> offset in file where hash preseeded state is found
    U32 table_ofs       -> offset in file where bucket table starts
    U32 key_flags_ofs   -> offset in file where key flags are located
    U32 val_flags ofs   -> offset in file where val flags are located
    U32 str_buf_ofs     -> offset in file where strings are located
    U64 table_checksum  -> hash value checksum of table and key/val flags
    U64 str_buf_checksum-> hash value checksum of string data

All "_ofs" members in the header are aligned on 16 byte boundaries and
may be right padded with nulls if necessary to make them a multiple of 16 bytes
long, including the string buffer.

The string buffer contains the comment at str_buf_ofs+1, its length can be found
with strlen(), the comment may NOT contain nulls, and will be null terminated. All
other strings in the table are NOT null padded, the length data stored in the
bucket records should be used to determine the length of the keys and values.

The table_checksum is the hash (using the seed/state data stored at state_ofs)
of the data in the file from table_ofs to str_buf_ofs, eg it includes the
key_flags bit vector and val_flags bit vector. The str_buf_checksum is
similar but of the data from the str_buf_ofs to the end of the file.

Buckets:

   U32 xor_val      -> the xor_val for this bucket's h1 lookups (0 means none)
   U32 key_ofs      -> offset from str_buf_ofs to find this key (nonzero always)
   U32 val_ofs      -> offset from str_buf_ofs to find this value (0 means undef)
   U16 key_len      -> length of key
   U16 val_len      -> length of value

The hash function used is stadtx hash, which uses a 16 byte seed to produce
a 32 byte state vector.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Algorithm::MinPerfHashTwoLevel

=head1 AUTHOR

Yves Orton

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Yves Orton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
