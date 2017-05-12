package Algorithm::ConsistentHash::Ketama;
use strict;
use Algorithm::ConsistentHash::Ketama::Bucket;
use XSLoader;
our $VERSION;

BEGIN {
    $VERSION = '0.00012';
    XSLoader::load( __PACKAGE__, $VERSION );
}
use constant +{
    HASHFUNC1 => 1,
    HASHFUNC2 => 2,
};
our $DEFAULT_HASHFUNC = HASHFUNC1; # Use old behavior by default (broken).
our %VALID_HASHFUNCS = map { ($_ => 1) } (HASHFUNC1, HASHFUNC2);

sub new {
    my ($class, %args) = @_;

    my $hf = $DEFAULT_HASHFUNC;
    my $x_hf = $args{use_hashfunc};
    if (defined $x_hf) {
        if (exists $VALID_HASHFUNCS{$x_hf}) {
            $hf = $x_hf
        }
        # for all other values of $x_hf, ignore it
    }

    my $self = $class->xs_create($x_hf);
    return $self;
}

1;

__END__

=head1 NAME

Algorithm::ConsistentHash::Ketama - Ketama Consistent Hashing for Perl (XS)

=head1 SYNOPSIS

    use Algorithm::ConsistentHash::Ketama;

    my $ketama = Algorithm::ConsistentHash::Ketama->new();

    # Or
    # $ketama = Algorithm::ConsistentHash::Ketama->new(
    #    use_hashfunc => Algorithm::ConsistentHash::Ketama::HASHFUNC2(),
    # )
    # See "IMPORTANT NOTES FOR USERS OF 0.00011 AND BELOW"

    $ketama->add_bucket( $key1, $weight1 );
    $ketama->add_bucket( $key2, $weight2 );
    $ketama->add_bucket( $key3, $weight3 );
    $ketama->add_bucket( $key4, $weight4 );

    my $key = $ketama->hash( $thing );

=head1 DESCRIPTION

WARNING: Alpha quality code -- and I wrote it for the heck of it, so no
guarantees as of yet. Patches, tests welcome.

This module implements just the libketama algorithm. You can specify a list of
"buckets", and then you can get the corresponding bucket name back when you
hash a string.

=head1 METHODS

=head2 new

Creates a new instance of Algorithm::ConsistentHash::Ketama

=head2 clone

Clones the current object.

=head2 add_bucket( $key, $weight )

Adds a bucket to the list. C<$key> is the name of the bucket, and C<$weight>
denotes the weight of the C<$key>.

=head2 hash( $string )

Returns the corresponding bucket name (which you gave when you did add_bucket).

=head2 remove_bucket( $key )

Removes the given bucket from the list

=head2 buckets()

Returns a list of Algorithm::ConsistentHash::Ketama::Bucket objects

=head2 hash_with_hashnum( $string )

This is an advanced function. Reach for it only if you know exactly
why you need it.

Returns both the label (as with the hash() function) AND the computed internal
hash. This internal hash number can be used to look up the label again without
recomputing the hash.

=head2 label_from_hashnum( $hash )

Given a number, returns the label associated with that hash number. Only
hashes returned by hash_with_hashnum are permissible.

=head1 IMPORTANT NOTES FOR USERS OF 0.00011 AND BELOW

Prior to version 0.00010 of this module, there used be a integer underflow
bug. which caused inconsistencies with other implementations of this algorithm.

This has been reported here: https://github.com/dgryski/go-ketama/commit/5fb0f7e85cb457c4cfb78bb892d02434d9f0620b

The underflow should be fixed, but because this changes the hashing behavior
for some keys and you may have already filled your cache with important data
already, the old behavior is preserved by default.

If you would like to switch to the new behavior, you may do one of the
following:

    # Change the behavior for this particular instance of A::C::Ketama:
    my $ketama = Algorithm::ConsistentHash::Ketama->new(
        use_hashfunc => Algorithm::ConsistentHash::Ketama::HASHFUNC2(),
    );

    # Globally change the behavior
    local $Algorithm::ConsistentHash::Ketama::DEFAULT_HASHFUNC =
        Algorithm::ConsistentHash::Ketama::HASHFUNC2();
    my $ketama = Algorithm::ConsistentHash::Ketama->new();

=head1 LICENSE AND COPYRIGHT

Portions of this distribution are derived from libketama, which is:

    Copyright (C) 2007 by                                          
       Christian Muehlhaeuser C<< <chris@last.fm> >>
       Richard Jones C<< <rj@last.fm> >>

Affected portions are licensed under GPL v2.

The rest of the code which is written by Daisuke Maki are available under
Artistic License v2, and is:

    Copyright (C) 2010  Daisuke Maki C<< <daisuke@endeworks.jp> >>

Please see the file xs/Ketama.xs for more detail.

=cut
