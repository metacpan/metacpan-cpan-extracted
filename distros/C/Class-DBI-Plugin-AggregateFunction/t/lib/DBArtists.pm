package DBArtists;
use strict;
use base qw/DBBase/;

__PACKAGE__->table('artists');
__PACKAGE__->columns( Primary   => 'id');
__PACKAGE__->columns( Essential => qw/ id name /);
__PACKAGE__->columns( All       => qw/ id name age/);

__PACKAGE__->_create_table;

__PACKAGE__->has_many(cds => 'DBCDs');

sub _create_table {
    my $class = shift;
    $class->db_Main->do(<<__SQL__);
CREATE TABLE artists (
  id    INTEGER NOT NULL,
  name  VARCHAR(255) NOT NULL,
  age   INTEGER NOT NULL,
  primary key (id)
)
__SQL__
}

sub _insert_data {
    my $class = shift;
    while (<DATA>) {
        chomp;
        my %data;
        @data{qw/id name age/} = split /\s+/, $_, 3;
        $class->create( \%data );
    }
}

1;
__DATA__
1	foo	20
2	bar	22
3	baz	31
4	hoge	12
5	fuga	55
