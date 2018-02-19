# make;perl -Iblib/lib t/40_aoh2.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 3;
my @oceania=a2h(
  [qw(Area      Population Capital             Code  Name)],
  [   undef,    54343,    'Pago Pago',        'AS', 'American Samoa'],
  [   7686850,  22751014, 'Canberra',         'AU', 'Australia'],
  [   undef,    596,      'West Island',      'CC', 'Cocos (Keeling) Islands'],
  [   240,      9838,     'Avarua',           'CK', 'Cook Islands'],
  [   undef,    1530,     'Flying Fish Cove', 'CX', 'Christmas Island'],
  [   18270,    909389,   'Suva',             'FJ', 'Fiji'],
  [   702,      105216,   'Palikir',          'FM', 'Micronesia, Federated States of'],
  [   549,      161785,   'Hagatna (Agana)',  'GU', 'Guam'],
  [   undef,    0,         undef,             'HM', 'Heard Island and McDonald Islands'],
  [   811,      105711,   'Tarawa',           'KI', 'Kiribati'],
  [   181.3,    72191,    'Majuro',           'MH', 'Marshall Islands'],
  [   19060,    271615,   'Noumea',           'NC', 'New Caledonia'],
  [   undef,    2210,     'Kingston',         'NF', 'Norfolk Island'],
  [   21,       9540,     'Yaren District',   'NR', 'Nauru'],
  [   260,      1190,     'Alofi',            'NU', 'Niue'],
  [   268680,   4438393,  'Wellington',       'NZ', 'New Zealand'],
  [   undef,    282703,   'Papeete',          'PF', 'French Polynesia'],
  [   462840,   6672429,  'Port Moresby',     'PG', 'Papua New Guinea'],
  [   undef,    48,       'Adamstown',        'PN', 'Pitcairn'],
  [   458,      21265,    'Melekeok',         'PW', 'Palau'],
  [   28450,    622469,   'Honiara',          'SB', 'Solomon Islands'],
  [   undef,    1337,      undef,             'TK', 'Tokelau'],
  [   26,       10869,    'Funafuti',         'TV', 'Tuvalu'],
  [   undef,    undef,     undef,             'UM', 'United States Minor Outlying Islands'],
  [   12200,    272264,   'Port-Vila',        'VU', 'Vanuatu'],
  [   undef,    15500,    'Mata-Utu',         'WF', 'Wallis and Futuna'],
  [   2944,     197773,   'Apia',             'WS', 'Samoa (Western)']
);
my $sql1=aoh2sql(\@oceania,{name=>'country',drop=>2});
my $sql2=<<'.';
begin;

drop table if exists country;

create table country (
  Area                           numeric(9,1),
  Capital                        varchar(16),
  Code                           varchar(2) not null,
  Name                           varchar(36) not null,
  Population                     numeric(9)
);

insert into country values (null,'Pago Pago','AS','American Samoa',54343);
insert into country values (7686850,'Canberra','AU','Australia',22751014);
insert into country values (null,'West Island','CC','Cocos (Keeling) Islands',596);
insert into country values (240,'Avarua','CK','Cook Islands',9838);
insert into country values (null,'Flying Fish Cove','CX','Christmas Island',1530);
insert into country values (18270,'Suva','FJ','Fiji',909389);
insert into country values (702,'Palikir','FM','Micronesia, Federated States of',105216);
insert into country values (549,'Hagatna (Agana)','GU','Guam',161785);
insert into country values (null,null,'HM','Heard Island and McDonald Islands',0);
insert into country values (811,'Tarawa','KI','Kiribati',105711);
insert into country values (181.3,'Majuro','MH','Marshall Islands',72191);
insert into country values (19060,'Noumea','NC','New Caledonia',271615);
insert into country values (null,'Kingston','NF','Norfolk Island',2210);
insert into country values (21,'Yaren District','NR','Nauru',9540);
insert into country values (260,'Alofi','NU','Niue',1190);
insert into country values (268680,'Wellington','NZ','New Zealand',4438393);
insert into country values (null,'Papeete','PF','French Polynesia',282703);
insert into country values (462840,'Port Moresby','PG','Papua New Guinea',6672429);
insert into country values (null,'Adamstown','PN','Pitcairn',48);
insert into country values (458,'Melekeok','PW','Palau',21265);
insert into country values (28450,'Honiara','SB','Solomon Islands',622469);
insert into country values (null,null,'TK','Tokelau',1337);
insert into country values (26,'Funafuti','TV','Tuvalu',10869);
insert into country values (null,null,'UM','United States Minor Outlying Islands',null);
insert into country values (12200,'Port-Vila','VU','Vanuatu',272264);
insert into country values (null,'Mata-Utu','WF','Wallis and Futuna',15500);
insert into country values (2944,'Apia','WS','Samoa (Western)',197773);
commit;
.
is( $sql1, $sql2, 'correct' );

my $sql3=aoh2sql(\@oceania,{name=>'country',create=>0});
$sql2=~s,^(drop|create) table.*?;\n\n,,sgm;

is( $sql3, $sql2, 'correct without drop and create' );
eval{ require Spreadsheet::WriteExcel };
if($@){
	ok(1,'Spreadsheet::WriteExcel not installed, skip test for aoh2xls()');
	exit;
}
my $workbook = Spreadsheet::WriteExcel->new('/tmp/40_aoh2.xls');
my $worksheet = $workbook->add_worksheet();
my $format = $workbook->add_format(); # Add a format
$format->set_bold();
$format->set_color('red');
$format->set_align('center');
$col = $row = 0;
$worksheet->write($row, $col, 'Hi Excel!', $format);
$worksheet->write(1,    $col, 'Hi Excel!');
# Write a number and a formula using A1 notation
$worksheet->write('A3', 1.2345);
$worksheet->write('A4', '=SIN(PI()/4)');
ok(1);

#wget https://en.wikipedia.org/wiki/List_of_largest_cities_and_towns_in_Tennessee_by_population
#perl -MAcme::Tools -le'print aoh2sql([a2h(ht2t(join("",<>),"listings"))],{name=>"list",fix_colnames=>1})' List_of_largest_cities_and_towns_in_Tennessee_by_population |xz -9e|wcc
#perl -MAcme::Tools -le'print aoh2sql([a2h(ht2t(join("",<>),"listings"))],{drop=>2,name=>"list",fix_colnames=>1})' List_of_largest_cities_and_towns_in_Tennessee_by_population |sqlite3 brb.sqlite
