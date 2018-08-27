package Boost::UUID;
use 5.020;
use strict;
use warnings;
use XSLoader;

=head1 NAME

Boost::UUID

=cut

our $VERSION = '0.02';
XSLoader::load( 'Boost::UUID', $VERSION );


=head1 SYNOPSYS

Simple Perl interface for boost::uuid_generators ( look here [boost::uuid doc] L<https://www.boost.org/doc/libs/1_43_0/libs/uuid/uuid.html> )

=cut

=head1 DESCRIPTION

=head3 Random UUID generator

Genarate unique SHA-1 hash every time.

Work with B<boost::uuids::random_generator()>

C< my $uuid = Boost::UUID::random_uuid(); >

Result: B<01234567-89ab-cdef-0123-456789abcdef>

=head3 Nil UUID generator

Generate nil UUID

Work with B<boost::uuids::nil_generator()>

C<my $uuid = Boost::UUID::nil_uuid();>

Result: B<00000000-0000-0000-0000-000000000000>

=head3 String UUID

Convert string UUID to boost UUID ( better check out [doc] L<https://www.boost.org/doc/libs/1_43_0/libs/uuid/uuid.html#boost/uuid/string_generator.hpp> )

Work with B<boost::uuids::string_generator()>, but return nill UUID in wrong input string case

C< Boost::UUID::string_uuid("0123456789abcdef0123456789abcdef") >

Result: B<01234567-89ab-cdef-0123-456789abcdef>

=head3 Name UUID generator

Generate SHA hash from any string.

Work with B<boost::uuids::name_generator()>

C< Boost::UUID::name_uuid("crazypanda.ru"); >

Result:  B<25f9de77-a9a6-5816-b7cb-bafc0a203417>

=cut

=head1 AUTHOR

Vladimir Melnichenko <melnichenkovv@gmail.com>, Crazy Panda, CP Decision LTD

L<https://github.com/VMELNICHENKO/Boost-UUID>

=cut

=head1 LICENSE

You may distribute this code under the same terms as Boost itself.


=cut
