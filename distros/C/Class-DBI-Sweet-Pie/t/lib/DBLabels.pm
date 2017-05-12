package DBLabels;
use strict;
use base qw/DBBase/;

__PACKAGE__->table('labels');
__PACKAGE__->columns( Primary   => 'id');
__PACKAGE__->columns( Essential => qw/ id name /);
__PACKAGE__->columns( All       => qw/ id name /);

__PACKAGE__->db_Main->do(<<'');
CREATE TABLE labels (
  id    INTEGER NOT NULL,
  name  VARCHAR(255) NOT NULL,
  primary key (id)
)

__PACKAGE__->has_many(artists => 'DBArtists');

__PACKAGE__->mk_aggregate_function('max');
__PACKAGE__->mk_aggregate_function('min');
__PACKAGE__->mk_aggregate_function('sum');
__PACKAGE__->mk_aggregate_function('count' => 'counter');


{
    while (<DATA>) {
        chomp;
        my %data;
        @data{qw/id name/} = split /\s+/, $_, 2;
        __PACKAGE__->create( \%data );
    }
}

1;
__DATA__
1	eng
2	jpn
