package Broadworks::OCIP::Response;

# ABSTRACT: A Broadworks OCI-P Response Message

use strict;
use warnings;
use utf8;
use feature 'unicode_strings';

our $VERSION = '0.08'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Broadworks::OCIP::Throwable;
use Moose;
use Method::Signatures;
use MooseX::StrictConstructor;
use Try::Tiny;
use XML::Fast;


# ------------------------------------------------------------------------
sub _list {
    return () unless ( defined( $_[0] ) );
    return @{ $_[0] } if ( ref( $_[0] ) eq 'ARRAY' );
    return $_[0];
}

# ------------------------------------------------------------------------


has xml => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# ------------------------------------------------------------------------


has expected => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# ------------------------------------------------------------------------


has die_on_error => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
    default  => 1,
);

# ------------------------------------------------------------------------


has hash => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_hash'
);

method _build_hash () {
    my $hash;
    try { $hash = XML::Fast::xml2hash( $self->xml ); }
    catch {
        Broadworks::OCIP::Throwable->throw(
            message         => sprintf( "Error on XML unpack %s with %s", $_, $self->xml ),
            execution_phase => 'response',
            error_code      => 'xml_unpack'
        );
    };

    Broadworks::OCIP::Throwable->throw(
        message         => sprintf( "Nothing returned from parse - received XML was [%s]", $self->xml ),
        execution_phase => 'response',
        error_code      => 'xml_null'
    ) unless ( $hash and $hash->{BroadsoftDocument} and ( $hash->{BroadsoftDocument}{-protocol} eq 'OCI' ) );

    return $hash->{BroadsoftDocument};
}

# ------------------------------------------------------------------------


has type => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => '_build_type',
    weak_ref => 1
);
method _build_type () { return ( $self->payload->{'-xsi:type'} ); }

# ------------------------------------------------------------------------


has status_ok => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_build_status_ok'
);
method _build_status_ok () { return ( ( $self->type eq $self->expected ) ? 1 : 0 ); }

# ------------------------------------------------------------------------


has payload => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    builder  => '_build_payload',
    weak_ref => 1
);
method _build_payload () { return $self->hash->{command}; }

# ------------------------------------------------------------------------


has tables => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_tables',
);

method _build_tables () {
    my $tables = {};
    while ( my ( $k, $v ) = each %{ $self->payload } ) {
        if ( $k =~ /Table$/ ) {
            my $table = [];
            $tables->{$k} = $table;
            my @cols = _list( $v->{colHeading} );
            foreach my $row ( _list( $v->{row} ) ) {
                push( @{$table}, { map { $cols[$_] => $row->{col}->[$_] } 0 .. $#cols } );
            }
        }
    }
    return $tables;
}

# ------------------------------------------------------------------------


method table ($table_name) { return ( @{ $self->tables->{$table_name} || [] } ); }

# ------------------------------------------------------------------------
method BUILD ($args) {

    # check this object is valid and the right type
    Broadworks::OCIP::Throwable->throw(
        message =>
            sprintf( "Expecting a response of type %s but got %s\n%s\n", $self->expected, $self->type, $self->xml ),
        execution_phase => 'response',
        error_code      => 'ocip_unexpected'
    ) if ( $self->die_on_error and not $self->status_ok );
}

# ------------------------------------------------------------------------
method list ($key) {
    my $val = $self->payload->{$key};
    return () unless ( defined($val) );
    return @{$val} if ( ref($val) eq 'ARRAY' );
    return $val;
}

# ------------------------------------------------------------------------

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Broadworks::OCIP::Response - A Broadworks OCI-P Response Message

=head1 VERSION

version 0.08

=for test_synopsis 1;
__END__

=for stopwords NIGELM

=for Pod::Coverage mvp_multivalue_args

=head1 SYNOPSIS

  use Broadworks::OCIP::Response;

  my $res = Broadworks::OCIP::Response->new(
    xml => string,
    expected => 'SuccessResponse' );
  $res->status_ok;

=head1 DESCRIPTION

Unpacks an XML document sent as a reply and allows its manipulation.

=head2 Required Parameters

=head3 xml

The XML document returned.  This should be a perl string - not encoded.

=head3 expected

The response type we are expecting.  This is used to populate C<status_ok>. If
C<die_on_error> is set an exception will be thrown if the received document is
not of this type.

=head3 die_on_error

Whether we throw toys out of pram on unexpected input.

=head3 hash

A perl hash representation of the XML.

=head3 type

The type of the returned XML.

=head3 status_ok

Is this the expected return type.

=head3 payload

The hash payload of the XML document.

=head3 tables

Any tables that are in the returned data.  This returns a hash of tables named
by the table name.

Each table is an array of rows, each of which is a hash.

=head3 table

Returns the content of a single named table, as a list

=head1 AUTHOR

Nigel Metheringham <Nigel.Metheringham@redcentricplc.com>

=head1 COPYRIGHT

Copyright 2014 Recentric Solutions Limited. All rights reserved.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
