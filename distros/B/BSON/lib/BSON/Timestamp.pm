use 5.010001;
use strict;
use warnings;

package BSON::Timestamp;
# ABSTRACT: BSON type wrapper for timestamps

use version;
our $VERSION = 'v1.6.1';

use Carp ();

use Moo;

#pod =attr seconds
#pod
#pod A value representing seconds since the Unix epoch.  The default is
#pod current value of C<time()>.
#pod
#pod =attr increment
#pod
#pod A numeric value to disambiguate timestamps in the same second.  The
#pod default is 0.
#pod
#pod =cut

has [qw/seconds increment/] => (
    is => 'ro'
);

use namespace::clean -except => 'meta';

my $max_int32 = 2147483647;

# Support back-compat 'secs' and inc' and legacy constructor shortcut
sub BUILDARGS {
    my ($class) = shift;

    my %args;
    if ( @_ && $_[0] !~ /^[s|i]/ ) {
        $args{seconds}   = $_[0];
        $args{increment} = $_[1];
    }
    else {
        Carp::croak( __PACKAGE__ . "::new called with an odd number of elements\n" )
          unless @_ % 2 == 0;

        %args = @_;
        $args{seconds}   = $args{secs} if exists $args{secs} && !exists $args{seconds};
        $args{increment} = $args{inc}  if exists $args{inc}  && !exists $args{increment};
    }

    $args{seconds}   = time unless defined $args{seconds};
    $args{increment} = 0    unless defined $args{increment};
    $args{$_} = int( $args{$_} ) for qw/seconds increment/;

    return \%args;
}

sub BUILD {
    my ($self) = @_;

    for my $attr (qw/seconds increment/) {
        my $v = $self->$attr;
        Carp::croak("BSON::Timestamp 'seconds' must be uint32")
          unless $v >= 0 && $v <= $max_int32;
    }

    return;
}

# For backwards compatibility
{
    no warnings 'once';
    *sec = \&seconds;
    *inc = \&increment;
}

#pod =method TO_JSON
#pod
#pod If the C<BSON_EXTJSON> option is true, returns a hashref compatible with
#pod MongoDB's L<extended JSON|https://docs.mongodb.org/manual/reference/mongodb-extended-json/>
#pod format, which represents it as a document as follows:
#pod
#pod     {"$timestamp" : { "t":<seconds>, "i":<increment> }}
#pod
#pod If the C<BSON_EXTJSON> option is false, an error is thrown, as this value
#pod can't otherwise be represented in JSON.
#pod
#pod =cut

sub TO_JSON {
    if ( $ENV{BSON_EXTJSON} ) {
        return { '$timestamp' => { t => $_[0]->{seconds}, i => $_[0]->{increment} } };
    }

    Carp::croak( "The value '$_[0]' is illegal in JSON" );
}

sub _cmp {
    my ( $l, $r ) = @_;
    return ( $l->{seconds} <=> $r->{seconds} )
      || ( $l->{increment} <=> $r->{increment} );
}

use overload (
    '<=>'     => \&_cmp,
    fallback => 1,
);

1;

=pod

=encoding UTF-8

=head1 NAME

BSON::Timestamp - BSON type wrapper for timestamps

=head1 VERSION

version v1.6.1

=head1 SYNOPSIS

    use BSON::Types ':all';

    bson_timestamp( $seconds );
    bson_timestamp( $seconds, $increment );

=head1 DESCRIPTION

This module provides a BSON type wrapper for a BSON timestamp value.

Generally, it should not be used by end-users, but is provided for
backwards compatibility.

=head1 ATTRIBUTES

=head2 seconds

A value representing seconds since the Unix epoch.  The default is
current value of C<time()>.

=head2 increment

A numeric value to disambiguate timestamps in the same second.  The
default is 0.

=head1 METHODS

=head2 TO_JSON

If the C<BSON_EXTJSON> option is true, returns a hashref compatible with
MongoDB's L<extended JSON|https://docs.mongodb.org/manual/reference/mongodb-extended-json/>
format, which represents it as a document as follows:

    {"$timestamp" : { "t":<seconds>, "i":<increment> }}

If the C<BSON_EXTJSON> option is false, an error is thrown, as this value
can't otherwise be represented in JSON.

=for Pod::Coverage BUILD BUILDARGS sec inc

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Stefan G. <minimalist@lavabit.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Stefan G. and MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
