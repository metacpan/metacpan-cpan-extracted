# Monkeypatch to support ->column_info
# in DBD::SQLite (versions up to 1.14 don't)

sub _sqlite_column_info {
my($dbh, $catalog, $schema, $table, $column) = @_;

$column = undef
if defined $column && $column eq '%';

my $sth_columns = $dbh->prepare( qq{PRAGMA table_info('$table')} );
$sth_columns->execute;

my @names = qw( TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME
DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH
DECIMAL_DIGITS NUM_PREC_RADIX NULLABLE
REMARKS COLUMN_DEF SQL_DATA_TYPE SQL_DATETIME_SUB
CHAR_OCTET_LENGTH ORDINAL_POSITION IS_NULLABLE
);

my @cols;
while ( my $col_info = $sth_columns->fetchrow_hashref ) {
next if defined $column && $column ne $col_info->{name};

my %col;

$col{TABLE_NAME} = $table;
$col{COLUMN_NAME} = $col_info->{name};

my $type = $col_info->{type};
if ( $type =~ s/(\w+)\((\d+)(?:,(\d+))?\)/$1/ ) {
$col{COLUMN_SIZE} = $2;
$col{DECIMAL_DIGITS} = $3;
}

$col{TYPE_NAME} = $type;

$col{COLUMN_DEF} = $col_info->{dflt_value}
if defined $col_info->{dflt_value};

if ( $col_info->{notnull} ) {
$col{NULLABLE} = 0;
$col{IS_NULLABLE} = 'NO';
}
else {
$col{NULLABLE} = 1;
$col{IS_NULLABLE} = 'YES';
}

for my $key (@names) {
$col{$key} = undef
unless exists $col{$key};
}

push @cols, \%col;
}

my $sponge = DBI->connect("DBI:Sponge:", '','')
or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge:
$DBI::errstr");
my $sth = $sponge->prepare("column_info $table", {
rows => [ map { [ @{$_}{@names} ] } @cols ],
NUM_OF_FIELDS => scalar @names,
NAME => \@names,
}) or return $dbh->DBI::set_err($sponge->err(), $sponge->errstr());
return $sth;
}

1;
