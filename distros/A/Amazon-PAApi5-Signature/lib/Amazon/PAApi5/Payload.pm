package Amazon::PAApi5::Payload;
use strict;
use warnings;
use Carp qw/croak/;
use String::CamelCase qw/decamelize/;
use JSON qw//;
use Class::Accessor::Lite (
    rw  => [qw/
        partner_tag
        marketplace
        partner_type
    /],
);

sub new {
    my $class       = shift;
    my $partner_tag = shift or croak 'partner_tag is required';
    my $marketplace = shift || 'www.amazon.com';
    my $opt         = shift || {};

    return bless {
        partner_tag  => $partner_tag,
        marketplace  => $marketplace,
        partner_type => $opt->{partner_type} || 'Associates',
    }, $class;
}

sub to_json {
    my ($self, $data) = @_;

    my $hash = {};

    for my $k (keys %{$data}) {
        $hash->{$k} = $data->{$k};
    }

    for my $k (qw/
        PartnerTag
        Marketplace
        PartnerType
    /) {
        my $method = decamelize($k);
        $hash->{$k} = $self->$method;
    }

    return JSON::to_json($hash, { utf8 => 0, canonical => 1 });
}

1;

__END__

=encoding UTF-8

=head1 NAME

Amazon::PAApi5::Payload - Handle request body


=head1 SYNOPSIS

    use Amazon::PAApi5::Payload;

    my $payload = Amazon::PAApi5::Payload->new(
        'PARTNER_TAG'
    );

    say $payload->to_json({
        Keywords    => 'Perl',
        SearchIndex => 'All',
        ItemCount   => 2,
        Resources   => [qw/
            ItemInfo.Title
        /],
    });

=head1 DESCRIPTION

Amazon::PAApi5::Payload handles request body

See B<example/> directory of this module.

L<https://webservices.amazon.com/paapi5/documentation/api-reference.html>


=head1 METHODS

=head2 new($partner_tag, $marketplace, $options)

Constructor

=head2 to_json

Get request body as JSON string


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

C<Amazon::PAApi5::Signature> is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0. (Note that, unlike the Artistic License 1.0, version 2.0 is GPL compatible by itself, hence there is no benefit to having an Artistic 2.0 / GPL disjunction.) See the file LICENSE for details.

=cut
