use strict;
use warnings;
use 5.010_001;

package    # hide from PAUSE
    DBIx::Squirrel::util;

=pod

=encoding UTF-8

=head1 NAME

DBIx::Squirrel::util - Utilities

=head1 DESCRIPTION

A collection of helper functions used by other DBIx::Squirrel packages.

=cut

our @ISA = qw(Exporter);
our @EXPORT;
our %EXPORT_TAGS = ( all => [
    our @EXPORT_OK = qw(
        carpf
        cluckf
        confessf
        decrypt
        get_file_contents
        global_destruct_phase
        isolate_callbacks
        slurp
        uncompress
        unmarshal
        utf8decode
    )
] );

use Carp                          ();
use Compress::Bzip2               ();
use Devel::GlobalDestruction      ();
use Dotenv                        ();
use Encode                        ();
use Exporter                      ();
use JSON::Syck                    ();
use DBIx::Squirrel::Crypt::Fernet ();

if ( -e '.env' ) {
    Dotenv->load();
}

=head2 EXPORTS

Nothing is exported by default.

=head3 C<carpf>

Emits a warning without a stack-trace.

    carpf();

The warning will be set to C<$@> if it contains something useful. Otherwise 
an "Unhelpful warning" will be emitted.

    carpf($message);
    carpf(\@message);

The warning will be set to C<$message>, or the concatenated C<@message> array,
or C<$@>, if there is no viable message. If there is still no viable message
then an "Unhelpful warning" is emitted.

During concatenation, the elements of the C<@message> array are separated
by a single space. The intention is to allow for long warning messages to be
split apart in a tidier manner.

    carpf($format, @arguments);
    carpf(\@format, @arguments);

The warning is composed using a C<sprintf> format-string (C<$format>), together
with any remaining arguments. Alternatively, the format-string may be produced
by concatenating the C<@format> array whose elements are separated by a single
space.

=cut

sub carpf {
    @_ = do {
        if (@_) {
            my $format = do {
                if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                    join ' ', @{ +shift };
                }
                else {
                    shift;
                }
            };
            if (@_) {
                sprintf $format, @_;
            }
            else {
                $format or $@ or 'Unhelpful warning';
            }
        }
        else {
            $@ or 'Unhelpful warning';
        }
    };
    goto &Carp::carp;
}


=head3 C<cluckf>

Emits a warning with a stack-trace.

    cluckf();

The warning will be set to C<$@> if it contains something useful. Otherwise 
an "Unhelpful warning" will be emitted.

    cluckf($message);
    cluckf(\@message);

The warning will be set to C<$message>, or the concatenated C<@message> array,
or C<$@>, if there is no viable message. If there is still no viable message
then an "Unhelpful warning" is emitted.

During concatenation, the elements of the C<@message> array are separated
by a single space. The intention is to allow for long warning messages to be
split apart in a tidier manner.

    cluckf($format, @arguments);
    cluckf(\@format, @arguments);

The warning is composed using a C<sprintf> format-string (C<$format>), together
with any remaining arguments. Alternatively, the format-string may be produced
by concatenating the C<@format> array whose elements are separated by a single
space.

=cut

sub cluckf {
    @_ = do {
        if (@_) {
            my $format = do {
                if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                    join ' ', @{ +shift };
                }
                else {
                    shift;
                }
            };
            if (@_) {
                sprintf $format, @_;
            }
            else {
                $format or $@ or 'Unhelpful warning';
            }
        }
        else {
            $@ or 'Unhelpful warning';
        }
    };
    goto &Carp::cluck;
}


=head3 C<confessf>

Throws and exception with a stack-trace.

    confessf();

The error will be set to C<$@> if it contains something useful (effectivly
re-throwing the previous exception). Otherwise it will an "Unknown error"
exception is thrown.

    confessf($message);
    confessf(\@message);

The error will be set to C<$message>, or the concatenated C<@message> array,
or C<$@>, if there is no viable message. If there is still no viable message
then an "Unknown error" is thrown.

During concatenation, the elements of the C<@message> array are separated
by a single space. The intention is to allow for long error messages to be
split apart in a tidier manner.

    confessf($format, @arguments);
    confessf(\@format, @arguments);

The error message is composed using a C<sprintf> format-string (C<$format>),
together with any remaining arguments. Alternatively, the format-string may
be produced by concatenating the C<@format> array whose elements are separated
by a single space.

=cut

sub confessf {
    @_ = do {
        if (@_) {
            my $format = do {
                if ( UNIVERSAL::isa( $_[0], 'ARRAY' ) ) {
                    join ' ', @{ +shift };
                }
                else {
                    shift;
                }
            };
            if (@_) {
                sprintf $format, @_;
            }
            else {
                $format or $@ or 'Unknown error';

            }
        }
        else {
            $@ or 'Unknown error';
        }
    };
    goto &Carp::confess;
}


=head3 C<decrypt>

    $buffer = decrypt($fernet_key);
    $buffer = decrypt($buffer, $fernet_key);

Decrypts a Fernet-encrypted buffer, returning the decrypted data.

A Fernet key can be provided as the second argument, and this can be a
Base64-encoded string or a C<DBIx::Squirrel::Crypt::Fernet> instance. If no
second argument is defined, the function will fall back to using the
C<FERNET_KEY> environment variable, and if that isn't defined then an
exception will be thrown.

If C<$buffer> is omitted then C<$_> will be used.

=cut

sub decrypt {
    my $fernet = pop;
    my $buffer = @_ ? shift : $_;
    unless ( defined $fernet ) {
        unless ( defined $ENV{FERNET_KEY} ) {
            confessf [
                "Neither a Fernet key nor a Fernet object have been",
                "defined. Decryption is impossible",
            ];
        }
        $fernet = $ENV{FERNET_KEY};
    }
    $fernet = DBIx::Squirrel::Crypt::Fernet->new($fernet)
        unless UNIVERSAL::isa( $fernet, 'DBIx::Squirrel::Crypt::Fernet' );
    return $_ = $fernet->decrypt($buffer);
}


=head3 C<get_file_contents>

    $contents = get_file_contents($filename[, \%options]);

Return the entire contents of a file to the caller.

The file is read in raw (binary) mode. What happens to the contents after
reading depends on the file's name and/or the contents of C<%options>:

=over

=item *

If ".encrypted" forms part of the file's name or the C<decrypt> option is
true, then the file contents will be decrypted after they have been read
using the Fernet key provided in the C<fernet> option or the C<FERNET_KEY>
environment variable.

=item *

If ".bz2" forms part of the file's name or the C<uncompress> option is
true, then the file contents will be uncompressed after they have been read
and possibly decrypted.

=item *

If ".json" forms part of the file's name or the C<unmarshal> option is
true, then the file contents will be unmarshalled after they have been read,
possibly decrypted, and possibly uncompressed.

=item *

If the C<utf8decode> option is true, then the file contents will be decoded
as a UTF-8 string.

=back

=cut

sub get_file_contents {
    my $filename = shift;
    my $options  = { utf8decode => !!1, %{ shift || {} } };
    my $contents = slurp($filename);
    $contents = decrypt( $contents, $options->{fernet} )
        if $filename =~ /\.encrypted\b/ || $options->{decrypt};
    $contents = uncompress($contents)
        if $filename =~ /\.bz2\b/ || $options->{uncompress};
    return unmarshal($contents)
        if $filename =~ /\.json\b/ || $options->{unmarshal};
    return utf8decode($contents)
        if $options->{utf8decode};
    return $_ = $contents;
}


=head3 C<global_destruct_phase>

    $bool = global_destruct_phase();

Detects whether the Perl program is in the Global Destruct Phase. Knowing
this can make C<DESTROY> methods safer. Perl versions older than 5.14
don't support the ${^GLOBAL_PHASE} variable, so provide a shim that
works regardless of Perl version.

=cut

sub global_destruct_phase {
    return Devel::GlobalDestruction::in_global_destruction();
}


=head3 C<isolate_callbacks>

    (\@callbacks, @arguments) = isolate_callbacks(@argments);

When using C<DBIx::Squirrel>, some calls allow the caller to reshape results
before they are returned, using transformation pipelines. A transformation
pipeline is one or more contiguous code-references presented at the end of
a call's argument list. 

Th C<isolate_callbacks> function inspects an array of arguments, moving any
trailing code-references from the source array into a separate array — the
transformation pipeline. It returns a reference to that array, followed by
any remaining arguments, to the caller.

    (\@callbacks, @arguments) = &isolate_callbacks;

The terse C<&>-sigil calling style causes C<isolate_callbacks> to use the
calling function's C<@_> array.

=cut

sub isolate_callbacks {
    my $n = my $s = scalar @_;
    $n-- while $n && UNIVERSAL::isa( $_[ $n - 1 ], 'CODE' );
    return [], @_ if $n == $s;
    return [ @_[ $n .. $#_ ] ], @_[ 0 .. $n - 1 ] if $n;
    return [@_];
}


=head3 C<slurp>

    $buffer = slurp();
    $buffer = slurp($filename);

Reads the entirety of the specified file in raw mode, returning the contents.

If C<$filename> is omitted then C<$_> will be used.

=cut

sub slurp {
    my $filename = @_ ? shift : $_;
    open my $fh, '<:raw', $filename
        or confessf "$! - $filename";
    read $fh, my $buffer, -s $filename;
    close $fh;
    return $_ = $buffer;
}


=head3 C<uncompress>

    $buffer = uncompress();
    $buffer = uncompress($buffer);

Uncompresses a Bzip2-compressed buffer, returning the uncompressed data.

If C<$buffer> is omitted then C<$_> will be used.

=cut

sub uncompress {
    my $buffer = @_ ? shift : $_;
    return $_ = Compress::Bzip2::memBunzip($buffer);
}


=head3 C<unmarshal>

    $data = unmarshal($json);
    $data = unmarshal($json, $decode);

Unmarshals a JSON-encoded buffer into the data-structure it represents. By
default, UTF-8 binaries are properly decoded, and this behaviour can be
inhibited by setting C<$decode> to false.

=cut

sub unmarshal {
    my $json   = shift;
    my $decode = @_ ? !!shift : !!1;
    local $JSON::Syck::ImplicitUnicode = $decode;
    return $_ = JSON::Syck::Load( $decode ? utf8decode($json) : $json );
}


=head3 C<utf8decode>

    $string = utf8decode();
    $string = utf8decode($buffer);

Decode a byte buffer, returning a UTF-8 string.

If C<$buffer> is omitted then C<$_> will be used.

=cut

sub utf8decode {
    my $buffer = @_ ? shift : $_;
    return $_ = Encode::decode_utf8( $buffer, @_ );
}

=head1 AUTHORS

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENSE

The DBIx::Squirrel module is Copyright (c) 2020-2025 Iain Campbell.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl 5.10.0 README file.

=head1 SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=cut

1;
