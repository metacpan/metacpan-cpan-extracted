package DBCDs;
use strict;
use base qw/DBBase/;

__PACKAGE__->table('cds');
__PACKAGE__->columns( Primary   => 'id');
__PACKAGE__->columns( Essential => qw/title/);
__PACKAGE__->columns( All       => qw/id title artist price/);

__PACKAGE__->_create_table;
__PACKAGE__->has_a(artist => 'DBArtists');

__PACKAGE__->mk_aggregate_function('max');
__PACKAGE__->mk_aggregate_function('min');
__PACKAGE__->mk_aggregate_function('sum');
__PACKAGE__->mk_aggregate_function('count' => 'counter');

sub _create_table {
    my $class = shift;
    $class->db_Main->do(<<__SQL__);
CREATE TABLE cds (
  id     INTEGER NOT NULL,
  title  VARCHAR(255) NOT NULL,
  artist INTEGER NOT NULL,
  price  INTEGER NOT NULL,
  primary key (id)
)
__SQL__
}

sub _insert_data {
    my $class = shift;
    my $i = 0;
    while (<DATA>) {
        chomp;
        $i++;
        my %data;
        @data{qw/id title artist price/} = ($i, split /\s+/, $_, 3);
        $class->create( \%data );
    }
}

1;
__DATA__
foo's_1st	1	1000
foo's_2nd	1	1200
foo's_3rd	1	1200
bar's		2	1000
baz's		3	1000
hoge's		4	2000
fuga's		5	2500
