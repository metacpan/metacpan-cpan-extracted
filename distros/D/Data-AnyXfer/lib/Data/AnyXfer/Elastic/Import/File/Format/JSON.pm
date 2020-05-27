package Data::AnyXfer::Elastic::Import::File::Format::JSON;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Data::AnyXfer::JSON ( );

with 'Data::AnyXfer::Elastic::Import::File::Format';


=head1 NAME

Data::AnyXfer::Elastic::Import::File::Format::JSON -
Elasticsearch import data storage format using JSON

=head1 SYNOPSIS

    # data to printable characters
    my $json_string = $format->serialise($data);

    # and back again
    my $original_data = $format->deserialise($json_string);

=head1 DESCRIPTION

This class can be supplied to a
L<Data::AnyXfer::Elastic::Import::File> implementation
to store and retrieve data in JSON format from a storage backend.

=head1 SEE ALSO

L<Data::AnyXfer::Elastic::Import::File>,
L<Data::AnyXfer::Elastic::Import::Storage>,
L<Data::AnyXfer::JSON>

=head1 FORMAT INTERFACE

B<Please see L<Data::AnyXfer::Elastic::Import::File::Format>
for the interface definition and information>.

=head2 Implementation Details

=over

=item B<format_suffix> - C<.json>

=item This module is based on L<Data::AnyXfer::JSON>.

=back

=cut


use constant format_suffix => '.json';


sub serialise {
    return Data::AnyXfer::JSON::encode_json($_[1]);
}

sub deserialise {
    return Data::AnyXfer::JSON::decode_json($_[1]);
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

