=head1 LICENSE

Copyright [2015-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Test::Exception;

use Bio::DB::Big::AutoSQL;

my $raw_autosql = qq{table addressBook
"A simple address book"
    (
    uint id primary auto; "Autoincrementing primary key for this record."
    string name unique;  "Name - first or last or both, we don't care, except it must be unique"
    lstring address;  "Street address"
    string city index[12];  "City - indexing just first 12 character"
    uint zipCode index;  "A zip code is always positive, so can be unsigned"
    char[2] state index;  "Just store the abbreviation for the state"
    enum(one, two) testenum; "Checking enums"
    set(blib,blob) testset; "Checking sets"
    int faceCount; "Numbers of faces"
    object face[faceCount] faces; "List of faces"
    simple point[faceCount] points; "Array of points"
    lstring field12; "Undocumented field"
    lstring random; "Undocumented field"
    )};
my $alternative_name_lookup = {postcode => 'zipCode'};
my $as = Bio::DB::Big::AutoSQL->new($raw_autosql, $alternative_name_lookup);

my $as_obj = 'Bio::DB::Big::AutoSQLField';
my $expected_structure = bless({
  raw => $raw_autosql,
  type => 'table',
  name => 'addressBook',
  comment => 'A simple address book',
  alternative_name_lookup => $alternative_name_lookup,
  fields => [
    bless(
    { type => 'uint', name => 'id', comment => 'Autoincrementing primary key for this record.', position => 1,
      field_size => undef, field_values => [], declare_size => undef, index_type => 'primary',
      index_size => undef, auto => 'auto', declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'string', name => 'name', comment => q{Name - first or last or both, we don't care, except it must be unique}, position => 2,
      field_size => undef, field_values => [], declare_size => undef, index_type => 'unique',
      index_size => undef, auto => undef, declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'lstring', name => 'address', comment => 'Street address', position => 3,
      field_size => undef, field_values => [], declare_size => undef, index_type => undef,
      index_size => undef, auto => undef, declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'string', name => 'city', comment => 'City - indexing just first 12 character', position => 4,
      field_size => undef, field_values => [], declare_size => undef, index_type => 'index',
      index_size => "12", auto => undef, declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'uint', name => 'zipCode', comment => 'A zip code is always positive, so can be unsigned', position => 5,
      field_size => undef, field_values => [], declare_size => undef, index_type => 'index',
      index_size => undef, auto => undef, declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'char', name => 'state', comment => 'Just store the abbreviation for the state', position => 6,
      field_size => "2", field_values => [], declare_size => undef, index_type => 'index',
      index_size => undef, auto => undef, declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'enum', name => 'testenum', comment => 'Checking enums', position => 7,
      field_size => undef, field_values => [qw/one two/], declare_size => undef, index_type => undef,
      index_size => undef, auto => undef, declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'set', name => 'testset', comment => 'Checking sets', position => 8,
      field_size => undef, field_values => [qw/blib blob/], declare_size => undef, index_type => undef,
      index_size => undef, auto => undef, declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'int', name => 'faceCount', comment => 'Numbers of faces', position => 9,
      field_size => undef, field_values => [], declare_size => undef, index_type => undef,
      index_size => undef, auto => undef, declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'object', name => 'faces', comment => 'List of faces', position => 10,
      field_size => undef, field_values => [], declare_size => 'faceCount', index_type => undef,
      index_size => undef, auto => undef, declare_name => 'face',
    }, $as_obj),
    bless(
    { type => 'simple', name => 'points', comment => 'Array of points', position => 11,
      field_size => undef, field_values => [], declare_size => 'faceCount', index_type => undef,
      index_size => undef, auto => undef, declare_name => 'point',
    }, $as_obj),
    bless(
    { type => 'lstring', name => 'field12', comment => 'Undocumented field', position => 12,
      field_size => undef, field_values => [], declare_size => undef, index_type => undef,
      index_size => undef, auto => undef, declare_name => undef,
    }, $as_obj),
    bless(
    { type => 'lstring', name => 'random', comment => 'Undocumented field', position => 13,
      field_size => undef, field_values => [], declare_size => undef, index_type => undef,
      index_size => undef, auto => undef, declare_name => undef,
    }, $as_obj),
  ],
}, 'Bio::DB::Big::AutoSQL');

# Need 1:1 mapping between above expected
eq_or_diff($as, $expected_structure, 'Checking fields parse as expected');

throws_ok { Bio::DB::Big::AutoSQL->new('bogus') } qr/Parse error/, 'Checking bogus AutoSQL is picked up on';

ok($as->is_table(), 'Checking we say this is a table');

ok($as->get_field('field12')->is_autogenerated(), 'Field12 is an autogenerated field');
ok($as->get_field('random')->is_autogenerated(), 'Field "random" is an autogenerated field due to its comment');
ok(! $as->get_field('id')->is_autogenerated(), 'Field "id" is not an autogenerated field');

ok($as->has_field('postcode'), 'Checking we have the postcode field which is an alt name for zipCode');
ok(defined $as->get_field('postcode'), 'Checking we have the postcode field passed back');

done_testing();
