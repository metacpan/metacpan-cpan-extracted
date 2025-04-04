#!/usr/bin/env perl

use strict;
use warnings;

use Data::ExternalId;
use Data::Person;
use DateTime;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $obj = Data::Person->new(
        'email' => 'skim@cpan.org',
        'external_ids' => [
                Data::ExternalId->new(
                        'key' => 'Wikidata',
                        'value' => 'Q27954834',
                ),
        ],
        'id' => 1,
        'name' => decode_utf8('Michal Josef Špaček'),
        'sex' => 'male',
);

# Print out.
print 'Id: '.$obj->id."\n";
print 'Name: '.encode_utf8($obj->name)."\n";
print 'Email: '.$obj->email."\n";
print 'Sex: '.$obj->sex."\n";
foreach my $external_id (@{$obj->external_ids}) {
       print 'External id - '.$external_id->key.': '.$external_id->value."\n";
}

# Output:
# Id: 1
# Name: Michal Josef Špaček
# Email: skim@cpan.org
# Sex: male
# External id - Wikidata: Q27954834