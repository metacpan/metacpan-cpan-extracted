use strict;
use warnings;
use utf8;
use Test::More;
use Catmandu::Validator::PICA;
use PICA::Schema;

my $validator = Catmandu::Validator::PICA->new(
   schema => 't/files/schema.json'
);

sub check {
    my $record = shift;
    is @_ ? 0 : 1, $validator->is_valid({ record => $record });
    is_deeply(\@_, [ map { "$_" } @{$validator->last_errors} ]) if @_;
}

my $record = [ [ '021A', undef, a => 'title' ] ];

check($record);
push @$record, $record->[0];
check($record, 'field 021A is not repeatable'),

my $schema = { fields => { '021A' => { repeatable => 0 } } };

foreach ( ($schema, PICA::Schema->new($schema)) ) {
    $validator = Catmandu::Validator::PICA->new( schema => $_ );
    check($record, 'field 021A is not repeatable');
}

$validator = Catmandu::Validator::PICA->new( schema => {}, ignore_unknown_fields => 1 );
check($record);

done_testing;
