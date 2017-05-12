BEGIN { $| = 1; }
use strict;
use Test::More tests=>87;
use Data::Table;
#use Data::Dumper;

#$loaded = 1;
#print "ok loaded\n";

my $t = Data::Table::fromCSV("aaa.csv");
ok(defined($t), "fromCSV()");
ok($t->colIndex('Grams "(a.a.)"/100g sol.') == 3, "colIndex()");
ok($t->nofCol() == 6, "nofCol()");
ok($t->nofRow() == 9, "nofRow()");
ok($t->html() =~ /^<table/i, "html()");
ok($t->html2() =~ /^<table/i, "html2()");
ok($t->wiki() =~ /^\{\|/i, "wiki()");
ok($t->wiki2() =~ /^\{\|/i, "wiki2()");
ok($t->nofCol() == 6, "nofCol()");

my $fun = sub {return lc;};
ok($t->colMap(0,$fun)>0, "colMap()");
$fun = sub {$_->[0] = ucfirst $_->[0]};
ok($t->colsMap($fun)>0, "colsMap()");

my $row;
ok(($row = $t->delRow(0)) && $t->nofRow==8, "delRow()");
ok($t->addRow($row) && $t->nofRow==9, "addRow()");

my @rows;
ok((@rows = $t->delRows([0,2,3])) && $t->nofRow==6, "delRows()");
$t->addRow(shift @rows,0);
$t->addRow(shift @rows,2);
$t->addRow(shift @rows,3);

my $col;
ok($t->nofRow==9, "delRows() & addRow()");
ok(($col = $t->delCol("Solvent")) && $t->nofCol==5, "delCol()");
ok($t->addCol($col, "Solvent",2) && $t->nofCol==6, "addCol()");

my @cols;
ok((@cols = $t->delCols(["Temp, C","Amino acid","Entry"])) && $t->nofCol==3, "delCols()");
$t->addCol(shift @cols,"Temp, C",2);
$t->addCol(shift @cols,"Amino acid",0);
$t->addCol(shift @cols,"Entry",1);

ok($t->nofCol==6, "delCols() & addCol()");
ok($t->rowRef(3), "rowRef()");
ok($t->rowRefs(undef), "rowRefs()");
ok($t->row(3), "row()");
ok($t->colRef(3), "colRef()");
ok($t->colRefs(["Temp, C", "Amino acid", "Solvent"]), "colRefs()");
ok($t->col(3), "col()");
ok($t->rename("Entry", "New Entry"), "rename()");
$t->rename("New Entry", "Entry");

my @t = $t->col("Entry");
$t->replace("Entry", [1..$t->nofRow()], "New Entry");
ok($t->replace("New Entry",\@t, 'Entry'), "replace()");

ok($t->swap("Amino acid","Entry"), "swap()");
$t->swap("Amino acid","Entry");
ok($t->elm(3,"Temp, C")==79, "elm()");
ok(${$t->elmRef(3,"Temp, C")}==79, "elmRef()");
$t->setElm(3,"Temp, C", 100);
ok($t->elm(3,"Temp, C")==100, "setElm()");
$t->setElm(3,"Temp, C",79);
ok($t->sort('Ref No.',1,1,'Temp, C',1,0), "sort()");

my $t2;
ok(($t2=$t->match_pattern('$_->[0] =~ /^L-a/ && $_->[3]<0.2')) && $t2->nofRow()==2, "match_pattern()");
ok(($t2=$t->match_string('allo|cine')) && $t2->nofRow()==4, "match_string()");
ok($t2=$t->clone(), "clone()");
ok($t2=$t->subTable([2..4],[0..($t->nofCol()-1)]), "subTable()");
ok($t2=$t->subTable([2..4],undef), "subTable(\$rowIdcsRef,undef)");
ok(($t2=$t->subTable(undef,[0..($t->nofCol-1)]))&& ($t2->nofRow() == 9), "subTable(undef,\$colIDsRef)");
ok($t->rowMerge($t2) && $t->nofRow()==18, "rowMerge()");
$t->delRows([9..$t->nofRow-1]);
$t2=$t->subTable([0..($t->nofRow-1)],[1]);
$t2->rename(0, "new column");
ok($t->colMerge($t2) && $t->nofCol()==7, "colMerge()");
$t->delCol('new column');
$t->sort('Entry',Data::Table::STRING,Data::Table::ASC);
$t2 = Data::Table::fromTSV("aaa.tsv");
ok($t->tsv eq $t2->tsv, "fromTSV() and tsv()");
$t2 = $t->rowHashRef(1);
ok(scalar keys(%$t2) == $t->nofCol, "rowHashRef()");
$t2=Data::Table::fromCSV('aaa.csv');
is_deeply($t->rowRefs(), $t2->rowRefs(), "Looks good so far");
$t2->rename(0,'New1');
$t2->rename(1,'New2');
$t2->rename(2,'New3');
$t2->rename(3,'New4');
$t2->rename(4,'New5');
$t2->rename(5,'New6');
$t2->delRows([2,3,4]);
$t->delRows([0,8]);

my $t3 = $t->join($t2, 0, [0,1], [0,1]);
ok($t3->nofRow == 4, "join: inner");
$t3 = $t->join($t2, 1, [0,1], [0,1]);
ok($t3->nofRow == 7, "join: left outer");
$t3 = $t->join($t2, 2, [0,1], [0,1]);
ok($t3->nofRow == 6, "join: right outer");
$t3 = $t->join($t2, 3, [0,1], [0,1]);
ok($t3->nofRow == 9, "join: full outer");

$t = Data::Table->fromCSVi("aaa.csv");
$t2=Data::Table::fromCSV('aaa.csv');
is_deeply($t->rowRefs(), $t2->rowRefs(), "instant method fromCSVi");
$t = Data::Table->fromTSVi("aaa.tsv");
is_deeply($t->rowRefs(), $t2->rowRefs(), "instant method fromTSVi");

$t2 = $t->match_string("L-proline");
$t3 = $t->rowMask(\@Data::Table::OK, 1);
ok($t2->nofRow == 1 && $t3->nofRow == $t->nofRow - $t2->nofRow, "rowMask()"); 

my @h = $t2->header;
my @h2 = @h;
$h2[1] = "new name";
$t2->header(\@h2);
ok($t2->rename("new name", $h[1]), "header rename()");

$t = Data::Table->new(
  [
    ['Tom', 'male', 'IT', 65000],
    ['John', 'male', 'IT', 75000],
    ['Peter', 'male', 'HR', 85000],
    ['Mary', 'female', 'HR', 80000],
    ['Nancy', 'female', 'IT', 55000],
    ['Jack', 'male', 'IT', 88000],
    ['Susan', 'female', 'HR', 92000]
  ],
  ['Name', 'Sex', 'Department', 'Salary'], 0);

sub average {
  my @data = @_;
  my ($sum, $n) = (0, 0);
  foreach my $x (@data) {
    next unless $x;
    $sum += $x; $n++;
  }
  return ($n>0)?$sum/$n:undef;
}

$t2 = $t->group([],["Name", "Salary"], [sub {scalar @_}, \&average], ["Nof Employee", "Average Salary"], 0);
ok($t2->nofRow == 1 && $t2->elm(0,0) == 7, "group() with no key");
$t2 = $t->group(["Department","Sex"],["Name", "Salary"], [sub {scalar @_}, \&average], ["Nof Employee", "Average Salary"]);
ok($t2->nofRow == 4 && $t2->nofCol == 4, "group()");

$t2 = $t2->pivot("Sex", Data::Table::STRING, "Average Salary", ["Department"]);
#print $t2->html;
ok($t2->nofRow == 2 && $t2->nofCol == 3, "pivot()");

my $s = $t2->csv;
#open my $fh, "<", \$s or die "Cannot open in-memory file\n";
my $fh;
open($fh, "ccc.csv") or die "Cannot open ccc.csv to read\n";
my $t_fh=Data::Table::fromCSV($fh);
close($fh);
ok($t_fh->csv eq $s, "fromCSV() using file handler");
#print $t2->csv;

#my $s = $t2->tsv;
#open my $fh, "<", \$s or die "Cannot open in-memory file\n";
open($fh, "ccc.csv") or die "Cannot open ccc.csv to read\n";
$t_fh=Data::Table::fromTSV($fh);
close($fh);
ok($t_fh->tsv eq $s, "fromTSV() using file handler");
#print $t2->csv;

my $Well=["A_1", "A_2", "A_11", "A_12", "B_1", "B_2", "B_11", "B_12"];
$t = Data::Table->new([$Well], ["PlateWell"], 1);
$t->sort("PlateWell", 1, 0);
#print join(" ", $t->col("PlateWell"));
# in string sorting, "A_11" and "A_12" appears before "A_2";
my $my_sort_func = sub {
  my @a = split /_/, $_[0];
  my @b = split /_/, $_[1];
  return ($a[0] cmp $b[0]) || (int($a[1]) <=> int($b[1]));
};
$t->sort("PlateWell", $my_sort_func, 0);
#print join(" ", $t->col("PlateWell"));
#$t->sort("PlateWell", $my_sort_func, 1);
#print join(" ", $t->col("PlateWell"));

ok(join("", $t->col("PlateWell")) eq join("", @$Well), "sort using custom operator");

#open $fh, "<", \$s or die "Cannot open in-memory file\n";
open($fh, "colon.csv") or die "Cannot open colon.csv to read\n";
$t_fh=Data::Table::fromCSV($fh, 1, undef, {delimiter=>':', qualifier=>"'"});
close($fh);
  # col_A,col_B,col_C
  # 1,"2, 3 or 5",3.5
  # one,one:two,"double"", single'"
ok($t_fh->elm(0, 'col_B') eq "2, 3 or 5"
    && $t_fh->elm(1, 'col_B') eq "one:two"
    && $t_fh->elm(1, 'col_C') eq 'double", single\'',
    "using custom delimiter and qualifier for fromCSV()");

$t = Data::Table::fromCSV("bbb.csv", 1, undef, {skip_lines=>1, delimiter=>':', skip_pattern=>'^\s*#'});
$s = $t->tsv;
$t2 = Data::Table::fromTSV("aaa.tsv", 1);
is_deeply($t->rowRefs, $t2->rowRefs, "using skip_lines and skip_pattern for fromCSV()");

$t=Data::Table::fromFile("ttt.tsv", {transform_element=>0});
$t2=Data::Table::fromFile("ttt.csv");
is_deeply($t->rowRefs(), $t2->rowRefs(), "using fromFile, fromTSV, transform_element");

ok($t->html({odd=>'myOdd', even=>'myEven', header=>'myHeader'}), "using html with CSS class");

my %myRow=(COL_B=>'xyz');
$t->addRow(\%myRow, 1);
if ($t->nofRow==3) {
  is_deeply($t->rowRef(1), [undef, 'xyz'], "addRow() with hash_ref");
} else {
  ok(0, "addRow() with hash_ref, row was not added.");
}
#ok($t->addRow(\%myRow, 1) && $t->nofRow==3 && equal([$t->rowRef(1)], [[undef, 'xyz']]), "addRow() with hash_ref");

$t2 = $t->clone();
map {$t2->rename($_, $_."2")} $t2->header;
$t->rowMerge($t2, {byName => 1});
ok($t->nofRow == $t2->nofRow*2 && $t->nofCol == $t2->nofCol, "rowMerge() with byName=1");

$t->rowMerge($t2, {byName => 1, addNewCol => 1});
ok($t->nofRow == $t2->nofRow*3 && $t->nofCol == $t2->nofCol*2, "rowMerge() with byName=1 and addNewCol=1");

$t2->rename(0, 'COL_A');
$t2->rename(1, 'COL_B');
$t->rowMerge($t2, {byName => 0, addNewCol => 1});
ok($t->nofRow == $t2->nofRow*4 && $t->nofCol == $t2->nofCol, "rowMerge() with byName=0 and addNewCol=1");

$t=Data::Table::fromCSV("aaa.csv", 1);
$t2=$t->clone();
$t = $t->join($t2, 0, ['Amino acid'], ['Amino acid'], {renameCol => 1});
ok($t->nofRow == $t2->nofRow && $t->nofCol == $t2->nofCol*2-1, "join() with auto renaming duplicate column names");

$t=Data::Table::fromCSV("aaa.csv", 1);
$t2=$t->clone();
$t->colMerge($t2, {renameCol => 1});
ok($t->nofCol == $t2->nofCol*2, "colMerge() with auto renaming duplicate column names");

$t=Data::Table::fromCSV("aaa.csv", 1);
ok(($t2=$t->match_pattern_hash('$_{"Amino acid"} =~ /^L-a/ && $_{"Grams \"(a.a.)\"/100g sol."}<0.2')) && $t2->nofRow()==2, "match_pattern_hash()");

$t2 = $t->subTable($t->{OK}, undef, {useRowMask=>1});
#print Dumper($t2);
ok($t2->nofRow()==2, "subTable() with row mask");

$t2->moveCol('Amino acid', 1);
ok(($t2->header)[1] eq 'Amino acid', "moveCol()");

#Entry,Amino acid,Solvent,"Grams ""(a.a.)""/100g sol.","Temp, C",Ref No.
$t2->reorder(["Amino acid","Temp, C","Entry"]);
ok(($t2->header)[1] eq 'Temp, C', "reorder()");

$t = Data::Table->new([[1,1,5,6], [1,2,3,5], [2,1,6,1], [2,2,2,4]],
  ['id','time','x1','x2'], Data::Table::ROW_BASED);

$t2=Data::Table->new([],['id','count', 'rows']);
$t->each_group(['id'], sub { my ($t, $rows) = @_; $t2->addRow([$t->elm(0,'id'), $t->nofRow, join(":", @$rows)])});
$t3 = Data::Table->new([[1,2], [2,2], ['0:1','2:3']], ['id','count','rows'], Data::Table::COL_BASED);
is_deeply($t2->rowRefs, $t3->rowRefs, "group_each()");

$t2 = $t->melt(['id','time']);
ok($t2->nofRow == 8 && $t2->nofCol == 4, "melt()");

$t3 = $t2->cast(['id'],'variable',Data::Table::STRING,'value', \&average);
$t=Data::Table->new([[1,4,5.5], [2,4,2.5]], ['id','x1','x2'], Data::Table::ROW_BASED);
is_deeply($t3->rowRefs, $t->rowRefs, "cast()");

$t3 = $t2->cast(['id'],undef,Data::Table::STRING,'value', \&average);
$t=Data::Table->new([[1,4.75], [2,3.25]], ['id','(all)'], Data::Table::ROW_BASED);
is_deeply($t3->rowRefs, $t->rowRefs, "cast() without column to split");

$t3 = $t2->cast(undef,undef,Data::Table::STRING,'value', \&average);
$t=Data::Table->new([[4]], ['(all)'], Data::Table::ROW_BASED);
is_deeply($t3->rowRefs, $t->rowRefs, "cast() with total aggregate");

my $t_product=Data::Table::fromFile("Product.csv");

my $callback = sub {
  my ($tag, $row, $col, $colName, $table) = @_;
  if ($row >=0 && $colName eq 'UnitPrice') {
    $tag->{'style'} = 'background-color:'. (($table->elm($row, $col)>=20) ? '#fc8d59':'#91bfdb') . ';';
  }
  if ($row >=0 && $colName eq 'Discontinued') {
    $tag->{'style'} = 'background-color:'. (($table->elm($row, $col) eq 'TRUE') ? '#999999':'#af8dc3') .';';
  }
  return $tag;
};

#check callback function
ok($t_product->html(["","",""], undef, undef, undef, undef, undef, $callback) =~ /#999999/, "html() with callback");
ok($t_product->html2(["","",""], undef, undef, undef, undef, $callback) =~ /#999999/, "html2() with callback");
ok($t_product->wiki(["","",""], undef, undef, undef, undef, undef, $callback) =~ /#999999/, "wiki() with callback");
ok($t_product->wiki2(["","",""], undef, undef, undef, undef, $callback) =~ /#999999/, "wiki2() with callback");

$t_product->match_pattern_hash('$_{UnitPrice} > 20');
$t_product->addCol('No', 'IsExpensive');
ok($t_product->lastCol == 6 && $t_product->elm(0, 'IsExpensive') eq 'No', "addCol() with default value");

ok(@{$t_product->{MATCH}} == 37, "{MATCH} after match_pattern_hash");

$t_product->setElm($t_product->{MATCH}, 'IsExpensive', 'Yes');
ok($t_product->elm($t_product->{MATCH}->[0], 'IsExpensive') eq 'Yes',
    "setElm() for multiple cells");

my $cnt = 0;
my $next = $t_product->iterator();
while (my $row = &$next) {
  $cnt ++;
  $t_product->setElm(&$next(1), 'ProductName', 'New! '.$row->{ProductName});
}

ok($cnt == 77 && $t_product->elm(0, 'ProductName') =~ /^New!/,
    "iterator()");

$t_product->addRow({NewColumn=>'xyz',CategoryName=>'myname'}, undef, {addNewCol=>1});
ok($t_product->hasCol('NewColumn') && $t_product->elm($t_product->lastRow, 'NewColumn') eq 'xyz',
    "addRow() that adds a column");

# use DBI;
# $dbh= DBI->connect("DBI:mysql:test", "test", "") or die $dbh->errstr;
# $t = Data::Table::fromSQL($dbh, "show tables");
# print $t->csv;
# $t = Data::Table->fromSQLi($dbh, "show tables");
# print $t->csv;

# @_ in match_
package FOO;
our @ISA = qw(Data::Table);

1;

package main;

my $foo=FOO->new([[11,12],[21,22],[31,32]],['header1','header2'],0);
ok($foo->csv ne '', "Inheritance");

$foo = FOO->fromCSVi("aaa.csv");
ok($foo->csv ne '', "inheritated instant method fromCSVi");

# no longer needed, use is_deep instead
#sub equal {
#  return is_deeply($data, $data2);
#  my ($data, $data2) = @_;
#  my ($i ,$j);
#  return 0 if (scalar @$data != scalar @$data2);
#  for ($i=0; $i< scalar @$data; $i++) {
#    return 0 if (scalar @{$data->[$i]} != scalar @{$data2->[$i]});
#    for ($j=0; $j< scalar @{$data->[0]}; $j++) {
#      if (!defined($data->[$i]->[$j]) || !defined($data2->[$i]->[$j])) {
#        return 0 if (defined($data->[$i]->[$j]) || defined($data2->[$i]->[$j]));
#      }
#      return 0 if ("".$data->[$i]->[$j] ne "".$data2->[$i]->[$j]);
#    }
#  }
#  return 1;
#}
