package Tie::Hash::MinPerfHashTwoLevel::OnDisk;
use strict;
use warnings;
our $VERSION = '0.16';
our $DEFAULT_VARIANT = 5;

# this also installs the XS routines we use into our namespace.
use Algorithm::MinPerfHashTwoLevel ( 'hash_with_state', '$DEFAULT_VARIANT', ':flags', 'MAX_VARIANT', 'MIN_VARIANT' );
use Exporter qw(import);
my %constants;
BEGIN {
    %constants= (
        MAGIC_STR               =>  "PH2L",
       #MPH_F_FILTER_UNDEF      =>  (1<<0),
       #MPH_F_DETERMINISTIC     =>  (1<<1),
        MPH_F_NO_DEDUPE         =>  (1<<2),
        MPH_F_VALIDATE          =>  (1<<3),
    );
}

use constant \%constants;
use Carp;

our %EXPORT_TAGS = (
    'all' => [ qw(mph2l_tied_hashref mph2l_make_file MAX_VARIANT MIN_VARIANT), sort keys %constants ],
    'flags' => ['MPH_F_DETERMINISTIC', grep /MPH_F_/, sort keys %constants],
    'magic' => [grep /MAGIC/, sort keys %constants],
);

my $scalar_has_slash= scalar(%EXPORT_TAGS)=~m!/!;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

sub mph2l_tied_hashref {
    my ($file, %opts)= @_;
    tie my %tied, __PACKAGE__, $file, %opts;
    return \%tied;
}

sub mph2l_make_file {
    my ($file,%opts)= @_;
    return __PACKAGE__->make_file(file => $file, %opts);
}

sub mph2l_validate_file {
    my ($file, %opts)= @_;
    return __PACKAGE__->validate_file(file => $file, %opts);
}

sub new {
    my ($class, %opts)= @_;

    $opts{flags} ||= 0;
    $opts{flags} |= MPH_F_VALIDATE if $opts{validate};
    my $error;
    my $mount= mount_file($opts{file},$error,$opts{flags});
    my $error_rsv= delete $opts{error_rsv};
    if ($error_rsv) {
        $$error_rsv= $error;
    }
    if (!defined($mount)) {
        if ($error_rsv) {
            return;
        } else {
            die "Failed to mount file '$opts{file}': $error";
        }
    }
    $opts{mount}= $mount;
    return bless \%opts, $class;
}

sub TIEHASH {
    my ($class, $file, %opts)= @_;
    return $class->new( file => $file, %opts );
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
    my $buckets= $self->get_hdr_num_buckets();
    if ($scalar_has_slash) {
        $buckets .= "/" . $buckets;
    }
    return $buckets;
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

sub make_file {
    my ($class, %opts)= @_;

    my $ofile= $opts{file} 
        or die "file is a mandatory option to make_file";
    my $source_hash= $opts{source_hash}
        or die "source_hash is a mandatory option to make_file";
    $opts{comment}= "" unless defined $opts{comment};
    $opts{variant}= $DEFAULT_VARIANT unless defined $opts{variant};
    
    my $comment= $opts{comment}||"";
    my $debug= $opts{debug} || 0;
    my $variant= int($opts{variant});
    my $deterministic;
    $deterministic //= delete $opts{canonical};
    $deterministic //= delete $opts{deterministic};
    $deterministic //= 1;

                    #1234567812345678
    $opts{seed} = "MinPerfHash2Levl"
        if !defined($opts{seed}) and $deterministic;

    my $compute_flags= int($opts{compute_flags}||0);
    $compute_flags |= MPH_F_NO_DEDUPE if delete $opts{no_dedupe};
    $compute_flags |= MPH_F_DETERMINISTIC
        if $deterministic;
    $compute_flags |= MPH_F_FILTER_UNDEF
        if delete $opts{filter_undef};

    die "Unknown variant '$variant', max known is "
        . MAX_VARIANT . " default is " . $DEFAULT_VARIANT
        if $variant > MAX_VARIANT;
    die "Unknown variant '$variant', min known is "
        . MIN_VARIANT . " default is " . $DEFAULT_VARIANT
        if $variant < MIN_VARIANT;

    die "comment cannot contain null"
        if index($comment,"\0") >= 0;

    my $seed= $opts{seed};
    my $hasher= Algorithm::MinPerfHashTwoLevel->new(
        debug => $debug,
        seed => (ref $seed ? $$seed : $seed),
        variant => $variant,
        compute_flags => $compute_flags,
        max_tries => $opts{max_tries},
    );
    my $buckets= $hasher->compute($source_hash);
    my $buf_length= $hasher->{buf_length};
    my $state= $hasher->{state};
    my $buf= packed_xs($variant, $buf_length, $state, $comment, $compute_flags, @$buckets);
    $$seed= $hasher->get_seed if ref $seed;

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
    my ($variant,$msg);

    my $error_sv;
    my $self= $class->new(file => $file, flags => MPH_F_VALIDATE, error_rsv => \$error_sv);
    if ($self) {
        $msg= sprintf "file '%s' is a valid '%s' file\n"
         . "  variant: %d\n"
         . "  keys: %d\n"
         . "  hash-state: %s\n"
         . "  table  checksum: %016x\n"
         . "  string checksum: %016x\n"
         . "  comment: %s"
         ,  $file,
            MAGIC_STR,
            $self->get_hdr_variant,
            $self->get_hdr_num_buckets,
            unpack("H*", $self->get_state),
            $self->get_hdr_table_checksum,
            $self->get_hdr_str_buf_checksum,
            $self->get_comment,
        ;
        $variant = $self->get_hdr_variant;
    } else {
        $msg= $error_sv;
    }
    if ($verbose) {
        if (defined $variant) {
            print $msg;
        } else {
            die $msg."\n";
        }
    }
    return ($variant, $msg);
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

Construct a new file from a given 'source_hash' argument. Takes the following arguments:

=over 4

=item file

The file name to produce, mandatory.

=item comment

An arbitrary piece of text of your choosing. Can be extracted from
the file later if needed. Only practical restriction on the value is
that it cannot contain a null.

=item seed

A 16 byte string (or a reference to one) to use as the seed for
the hashing and generation process. If this is omitted a standard default
is chosen.

If it should prove impossible to construct a solution using the seed chosen
then a new one will be constructed deterministically from the old until a
solution is found (see L<max_tries>) (prior to version v0.10 this used rand()).
Should you wish to access the seed actually used for the final solution
then you can pass in a reference to a scalar containing your chosen seed.
The reference scalar will be updated after successful construction.

Thus both of the following are valid:

    Tie::Hash::MinPerfHashTwoLevel::OnDisk->make_file(seed => "1234567812345678", ...);
    Tie::Hash::MinPerfHashTwoLevel::OnDisk->make_file(seed => \my $seed= "1234567812345678", ...);

=item compute_flags

This is an integer which contains various flags which control construction.
They are as follows:

       MPH_F_FILTER_UNDEF   =>  1 - filter keys with undef values
       MPH_F_DETERMINISTIC  =>  2 - repeatable results (sort keys during processing)
       MPH_F_NO_DEDUPE      =>  4 - do not dedupe strings in final buffer

These constants can be imported via the ":flags" tag, but there are also options that
have the equivalent result, see C<no_dedupe>, C<deterministic> and C<filter_undef>.

=item no_dedupe

Speed up construction at the cost of a larger string buffer by disabling
deduplication of values and keys.  Same as setting the MPH_F_NO_DEDUPE bit
in compute_flags.

=item deterministic

=item canonical

Produce a canonical result from the source data set, albeit somewhat less quickly
than normal. Note this is independent of supplying a seed, the same seed may produce
a different result for the same set of keys without this option.  Same
as setting the MPH_F_DETERMINISTIC bit in compute_flags.

=item filter_undef

Ignore keys with undef values during construction. This means that exists() checks
may differ between source and the constructed hash table, but avoids the need to
store such keys in the resulting file, saving space. Same as setting the
MPH_F_FILTER_UNDEF bit in compute_flags.

=item max_tries

The maximum number of attempts to make to find a solution for this keyset.
Defaults to 3. 

=item debug

Enable debug during generation.

=item variant

Select which variant of construction algorithm and file format to produce.
When omitted the variant is determined by the global var

   $Tie::Hash::MinPerfHashTwoLevel::DEFAULT_VARIANT

which itself defaults to the latest version. This is mostly for testing,
Older variants will be deprecated and removed eventually.

The list of supported variants is as follows:

    5 - Xor, siphash, with inthash, 8 byte alignment, one checksum.

In version 0.15 we switched hash functions to use SipHash(1-3), which
unfortunately made supporting variants prior to 5 impossible.

=back

=item validate_file

Validate the file specified by the 'file' argument. Returns a list of
two values, 'variant' and 'message'. If the file fails validation the 'variant'
will be undef and the 'message' will contain an error message. If the file
passes validation the 'variant' will specify the variant of the file
(currently only 0 is valid), and 'message' will contain some basic information
about the file, such as how many keys it contains, the comment it was
created with, etc.

=back

=head2 SUBS

=over 4

=item mph2l_tied_hashref

Simple wrapper to replace the cumbersome

    tie my %hash, "Tie::Hash::MinPerfHashTwoLevel::OnDisk", $file;

with a simple sub that can be imported

    my $hashref= mph2l_tied_hashref($file,$validate);

The validate flag causes MPH_F_VALIDATE validations to occur on load.

=item mph2l_make_file

Sub form of L<make_file>. Eg:

  use Tie::Hash::MinPerfHashTwoLevel::OnDisk;
  Tie::Hash::MinPerfHashTwoLevel::OnDisk->make_file(@args);

is identical to

  use Tie::Hash::MinPerfHashTwoLevel::OnDisk qw(mph2l_make_file);
  mph2l_make_file(@args);

Sub form of C<make_file()>.

=item mph2l_validate_file

Sub form of C<validate_file()>. Eg:

  use Tie::Hash::MinPerfHashTwoLevel::OnDisk;
  Tie::Hash::MinPerfHashTwoLevel::OnDisk->validate_file(@args);

is identical to

  use Tie::Hash::MinPerfHashTwoLevel::OnDisk qw(mph2l_validate_file);
  mph2l_validate_file(@args);

=back

=head2 TIED INTERFACE

  my %hash;
  tie %hash, "Tie::Hash::MinPerfHashTwoLevel::OnDisk", $some_file, $flags;

will setup %hash to read from the mmapped image on disk as created by make_file().
The underlying image is never altered, and copies of the keys and values are made
when necessary. The flags field is an integer which contains bit-flags to control
the reading process, currently only one flag is supported MPH_F_VALIDATE which enables
a full file checksum before returning (forcing the data to be loaded and then read).
By default this validation is disabled, however basic checks of that the header is
sane will be performed on loading (or "mounting") the image. The tie operation may
die if the file is not found or any of these checks fail.

As this is somewhat cumbersome to type you may want to look at the mph2l_tied_hashref()
function which is wrapper around this function.

=head2 FILE FORMAT

Currently there is only one support file format variant, 5.

The file structure consists of a header, followed by a byte vector of seed/state
data for the hash function, followed by a bucket table with records of a fixed size,
optionally followed by a bitvector of the flags for the keys with two bits per key,
optionally followed by a bitvector of flags for values with one bit per value,
followed by a string table containing the comment for the file and the strings it 
contains, and lastly a checksum; the last 8 bytes of the file contain a hash of the
rest of the file. The key flags may be 0 for "latin-1/not-utf8", 1 for "is-utf8", 
and 2 for "was-utf8" which is used for keys which can be represented as latin-1, 
but should be restored as unicode/utf8. The val flags are similar but do not (need to) 
support "was-utf8".

Structure:

    Header
    Hash-state
    Bucket-table
    Key flags (optional)
    Val flags (optional)
    Strings
    Checksum

Header:

    U32 magic_num       -> 1278363728 -> "PH2L"
    U32 variant         -> 5
    U32 num_buckets     -> number of buckets/keys in hash
    U32 state_ofs       -> offset in file where hash preseeded state is found
    U32 table_ofs       -> offset in file where bucket table starts
    U32 key_flags_ofs   -> offset in file where key flags are located
    U32 val_flags ofs   -> offset in file where val flags are located
    U32 str_buf_ofs     -> offset in file where strings are located
    U64 general_flags   -> flags used for this header
    U64 reserved        -> reserved field.

All "_ofs" values in the header are a multiple of 8, and the relevant sections
maybe be null padded to ensure this is so.

The string buffer contains the comment at str_buf_ofs+1, its length can be found
with strlen(), the comment may NOT contain nulls, and will be null terminated. All
other strings in the table are NOT null padded, the length data stored in the
bucket records should be used to determine the length of the keys and values. 
The last 8 bytes of the file contains a hash checksum of the rest of the entire 
file. This value is itself 8 byte aligned.

Buckets:

   U32 xor_val      -> the xor_val for this bucket's h1 lookups (0 means none)
                       for variant 1 and later this may also be treated as a signed
                       integer, with negative values representing the index of
                       the bucket which contains the correct key (-index-1).
   U32 key_ofs      -> offset from str_buf_ofs to find this key (nonzero always)
   U32 val_ofs      -> offset from str_buf_ofs to find this value (0 means undef)
   U16 key_len      -> length of key
   U16 val_len      -> length of value

The hash function used is Siphash 1-3, which uses a 16 byte seed to produce
a 32 byte state vector used for hashing. The file contains the state vector
required for hashing and does not include the original seed.

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
