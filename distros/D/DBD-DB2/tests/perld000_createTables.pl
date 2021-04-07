#!/bin/perl
#*****************************************************************************
# TESTCASE NAME    : perld000_createTables.pl
# RELEASE          : DB2 UDB V5.2
# LINE ITEM        : DBD::DB2 database driver for Perl 
# COMPONENT(S)     : perldb2
# DEVELOPER        : Mike Moran in Austin
# FUNCTION TESTER  : DB2 UDB Precompiler team
# KEYWORDS         :
# PREREQUISITE     : Perl 5.004_04 or later
#                  : DBI module, level 0.93 or later
# PRERUN           : -
# POSTRUN          : -
# APAR FIX         : -
# DEFECT(S)        : -
# SETUP            : AUTOMATED
# DESCRIPTION      : Create tables and populate them with data 
# EXPECTED RESULTS : Success 
# MODIFIED BY      : 
#
#  DEFECT      WHO        WHEN          DESCRIPTION 
# --------  ----------  --------- -------------------------------------------
#  96764    Kelvin Ho    98Aug13  Create the testcase
#  95027    L.Huffman    99Jan12  Remove extension from testcase name
# 156353    R. Indrigo   00Aug16  Fix for OS/390
#****************************************************************************/

require "perldutl.pl";
require "connection.pl";

# The DB2_HOME environment variable needs to be set to the installed
# location of UDB.
($testcase = $0) =~ s@.*/@@;
($tcname,$extension) = split(/\./, $testcase);

use DBI;

#***************************************************************************
# Begin Testcase
#***************************************************************************
fvt_begin_testcase($tcname);

$dbh = DBI->connect("dbi:DB2:$DATABASE", $USERID, $PASSWORD, {PrintError => 0});
check_error("CONNECT");
if ($DBI::err != 0)
{
  goto end;
}

$arg = shift;
if ($arg eq 'unpop')
{
  @tables = ( 'org', 'staff', 'employee', 'emp_resume' );
  foreach $table (@tables)
  {
    # Drop the table even if it does not exist 
    $dbh->do("DROP TABLE $table");
  }

  goto end;
}

init();
#
# Create and populate tables
#
foreach $table (@tables)
{
  # Drop the table even if it does not exist 
  $dbh->do("DROP TABLE $table");

  $dbh->do($create{$table});
  check_error("CREATE TABLE $table");

  for($i = 0; $i < @{$insert{$table}}; $i++)
  {
    $dbh->do($insert{$table}[$i]);
    check_error("$insert{$table}[$i]");
  }
}

$dbh->disconnect();
check_error("DISCONNECT");

#***************************************************************************
# End Testcase
#***************************************************************************
end:
fvt_end_testcase($tcname);

exit 0;

#
# init() initializes some global arrays and hashes
#
sub init
{
  @tables = ( 'org', 'staff', 'employee', 'emp_resume');

  %create = (
    'org' => "CREATE TABLE org (deptnumb smallint not null, ".
                               "deptname varchar(14),       ".
                               "manager  smallint,          ".
                               "division varchar(10),       ".
                               "location varchar(13))       ",
    'staff' => "CREATE TABLE staff (id     smallint not null, ".
                                   "name   varchar(9),        ".
                                   "dept   smallint,          ".
                                   "job    char(5),           ".
                                   "years  smallint,          ".
                                   "salary decimal(7,2),      ".
                                   "comm   decimal(7,2))      ",
    'employee' => "CREATE TABLE employee (empno     char(6) not null,    ".
                                         "firstnme  varchar(12) not null,".
                                         "midinit   char(1),             ".
                                         "lastname  varchar(15) not null,".
                                         "workdept  char(3),             ".
                                         "phoneno   char(4),             ".
                                         "hiredate  date,                ".
                                         "job       char(8),             ".
                                         "edlevel   smallint not null,   ".
                                         "sex       char(1),             ".
                                         "birthdate date,                ".
                                         "salary    decimal(9,2),        ".
                                         "bonus     decimal(9,2),        ".
                                         "comm      decimal(9,2))        ",
    'emp_resume' => "CREATE TABLE emp_resume ".
                      "(empno         char(6) not null,    ".
                      " resume_format varchar(10) not null,".
                      " resume        clob(5K))            ",
    'magictest'  => "CREATE TABLE magictest ".
                    "(id integer,".
                    "value char) "
  );

  %insert = (
    'org' => [
      "INSERT INTO org VALUES ( 10, 'Head Office',    160, 'Corporate', 'New York')",
      "INSERT INTO org VALUES ( 15, 'New England',     50, 'Eastern',   'Boston')",
      "INSERT INTO org VALUES ( 20, 'Mid Atlantic',    10, 'Eastern',   'Washington')",
      "INSERT INTO org VALUES ( 38, 'South Atlantic',  30, 'Eastern',   'Atlanta')",
      "INSERT INTO org VALUES ( 42, 'Great Lakes',    100, 'Midwest',   'Chicago')",
      "INSERT INTO org VALUES ( 66, 'Pacific',        270, 'Western',   'San Francisco')",
      "INSERT INTO org VALUES ( 51, 'Plains',         140, 'Midwest',   'Dallas')",
      "INSERT INTO org VALUES ( 84, 'Mountain',       290, 'Western',   'Denver')"
    ],
    'staff' => [
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (10,  'Sanders',   20, 'Mgr',    7, 18357.50)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (20,  'Pernal',    20, 'Sales',  8, 18171.25, 612.45)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (30,  'Marenghi',  38, 'Mgr',    5, 17506.75)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (40,  'O''Brien',   38, 'Sales',  6, 18006.00, 846.55)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (50,  'Hanes',     15, 'Mgr',   10, 20659.80)",
      "INSERT INTO staff (id, name, dept, job,        salary, comm) VALUES (60,  'Quigley',   38, 'Sales',     16808.30, 650.25)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (70,  'Rothman',   15, 'Sales',  7, 16502.83, 1152.00)",
      "INSERT INTO staff (id, name, dept, job,        salary, comm) VALUES (80,  'James',     20, 'Clerk',     13504.60, 128.20)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (90,  'Koonitz',   42, 'Sales',  6, 18001.75, 1386.70)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (100, 'Plotz',     42, 'Mgr',    7, 18352.80)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (110, 'Ngan',      15, 'Clerk',  5, 12508.20, 206.60)",
      "INSERT INTO staff (id, name, dept, job,        salary, comm) VALUES (120, 'Naughton',  38, 'Clerk',     12954.75, 180.00)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (130, 'Yamaguchi', 42, 'Clerk',  6, 10505.90, 75.60)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (140, 'Fraye',     51, 'Mgr',    6, 21150.00)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (150, 'Williams',  51, 'Sales',  6, 19456.50, 637.65)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (160, 'Molinare',  10, 'Mgr',    7, 22959.20)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (170, 'Kermisch',  15, 'Clerk',  4, 12258.50, 110.10)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (180, 'Abrahams',  38, 'Clerk',  3, 12009.75, 236.50)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (190, 'Sneider',   20, 'Clerk',  8, 14252.75, 126.50)",
      "INSERT INTO staff (id, name, dept, job,        salary, comm) VALUES (200, 'Scoutten',  42, 'Clerk',     11508.60, 84.20)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (210, 'Lu',        10, 'Mgr',   10, 20010.00)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (220, 'Smith',     51, 'Sales',  7, 17654.50, 992.80)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (230, 'Lundquist', 51, 'Clerk',  3, 13369.80, 189.65)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (240, 'Daniels',   10, 'Mgr',    5, 19260.25)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (250, 'Wheeler',   51, 'Clerk',  6, 14460.00, 513.30)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (260, 'Jones',     10, 'Mgr',   12, 21234.00)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (270, 'Lea',       66, 'Mgr',    9, 18555.50)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (280, 'Wilson',    66, 'Sales',  9, 18674.50, 811.50)",
      "INSERT INTO staff (id, name, dept, job, years, salary      ) VALUES (290, 'Quill',     84, 'Mgr',   10, 19818.00)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (300, 'Davis',     84, 'Sales',  5, 15454.50, 806.10)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (310, 'Graham',    66, 'Sales', 13, 21000.00, 200.30)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (320, 'Gonzales',  66, 'Sales',  4, 16858.20, 844.00)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (330, 'Burke',     66, 'Clerk',  1, 10988.00, 55.50)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (340, 'Edwards',   84, 'Sales',  7, 17844.00, 1285.00)",
      "INSERT INTO staff (id, name, dept, job, years, salary, comm) VALUES (350, 'Gafney',    84, 'Clerk',  5, 13030.50, 188.00)"
    ],
    'employee' => [
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000010', 'CHRISTINE', 'I', 'HAAS', 'A00', '3978', '01/01/1965', 'PRES', 18, 'F', '08/24/1933', 52750.00, 1000.00, 4220.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000020', 'MICHAEL', 'L', 'THOMPSON', 'B01', '3476', '10/10/1973', 'MANAGER', 18, 'M', '02/02/1948', 41250.00, 800.00, 3300.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000030', 'SALLY', 'A', 'KWAN', 'C01', '4738', '04/05/1975', 'MANAGER', 20, 'F', '05/11/1941', 38250.00, 800.00, 3060.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000050', 'JOHN', 'B', 'GEYER', 'E01', '6789', '08/17/1949', 'MANAGER', 16, 'M', '09/15/1925', 40175.00, 800.00, 3214.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000060', 'IRVING', 'F', 'STERN', 'D11', '6423', '09/14/1973', 'MANAGER', 16, 'M', '07/07/1945', 32250.00, 500.00, 2580.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000070', 'EVA', 'D', 'PULASKI', 'D21', '7831', '09/30/1980', 'MANAGER', 16, 'F', '05/26/1953', 36170.00, 700.00, 2893.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000090', 'EILEEN', 'W', 'HENDERSON', 'E11', '5498', '08/15/1970', 'MANAGER', 16, 'F', '05/15/1941', 29750.00, 600.00, 2380.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000100', 'THEODORE', 'Q', 'SPENSER', 'E21', '0972', '06/19/1980', 'MANAGER', 14, 'M', '12/18/1956', 26150.00, 500.00, 2092.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000110', 'VINCENZO', 'G', 'LUCCHESSI', 'A00', '3490', '05/16/1958', 'SALESREP', 19, 'M', '11/05/1929', 46500.00, 900.00, 3720.00)",
      "INSERT INTO employee (empno, firstnme,          lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000120', 'SEAN', 'O''CONNELL', 'A00', '2167', '12/05/1963', 'CLERK', 14, 'M', '10/18/1942', 29250.00, 600.00, 2340.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000130', 'DOLORES', 'M', 'QUINTANA', 'C01', '4578', '07/28/1971', 'ANALYST', 16, 'F', '09/15/1925', 23800.00, 500.00, 1904.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000140', 'HEATHER', 'A', 'NICHOLLS', 'C01', '1793', '12/15/1976', 'ANALYST', 18, 'F', '01/19/1946', 28420.00, 600.00, 2274.00)",
      "INSERT INTO employee (empno, firstnme,          lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000150', 'BRUCE', 'ADAMSON', 'D11', '4510', '02/12/1972', 'DESIGNER', 16, 'M', '05/17/1947', 25280.00, 500.00, 2022.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000160', 'ELIZABETH', 'R', 'PIANKA', 'D11', '3782', '10/11/1977', 'DESIGNER', 17, 'F', '04/12/1955', 22250.00, 400.00, 1780.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000170', 'MASATOSHI', 'J', 'YOSHIMURA', 'D11', '2890', '09/15/1978', 'DESIGNER', 16, 'M', '01/05/1951', 24680.00, 500.00, 1974.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000180', 'MARILYN', 'S', 'SCOUTTEN', 'D11', '1682', '07/07/1973', 'DESIGNER', 17, 'F', '02/21/1949', 21340.00, 500.00, 1707.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000190', 'JAMES', 'H', 'WALKER', 'D11', '2986', '07/26/1974', 'DESIGNER', 16, 'M', '06/25/1952', 20450.00, 400.00, 1636.00)",
      "INSERT INTO employee (empno, firstnme,          lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000200', 'DAVID', 'BROWN', 'D11', '4501', '03/03/1966', 'DESIGNER', 16, 'M', '05/29/1941', 27740.00, 600.00, 2217.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000210', 'WILLIAM', 'T', 'JONES', 'D11', '0942', '04/11/1979', 'DESIGNER', 17, 'M', '02/23/1953', 18270.00, 400.00, 1462.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000220', 'JENNIFER', 'K', 'LUTZ', 'D11', '0672', '08/29/1968', 'DESIGNER', 18, 'F', '03/19/1948', 29840.00, 600.00, 2387.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000230', 'JAMES', 'J', 'JEFFERSON', 'D21', '2094', '11/21/1966', 'CLERK', 14, 'M', '05/30/1935', 22180.00, 400.00, 1774.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000240', 'SALVATORE', 'M', 'MARINO', 'D21', '3780', '12/05/1979', 'CLERK', 17, 'M', '03/31/1954', 28760.00, 600.00, 2301.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000250', 'DANIEL', 'S', 'SMITH', 'D21', '0961', '10/30/1969', 'CLERK', 15, 'M', '11/12/1939', 19180.00, 400.00, 1534.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000260', 'SYBIL', 'P', 'JOHNSON', 'D21', '8953', '09/11/1975', 'CLERK', 16, 'F', '10/05/1936', 17250.00, 300.00, 1380.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000270', 'MARIA', 'L', 'PEREZ', 'D21', '9001', '09/30/1980', 'CLERK', 15, 'F', '05/26/1953', 27380.00, 500.00, 2190.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000280', 'ETHEL', 'R', 'SCHNEIDER', 'E11', '8997', '03/24/1967', 'OPERATOR', 17, 'F', '03/28/1936', 26250.00, 500.00, 2100.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000290', 'JOHN', 'R', 'PARKER', 'E11', '4502', '05/30/1980', 'OPERATOR', 12, 'M', '07/09/1946', 15340.00, 300.00, 1227.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000300', 'PHILIP', 'X', 'SMITH', 'E11', '2095', '06/19/1972', 'OPERATOR', 14, 'M', '10/27/1936', 17750.00, 400.00, 1420.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000310', 'MAUDE', 'F', 'SETRIGHT', 'E11', '3332', '09/12/1964', 'OPERATOR', 12, 'F', '04/21/1931', 15900.00, 300.00, 1272.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000320', 'RAMLAL', 'V', 'MEHTA', 'E21', '9990', '07/07/1965', 'FIELDREP', 16, 'M', '08/11/1932', 19950.00, 400.00, 1596.00)",
      "INSERT INTO employee (empno, firstnme,          lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000330', 'WING', 'LEE', 'E21', '2103', '02/23/1976', 'FIELDREP', 14, 'M', '07/18/1941', 25370.00, 500.00, 2030.00)",
      "INSERT INTO employee (empno, firstnme, midinit, lastname, workdept, phoneno, hiredate, job, edlevel, sex, birthdate, salary, bonus, comm) VALUES ('000340', 'JASON', 'R', 'GOUNOT', 'E21', '5698', '05/05/1947', 'FIELDREP', 16, 'M', '05/17/1926', 23840.00, 500.00, 1907.00)",
    ],
    'emp_resume' => [
      "INSERT INTO emp_resume VALUES ('000130', 'ascii', 'resume 130')",
      "INSERT INTO emp_resume VALUES ('000140', 'ascii', 'resume 140')",
      "INSERT INTO emp_resume VALUES ('000150', 'ascii', 'resume 150')",
      "INSERT INTO emp_resume VALUES ('000160', 'ascii', 'resume 160')"
    ]

  );

}
