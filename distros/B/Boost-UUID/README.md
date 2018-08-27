# Name
**Boost::UUID**

# Description
Simple Perl interface for boost::uuid_generators ( look here [boost::uuid doc](https://www.boost.org/doc/libs/1_43_0/libs/uuid/uuid.html) )

# Synopsis

## Random UUID generator
Genarate unique SHA-1 hash every time.

Work with **boost::uuids::random_generator()**

> use Boost::UUID;

> my $uuid = Boost::UUID::random_uuid();

Result: **01234567-89ab-cdef-0123-456789abcdef**

## Nil UUID generator
Generate nil UUID

Work with **boost::uuids::nil_generator()**

> use Boost::UUID;

> my $uuid = Boost::UUID::nil_uuid();

Result: **00000000-0000-0000-0000-000000000000**

## String UUID
Convert string UUID to boost UUID ( better check out [doc](https://www.boost.org/doc/libs/1_43_0/libs/uuid/uuid.html#boost/uuid/string_generator.hpp) )

Work with **boost::uuids::string_generator()**, but return nill UUID in wrong input string case
> use Boost::UUID;

> Boost::UUID::string_uuid("0123456789abcdef0123456789abcdef")

Result: **01234567-89ab-cdef-0123-456789abcdef**

## Name UUID generator
Generate SHA hash from any string.

Work with **boost::uuids::name_generator()**
> use Boost::UUID;

> Boost::UUID::name_uuid("crazypanda.ru");

Result:  **25f9de77-a9a6-5816-b7cb-bafc0a203417**

# AUTHOR
Vladimir Melnichenko <melnichenkovv@gmail.com>, Crazy Panda, CP Decision LTD

# LICENSE
You may distribute this code under the same terms as Boost itself.
