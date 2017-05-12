use strict;
use warnings;
package Dancer::Serializer::CBOR;
# ABSTRACT: serializer for handling CBOR data

use Carp;
use Dancer::Exception qw(:all);
use CBOR::XS;
use base 'Dancer::Serializer::Abstract';

our $VERSION = '0.101'; # VERSION



sub serialize {
    my ($self, $entity) = @_;
    CBOR::XS::encode_cbor($entity);
}


sub deserialize {
    my ($self, $content) = @_;
    CBOR::XS::decode_cbor($content);
}


sub content_type {'application/cbor'}


1;

__END__

=pod

=head1 NAME

Dancer::Serializer::CBOR - serializer for handling CBOR data

=head1 VERSION

version 0.101

=head1 DESCRIPTION

This serializer allows to serialize and deserialize automatically the CBOR (Concise Binary Object Representation) structure.

=head1 SYNOPSIS

    use Dancer;
    
    set serializer => 'CBOR';
    
    get '/view/user/:id' => sub {
        my $id = params->{'id'};
        return { user => get_id($id) };
    };

=head1 METHODS

=head2 serialize

Serialize a data structure to a concise binary object representation.

=head2 deserialize

Deserialize a concise binary object representation to a data structure.

=head2 content_type

Return 'application/cbor'

=head1 SEE ALSO

=over 4

=item * L<CBOR::XS>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libdancer-serializer-cbor-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
