package App::Oozie::Serializer;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.019'; # VERSION

use App::Oozie::Util::Plugin qw(
    find_plugins
    load_plugin
);
use Moo;
use Types::Standard qw(
    InstanceOf
    Int
    Str
);
use Type::Library ();

use constant {
    VALID_SERIALIZERS => find_plugins( __PACKAGE__ ),
};

has 'format' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

has enforce_type => (
    is  => 'rw',
    isa => InstanceOf['Type::Tiny'],
);

has slurp => (
    is      => 'rw',
    isa     => Int,
    default => sub { 0 },
);

has __file => (
    is => 'rwp',
);

has '__object' => (
    is => 'rwp',
);

sub BUILD {
    my ($self, $args) = @_;
    my $s = VALID_SERIALIZERS->{ $args->{format} };

    if ( ! $s ) {
        my $default = 'dummy';
        warn sprintf '%s is an unknown serializer, falling back to %s',
                        $args->{format},
                        $default,
        ;
        $self->format( $default );
        ($s) = grep { m{::${default} \z}xmsi } values %{ +VALID_SERIALIZERS };
    }

    if ( ! $s ) {
        # Shouldn't happen, apart from a possible future code change
        die 'Failed to locate a serializer!';
    }

    $self->_set___object( load_plugin( $s )->new );

    return;
}

sub encode {
    my $self = shift;
    my $data = shift || die 'Nothing to encode!';

    die 'The data to encode needs to be a reference' if ! ref $data;

    $self->_assert_type( $data ) if $self->enforce_type;

    return $self->__object->encode( $data )
}

sub decode {
    my $self = shift;
    my $data = shift || die 'Nothing to decode!';

    die q{The data to decode can't be a reference!} if ref $data;

    my $is_file = $self->slurp && $data !~ m{ \n }xms && -e $data && -f _;

    my $rv = $self->__object->decode(
          $is_file            ? do { local(@ARGV, $/) = $data; <> }
        : $data eq 'meta.yml' ? die 'Only a file name (which does not exist) passed as meta data'
                 : $data
    );

    if ( $is_file ) {
       $self->_set___file( $data );
    }

    $self->_assert_type( $rv ) if $self->enforce_type;

    return $rv;
}

sub _assert_type {
    my $self  = shift;
    my $input = shift || die 'No data specified to enforce a type!';
    my $type  = $self->enforce_type || return;

    my $failed   = $type->validate_explain( $input, 'USER_INPUT' ) || return;
    my $full_msg = join "\n\n", @{ $failed };
    require Data::Dumper;
    my $d        = Data::Dumper->new( [ $input ], [ '*INPUT' ] );

    die sprintf <<'DID_NOT_PASS', $full_msg, $d->Dump;
The data structure does not match the type definition: %s

Input was decoded as (compare to the errors above):

%s
DID_NOT_PASS
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Oozie::Serializer

=head1 VERSION

version 0.019

=head1 SYNOPSIS

    use App::Oozie::Serializer;
    my $s = App::Oozie::Serializer->new(
        # ...
        format => 'yaml',
    );
    my $d = $s->decode( $input );

=head1 DESCRIPTION

Internal serializer.

=for Pod::Coverage BUILD

=head1 NAME

App::Oozie::Serializer - Serializer for various formats.

=head1 Methods

=head2 decode

=head2 encode

=head1 Accessors

=head2 Overridable from sub-classes

=head3 enforce_type

=head3 format

=head3 slurp

=head1 SEE ALSO

L<App::Oozie>.

=head1 AUTHORS

=over 4

=item *

David Morel

=item *

Burak Gursoy

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Booking.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
