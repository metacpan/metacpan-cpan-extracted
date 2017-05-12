package AnyMongo::BSON;
BEGIN {
  $AnyMongo::BSON::VERSION = '0.03';
}
# ABSTRACT: BSON encoding and decoding utilities
use strict;
use warnings;
use AnyMongo;
use parent 'Exporter';
our @EXPORT_OK = qw(bson_encode bson_decode);

$AnyMongo::BSON::char = '$';
$AnyMongo::BSON::utf8_flag_on = '$';


$AnyMongo::BSON::use_boolean = 0;

1;


=pod

=head1 NAME

AnyMongo::BSON - BSON encoding and decoding utilities

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Return boolean values as booleans instead of integers

    $MongoDB::BSON::use_boolean = 1

By default, booleans are deserialized as integers.  If you would like them to be
deserialized as L<boolean/true> and L<boolean/false>, set 
C<$MongoDB::BSON::use_boolean> to 1.

=head1 AUTHORS

=over 4

=item *

Pan Fan(nightsailer) <nightsailer at gmail.com>

=item *

Kristina Chodorow <kristina at 10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
