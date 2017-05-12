package DBArtists;
use strict;
use base qw/DBBase/;

__PACKAGE__->table('artists');
__PACKAGE__->columns( Primary   => 'id');
__PACKAGE__->columns( Essential => qw/ id name /);
__PACKAGE__->columns( All       => qw/ id name age label /);

__PACKAGE__->db_Main->do(<<'');
CREATE TABLE artists (
  id    INTEGER NOT NULL,
  name  VARCHAR(255) NOT NULL,
  age   INTEGER NOT NULL,
  label INTEGER NOT NULL,
  primary key (id)
)

__PACKAGE__->has_many(cds   => 'DBCDs');
__PACKAGE__->has_a   (label => 'DBLabels');

__PACKAGE__->mk_aggregate_function('max');
__PACKAGE__->mk_aggregate_function('min');
__PACKAGE__->mk_aggregate_function('sum');
__PACKAGE__->mk_aggregate_function('count' => 'counter');

{
    while (<DATA>) {
        chomp;
        my %data;
        @data{qw/id name age label/} = split /\s+/, $_, 4;
        __PACKAGE__->create( \%data );
    }
}

1;
__DATA__
1	foo	20	1
2	bar	22	1
3	baz	31	1
4	hoge	12	2
5	fuga	55	2
