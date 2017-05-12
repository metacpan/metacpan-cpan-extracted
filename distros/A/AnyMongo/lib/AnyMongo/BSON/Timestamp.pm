package AnyMongo::BSON::Timestamp;
BEGIN {
  $AnyMongo::BSON::Timestamp::VERSION = '0.03';
}
# ABSTRACT: BSON Timestamps data type, it is used internally by MongoDB's replication.
use strict;
use warnings;
use namespace::autoclean;
use Any::Moose;


has sec => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);


has inc => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);


# __PACKAGE__->meta->make_immutable (inline_destructor => 0);
__PACKAGE__->meta->make_immutable;
1;


=pod

=head1 NAME

AnyMongo::BSON::Timestamp - BSON Timestamps data type, it is used internally by MongoDB's replication.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 sec

Seconds since epoch.

=head2 inc

Incrementing field.

=head1 NAME

AnyMongo::Timstamp 

=head1 AUTHOR

=head1 COPYRIGHT

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


