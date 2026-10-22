# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Request;

use v5.10;
use strict;
use warnings;

use Carp;
use Scalar::Util qw(weaken);
use URI;

use Data::Identifier v0.25;

use parent 'Data::Identifier::Interface::Userdata';

use constant {
    BOOL_TRUE  => Data::Identifier->new(uuid => 'eb50b3dc-28be-4cfc-a9ea-bd7cee73aed5')->register,
    BOOL_FALSE => Data::Identifier->new(uuid => '6d34d4a1-8fbc-4e22-b3e0-d50f43d97cb1')->register,
};

our $VERSION = v0.26;

my %_attributes = (
    service => {rawtype => 'Data::URIID::Service'},
    result  => {rawtype => 'Data::URIID::Result'},
    online  => {prepare => sub { $_[1] ? BOOL_TRUE : BOOL_FALSE }},
    pass    => {prepare => sub { require Data::Identifier::Generate; Data::Identifier::Generate->integer($_[1]) }},
    (map {$_ => {prepare => sub { URI->new($_[1]) }}} qw(request_url actual_url)),
    (map {$_ => {}} qw(structured raw_data decoded_data)),
);



sub attribute {
    my ($self, $key, %opts) = @_;
    my $info = $_attributes{$key} // croak 'No such key';
    my $raw = $self->{$key};
    my @list;

    unless (defined $raw) {
        if (exists $opts{default}) {
            return @{$opts{default}} if $opts{list};
            return $opts{default};
        }

        croak 'No such data';
    }

    if (ref($raw) eq 'ARRAY') {
        @list = @{$raw};
    } else {
        @list = ($raw);
    }

    if (defined(my $as = $opts{as})) {
        if (defined(my $prepare = $info->{prepare})) {
            foreach my $ent (@list) {
                $ent = $self->$prepare($ent);
            }
        }
        foreach my $ent (@list) {
            $ent = Data::Identifier::as($ent => $as, extractor => $self->{extractor}, rawtype => $info->{rawtype});
        }
    }

    if ($opts{list}) {
        return @list;
    } elsif (scalar(@list) == 1) {
        return $list[0];
    } else {
        croak 'Zero or multiple values, need to call with list => 1';
    }
}

# ---- Private helpers ----

sub _construct {
    my ($pkg, %opts) = @_;

    return undef unless defined $opts{result};

    if (defined(my $target = $opts{result}{requests})) {
        my $self = bless \%opts, $pkg;

        weaken($self->{result});

        $self->{pass}   = int $self->{pass} if exists($self->{pass}) && defined($self->{pass});

        push(@{$target}, $self);

        return $self;
    }

    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Request - Extractor for identifiers from URIs

=head1 VERSION

version v0.26

=head1 SYNOPSIS

    use Data::URIID::Request;

(experimental since v0.26)

This package inherits from
L<Data::Identifier::Interface::Userdata> (since v0.26).

=head1 METHODS

=head2 attribute

    my $value  = $request->attribute($key [, %opts ] );
    # or:
    my @values = $request->attribute($key [, %opts ], list => 1 );

(experimental since v0.26)

This returns a value from the request.
The type of returned value depend on the given key and options.

If the key is unknown or no value is present this method will C<die>.

The following attributes are defined. Not all of them are available for all requests.

=over

=item C<actual_url>

(experimental since v0.26)

If the request is to an external service the actual URL that was queried.
This can be a local file.

=item C<online>

(experimental since v0.26)

Whether the request was an online request.
Note that the same result can include online and offline requests.

=item C<pass>

(experimental since v0.26)

The pass number in which the request happened.
This might not be defined if the request was made outside the multipass body, such as a warmup request.
Which numbers can be returned is not defined. However larger numbers mean later.

=item C<request_url>

(experimental since v0.26)

The initial URL that was requested (before any overrides or redirects).

=item C<result>

(experimental since v0.26)

The result (see L<Data::URIID::Result>) for which this is an request.

=item C<service>

(experimental since v0.26)

The service (see L<Data::URIID::Service>) which was queried.

=back

The following, all optional, options are supported:

=over

=item C<default>

Returns the given value if no value is found.
This can also be set to C<undef> to allow returning C<undef> in case of no value found instead of C<die>-ing.

=item C<no_defaults>

(ignored)

=item C<list>

Returns the value as a list. When not in list mode, there must be exactly one value, otherwise this method will C<die>.

=item C<as>

The type to return the value in. This is implemented via L<Data::Identifier/as>.

=back

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
