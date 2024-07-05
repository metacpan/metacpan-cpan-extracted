#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::Random::Person;

my $obj = Data::Random::Person->new(
        'mode_id' => 1,
        'num_people' => 2,
);

my @people = $obj->random;

# Dump person records to out.
p @people;

# Output like:
# [
#     [0] Data::Person  {
#             parents: Mo::Object
#             public methods (6):
#                 BUILD
#                 Mo::utils:
#                     check_length, check_number_id, check_strings
#                 Mo::utils::Email:
#                     check_email
#                 Readonly:
#                     Readonly
#             private methods (0)
#             internals: {
#                 email   "jiri.sykora@example.com",
#                 id      1,
#                 name    "Jiří Sýkora"
#             }
#         },
#     [1] Data::Person  {
#             parents: Mo::Object
#             public methods (6):
#                 BUILD
#                 Mo::utils:
#                     check_length, check_number_id, check_strings
#                 Mo::utils::Email:
#                     check_email
#                 Readonly:
#                     Readonly
#             private methods (0)
#             internals: {
#                 email   "bedrich.pavel.stepanek@example.com",
#                 id      2,
#                 name    "Bedřich Pavel Štěpánek"
#             }
#         }
# ]