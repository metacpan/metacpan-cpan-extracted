package DBSchema::Sample::Pg;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBSchema::Sample ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.07';


# Preloaded methods go here.

# -----------------------------------------------------------------
# author inserts
# -----------------------------------------------------------------



sub sql {

#    warn " *** in __PACKAGE__ ***";

    my $sql;
    while ( <DATA>) {
	last if /__END__/;
	$sql .= $_;
    }

    my @sql = split ';', $sql;

    \@sql;

}


1;
__DATA__
create table authors	(
       au_id char(11) not null,	au_lname varchar(40) not null,	au_fname varchar(20) not null,	
       phone char(12) null,	address varchar(40) null,	city varchar(20) null,	state char(2) null,	zip char(5) null);
create table publishers	(pub_id char(4) not null,	pub_name varchar(40) null,	address varchar(40) null,	city varchar(20) null,	state char(2) null);
create table roysched	(title_id char(6) not null,	lorange int null,	hirange int null,	royalty dec(5,2) null);
create table titleauthors	(au_id char(11) not null,	title_id char(6) not null,	au_ord int null,	royaltyshare dec(5,2) null);
create table titles	(title_id char(6) not null,	title varchar(80) not null,	type char(12) null,	pub_id char(4) null,	price numeric(8,2) null,	advance numeric(10,2) null,	ytd_sales int null,	contract int not null,	notes varchar(200) null,	pubdate date null);
create table editors	(ed_id char(11) not null,	ed_lname varchar(40) not null,	ed_fname varchar(20) not null,	ed_pos varchar(12) null,	phone char(12) null,	address varchar(40) null,	city varchar(20) null,	state char(2) null,	zip char(5) null,	ed_boss char(11) null );
create table titleditors	(ed_id char(11) not null,	title_id char(6) not null,	ed_ord int null);
create table sales	(sonum int not null,	stor_id char(4) not null,	ponum varchar(20) not null,	sdate date null);
create table salesdetails	(sonum int not null,	qty_ordered smallint not null,	qty_shipped smallint null,	title_id char(6) not null,	date_shipped date null);
create unique index auidind on authors (au_id);
create index aunmind on authors (au_lname, au_fname);
create unique index titleidind on titles (title_id);
create index titleind on titles (title);
create unique index taind on titleauthors (au_id, title_id);
create unique index edind on editors (ed_id);
create index ednmind on editors (ed_lname, ed_fname);
create unique index teind on titleditors (ed_id, title_id);
create index rstidind on roysched (title_id);
create unique index sdind on salesdetails (sonum, title_id) ;
create unique index salesind on sales (sonum);
insert into authors values('409-56-7008', 'Bennet', 'Abraham','415 658-9932', '6223 Bateman St.', 'Berkeley', 'CA', '94705');
insert into authors values ('213-46-8915', 'Green', 'Marjorie','415 986-7020', '309 63rd St. #411', 'Oakland', 'CA', '94618');
insert into authors values('238-95-7766', 'Carson', 'Cheryl','415 548-7723', '589 Darwin Ln.', 'Berkeley', 'CA', '94705');
insert into authors values('998-72-3567', 'Ringer', 'Albert','801 826-0752', '67 Seventh Av.', 'Salt Lake City', 'UT', '84152');
insert into authors values('899-46-2035', 'Ringer', 'Anne','801 826-0752', '67 Seventh Av.', 'Salt Lake City', 'UT', '84152');
insert into authors values('722-51-5454', 'DeFrance', 'Michel','219 547-9982', '3 Balding Pl.', 'Gary', 'IN', '46403');
insert into authors values('807-91-6654', 'Panteley', 'Sylvia','301 946-8853', '1956 Arlington Pl.', 'Rockville', 'MD', '20853');
insert into authors values('893-72-1158', 'McBadden', 'Heather','707 448-4982', '301 Putnam', 'Vacaville', 'CA', '95688');
insert into authors values('724-08-9931', 'Stringer', 'Dirk','415 843-2991', '5420 Telegraph Av.', 'Oakland', 'CA', '94609');
insert into authors values('274-80-9391', 'Straight', 'Dick','415 834-2919', '5420 College Av.', 'Oakland', 'CA', '94609');
insert into authors values('756-30-7391', 'Karsen', 'Livia','415 534-9219', '5720 McAuley St.', 'Oakland', 'CA', '94609');
insert into authors values('724-80-9391', 'MacFeather', 'Stearns','415 354-7128', '44 Upland Hts.', 'Oakland', 'CA', '94612');
insert into authors values('427-17-2319', 'Dull', 'Ann','415 836-7128', '3410 Blonde St.', 'Palo Alto', 'CA', '94301');
insert into authors values('672-71-3249', 'Yokomoto', 'Akiko','415 935-4228', '3 Silver Ct.', 'Walnut Creek', 'CA', '94595');
insert into authors values('267-41-2394', 'O''Leary', 'Michael','408 286-2428', '22 Cleveland Av. #14', 'San Jose', 'CA', '95128');
insert into authors values('472-27-2349', 'Gringlesby', 'Burt','707 938-6445', 'PO Box 792', 'Covelo', 'CA', '95428');
insert into authors values('527-72-3246', 'Greene', 'Morningstar','615 297-2723', '22 Graybar Rd.', 'Nashville', 'TN', '37215');
insert into authors values('172-32-1176', 'White', 'Johnson','408 496-7223', '10932 Bigge Rd.', 'Menlo Park', 'CA', '94025');
insert into authors values('712-45-1867', 'del Castillo', 'Innes','615 996-8275', '2286 Cram Pl. #86', 'Ann Arbor', 'MI', '48105');
insert into authors values('846-92-7186', 'Hunter', 'Sheryl','415 836-7128', '3410 Blonde St.', 'Palo Alto', 'CA', '94301');
insert into authors values('486-29-1786', 'Locksley', 'Chastity','415 585-4620', '18 Broadway Av.', 'San Francisco', 'CA', '94130');
insert into authors values('648-92-1872', 'Blotchet-Halls', 'Reginald','503 745-6402', '55 Hillsdale Bl.', 'Corvallis', 'OR', '97330');
insert into authors values('341-22-1782', 'Smith', 'Meander','913 843-0462', '10 Misisipi Dr.', 'Lawrence', 'KS', '66044');
insert into publishers values('0736', 'New Age Books', '1 1st St','Boston', 'MA');
insert into publishers values('0877', 'Binnet & Hardley','2 2nd Ave.', 'Washington', 'DC');
insert into publishers values('1389', 'Algodata Infosystems', '3 3rd Dr.','Berkeley', 'CA');
insert into roysched values('BU1032', 0, 5000, .10);
insert into roysched values('BU1032', 5001, 50000, .12);
insert into roysched values('PC1035', 0, 2000, .10);
insert into roysched values('PC1035', 2001, 4000, .12);
insert into roysched values('PC1035', 4001, 50000, .16);
insert into roysched values('BU2075', 0, 1000, .10);
insert into roysched values('BU2075', 1001, 5000, .12);
insert into roysched values('BU2075', 5001, 7000, .16);
insert into roysched values('BU2075', 7001, 50000, .18);
insert into roysched values('PS9999', 0, 50000, .10);
insert into roysched values('PS2091', 0, 1000, .10);
insert into roysched values('PS2091', 1001, 5000, .12);
insert into roysched values('PS2091', 5001, 50000, .14);
insert into roysched values('PS2106', 0, 2000, .10);
insert into roysched values('PS2106', 2001, 5000, .12);
insert into roysched values('PS2106', 5001, 50000, .14);
insert into roysched values('MC3021', 0, 1000, .10);
insert into roysched values('MC3021', 1001, 2000, .12);
insert into roysched values('MC3021', 2001, 6000, .14);
insert into roysched values('MC3021', 6001, 8000, .18);
insert into roysched values('MC3021', 8001, 50000, .20);
insert into roysched values('TC3218', 0, 2000, .10);
insert into roysched values('TC3218', 2001, 6000, .12);
insert into roysched values('TC3218', 6001, 8000, .16);
insert into roysched values('TC3218', 8001, 50000, .16);
insert into roysched values('PC8888', 0, 5000, .10);
insert into roysched values('PC8888', 5001, 50000, .12);
insert into roysched values('PS7777', 0, 5000, .10);
insert into roysched values('PS7777', 5001, 50000, .12);
insert into roysched values('PS3333', 0, 5000, .10);
insert into roysched values('PS3333', 5001, 50000, .12);
insert into roysched values('MC3026', 0, 1000, .10);
insert into roysched values('MC3026',1001, 2000, .12);
insert into roysched values('MC3026', 2001, 6000, .14);
insert into roysched values('MC3026', 6001, 8000, .18);
insert into roysched values('MC3026', 8001, 50000, .20);
insert into roysched values('BU1111', 0, 4000, .10);
insert into roysched values('BU1111', 4001, 8000, .12);
insert into roysched values('BU1111', 8001, 50000, .14);
insert into roysched values('MC2222', 0, 2000, .10);
insert into roysched values('MC2222', 2001, 4000, .12);
insert into roysched values('MC2222', 4001, 8000, .14);
insert into roysched values('MC2222', 8001, 12000, .16);
insert into roysched values('TC7777', 0, 5000, .10);
insert into roysched values('TC7777', 5001, 15000, .12);
insert into roysched values('TC4203', 0, 2000, .10);
insert into roysched values('TC4203', 2001, 8000, .12);
insert into roysched values('TC4203', 8001, 16000, .14);
insert into roysched values('BU7832', 0, 5000, .10);
insert into roysched values('BU7832', 5001, 50000, .12);
insert into roysched values('PS1372', 0, 50000, .10);
insert into titleauthors values('409-56-7008', 'BU1032', 1, .60);
insert into titleauthors values('486-29-1786', 'PS7777', 1, 1.00);
insert into titleauthors values('486-29-1786', 'PC9999', 1, 1.00);
insert into titleauthors values('712-45-1867', 'MC2222', 1, 1.00);
insert into titleauthors values('172-32-1176', 'PS3333', 1, 1.00);
insert into titleauthors values('213-46-8915', 'BU1032', 2, .40);
insert into titleauthors values('238-95-7766', 'PC1035', 1, 1.00);
insert into titleauthors values('213-46-8915', 'BU2075', 1, 1.00);
insert into titleauthors values('998-72-3567', 'PS2091', 1, .50);
insert into titleauthors values('899-46-2035', 'PS2091', 2, .50);
insert into titleauthors values('998-72-3567', 'PS2106', 1, 1.00);
insert into titleauthors values('722-51-5454', 'MC3021', 1, .75);
insert into titleauthors values('899-46-2035', 'MC3021', 2, .25);
insert into titleauthors values('807-91-6654', 'TC3218', 1, 1.00);
insert into titleauthors values('274-80-9391', 'BU7832', 1, 1.00);
insert into titleauthors values('427-17-2319', 'PC8888', 1, .50);
insert into titleauthors values('846-92-7186', 'PC8888', 2, .50);
insert into titleauthors values('756-30-7391', 'PS1372', 1, .75);
insert into titleauthors values('724-80-9391', 'PS1372', 2, .25);
insert into titleauthors values('724-80-9391', 'BU1111', 1, .60);
insert into titleauthors values('267-41-2394', 'BU1111', 2, .40);
insert into titleauthors values('672-71-3249', 'TC7777', 1, .40);
insert into titleauthors values('267-41-2394', 'TC7777', 2, .30);
insert into titleauthors values('472-27-2349', 'TC7777', 3, .30);
insert into titleauthors values('648-92-1872', 'TC4203', 1, 1.00);
insert into titles values ('PC8888', 'Secrets of Silicon Valley','popular_comp', '1389', 40.00, 8000.00, 4095,1,'Muckraking reporting on the world''s largest computer hardware and software manufacturers.','06/12/1998');
insert into titles values ('BU1032', 'The Busy Executive''s Database Guide','business', '1389', 29.99, 5000.00, 4095, 1,'An overview of available database systems with emphasis on common business applications.  Illustrated.','06/12/1998');
insert into titles values ('PS7777', 'Emotional Security: A New Algorithm','psychology', '0736', 17.99, 4000.00, 3336, 1,'Protecting yourself and your loved ones from undue emotional stress in the modern world.  Use of computer and nutritional aids emphasized.','06/12/1998');
insert into titles values ('PS3333', 'Prolonged Data Deprivation: Four Case Studies','psychology', '0736', 29.99, 2000.00, 4072,1,'What happens when the data runs dry?  Searching evaluations of information-shortage effects.','06/12/1998');
insert into titles values ('BU1111', 'Cooking with Computers: Surreptitious Balance Sheets','business', '1389', 21.95, 5000.00, 3876, 1,'Helpful hints on how to use your electronic resources to the best advantage.', '06/09/1998');
insert into titles values ('MC2222', 'Silicon Valley Gastronomic Treats','mod_cook', '0877', 29.99, 0.00, 2032, 1, 'Favorite recipes for quick, easy, and elegant meals tried and tested by people who never have time to eat, let alone cook.','06/09/1998');
insert into titles values ('TC7777', 'Sushi, Anyone?','trad_cook', '0877', 29.99, 8000.00, 4095, 1,'Detailed instructions on improving your position in life by learning how to make authentic Japanese sushi in your spare time. 5-10% increase in number of friends per recipe reported from beta test. ','06/12/1998');
insert into titles values ('TC4203', 'Fifty Years in Buckingham Palace Kitchens','trad_cook', '0877', 21.95, 4000.00, 15096, 1,'More anecdotes from the Queen''s favorite cook describing life among English royalty.  Recipes, techniques, tender vignettes.','06/12/1998');
insert into titles values ('PC1035', 'But Is It User Friendly?','popular_comp', '1389', 42.95, 7000.00, 8780, 1,'A survey of software for the naive user, focusing on the ''friendliness'' of each.','06/30/1998');
insert into titles values('BU2075', 'You Can Combat Computer Stress!','business', '0736', 12.99, 10125.00, 18722, 1,'The latest medical and psychological techniques for living with the electronic office.  Easy-to-understand explanations.','06/30/1998');
insert into titles values('PS2091', 'Is Anger the Enemy?','psychology', '0736', 21.95, 2275.00, 2045, 1,'Carefully researched study of the effects of strong emotions on the body. Metabolic charts included.','06/15/1998');
insert into titles values('PS2106', 'Life Without Fear','psychology', '0736', 17.00, 6000.00, 111, 1,'New exercise, meditation, and nutritional techniques that can reduce the shock of daily interactions. Popular audience.  Sample menus included, exercise video available separately.','10/05/1998');
insert into titles values('MC3021', 'The Gourmet Microwave','mod_cook', '0877', 12.99, 15000.00, 22246, 1,'Traditional French gourmet recipes adapted for modern microwave cooking.','06/18/1998');
insert into titles values('TC3218','Onions, Leeks, and Garlic: Cooking Secrets of the Mediterranean','trad_cook', '0877', 40.95, 7000.00, 375, 1,'Profusely illustrated in color, this makes a wonderful gift book for a cuisine-oriented friend.','10/21/1998');
insert into titles (title_id, title, pub_id, contract) values('MC3026', 'The Psychology of Computer Cooking', '0877', 0);
insert into titles values ('BU7832', 'Straight Talk About Computers','business', '1389', 29.99, 5000.00, 4095, 1,'Annotated analysis of what computers can do for you: a no-hype guide for the critical user.','06/22/1998');
insert into titles values('PS1372','Computer Phobic and Non-Phobic Individuals: Behavior Variations','psychology', '0736', 41.59, 7000.00, 375, 1,'A must for the specialist, this book examines the difference between those who hate and fear computers and those who think they are swell.','10/21/1998');
insert into titles (title_id, title, type, pub_id, contract, notes) values('PC9999', 'Net Etiquette', 'popular_comp', '1389', 0,'A must-read for computer conferencing debutantes!.');
insert into editors values ( '321-55-8906', 'DeLongue', 'Martinella', 'project','415 843-2222', '3000 6th St.', 'Berkeley', 'CA', '94710', '993-86-0420' );
insert into editors values ( '527-72-3246', 'Greene', 'Morningstar', 'copy',          '615 297-2723', '22 Graybar House Rd.', 'Nashville', 'TN','37215', '826-11-9034' );
insert into editors values ( '712-45-1867', 'del Castillo', 'Innes', 'copy','615 996-8275', '2286 Cram Pl. #86', 'Ann Arbor', 'MI', '48105', '826-11-9034' );
insert into editors values ('777-02-9831', 'Samuelson', 'Bernard', 'project','415 843-6990', '27 Yosemite', 'Oakland', 'CA', '94609', '993-86-0420' );
insert into editors values ('777-66-9902', 'Almond', 'Alfred', 'copy','312 699-4177', '1010 E. Devon', 'Chicago', 'IL', '60018', '826-11-9034' );
insert into editors values ('826-11-9034', 'Himmel', 'Eleanore', 'project','617 423-0552', '97 Bleaker', 'Boston', 'MA', '02210', '993-86-0420' );
insert into editors values ('885-23-9140', 'Rutherford-Hayes', 'Hannah', 'project','301 468-3909', '32 Rockbill Pike', 'Rockbill', 'MD', '20852', '993-86-0420' );
insert into editors values ('993-86-0420', 'McCann', 'Dennis', 'acquisition','301 468-3909', '32 Rockbill Pike', 'Rockbill', 'MD', '20852', null );
insert into editors values ('943-88-7920', 'Kaspchek', 'Christof', 'acquisition','415 549-3909', '18 Severe Rd.', 'Berkeley', 'CA', '94710', null);
insert into titleditors  values('826-11-9034', 'BU2075', 2);
insert into titleditors  values('826-11-9034', 'PS2091', 2);
insert into titleditors  values('826-11-9034', 'PS2106', 2);
insert into titleditors  values('826-11-9034', 'PS3333', 2);
insert into titleditors  values('826-11-9034', 'PS7777', 2);
insert into titleditors  values('826-11-9034', 'PS1372', 2);
insert into titleditors  values('885-23-9140', 'MC2222', 2);
insert into titleditors  values('885-23-9140', 'MC3021', 2);
insert into titleditors  values('885-23-9140', 'TC3281', 2);
insert into titleditors  values('885-23-9140', 'TC4203', 2);
insert into titleditors  values('885-23-9140', 'TC7777', 2);
insert into titleditors  values('321-55-8906', 'BU1032', 2);
insert into titleditors  values('321-55-8906', 'BU1111', 2);
insert into titleditors  values('321-55-8906', 'BU7832', 2);
insert into titleditors  values('321-55-8906', 'PC1035', 2);
insert into titleditors  values('321-55-8906', 'PC8888', 2);
insert into titleditors  values('321-55-8906', 'BU2075', 3);
insert into titleditors  values('777-02-9831', 'PC1035', 3);
insert into titleditors  values('777-02-9831', 'PC8888', 3);
insert into titleditors  values('943-88-7920', 'BU1032', 1);
insert into titleditors  values('943-88-7920', 'BU1111', 1);
insert into titleditors  values('943-88-7920', 'BU2075', 1);
insert into titleditors  values('943-88-7920', 'BU7832', 1);
insert into titleditors  values('943-88-7920', 'PC1035', 1);
insert into titleditors  values('943-88-7920', 'PC8888', 1);
insert into titleditors  values('993-86-0420', 'PS1372', 1);
insert into titleditors  values('993-86-0420', 'PS2091', 1);
insert into titleditors  values('993-86-0420', 'PS2106', 1);
insert into titleditors  values('993-86-0420', 'PS3333', 1);
insert into titleditors  values('993-86-0420', 'PS7777', 1);
insert into titleditors  values('993-86-0420', 'MC2222', 1);
insert into titleditors  values('993-86-0420', 'MC3021', 1);
insert into titleditors  values('993-86-0420', 'TC3218', 1);
insert into titleditors  values('993-86-0420', 'TC4203', 1);
insert into titleditors  values('993-86-0420', 'TC7777', 1);
insert into sales values(1,'7066', 'QA7442.3', '09/13/1998');
insert into sales values(2,'7067', 'D4482', '09/14/1998');
insert into sales values(3,'7131', 'N914008', '09/14/1998');
insert into sales values(4,'7131', 'N914014', '09/14/1998');
insert into sales values(5,'8042', '423LL922', '09/14/1998');
insert into sales values(6,'8042', '423LL930', '09/14/1998');
insert into sales values(7, '6380', '722a', '09/13/1998');
insert into sales values(8,'6380', '6871', '09/14/1998');
insert into sales values(9,'8042','P723', '03/11/2001');
insert into sales values(19,'7896','X999', '02/21/2001');
insert into sales values(10,'7896','QQ2299', '10/28/2000');
insert into sales values(11,'7896','TQ456', '12/12/2000');
insert into sales values(12,'8042','QA879.1', '5/22/2000');
insert into sales values(13,'7066','A2976', '5/24/2000');
insert into sales values(14,'7131','P3087a', '5/29/2000');
insert into sales values(15,'7067','P2121', '6/15/2000');
insert into salesdetails values(1, 75, 75,'PS2091', '9/15/1998');
insert into salesdetails values(2, 10, 10,'PS2091', '9/15/1998');
insert into salesdetails values(3, 20, 720,'PS2091', '9/18/1998');
insert into salesdetails values(4, 25, 20,'MC3021', '9/18/1998');
insert into salesdetails values(5, 15, 15,'MC3021', '9/14/1998');
insert into salesdetails values(6, 10, 3,'BU1032', '9/22/1998');
insert into salesdetails values(7, 3, 3,'PS2091', '9/20/1998');
insert into salesdetails values(8, 5, 5,'BU1032', '9/14/1998');
insert into salesdetails values(9, 25, 5,'BU1111', '03/28/2001');
insert into salesdetails values(19, 35, 35,'BU2075', '03/15/2001');
insert into salesdetails values(10, 15, 15,'BU7832', '10/29/2000');
insert into salesdetails values(11, 10, 10,'MC2222', '1/12/2001');
insert into salesdetails values(12, 30, 30,'PC1035', '5/24/2000');
insert into salesdetails values(13, 50, 50,'PC8888', '5/24/2000');
insert into salesdetails values(14, 20, 20,'PS1372', '5/29/2000');
insert into salesdetails values(14, 25, 25,'PS2106', '4/29/2000');
insert into salesdetails values(14, 15, 10,'PS3333', '5/29/2000');
insert into salesdetails values(14, 25, 25,'PS7777', '6/13/2000');
insert into salesdetails values(15, 40, 40,'TC3218', '6/15/2000');
insert into salesdetails values(15, 20, 20,'TC4203', '5/30/2000');
insert into salesdetails values(15, 20, 10,'TC7777', '6/17/2000')
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

DBSchema::Sample::Pg - Postgresql DBSchema::Sample class

=head2 EXPORT

None by default.

=head1 AUTHOR

T. M. Brannon, tbone@cpan.org

=cut
