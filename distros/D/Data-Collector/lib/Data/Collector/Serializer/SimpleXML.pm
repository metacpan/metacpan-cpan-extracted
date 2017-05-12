package Data::Collector::Serializer::SimpleXML;
{
  $Data::Collector::Serializer::SimpleXML::VERSION = '0.15';
}
# ABSTRACT: A XML::Simple serializer for Data::Collector

use Moose;
use XML::Simple;
use namespace::autoclean;

sub serialize {
    my ( $self, $data ) = @_;

    return XMLout($data);
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Data::Collector::Serializer::SimpleXML - A XML::Simple serializer for Data::Collector

=head1 VERSION

version 0.15

=head1 DESCRIPTION

Utilizes L<XML::Simple>.

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

