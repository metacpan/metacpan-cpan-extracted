package Data::AnyXfer::Elastic::Import::File::Format;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);


=head1 NAME

Data::AnyXfer::Elastic::Import::File::Format - Role representing
an Elasticsearch import data storage format

=head1 SYNOPSIS

    # data to printable characters
    my $storable_output = $format->serialise($data);

    # and back again
    my $original_data = $format->deserialise($storable_output);

=head1 DESCRIPTION

This role is used by
L<Data::AnyXfer::Elastic::Import::File> and related modules to store
and restore complex data.

Details of actual
storage and persistence are handled by the
L<Data::AnyXfer::Elastic::Import::Storage> backend.

=head1 SEE ALSO

L<Data::AnyXfer::Elastic::Import::File>,
L<Data::AnyXfer::Elastic::Import::Storage>

=head1 REQUIRED METHODS

=head2 serialise

    # data to printable characters
    my $storable_output = $format->serialise($data);

Serialise a perl data structure to printable characters / a storable
representation (can also return binary data).

Should either succeed or die with errors.

=head2 deserialise

    # and back again
    my $original_data = $format->deserialise($storable_output);

De-serialise perl data from character or binary data back to the original
 data structure.

Should either succeed or die with errors.

=head1 OPTIONAL METHODS

=head2 format_suffix

A short slug or format name which can be used to identify this serialisation
 format

=cut


use constant format_suffix => '';

requires 'serialise';

requires 'deserialise';



1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

