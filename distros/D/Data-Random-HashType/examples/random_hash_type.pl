#!/usr/bin/env perl

use strict;
use warnings;

use Data::Printer;
use Data::Random::HashType;

my $obj = Data::Random::HashType->new(
        'mode_id' => 1,
        'num_generated' => 2,
);

my @hash_types = $obj->random;

# Dump hash types to out.
p @hash_types;

# Output:
# [
#     [0] Data::HashType  {
#             parents: Mo::Object
#             public methods (5):
#                 BUILD
#                 Mo::utils:
#                     check_bool, check_length, check_number, check_required
#             private methods (0)
#             internals: {
#                 active   1,
#                 id       1,
#                 name     "SHA-256"
#             }
#         },
#     [1] Data::HashType  {
#             parents: Mo::Object
#             public methods (5):
#                 BUILD
#                 Mo::utils:
#                     check_bool, check_length, check_number, check_required
#             private methods (0)
#             internals: {
#                 active   1,
#                 id       2,
#                 name     "SHA-384"
#             }
#         }
# ]