package Data::Collector::Serializer::JSON;
{
  $Data::Collector::Serializer::JSON::VERSION = '0.15';
}
# ABSTRACT: A JSON serializer for Data::Collector

use JSON;
use Moose;
use namespace::autoclean;

sub serialize {
    my ( $self, $data ) = @_;

    return encode_json $data;
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Data::Collector::Serializer::JSON - A JSON serializer for Data::Collector

=head1 VERSION

version 0.15

=head1 DESCRIPTION

Utilizes L<JSON>.

=head1 SUBROUTINES/METHODS

=head2 serialize

Gets data, serializes it and returns it.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

