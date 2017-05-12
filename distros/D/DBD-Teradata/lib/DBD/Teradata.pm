require 5.008;
use DBI;
DBI->require_version(1.39);
use DBI::DBD;
use DBI qw(:sql_types);
use Encode;
use bytes;
our $phdfltsz = 16;
our $maxbufsz = 64256;
our $maxbigbufsz = 2097100;
our $platform;
our $copyright = "Copyright(c) 2001-2007, Presicient Corporation, USA";
our ($dechi, $declo);
our $hostchars;
our $debug;
our $inited;
our $use_arm;
package DBD::Teradata;

use Config;
use Exporter;
use DBI qw(:sql_types);
use Time::Local;

BEGIN {
our @ISA = qw(Exporter);

our @EXPORT    = ();
our @EXPORT_OK = qw(
	%td_type_code2str
	%td_type_str2baseprec
	%td_type_str2basescale
	%td_lob_scale
	@td_decszs
	%td_type_str2dbi
	%td_type_str2size
	%td_type_str2pack
	%td_type_str2stringtypes
	%td_type_str2binarytypes
	%td_type_dbi2stringtypes
	%td_type_dbi2str
	%td_activity_types
	%td_sqlstates
	@td_indicbits
	@td_indicmasks
	@td_decstrs
	@td_decscales
	@td_decfactors
	%td_type_dbi2preconly
	%td_type_dbi2hasprec
	%td_type_dbi2hasscale
	%td_type_dbi2pack
	%td_type_code2dbi
	%td_type_dbi2code
	%td_type_dbi2size
	%td_type_str2ddcodes
	%td_type_ddcode2str
);

	$platform = $ENV{TDAT_PLATFORM_CODE};
	$hostchars = (ord('A') != 65) ? 64 : 127;

	my $netval = unpack('n', pack('s', 1234));
	$platform = ($hostchars == 64) ? 3 :
		(($netval == 1234) ? 7 : 8)
		unless $platform && ($platform=~/^\d+$/);
	$hostchars |= 128 if ($netval == 1234);

	my $phsz = $ENV{TDAT_PH_SIZE};
	$phdfltsz = $phsz
		if defined($phsz) && ($phsz=~/^\d+$/) && ($phsz > 0) && ($phsz < 1024);
	($dechi, $declo) = ($platform == 7) ? (0, 1) : (1, 0);

	$debug = $ENV{TDAT_DBD_DEBUG} || 0;

	$use_arm = ($Config{archname}=~/^arm-linux/i);
our $HAS_WEAKEN = eval {
	    require Scalar::Util;
	    Scalar::Util::weaken(my $test = \"foo");
	    1;
	};
};

our %td_type_code2str = (
400, 'BLOB',
404, 'DEFERRED BLOB',
408, 'BLOB LOCATOR',
416, 'CLOB',
420, 'DEFERRED CLOB',
424, 'CLOB LOCATOR',
448, 'VARCHAR',
452, 'CHAR',
456, 'LONG VARCHAR',
464, 'VARGRAPHIC',
468, 'GRAPHIC',
472, 'LONG VARGRAPHIC',
480, 'FLOAT',
484, 'DECIMAL',
496, 'INTEGER',
500, 'SMALLINT',
600, 'BIGINT',
688, 'VARBYTE',
692, 'BYTE',
696, 'LONG VARBYTE',
752, 'DATE',
756, 'BYTEINT',
760, 'TIMESTAMP',
764, 'TIME',
);

our %td_type_code2dbi = (
400, 30,
404, 30,
408, 31,
416, 40,
420, 40,
424, 41,
448, 12,
452, 1,
456, 12,
464, -9,
468, -8,
472, -10,
480, 6,
484, 3,
496, 4,
500, 5,
600, -5,
688, -3,
692, -2,
696, -3,
752, 9,
756, -6,
760, 11,
764, 10,
);

our %td_type_str2baseprec = (
'DEC', 5, 'DECIMAL', 5, 'CHAR', 1, 'VARCHAR', 1, 'BYTE', 1,
'VARBYTE', 1, 'GRAPHIC', 1, 'VARGRAPHIC', 1,
'TIMESTAMP', 6, 'TIME', 6, 'GRAPHIC', 1, 'YEAR', 2,
'MONTH', 2, 'DAY', 2, 'HOUR', 2,
'SECOND', 2, 'BLOB', 2147483648, 'CLOB', 2147483648);

our %td_type_str2basescale = (
'DEC', 0, 'DECIMAL', 0, 'YEAR', 6, 'DAY', 6, 'HOUR', 6, 'SECOND', 6);

our %td_lob_scale = (
'K', 1024,
'M', 1048576,
'G', 1073741824);

our @td_decszs = (1, 1, 1, 2, 2, 4, 4, 4, 4, 4, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8);

our %td_type_str2dbi = (
'CHAR', 1,
'VARCHAR', 12,
'BYTE', -2,
'VARBYTE', -3,
'INT', 4,
'INTEGER', 4,
'SMALLINT', 5,
'BYTEINT', -6,
'FLOAT', 6,
'DEC', 3,
'DECIMAL', 3,
'DATE', 9,
'TIMESTAMP', 11,
'INTERVAL', 11,
'GRAPHIC', -2,
'VARGRAPHIC', -3,
'TIME', 10,
'INTERVAL DAY', 103,
'INTERVAL DAY TO HOUR', 108,
'INTERVAL DAY TO MINUTE', 109,
'INTERVAL DAY TO SECOND', 110,
'INTERVAL HOUR', 104,
'INTERVAL HOUR TO MINUTE', 111,
'INTERVAL HOUR TO SECOND', 112,
'INTERVAL MINUTE', 105,
'INTERVAL MINUTE TO SECOND', 113,
'INTERVAL MONTH', 102,
'INTERVAL SECOND', 106,
'INTERVAL YEAR', 101,
'INTERVAL YEAR TO MONTH', 107,
'TIMESTAMP WITH TIME ZONE', 95,
'TIME WITH TIME ZONE', 94,
'CLOB', 40,
'BLOB', 30,
);

our %td_type_str2size = (
'CHAR', 1,
'VARCHAR', 32000,
'BYTE', 1,
'VARBYTE', 32000,
'INT', 4,
'INTEGER', 4,
'SMALLINT', 2,
'BYTEINT', 1,
'FLOAT', 8,
'DEC', 4,
'DECIMAL', 4,
'DATE', 4,
'GRAPHIC', 2,
'VARGRAPHIC', 32000,
'TIME', 8,
'TIMESTAMP', 19,
'TIMESTAMP WITH TIME ZONE', 25,
'TIME WITH TIME ZONE', 14,
'INTERVAL DAY', 1,
'INTERVAL DAY TO HOUR', 4,
'INTERVAL DAY TO MINUTE', 7,
'INTERVAL DAY TO SECOND', 10,
'INTERVAL HOUR', 1,
'INTERVAL HOUR TO MINUTE', 4,
'INTERVAL HOUR TO SECOND', 7,
'INTERVAL MINUTE', 1,
'INTERVAL MINUTE TO SECOND', 4,
'INTERVAL MONTH', 1,
'INTERVAL SECOND', 1,
'INTERVAL YEAR', 1,
'INTERVAL YEAR TO MONTH', 4);

our %td_type_str2pack = (
	'VARCHAR', 'S/a*',
	'CHAR', 'A',
	'FLOAT', 'd',
	'DEC', 'a',
	'DECIMAL', 'a',
	'INT', 'l',
	'INTEGER', 'l',
	'SMALLINT', 's',
	'BYTEINT', 'c',
	'VARBYTE', 'S/a*',
	'BYTE', 'a',
	'DATE', 'l',
	'TIMESTAMP', 'A',
	'TIME', 'A',
	'INTERVAL DAY', 'A',
	'INTERVAL DAY TO HOUR', 'A',
	'INTERVAL DAY TO MINUTE', 'A',
	'INTERVAL DAY TO SECOND', 'A',
	'INTERVAL HOUR', 'A',
	'INTERVAL HOUR TO MINUTE', 'A',
	'INTERVAL HOUR TO SECOND', 'A',
	'INTERVAL MINUTE', 'A',
	'INTERVAL MINUTE TO SECOND', 'A',
	'INTERVAL MONTH', 'A',
	'INTERVAL SECOND', 'A',
	'INTERVAL YEAR', 'A',
	'INTERVAL YEAR TO MONTH', 'A',
	'TIMESTAMP WITH TIME ZONE', 'A',
	'TIME WITH TIME ZONE', 'A',
	'CLOB', 'Q/a*',
	'BLOB', 'Q/a*',
	);

our %td_type_str2stringtypes = (
	'VARCHAR', 1,
	'CHAR', 1,
	'TIMESTAMP', 1,
	'TIME', 1,
	'INTERVAL DAY', 1,
	'INTERVAL DAY TO HOUR', 1,
	'INTERVAL DAY TO MINUTE', 1,
	'INTERVAL DAY TO SECOND', 1,
	'INTERVAL HOUR', 1,
	'INTERVAL HOUR TO MINUTE', 1,
	'INTERVAL HOUR TO SECOND', 1,
	'INTERVAL MINUTE', 1,
	'INTERVAL MINUTE TO SECOND', 1,
	'INTERVAL MONTH', 1,
	'INTERVAL SECOND', 1,
	'INTERVAL YEAR', 1,
	'INTERVAL YEAR TO MONTH', 1,
	'TIMESTAMP WITH TIME ZONE', 1,
	'TIME WITH TIME ZONE', 1,
	'CLOB', 1,
	);

our %td_type_str2binarytypes = (
	'VARGRAPHIC', 1,
	'GRAPHIC', 1,
	'VARBYTE', 1,
	'BYTE', 1,
	'BLOB', 1,
	);

our %td_type_dbi2str = (
	12, 'VARCHAR',
	1, 'CHAR',
	6, 'FLOAT',
	3, 'DECIMAL',
	4, 'INTEGER',
	5, 'SMALLINT',
	-6, 'BYTEINT',
	-3, 'VARBYTE',
	-2, 'BYTE',
	9, 'DATE',
	11, 'TIMESTAMP',
	10, 'TIME',
	103, 'INTERVAL DAY',
	108, 'INTERVAL DAY TO HOUR',
	109, 'INTERVAL DAY TO MINUTE',
	110, 'INTERVAL DAY TO SECOND',
	104, 'INTERVAL HOUR',
	111, 'INTERVAL HOUR TO MINUTE',
	112, 'INTERVAL HOUR TO SECOND',
	105, 'INTERVAL MINUTE',
	113, 'INTERVAL MINUTE TO SECOND',
	102, 'INTERVAL MONTH',
	106, 'INTERVAL SECOND',
	101, 'INTERVAL YEAR',
	107, 'INTERVAL YEAR TO MONTH',
	95, 'TIMESTAMP WITH TIME ZONE',
	94, 'TIME WITH TIME ZONE',
	);

our %td_activity_types = (
0, 'Unknown',
1, 'Select',
2, 'Insert',
3, 'Update',
4, 'Update..RETRIEVING',
5, 'Delete',
6, 'Create Table',
7, 'Modify Table',
8, 'Create View',
9, 'Create Macro',
10, 'Drop Table',
11, 'Drop View',
12, 'Drop Macro',
13, 'Drop Index',
14, 'Rename Table',
15, 'Rename View',
16, 'Rename Macro',
17, 'Create Index',
18, 'Create Database',
19, 'Create User',
20, 'Grant',
21, 'Revoke',
22, 'Give',
23, 'Drop Database',
24, 'Modify Database',
25, 'Database',
26, 'Begin Transaction',
27, 'End Transaction',
28, 'Abort',
29, 'Null',
30, 'Execute',
31, 'Comment Set',
32, 'Comment Returning',
33, 'Echo',
34, 'Replace View',
35, 'Replace Macro',
36, 'Checkpoint',
37, 'Delete Journal',
38, 'Rollback',
39, 'Release Lock',
40, 'HUT Config',
41, 'Verify Checkpoint',
42, 'Dump Journal',
43, 'Dump',
44, 'Restore',
45, 'RollForward',
46, 'Delete Database',
47, 'internal use only',
48, 'internal use only',
49, 'Show',
50, 'Help',
51, 'Begin Loading',
52, 'Checkpoint Load',
53, 'End Loading',
54, 'Insert',
64, 'Exec MLOAD',
76, '2PC Vote Request',
77, '2PC Vote and Terminate',
78, '2PC Commit',
79, '2PC Abort',
80, '2PC Yes Vote',
83, 'Set Session Rate',
84, 'Monitor Session',
85, 'Identify Session',
86, 'Abort Session',
87, 'Set Resource Rate',
89, 'ANSI Commit Work',
91, 'Monitor Virtual Config',
92, 'Monitor Physical Config',
93, 'Monitor Virtual Summary',
94, 'Monitor Physical Summary',
95, 'Monitor Virtual Resource',
96, 'Monitor Physical Resource',
97, 'Create Trigger',
98, 'Drop Trigger',
99, 'Rename Trigger',
100, 'Replace Trigger',
101, 'Alter Trigger',
103, 'Drop Procedure',
104, 'Create Procedure',
105, 'Call',
106, 'Rename Procedure',
107, 'Replace Procedure',
108, 'Set Session Account',
110, 'Monitor SQL',
111, 'Monitor Version',
112, 'Begin DBQL',
113, 'End DBQL',
114, 'Create Role',
115, 'Drop Role',
116, 'Grant Role',
117, 'Revoke Role',
118, 'Create Profile',
119, 'Modify Profile',
120, 'Drop Profile',
121, 'Set Role',
122, 'UDF',
123, 'UDF',
124, 'UDF',
125, 'UDF',
126, 'UDF',
127, 'Merge Mixed',
128, 'Merge Update',
129, 'Merge Insert',
130, 'Alter Procedure',
131, 'TDQM Enable',
132, 'TDQM Stats',
133, 'TDQM Performance Group',
);
our %td_sqlstates = qw(
2147 53018 2149 53018 2161 22012 2162 22012 2163 22012 2164 22003 2165 22003 2166 22003
2232 22003 2233 22003 2239 22003 2240 22003 2450 40001 2603 53015 2604 53015 2605 53015
2606 53015 2607 53015 2608 53015 2614 22003 2615 22003 2616 22003 2617 22003 2618 22012
2619 22012 2620 22021 2621 22012 2622 53015 2623 53015 2631 40001 2661 22000 2662 22011
2663 22011 2664 54001 2665 22007 2666 22007 2674 22003 2675 22003 2676 22012 2679 22012
2680 22023 2682 22003 2683 22003 2684 22012 2687 22012 2689 23502 2700 23700 2726 23726
2727 23727 2728 23728 2801 23505 2802 23505 2803 23505 2805 57014 2827 58004 2828 58004
2843 57014 2892 01003 2893 22001 2894 24894 2895 24895 2896 24896 2938 00000 2980 23505
3002 46000 3003 46000 3004 46000 3006 08T06 3007 08T07 3014 46000 3015 46000 3016 46000
3023 46000 3025 08T25 3026 46000 3110 00000 3111 40502 3120 58004 3121 02000 3130 57014
3504 53003 3509 54001 3513 00000 3514 00000 3515 52011 3517 52011 3518 54008 3519 52010
3520 22003 3523 42000 3524 42000 3526 52004 3527 42015 3528 22012 3529 42015 3530 42015
3532 53021 3534 52010 3535 22018 3539 52004 3540 54001 3541 57014 3543 57014 3545 42502
3554 53003 3556 54011 3560 52011 3564 44000 3568 42507 3569 56003 3574 56003 3577 57014
3580 53015 3581 53015 3582 42582 3597 54001 3604 23502 3606 52001 3609 54001 3617 42015
3622 53019 3627 42507 3628 42507 3629 54001 3637 53005 3638 57014 3639 53018 3640 53018
3641 53021 3642 53021 3643 53019 3644 53019 3653 53026 3654 53025 3656 52004 3659 53008
3660 53015 3661 57014 3662 53015 3663 53015 3669 21000 3702 54001 3704 42506 3705 54001
3710 54001 3712 54001 3714 54001 3721 24721 3731 42501 3732 0A732 3733 42514 3735 01004
3737 01004 3738 01004 3741 54001 3744 52010 3747 01003 3751 42504 3752 22003 3753 22003
3754 22003 3755 22003 3756 22012 3757 22003 3758 22003 3759 42504 3760 42503 3775 42506
3789 42514 3801 52010 3802 52004 3803 52010 3804 52010 3805 52010 3807 42000 3809 52002
3810 52003 3811 23502 3812 42000 3813 42000 3816 42505 3817 42505 3818 42505 3819 53015
3820 42505 3821 42505 3822 52002 3823 53007 3824 52004 3827 56021 3829 56021 3833 56021
3848 52006 3850 54001 3851 54001 3856 42501 3857 53015 3858 42501 3865 42501 3866 42501
3867 54001 3872 56003 3880 42501 3881 42501 3883 53003 3885 52001 3889 42514 3896 54001
3897 58004 3919 54011 3968 42968 3969 42969 3970 42970 3971 42971 3973 42973 3974 42974
3975 42975 3976 53030 3977 42977 3978 42978 3979 42979 3980 42980 3981 42981 3982 42982
3989 01001 3990 42990 3991 42991 3992 42992 3993 42993 3994 42994 3995 42995 3996 22001
3997 22019 3998 22025 3999 01999 5300 42J00 5301 42J01 5302 52009 5303 42J03 5304 42J04
5305 42J05 5306 42J06 5307 42J07 5308 42J08 5309 42J09 5310 42J10 5311 42J11 5312 42J12
5313 42J13 5314 42J14 5315 42J15 5316 44000 5317 23000 5800 01800 5801 01801 5802 01802
5803 01803 5804 01804 5805 01805 5806 01806 5807 01807 5808 01808 5809 01809 5810 01810
5811 01811 5812 01812 5813 01813 5814 01814 5815 01815 5816 01816 5817 01817 5818 01818
5819 01819 5820 01820 5821 01821 5822 01822 5823 01823 5824 01824 5825 01825 5826 01826
5827 01827 5828 01828 5829 01829 5830 01830 5831 01831 5832 01832 5833 01833 5834 01834
5835 01835 5836 01836 5837 01837 5838 01838 5839 01839 5840 01840 5841 01841 7601 20000
7610 24502 7627 21000 7631 24501 7632 02000 );
our @td_indicbits = (128, 64, 32, 16, 8, 4, 2, 1);
our @td_indicmasks = (0x7F, 0xBF, 0xDF, 0xEF, 0xF7, 0xFB, 0xFD, 0xFE);
our @td_decstrs = ( 'c', 'c', 'c', 's', 's', 'l', 'l', 'l', 'l', 'l');
our @td_decscales = ( 1.0, 1.0E-1, 1.0E-2, 1.0E-3, 1.0E-4, 1.0E-5, 1.0E-6,
	1.0E-7, 1.0E-8, 1.0E-9, 1.0E-10, 1.0E-11, 1.0E-12,
	1.0E-13, 1.0E-14, 1.0E-15, 1.0E-16, 1.0E-17, 1.0E-18);

our @td_decfactors = ( 1.0, 1.0E1, 1.0E2, 1.0E3, 1.0E4, 1.0E5, 1.0E6,
	1.0E7, 1.0E8, 1.0E9, 1.0E10, 1.0E11, 1.0E12,
	1.0E13, 1.0E14, 1.0E15, 1.0E16, 1.0E17, 1.0E18);

our %td_type_dbi2preconly = (
	1, 1,
	12, 1,
	-1, 1,
	-2, 1,
	-3, 1,
	3, 2);

our %td_type_dbi2hasprec = (
1, 1,
12, 1,
-2, 1,
-3, 1,
3, 1,
10, 1,
11, 1);

our %td_type_dbi2hasscale = (
3, 1,
110, 1,
112, 1,
113, 1,
);

our %td_type_dbi2pack = (
	12, 'S/a*',
	1, 'A',
	6, 'd',
	3, 'a',
	4, 'l',
	5, 's',
	-6, 'c',
	-3, 'S/a*',
	-2, 'a',
	-4, 'S/a*',
	9, 'l',
	11, 'A',
	10, 'A',
	103, 'A',
	108, 'A',
	109, 'A',
	110, 'A',
	104, 'A',
	111, 'A',
	112, 'A',
	105, 'A',
	113, 'A',
	102, 'A',
	106, 'A',
	101, 'A',
	107, 'A',
	95, 'A',
	94, 'A',
	);

our %td_type_dbi2size = (
	12, 32000,
	1, 32000,
	6, 8,
	3, 8,
	4, 4,
	5, 2,
	-6, 1,
	-3, 32000,
	-2, 32000,
	-4, 32000,
	9, 4,
	11, 26,
	10, 17
	);

our %td_type_dbi2code = (
30, 400,
31, 408,
40, 416,
41, 424,
12, 448,
1, 452,
-1, 456,
-9, 464,
-8, 468,
-10, 472,
6, 480,
3, 484,
4, 496,
5,500,
-5, 600,
-3, 688,
-2, 692,
-4, 696,
9, 752,
-6, 756,
11,760,
10, 764,
);

our %td_type_dbi2stringtypes = (
11, 1,
10, 1,
103, 1,
108, 1,
109, 1,
110, 1,
104, 1,
111, 1,
112, 1,
105, 1,
113, 1,
102, 1,
106, 1,
101, 1,
107, 1,
95, 1,
94,  1
);

our %td_type_ddcode2str = (
);

our %td_type_str2ddcodes = (
);

use vars qw($VERSION $drh);
our $VERSION = '1.52';
$drh = undef;
my $installed = undef;
use strict ;
sub driver {
	return $drh if $drh;
	my ($class, $attr) = @_;
	$class .= '::dr';
	$drh = DBI::_new_drh($class,
		{
			Name => 'Teradata',
			Version => $VERSION,
			Attribution => 'DBD::Teradata by Presicient Corp.'
		});
	unless ($DBD::Teradata::installed) {
		DBD::Teradata::dr->install_method('tdat_FirstAvailable');
		DBD::Teradata::dr->install_method('tdat_FirstAvailList');


		DBD::Teradata::st->install_method('tdat_BindColArray');
		DBD::Teradata::st->install_method('tdat_BindParmArray');
		DBD::Teradata::st->install_method('tdat_Rewind');
		DBD::Teradata::st->install_method('tdat_Realize');
		DBD::Teradata::st->install_method('tdat_CharSet');
		DBD::Teradata::st->install_method('tdat_Unpack');

		$DBD::Teradata::installed = 1;
	}
	DBI->trace_msg("DBD::Teradata v.$VERSION loaded on $^O\n", 1);
	$drh->{_connections} = {};
	return $drh;
}
sub CLONE {
	DBD::Teradata::impl->io_clone;
	undef $drh;
}
1;
package DBD::Teradata::dr;
$DBD::Teradata::dr::imp_data_size = 0;
sub connect {
	my ($drh, $dsn, $user, $auth, $attr) = @_;
	my $host = '';
	my $port = 1025;
	$attr = {}
		unless defined $attr;
	$attr->{tdat_utility} = 'DBC/SQL'
		unless exists $attr->{tdat_utility};
	$attr->{tdat_mode} = 'DEFAULT'
		unless exists $attr->{tdat_mode};
	if ($dsn=~/^(\d+\.\d+\.\d+\.\d+)(:(\d+))?$/) {
		return $drh->DBI::set_err(-1, 'CLI does not support numeric host addresses.', '08001');
	}
	elsif ($dsn=~/^(\w[^:]*)(:(\d+))?$/) {
		($host, $port) = ($1, $3);
	}
	else {
		return $drh->DBI::set_err(-1, "Malformed dsn $dsn", '08001');
	}
	$port = 1025 unless $port;
	my ($key, $val);
	while (($key, $val) = each %$attr) {
		if ($key eq 'tdat_mode') {
			return $drh->DBI::set_err(-1, "Unknown session mode $val specified.", 'S1000')
				unless ($val=~/^(ANSI|TERADATA|DEFAULT)$/i);
		}
		elsif ($key eq 'tdat_bufsize') {
			return $drh->DBI::set_err(-1, "Bad buffer size $val. Value must be between 64000 and 2097151.", 'S1000')
				unless ($val=~/^\d+$/);
			$attr->{tdat_bufsize} = 64000 unless ($val >= 64000);
			$attr->{tdat_bufsize} = 2097151 unless ($val < 2097152);
		}
		elsif ($key eq 'tdat_respsize') {
			return $drh->DBI::set_err(-1, "Bad reponse buffer size $val. Value must be between 64000 and 2097151.", 'S1000')
				unless ($val=~/^\d+$/);
			$attr->{tdat_respsize} = 64000 unless ($val >= 64000);
			$attr->{tdat_respsize} = 2097151 unless ($val < 2097152);
		}
		elsif ($key eq 'tdat_reqsize') {
			return $drh->DBI::set_err(-1, "Bad request buffer size $val. Value must be between 256 and 2097151.", 'S1000')
				unless ($val=~/^\d+$/);
			$attr->{tdat_reqsize} = 256 unless ($val >= 256);
			$attr->{tdat_reqsize} = 2097151 unless ($val < 2097152);
		}
		elsif ($key eq 'tdat_charset') {
			return $drh->DBI::set_err(-1, 'Bad character set.', 'S1000')
				unless ($val=~/^ASCII|UTF8|EBCDIC$/i);
		}
		elsif ($attr->{tdat_reconnect}) {
			return $drh->DBI::set_err(-1, 'Cannot reconnect non-SQL sessions.', 'S1000')
				if ($attr->{tdat_utility} ne 'DBC/SQL');
			return $drh->DBI::set_err(-1, 'Invalid tdat_reconnect value: must be scalar or coderef.', 'S1000')
				if (ref $attr->{tdat_reconnect} ne 'CODE');
		}
	}
	return $drh->DBI::set_err(-1, 'Username required for connect.', 'S1000')
		unless defined($user) || $attr->{tdat_passthru};
	$attr->{tdat_bufsize} = $maxbufsz
		unless exists $attr->{tdat_bufsize};
	$attr->{tdat_reqsize} = $attr->{tdat_bufsize}
		unless exists $attr->{tdat_reqsize};
	$attr->{tdat_respsize} = $attr->{tdat_bufsize}
		unless exists $attr->{tdat_respsize};
	my ($iobj, $err, $errstr, $state) =
		DBD::Teradata::impl->new($host, $port, $user, $auth, undef, $attr);
	return $drh->set_err($err, $errstr, $state)
		unless $iobj;
	$attr->{tdat_reqsize} = $iobj->io_set_reqsz($maxbufsz)
		if $attr->{tdat_reqsize} &&
			($attr->{tdat_reqsize} > $maxbufsz) &&
			(($iobj->[40] < 5000000) ||
			(($attr->{tdat_utility} ne 'DBC/SQL') && ($iobj->[40] < 6000000)));
	$attr->{tdat_respsize} = $iobj->io_set_respsz($maxbufsz)
		if $attr->{tdat_respsize} &&
			($attr->{tdat_respsize} > $maxbufsz) &&
			($iobj->[40] < 6000000);
	my ($outer, $dbh) = DBI::_new_dbh($drh,{
		Name 			=> $dsn,
		USER 			=> $user,
		CURRENT_USER	=> $user,
		tdat_utility	=> $attr->{tdat_utility},
		tdat_sessno 	=> $iobj->[13],
		tdat_hostid 	=> $iobj->[29],
		tdat_mode 		=> $attr->{tdat_mode},
		tdat_version	=> $iobj->[28],
		tdat_compatible => (defined($attr->{tdat_compatible}) ? $attr->{tdat_compatible} : 99.0),
		tdat_reconnect	=> $attr->{tdat_reconnect},
		tdat_charset	=> $attr->{tdat_charset},
		tdat_reqsize	=> $attr->{tdat_reqsize},
		tdat_respsize	=> $attr->{tdat_respsize},
		tdat_no_bigint  => $attr->{tdat_no_bigint},
	});
	$dbh->{tdat_password} = $auth
		if $attr->{tdat_lsn};
	$iobj->[31] = $dbh;
	$dbh->{tdat_uses_cli} = 1;
	$dbh->{tdat_versnum} = $iobj->[40];
	$dbh->{_iobj} = $iobj;
	$dbh->{_stmts} = { };
	$dbh->{_nextcursor} = 0;
	$dbh->{_cursors} = { };
	$dbh->{_debug} = $ENV{TDAT_DBD_DEBUG};
	$dbh->{_utf8} = ($attr->{tdat_charset} eq 'UTF8');
	$dbh->{Active} = 1;
	$drh->{_connections}{($dsn . '_' . $dbh->{tdat_sessno})} = $dbh
		unless $attr->{tdat_passthru};
	return $outer;
}
sub data_sources {}
sub DESTROY {
	$_[0]->disconnect_all();
}
sub disconnect_all {
	foreach (values %{$_[0]->{_connections}}) {
		$_->disconnect if defined($_);
	}
	$_[0]->{_connections} = { };
}
sub FirstAvailable {
	my ($drh, $dbhlist, $timeout) = @_;
	my @sesslist = ();
	my %seshash;
	foreach my $dbh (@$dbhlist) {
		push(@sesslist, defined($dbh) ?
			(ref $dbh) ? $dbh->{_iobj} : $dbh : undef);
	}
	my @outlist = DBD::Teradata::impl::io_FirstAvailList(\@sesslist, $timeout);
	return (@outlist ? $outlist[0] : undef);
}
*tdat_FirstAvailable = \&FirstAvailable;
sub FirstAvailList {
	my ($drh, $dbhlist, $timeout) = @_;
	my @sesslist = ();
	foreach my $dbh (@$dbhlist) {
		push(@sesslist, defined($dbh) ?
			(ref $dbh) ? $dbh->{_iobj} : $dbh : undef);
	}
	return DBD::Teradata::impl::io_FirstAvailList(\@sesslist, $timeout);
}
*tdat_FirstAvailList = \&FirstAvailList;
1;
package DBD::Teradata::db;
use DBI qw(:sql_types);
$DBD::Teradata::db::imp_data_size = 0;
our %readonly_attrs = qw(
	tdat_utility 1
	tdat_sessno  1
	tdat_hostid  1
	tdat_mode	 1
	tdat_version 1
	tdat_compatible 1
	tdat_charset 1
);
our %valid_attrs = (
'ChopBlanks', 1,
'tdat_sp_print', 1,
'tdat_sp_save', 1,
'tdat_compatible', 1,
'tdat_formatted', 1,
'tdat_keepresp', 1,
'tdat_nowait', 1,
'tdat_raw_in', 1,
'tdat_raw_out', 1,
'tdat_raw', 1,
'tdat_clone', 1,
'tdat_mload', 1,
'tdat_mlseq', 1,
'tdat_mlmask', 1,
'tdat_vartext_out', 1,
'tdat_vartext_in', 1,
'tdat_charset', 1,
'tdat_passthru', 1,
'tdat_no_bigint', 1,
);
my $pmapi_loaded;
sub table_info {
	my $dbh = shift;
	return undef
		unless ($dbh->{tdat_utility} eq 'DBC/SQL');
	my $sth = $dbh->prepare(
"SELECT NULL AS TABLE_CAT,
	DATABASENAME AS TABLE_SCHEM,
	TABLENAME AS TABLE_NAME,
	CASE TABLEKIND WHEN 'I' THEN 'JOIN INDEX'
	WHEN 'V' THEN 'VIEW'
	ELSE
	(CASE WHEN UPPER(REQUESTTEXT) LIKE '% GLOBAL TEMP% TABLE %'
		THEN 'GLOBAL TEMPORARY'
		ELSE (CASE WHEN UPPER(REQUESTTEXT) LIKE '% VOLATILE TABLE %'
			THEN 'VOLATILE'
		ELSE 'TABLE' END)
		END)
	END AS TABLE_TYPE,
	COMMENTSTRING (VARCHAR(256)) AS REMARKS
	FROM DBC.TABLESX
	WHERE TABLEKIND IN ('I', 'T', 'V')
	ORDER BY 2,3");
	$sth->execute;
	return $sth;
}
sub tables {
	my $dbh = shift;
	return undef
		unless ($dbh->{tdat_utility} eq 'DBC/SQL');
	my $sth = $dbh->prepare(
"SELECT TRIM(DATABASENAME) || '.' || TRIM(TABLENAME) AS ALL_TABLES
	FROM DBC.TABLESX
	WHERE TABLEKIND IN ('I', 'T', 'V')");
	$sth->execute;
	my @tbls = ();
	my $row;
	push(@tbls, $$row[0])
		while ($row = $sth->fetchrow_arrayref);
	return @tbls;
}
sub ping {
	return $_[0]->{_iobj}->io_ping ||
		$_[0]->DBI::set_err($_[0]->{_iobj}->io_get_error());
}
sub prepare {
	my ($dbh, $stmt, $attribs) = @_;
	$attribs = {}
		unless $attribs;
	$attribs->{tdat_raw_in} = $attribs->{tdat_raw},
	$attribs->{tdat_raw_out} = $attribs->{tdat_raw}
		if $attribs->{tdat_raw};
	return $dbh->DBI::set_err(-1, 'Raw output mode not compatible with formatted mode.', 'S1000')
		if $attribs->{tdat_raw_out} && $attribs->{tdat_formatted};
	return $dbh->DBI::set_err(-1, 'Raw input mode incompatible with vartext input mode.', 'S1000')
		if $attribs->{tdat_raw_in} && $attribs->{tdat_vartext_in};
	return $dbh->DBI::set_err(-1, 'Raw output mode incompatible with vartext output mode.', 'S1000')
		if $attribs->{tdat_raw_out} && $attribs->{tdat_vartext_out};
	my $passthru = $attribs->{tdat_passthru};
	my $csth = $attribs->{tdat_clone};
	return $dbh->DBI::set_err(-1, 'tdat_clone value must be DBI statement handle.', 'S1000')
		unless (! defined($csth)) ||
			(((ref $csth eq 'DBI::st') || (ref $csth eq 'DBD::Teradata::Utility::st')));
	foreach (keys %$attribs) {
		return $dbh->DBI::set_err(-1, "Unknown statement attribute \"$_\"." , 'S1000')
			unless $valid_attrs{$_};
		return $dbh->DBI::set_err(-1, 'Invalid raw mode value.', 'S1000')
			if (($_ eq 'tdat_raw_in') || ($_ eq 'tdat_raw_out')) &&
				($attribs->{$_} ne 'RecordMode') &&
				($attribs->{$_} ne 'IndicatorMode');
	}
	my $sessno = $dbh->{tdat_sessno};
	my $iobj = $dbh->{_iobj};
	my $partition = 1;
	$stmt =~s/\n/\r/g;
	$stmt=~s/^\s+//;
	$stmt=~s/\s+$//;
	return $dbh->DBI::set_err(-1, 'Cursor syntax only supported in ANSI mode.' , 'S1000')
		if ($dbh->{tdat_mode} ne 'ANSI') && ($stmt=~/\s+FOR\s+CURSOR\s*;?$/i);
	my $compatible = $attribs->{tdat_compatible} || $dbh->{tdat_compatible};
	if ($stmt=~/^\s*HELP\s+VOLATILE\s+TABLE\s*$/i) {
		return _make_sth($dbh,
			{
			%$attribs,
			Statement => $stmt,
			tdat_stmt_info => [
				undef,
				{
					ActivityType => 'Help',
					ActivityCount => 1,
					StartsAt => 0,
					EndsAt => 1,
				}
			],
			NUM_OF_FIELDS => 2,
			NAME => [ 'Table Name', 'Table Id' ],
			TYPE => [ 1, 1 ],
			PRECISION => [ 30, 12 ],
			SCALE => [ undef, undef ],
			NULLABLE => [ undef, undef ],
			tdat_TYPESTR => [ 'CHAR(30)', 'CHAR(30)' ],
			tdat_TITLE => [ 'Table Name', 'Table Id' ],
			tdat_FORMAT =>  [ 'X(30)', 'X(12)' ],
			_unpackstr => [ 'A30 A12' ],
			NUM_OF_PARAMS => 0,
			}
		);
	}
	elsif ($stmt=~/^ECHO\b/i) {
		return _make_sth($dbh,
			{
			%$attribs,
			Statement => $stmt,
			tdat_stmt_info => [
				undef,
				{
					ActivityType => 'Echo',
					ActivityCount => 0,
					StartsAt => 0,
					EndsAt => 0,
				}
			],
			NUM_OF_FIELDS => 1,
			NAME => [ 'ECHOTEXT' ],
			TYPE => [ 12 ],
			PRECISION => [ 255 ],
			SCALE => [ undef ],
			NULLABLE => [ 0 ],
			tdat_TYPESTR => [ 'VARCHAR(255)' ],
			tdat_TITLE => [ 'Echo Text' ],
			tdat_FORMAT => [ 'X(255)' ],
			_unpackstr => [ 'A*' ],
			NUM_OF_PARAMS => 0,
			}
		);
	}
	elsif ($stmt=~/^EXPLAIN\b/i) {
		return _make_sth($dbh,
			{
			%$attribs,
			Statement => $stmt,
			tdat_stmt_info => [
				undef,
				{
					ActivityType => 'Explain',
					ActivityCount => 0,
					StartsAt => 0,
					EndsAt => 0,
				}
			],
			NUM_OF_FIELDS => 1,
			NAME => [ 'Explanation' ],
			TYPE => [ 12 ],
			PRECISION => [ 80 ],
			SCALE => [ undef ],
			NULLABLE => [ 0 ],
			tdat_TYPESTR => [ 'VARCHAR(80)' ],
			tdat_TITLE => [ 'Explanation' ],
			tdat_FORMAT => [ 'X(80)' ],
			_unpackstr => [ 'A*' ],
			NUM_OF_PARAMS => 0,
			}
		);
	}
	elsif ($stmt=~/^(CREATE|REPLACE)\s+PROCEDURE\s+/i) {
		return _make_sth($dbh,
			{
			%$attribs,
			Statement => $stmt,
			tdat_stmt_info => [
				undef,
				{
					ActivityType => 'Create Procedure',
					ActivityCount => 0,
					StartsAt => 0,
					EndsAt => 0,
				},
			],
			NUM_OF_FIELDS => 1,
			NAME => [ 'COMPILE_ERROR' ],
			TYPE => [ 12 ],
			PRECISION => [ 255 ],
			SCALE => [ undef ],
			NULLABLE => [ 0 ],
			tdat_TYPESTR => [ 'VARCHAR(255)' ],
			tdat_TITLE => [ 'Compile Error' ],
			tdat_FORMAT => [ 'X(255)' ],
			_unpackstr => [ 'S/A' ],
			NUM_OF_PARAMS => 0,
			}
		);
	}
	my $rowid = undef;
	$rowid = $dbh->{_cursors}{uc $1}{_rowid}
		if ($stmt=~/\s+WHERE\s+CURRENT\s+OF\s+([^\s;]+)\s*;?\s*$/i);
	my $sth = $iobj->io_prepare($dbh, \&_make_sth, $stmt, $rowid, $attribs, $compatible, $passthru);
	return $sth || $dbh->DBI::set_err($iobj->io_get_error());
}
sub _make_sth {
	my ($dbh, $args) = @_;
	delete $args->{tdat_clone};
	delete $args->{tdat_passthru};
	$args->{CursorName} = 'CURS' . $dbh->{_nextcursor};
	$dbh->{_nextcursor}++;
	$args->{tdat_stmt_num} = 0;
	$args->{tdat_sessno} = $dbh->{tdat_sessno};
	$args->{tdat_compatible} = '999.0'
		unless $args->{tdat_compatible};
	$args->{tdat_no_bigint} = $dbh->{tdat_no_bigint}
		unless exists $args->{tdat_no_bigint};
	$args->{ParamValues} = {}
		unless $args->{ParamValues};
	$args->{ParamArrays} = {}
		unless $args->{ParamArrays};
	my @sthp = ();
	$sthp[13] = -1;
	$sthp[18] = delete $args->{_packstr};
	$sthp[10] = delete $args->{_unpackstr};
	$sthp[11] = $dbh->{_iobj};
	$sthp[5] = [];
	$sthp[2] = delete $args->{_ptypes};
	$sthp[9] = delete $args->{_plens};
	$sthp[15] = delete $args->{_usephs};
	$sthp[21] = delete $args->{_usenames};
	$sthp[22] = 1;
	$sthp[24] = 0;
	$sthp[4] = delete $args->{_parmdesc};
	$sthp[8] = delete $args->{_parmmap};
	$sthp[23] = $dbh;
	$args->{_p} = \@sthp;
	if ($args->{tdat_vartext_in}) {
		my ($ptypes, $plens) = ($sthp[2], $sthp[9]);
		foreach (0..$#$ptypes) {
			$dbh->set_err(0,
				'Using VARTEXT input with other than VARCHAR USING parameter.', '00000'),
			$ptypes->[$_] = 12,
			$plens->[$_] = 16
				unless ($ptypes->[$_] == 12);
		}
		$sthp[18] = ('S/a*' x (scalar @$ptypes));
	}
	my $stmtinfo = $args->{tdat_stmt_info};
	my ($outer, $sth) = DBI::_new_sth($dbh,
		{
			Statement => $args->{Statement},
			CursorName => $args->{CursorName}
		})
		or return $dbh->set_err(-1, 'Unable to create statement handle.', 'S1000');
	$sth->STORE('NUM_OF_PARAMS', delete $args->{NUM_OF_PARAMS});
	$sth->STORE('NUM_OF_FIELDS', delete $args->{NUM_OF_FIELDS});
	my ($key, $val);
	$sth->{$key} = $val
		while (($key, $val) = each %$args);
	$dbh->{_stmts}{$sth->{CursorName}} = $sth;
	Scalar::Util::weaken($dbh->{_stmts}{$sth->{CursorName}})
		if $DBD::Teradata::HAS_WEAKEN;
	$dbh->{_cursors}{$sth->{CursorName}} = $sth,
	$sth->{tdat_keepresp} = 1,
	$sthp[16] = 1
		if ($#$stmtinfo == 1) &&
			($stmtinfo->[1]{ActivityType} eq 'Select') &&
			($sth->{Statement}=~/\s+FOR\s+CURSOR\s*;?\s*$/i);
	$dbh->{tdat_nowait} = $sth->{tdat_nowait}
		if ($dbh->{tdat_utility} ne 'DBC/SQL');
	$sth->{tdat_TYPESTR} = DBD::Teradata::st::map_type2str($sth)
		unless defined $sth->{tdat_TYPESTR} || (! $sth->{NUM_OF_FIELDS});
	return wantarray ? ($outer, $sth) : $outer;
}
sub DESTROY {
	my $dbh = shift;
	return 1
		unless (defined($dbh->{tdat_sessno}) &&
			defined($dbh->{Name}) &&
			defined($dbh->{Driver}));
	my $host = $dbh->{Name} . '_' . $dbh->{tdat_sessno};
	return 1
		unless defined($dbh->{Driver}{_connections}{$host});
	$dbh->disconnect;
}
sub disconnect {
	my $dbh = shift;
	my $i;
	$dbh->{Active} = undef;
	$dbh->{_stmts} = $dbh->{_cursors} = undef;
	return 1
		unless defined($dbh->{tdat_sessno}) &&
			defined($dbh->{Name}) && defined($dbh->{Driver});
	my $sessno = $dbh->{tdat_sessno};
	my $host;
	my $drh = $dbh->{Driver};
	if ($sessno) {
		$host = $dbh->{Name} . '_' . $sessno;
		$dbh->set_err(0, 'Session not found'),
		return 1
			unless defined($drh->{_connections}{$host});
	}
	my $iobj = $dbh->{_iobj};
	$iobj->io_disconnect unless $dbh->{_ignore_destroy};
	$dbh->{_iobj} = undef;
	delete $drh->{_connections}{$host}
		if defined($host);
	1;
}
sub commit {
	my $dbh = shift;
	my $xactmode = $dbh->{AutoCommit};
	if (defined($xactmode) && ($xactmode == 1)) {
		warn('Commit ineffective while AutoCommit is on')
			if $dbh->{Warn};
		return 1;
	}
	my $iobj = $dbh->{_iobj};
	return 1 unless $iobj->[11];
	foreach (values(%{$dbh->{_stmts}})) {
		$_->finish
			unless $_->{_p}[22] ||
				($_->{tdat_keepresp} &&
					(! $_->{_p}[16]));
	}
	$iobj->io_commit;
	$dbh->DBI::set_err($iobj->io_get_error());
	$iobj->[11] = 0;
	return 1;
}
sub rollback {
	my $dbh = shift;
	my $xactmode = $dbh->{AutoCommit};
	if (defined($xactmode) && ($xactmode == 1)) {
		warn('Rollback ineffective while AutoCommit is on')
			if $dbh->{Warn};
		return 1;
	}
	my $iobj = $dbh->{_iobj};
	return 1 unless $iobj->[11];
	foreach (values(%{$dbh->{_stmts}})) {
		$_->finish
			unless $_->{_p}[22] ||
				($_->{tdat_keepresp} &&
					(! $_->{_p}[16]));
	}
	$iobj->io_rollback;
	$dbh->DBI::set_err($iobj->io_get_error());
	$iobj->[11] = 0;
	return 1;
}
sub STORE {
	my ($dbh, $attr, $val) = @_;
	return $dbh->SUPER::STORE($attr, $val)
		unless ($attr eq 'AutoCommit') || ($attr =~ /^(tdat_|_)/);
	$dbh->{$attr} = $val;
	$dbh->{tdat_respsize} = $dbh->{_iobj}->io_set_respsz($val)
		if ($attr eq 'tdat_respsize');
	$dbh->{tdat_reqsize} = $dbh->{_iobj}->io_set_reqsz($val)
		if ($attr eq 'tdat_reqsize');
	$dbh->{_iobj}->io_update_version($val),
	$dbh->{tdat_versnum} = $val
		if ($attr eq 'tdat_versnum') && ($val < 6020000);
	return 1;
}
sub FETCH {
	my ($dbh, $attr) = @_;
	return $dbh->{_iobj}[23] if ($attr eq 'tdat_active');
	return $dbh->{_iobj}[11] if ($attr eq 'tdat_inxact');
	return $dbh->{$attr}
		if ($attr eq 'AutoCommit') || ($attr =~ /^(tdat_|_)/);
	return $dbh->SUPER::FETCH($attr);
}
sub tdat_SetDebug {
	$_[0]->{_iobj}[15]->cli_set_debug($_[1]);
	return $_[0];
}
sub tdat_ProcessPrepare {
	my ($dbh, $flavor, $len, $parcel, $stmtno, $activity, $is_a_call) = @_;
	my %sthargs = (
		tdat_stmt_info => [ undef ],
		NAME => [],
		TYPE => [],
		tdat_TYPESTR => [],
		PRECISION => [],
		SCALE => [],
		NULLABLE => [],
		tdat_TITLE => [],
		tdat_FORMAT => [],
		_unpackstr => [],
		_parmdesc => [ ],
		_parmap => { },
		_parmnum => 0,
		_phnum => 0
	);
	my $nextcol = $dbh->{_iobj}->io_proc_prepinfo(
		$parcel, $stmtno, \%sthargs, $activity, $is_a_call, 0);
	return $nextcol ?
		{
			Names => $sthargs{NAME},
			Types => $sthargs{tdat_TYPESTR},
			Titles => $sthargs{tdat_TITLE},
			Formats => $sthargs{tdat_FORMAT},
		} :
		{};
}
sub get_info {
	my $v = $DBD::Teradata::GetInfo::info{int($_[1])};
	$v = $v->($_[0]) if ref $v eq 'CODE';
	return $v;
}
sub type_info_all
{
	return $DBD::Teradata::TypeInfo::type_info_all;
}
1;
package DBD::Teradata::st;
use DBI qw(:sql_types);
use Config;

use DBD::Teradata qw(
	@td_decstrs
	@td_decszs
	@td_decscales
	@td_decfactors
	%td_type_dbi2stringtypes
	%td_type_dbi2pack
	%td_type_dbi2code
	@td_indicmasks
	@td_indicbits
	%td_type_dbi2str
	%td_type_dbi2hasprec
	%td_type_dbi2hasscale
	%td_type_dbi2size
);
$DBD::Teradata::st::imp_data_size = 0;

our $has_bigint;

BEGIN {

	eval {
		require Math::BigInt;
	};
	$has_bigint = 1 unless $@;
}

our %nullvals = (
	12, '',
	1, '',
	6, 0.0,
	3,'',
	4, 0,
	5, 0,
	-6, 0,
	-3, '',
	-2, '',
	-4, '',
	9, 0,
	11, '',
	10, '',
	103, '',
	108, '',
	109, '',
	110, '',
	104, '',
	111, '',
	112, '',
	105, '',
	113, '',
	102, '',
	106, '',
	101, '',
	107, '',
	95, '',
	94, ''
	);
use constant MAX_PARM_TUPLES => 2147483648;
sub cvt_dec2flt {
	my ($decstr, $prec, $scale) = @_;
	return ((unpack($td_decstrs[$prec], $decstr)) * $td_decscales[$scale])
		if ($prec <= 9);
	my @ival = ($platform == 7) ?
		unpack('l L', $decstr) : unpack('L l', $decstr);
	return ($platform == 7) ?
		((($ival[0]*(2.0**32)) + $ival[1]) * $td_decscales[$scale]) :
		(($ival[1]*(2.0**32)) + $ival[0]) * $td_decscales[$scale];
}
sub cvt_eval_dec2bigint {
	my ($decstr, $prec, $scale) = @_;
	my $num;
	if ($prec <= 9) {
		$num = unpack($td_decstrs[$prec], $decstr);
	}
	else {
		my @ival = ($platform == 7) ?
			unpack('l L', $decstr) : unpack('L l', $decstr);
		eval {
			$num = Math::BigInt->new($ival[$dechi])->blsft(32)->badd($ival[$declo])->bstr();
		};
	}
	if ($scale) {
		my $sign = undef;
		($sign, $num) = (1, substr($num, 1))
			if (substr($num, 0, 1) eq '-');
		$num = ('0' x ($scale - length($num) + 1)) . $num
			if (length($num) <= $scale);
		$num = '-' . $num if $sign;
		substr($num, -$scale, 0) = '.';
	}
	return $num;
}
sub cvt_dec2bigint {
	my ($decstr, $prec, $scale) = @_;
	my $num;
	if ($prec <= 9) {
		$num = unpack($td_decstrs[$prec], $decstr);
	}
	else {
		my @ival = ($platform == 7) ?
			unpack('l L', $decstr) : unpack('L l', $decstr);
		$num = Math::BigInt->new($ival[$dechi])->blsft(32)->badd($ival[$declo])->bstr();
	}
	if ($scale) {
		my $sign = undef;
		($sign, $num) = (1, substr($num, 1))
			if (substr($num, 0, 1) eq '-');
		$num = ('0' x ($scale - length($num) + 1)) . $num
			if (length($num) <= $scale);
		$num = '-' . $num if $sign;
		substr($num, -$scale, 0) = '.';
	}
	return $num;
}
sub cvt_flt2dec {
	my ($dval, $packed) = @_;
	my ($prec, $scale) = (($packed >> 8) & 31, $packed & 31);
	$dval = int($dval * $td_decfactors[$scale]);
	return pack($td_decstrs[$prec], $dval) if ($prec <= 9);
	my $ival1 = int($dval/(2**32));
	$ival1-- if ($dval < 0);
	my $ival2 = int($dval - ($ival1*(2.0**32)));
	return ($platform == 7) ?
		pack('l L', $ival1, $ival2) :
		pack('L l', $ival2, $ival1);
}
sub cvt_eval_bigint2dec {
	return cvt_flt2dec(@_) if ($_[0]=~/[Ee]/);
	my $dval = shift;
	my ($prec, $scale) = (($_[0] >> 8) & 31, $_[0] & 31);
	my ($whole, $part) = split /\./, $dval;
	$part = '' unless defined($part);
	my $incr = ((length($part) > $scale) && (substr($part, $scale, 1) > 4)) ?
		(($dval < 0) ? -1 : 1) : 0;
	$dval =
		(length($part) < $scale) ? join('', $whole, $part, '0' x ($scale - length($part))) :
		(length($part) > $scale) ? join('', $whole, substr($part, 0, $scale)) :
		join('', $whole, $part);
	if ($incr) {
		eval {
			$dval = Math::BigInt->new($dval)->badd($incr)->bstr();
		};
	}
	return pack($td_decstrs[$prec], $dval)
		if ($prec <= 9);
	my ($ival1, $tval, $ival2, $out);
	eval {
		$ival1 = Math::BigInt->new($dval)->brsft(32);
		$tval = Math::BigInt->new($ival1)->blsft(32);
		$ival2 = Math::BigInt->new($dval)->bsub($tval);
		$out = ($platform == 7) ?
			pack('l L', $ival1->bstr(), $ival2->bstr()) :
			pack('L l', $ival2->bstr(), $ival1->bstr());
	};
	return $out;
}
sub cvt_bigint2dec {
	return cvt_flt2dec(@_) if ($_[0]=~/[Ee]/);
	my $dval = shift;
	my ($prec, $scale) = (($_[0] >> 8) & 31, $_[0] & 31);
	my ($whole, $part) = split /\./, $dval;
	$part = '' unless defined($part);
	my $incr = ((length($part) > $scale) && (substr($part, $scale, 1) > 4)) ?
		(($dval < 0) ? -1 : 1) : 0;
	$dval =
		(length($part) < $scale) ? join('', $whole, $part, '0' x ($scale - length($part))) :
		(length($part) > $scale) ? join('', $whole, substr($part, 0, $scale)) :
		join('', $whole, $part);
	$dval = Math::BigInt->new($dval)->badd($incr)->bstr()
		if $incr;
	return pack($td_decstrs[$prec], $dval)
		if ($prec <= 9);
	my $ival1 = Math::BigInt->new($dval)->brsft(32);
	my $tval = Math::BigInt->new($ival1)->blsft(32);
	my $ival2 = Math::BigInt->new($dval)->bsub($tval);
	return ($platform == 7) ?
		pack('l L', $ival1->bstr(), $ival2->bstr()) :
		pack('L l', $ival2->bstr(), $ival1->bstr());
}
sub BindColArray {
	my ($sth, $pNum, $ary, $maxlen) = @_;
	return $sth->DBI::set_err(-1, 'BindColArray() requires arrayref parameter.', 'S1000')
		if (ref $ary ne 'ARRAY');
	return $sth->DBI::set_err(-1, 'Invalid column number.', 'S1000')
		if ($pNum <= 0);
	my $sthp = $sth->{_p};
	my $c = $sthp->[1];
	$sthp->[1] = [ ],
	$c = $sthp->[1]
		unless $c;
	$$c[$pNum - 1] = $ary;
	if (defined($maxlen)) {
		my $ml = $sthp->[14];
		$sthp->[14] = $maxlen
			unless defined($ml) && ($ml >= $maxlen);
	}
	1;
}
*tdat_BindColArray = \&BindColArray;
*bind_col_array = \&BindColArray;
sub _split_vartext {
	my ($sth, $val) = @_;
	my $params = $sth->{_p}[5];
	my $numparms = $sth->{NUM_OF_PARAMS};
	my $p = (ref $val eq 'ARRAY') ? $val : (ref $val) ? [ $$val ] : [ $val ];
	map { $params->[$_] = []; } 0..$numparms-1;
	my $plens = $sth->{_p}[9];
	@$plens = (0) x $numparms;
	my @ps;
	my $notbar = ($sth->{tdat_vartext_in} eq '|') ? undef : $sth->{tdat_vartext_in};
	foreach my $v (@$p) {
		@ps = $notbar ? split($notbar, $v) : split('\|', $v);
		foreach (0..$numparms-1) {
			push (@{$params->[$_]}, $ps[$_]);
			$plens->[$_] = length($ps[$_])
				if defined($ps[$_]) && ($plens->[$_] < length($ps[$_]));
		}
	}
	map { $sth->{ParamArrays}{$_} = $sth->{ParamValues}{$_} = $params->[$_-1]; } 1..$numparms;
	return $params;
}
sub bind_param {
	my ($sth, $pNum, $val, $attr) = @_;
	my $sthp = $sth->{_p};
	my $pname = $pNum;
	unless ($pNum=~/^\d+$/) {
		return $sth->DBI::set_err(-1, 'Invalid parameter name.', 'S1000')
			unless (substr($pNum, 0, 1) eq ':') && $sthp->[21];
		my $i = 0;
		$pNum = uc substr($pNum, 1);
		$i++
			while (($i <= $#{$sthp->[21]}) &&
				($sthp->[21][$i] ne $pNum));
		return $sth->DBI::set_err(-1, 'Invalid parameter name.', 'S1000')
			if ($i > $#{$sthp->[21]});
		$pNum = $i + 1;
	}
	return $sth->DBI::set_err(-1, 'Only parameter number 1 valid for raw or vartext mode.', 'S1000')
		if ($pNum != 1) && ($sth->{tdat_raw_in} || $sth->{tdat_vartext_in});
	my $type = 12;
	my $tlen = $phdfltsz;
	my $usephs = $sthp->[15];
	if ($usephs && defined($attr)) {
		if (ref $attr) {
			$type = $attr->{TYPE} || 12;
			$tlen = ($type == 3) ?
				((($attr->{PRECISION} || 5) << 8) | ($attr->{SCALE} || 0)) :
				($td_type_dbi2hasprec{$type} && exists $attr->{PRECISION}) ? $attr->{PRECISION} :
				$td_type_dbi2size{$type};
		}
		else {
			$type = $attr;
			$tlen = ($type == 3) ? (5 << 8) : $td_type_dbi2size{$type};
		}
	}
	$sth->{ParamValues}{$pNum} = $val;
	$sth->{ParamArrays}{$pNum} = $val;
	_split_vartext($sth, $val),
	return 1
		if $sth->{tdat_vartext_in};
	$sthp->[5][$pNum-1] = $val;
	return 1
		unless $usephs;
	my $ptypes = $sthp->[2];
	$ptypes->[$pNum-1] = $td_type_dbi2stringtypes{$type} ? 12 : $type;
	my $plens = $sthp->[9];
	$plens->[$pNum-1] =
		(($type == 12) ||
		($type == -1) ||
		($type == -4) ||
		($type == -3)) ?
			(($attr && $attr->{PRECISION}) ? $tlen :
				(defined($val) && (! ref $val)) ? length($val) : $phdfltsz) :
			$tlen;
	1;
}
*BindParamArray = \&bind_param;
*tdat_BindParamArray = \&bind_param;
*bind_param_array = \&bind_param;
sub bind_param_status {
	return $_[0]->DBI::set_err(-1, 'Status argument must be arrayref.', 'S1000')
		unless (ref $_[1] eq 'ARRAY');
	$_[0]->{_p}[3] = $_[1];
	return 1;
}
sub cvt_arm_flt {
	my ($lo, $hi) = unpack('LL', pack('d', $_[0]));
	return unpack('d', pack('LL', $hi, $lo));
}
sub bind_param_inout {
	my ($sth, $pNum, $val, $maxlen, $attr) = @_;
	my $sthp = $sth->{_p};
	unless ($pNum=~/^\d+$/) {
		return $sth->DBI::set_err(-1, 'Invalid parameter name.', 'S1000')
			unless (substr($pNum, 0, 1) eq ':') && $sthp->[21];
		my $i = 0;
		$pNum = uc substr($pNum, 1);
		$i++
			while (($i <= $#{$sthp->[21]}) &&
				($sthp->[21][$i] ne $pNum));
		return $sth->DBI::set_err(-1, 'Invalid parameter name.', 'S1000')
			if ($i > $#{$sthp->[21]});
		$pNum = $i + 1;
	}
	$sth->bind_col($sthp->[8]{$pNum}+1, $val)
		if $sthp->[8] &&
			defined($sthp->[8]{$pNum});
	return bind_param($sth, $pNum, $val, $attr)
}
sub execute {
	return _execute_any({}, @_);
}
sub _execute_any {
	my ($attrs, $sth, @bind_values) = @_;
	my $sthp = $sth->{_p};
	my $iobj = $sthp->[11];
	$sth->finish
		if $sthp->[26];
	delete $iobj->[1]{$sthp->[12]}
		if defined($sthp->[12]);
	my $params = $attrs->{_fetch_sub} ? undef :
		(scalar @bind_values) ? \@bind_values :
		$sthp->[5];
	$params = delete $attrs->{_residual}
		if $attrs->{_residual};
	my $numParam = $sth->{NUM_OF_PARAMS} || 0;
	if ($sth->{tdat_vartext_in} && ($#bind_values >= 0)) {
		return undef
			unless $sth->bind_param(1, $bind_values[0]);
		$params = $sthp->[5];
	}
	my ($ptypes, $plens, $usephs) =
		($sthp->[2], $sthp->[9], $sthp->[15]);
	my ($sessno, $dbh, $partition) =
		($sth->{tdat_sessno}, $sthp->[23], $iobj->[19]);
	my $loading = (($partition == 5) || ($partition == 4));
	my ($use_cursor, $cursnm, $cursth) = (0, '', undef);
	if ($sth->{Statement}=~/\s+WHERE\s+CURRENT\s+OF\s+([^\s;]+)\s*;?$/i) {
		$cursnm = uc $1;
		$cursth = $dbh->{_cursors}{$cursnm};
		return $sth->DBI::set_err(-1, 'Specified cursor not defined or not updatable.', 'S1000')
			unless $cursth;
		return $sth->DBI::set_err(-1, 'Specified cursor not positioned on a valid row.', 'S1000')
			unless $cursth->{_p}[6];
		$use_cursor = 1;
	}
	$iobj->[14] = 0,
	$sth->{tdat_keepresp} = 1
		if ($sth->{Statement}=~/\s+FOR\s+CURSOR\s*;?$/i);
	my $rawmode = $sth->{tdat_raw_in};
	my $modepcl =
		($partition == 4) ? 104 :
		(($partition == 6) ||
			($rawmode && ($rawmode eq 'RecordMode'))) ? 3 :
				68;
	$numParam = 0
		unless ($partition != 6) ||
			($iobj->[6] && ($#$params >= 0));
	return $sth->DBI::set_err(-1, 'Too many parameters provided.', 'S1000')
		if defined($params) && (@$params > $numParam);
	return $sth->DBI::set_err(-1, 'No parameters provided for parameterized statement.', 'S1000')
		unless ($numParam == 0) || defined($params) || defined($dbh->{tdat_loading}) ||
			$attrs->{_fetch_sub};
	my $stmtno = 0;
	my $maxparmlen = 1;
	if ($attrs->{_fetch_sub}) {
		$maxparmlen = MAX_PARM_TUPLES;
	}
	else {
		foreach (0..$numParam-1) {
			$maxparmlen = scalar(@{$$params[$_]})
				if (ref $$params[$_] eq 'ARRAY') &&
					(scalar(@{$$params[$_]}) > $maxparmlen);
		}
	}
	my $fldcnt = $numParam;
	my ($tuples, $datainfo, $indicdata) = (0, '', '');
	my $pos = 0;
	if (($params && scalar @$params) || $attrs->{_fetch_sub}) {
		($tuples, $datainfo, $indicdata) =
			$usephs ? _process_ph_params($sth, $fldcnt, $params, $attrs) :
				_process_using_params($sth, $fldcnt, $rawmode, $modepcl, $params, $attrs);
		return undef
			unless $tuples;
	}
	$iobj->io_tddo('BT'),
	$iobj->[11] = 1
		if ($partition == 1) && (!$dbh->{AutoCommit}) &&
			($dbh->{tdat_mode} ne 'ANSI') && ($iobj->[11] == 0);
	$iobj->[11] = 1
		if ($partition == 1) && ($dbh->{tdat_mode} eq 'ANSI');
	return $tuples
		if $attrs->{_fetch_sub};
	my $rowcnt = $iobj->io_execute($sth, $datainfo, $indicdata,
		($use_cursor ? $cursth->{_p}[6] : undef));
	$sthp->[13] = $rowcnt;
	return $sth->DBI::set_err($iobj->io_get_error())
		unless defined($rowcnt);
	$sth->{Active} = ($sth->{NUM_OF_FIELDS} != 0);
	undef $sthp->[6]
		if ($sth->{Statement}=~/^DELETE\s+.+\s+WHERE\s+CURRENT\s+OF\s+\w+$/i);
	$sthp->[26] = 1
		unless $sthp->[22] && (! $sth->{tdat_keepresp});
	return ($rowcnt == 0) ? -1 : $rowcnt
		if ($sth->{tdat_compatible} lt '2.0');
	return ($rowcnt == 0) ? '0E0' : $rowcnt;
}
sub _gen_datainfo {
	my ($fldcnt, $ptypes, $plens, $maxszs) = @_;
	my $packstr = '';
	my $datainfo = pack('S', $fldcnt) . ("\0" x ($fldcnt * 4));
	my $prec;
	my $j = 2;
	foreach (0..$fldcnt-1) {
		my $tdtype = $td_type_dbi2code{$ptypes->[$_]}+1;
		$plens->[$_] ||= 0
			if ($ptypes->[$_] == 12) || ($ptypes->[$_] == -3);
		$prec = ($ptypes->[$_] == 3) ?
			$td_decszs[($plens->[$_] >> 8) & 31] : $plens->[$_];
		$packstr .=
			(($ptypes->[$_] == -2) ||
			($ptypes->[$_] == 3))		? "a$prec " :
			($ptypes->[$_] == 1) 		? "A$prec " :
				$td_type_dbi2pack{$ptypes->[$_]} . ' ';
		$prec = 2 + $plens->[$_]
			if ($maxszs->[$_] < $plens->[$_]) &&
				(($ptypes->[$_] == 12) ||
					($ptypes->[$_] == -3));
		substr($datainfo, $j, 4) = pack('SS', $tdtype, $plens->[$_]);
		$maxszs->[$_] = $prec;
		$j += 4;
	}
	return ($datainfo, $packstr);
}
sub _process_ph_params {
	my ($sth, $fldcnt, $params, $attrs) = @_;
	my $indicdata;
	my $pos = 0;
	my $maxsz = 100;
	my ($i, $p);
	my $sthp = $sth->{_p};
	my $iobj = $sthp->[11];
	my $ptypes = $sthp->[2];
	my $plens = $sthp->[9];
	my $fetch_sub = $attrs->{_fetch_sub};
	my @maxszs = ((0) x $fldcnt);
	my ($datainfo, $packstr) = _gen_datainfo($fldcnt, $ptypes, $plens, \@maxszs);
	my @tmpary = ();
	my $ttype = 12;
	my @indicvec = ();
	my $tuples = 0;
	my $deccvt =
		($sth->{tdat_no_bigint} || (!$has_bigint)) ? \&cvt_flt2dec :
		($^O eq 'MSWin32') ? \&cvt_bigint2dec :
		\&cvt_eval_bigint2dec;
	$params = &$fetch_sub()
		unless $params && scalar @$params;
	while ($params) {
		@indicvec = (0xFF) x (($fldcnt & 7) ?
			($fldcnt>>3) + 1 : $fldcnt>>3);
		$pos = 0;
		@tmpary = ();
		foreach (0..$fldcnt-1) {
			$ttype = $ptypes->[$_];
			$p = $params->[$_];
			$p = (ref $p eq 'ARRAY') ? $p->[0] : $$p
				if defined($p) && (ref $p);
			push(@tmpary, $nullvals{$ttype}),
			$pos +=
				(($ttype == 12) ||
				($ttype == -3))	? 2 : $maxszs[$_],
			next
				unless defined($p);
			$indicvec[$_>>3] &= $td_indicmasks[$_ & 7],
			push(@tmpary,
				($ttype == 3)				? $deccvt->($p, $plens->[$_]) :
				(($ttype == 6) && $use_arm) ? cvt_arm_flt($p) : $p);
			$pos +=
				(($ttype == 12) ||
				($ttype == -3))	? 2 + length($p) :
				($ttype == 3)		? $td_decszs[(($plens->[$_]>>8) & 31)] :
				$plens->[$_];
			$maxszs[$_] = length($p) + 2,
			substr($datainfo, 4 + ($_ << 2), 2, pack('S', $maxszs[$_]))
				if (($ttype == 12) || ($ttype == -3)) &&
					($maxszs[$_] < length($p) + 2);
		}
		map { $maxsz += $_; } @maxszs;
		$maxsz += scalar @indicvec;
		$indicdata = "\0" x $maxsz;
		substr($indicdata, 0, scalar(@indicvec), pack('C*', @indicvec));
		substr($indicdata, scalar(@indicvec), $pos, pack($packstr, @tmpary));
		$pos += scalar(@indicvec);
		return (++$tuples, $datainfo, substr($indicdata, 0, $pos))
			;
	}
	substr($iobj->[16], $attrs->{_datainfop}, length($datainfo), $datainfo);
	return ($tuples, undef, undef);
}
sub _process_using_params {
	my ($sth, $fldcnt, $rawmode, $modepcl, $params, $attrs) = @_;
	my $indicdata;
	my $pos = 0;
	my $maxsz = (($fldcnt & 7) ? ($fldcnt>>3) + 1 : $fldcnt>>3);
	my ($i, $k, $p);
	my $sthp = $sth->{_p};
	my $iobj = $sthp->[11];
	my $ptypes = $sthp->[2];
	my $plens = $sthp->[9];
	my $packstr = $sthp->[18];
	my $fetch_sub = $attrs->{_fetch_sub};
	my $tuples = 0;
	my $deccvt =
		($sth->{tdat_no_bigint} || (!$has_bigint)) ? \&cvt_flt2dec :
		($^O eq 'MSWin32') ? \&cvt_bigint2dec :
		\&cvt_eval_bigint2dec;
	unless ($rawmode) {
		for ($i = 0; $i < $fldcnt; $i++) {
			$maxsz += (($ptypes->[$i] == 3) ?
				$td_decszs[(($plens->[$i]>>8) & 31)] : $plens->[$i]);
			$maxsz += 2
				if ($ptypes->[$i] == 12) || ($ptypes->[$i] == -3);
		}
	}
	my @tmpary = ();
	my $ttype = 12;
	my @indicvec = ();
	$params = &$fetch_sub()
		unless $params && scalar @$params;
	my $is_vartext = $sth->{tdat_vartext_in};
	my @ps;
	my $notbar = ($is_vartext && ($is_vartext eq '|')) ? undef : $is_vartext;
	while ($params) {
		if ($is_vartext && (scalar @$params == 1)) {
			@$params = $notbar ? split($notbar, $params->[0]) : split('\|', $params->[0]);
			foreach (0..$fldcnt-1) {
				$plens->[$_] = length($params->[$_])
					if defined($params->[$_]) && ($plens->[$_] < length($params->[$_]));
			}
		}
		unless ($rawmode) {
			@indicvec = (0xFF) x (($fldcnt & 7) ? ($fldcnt>>3) + 1 : $fldcnt>>3);
			$pos = 0;
			@tmpary = ();
			foreach (0..$fldcnt-1) {
				$ttype = $ptypes->[$_];
				$p = $params->[$_];
				$p = (ref $p eq 'ARRAY') ? $p->[0] : $$p
					if defined($p) && (ref $p);
				push(@tmpary, $nullvals{$ttype}),
				$pos +=
					(($ttype == 12) ||
					($ttype == -3))	? 2 :
					($ttype == 3)		? $td_decszs[($plens->[$_] >> 8) & 31] :
						$plens->[$_],
				next
					unless defined($p);
				$indicvec[$_>>3] &= $td_indicmasks[$_ & 7],
				push(@tmpary,
					($ttype == 3)				? $deccvt->($p, $plens->[$_]) :
					(($ttype == 6) && $use_arm) ? cvt_arm_flt($p) : $p);
				$pos +=
					(($ttype == 12) ||
					($ttype == -3))	? 2 + length($p) :
					($ttype == 3)		? $td_decszs[(($plens->[$_]>>8) & 31)] :
					$plens->[$_];
					$ttype = $ptypes->[$i];
					$p = $params->[$i];
					$p = $$p
						if defined($p) && (ref $p);
			}
			$indicdata = "\0" x $maxsz;
			substr($indicdata, 0, scalar(@indicvec), pack('C*', @indicvec));
			substr($indicdata, scalar(@indicvec), $pos, pack($packstr, @tmpary));
			$pos += scalar(@indicvec);
		}
		else {
			$p = $params->[0];
			$p = (ref $p eq 'ARRAY') ? $p->[0] : $$p
				if defined($p) && (ref $p);
			$pos = length($p) - 3;
			$indicdata = substr($p, 2, $pos);
		}
		return (++$tuples, undef, substr($indicdata, 0, $pos))
		;
	}
	return ($tuples, undef, undef);
}
sub Realize {
	return defined($_[0]->{_p}[11]->io_Realize($_[0])) ?
		1 : $_[0]->DBI::set_err($_[0]->{_p}[11]->io_get_error());
}
*tdat_Realize = \&Realize;
sub tdat_Rewind {
	return $_[0]->{_p}[11]->io_rewind($_[0]);
}
sub fetch {
	return $_[0]->tdat_Unpack();
}
sub tdat_Unpack {
	my ($sth, $rec, $recmode) = @_;
	my $sthp = $sth->{_p};
	my $sessno = $sth->{tdat_sessno};
	my $stmtno = $sth->{tdat_stmt_num};
	my $nowait = $sth->{tdat_nowait};
	my $stmtinfo = $sth->{tdat_stmt_info};
	my $rawmode = $sth->{tdat_raw_out};
	my $vartext = $sth->{tdat_vartext_out};
	my $colary = $sthp->[1];
	my $maxlen = $sthp->[14];
	my $iobj = $sthp->[11];
	my $data = '';
	my @tmpary = ();
	my $ary = (defined($colary) ? ($rawmode ? $$colary[0] : \@tmpary) : undef);
	my $rc;
	if (defined($rec)) {
		$data = $rec;
		$rc = 1;
	}
	else {
		$rc = $iobj->io_fetch($sth, $ary, \$data);
		return $sth->DBI::set_err($iobj->io_get_error())
			unless defined($rc);
		$sth->{Active} = undef
			unless ($rc > 0) || $sth->{tdat_more_results};
		return $rc if ($rc <= 0);
	}
	my $loopcnt = $rc;
	my $ftypes = $sth->{TYPE};
	my $fprec = $sth->{PRECISION};
	my $fscale = $sth->{SCALE};
	my $stmthash = $$stmtinfo[$stmtno];
	my $isCall = ($stmthash->{ActivityType} eq 'Call');
	my $actends = $stmthash->{EndsAt};
	my $actstarts = $stmthash->{StartsAt};
	my $actsumstarts = $stmthash->{SummaryStarts};
	my $actsumends = $stmthash->{SummaryEnds};
	my $issum = $stmthash->{IsSummary};
	my $numflds = defined($issum) ?
		$$actsumends[$issum] - $$actsumstarts[$issum] + 1 :
		$actends - $actstarts + 1;
	my $unpackstr = $sthp->[10][
		(defined($issum) ? $$actsumstarts[$issum] : $actstarts)];
	my $ibytes = ((($numflds & 7) !=  0) ? ($numflds>>3) + 1 : $numflds>>3);
	my @row;
	$#row = $sth->{NUM_OF_FIELDS} - 1;
	if ($rawmode) {
		return $sth->_set_fbav(\@row) if defined($colary);
		$data = substr($data, $ibytes) if ($rawmode eq 'RecordMode');
		$row[0] = pack('S a* c', length($data), $data, 10);
		return $sth->_set_fbav(\@row);
	}
	my $fpos = 0;
	$tmpary[0] = $data unless defined($colary);
	my $ibit = 0;
	my $pos = 0;
	my $prec = 0;
	my $ftype = 0;
	my $indstr ='';
	my @indics = ();
	my $lastpos = 0;
	my $chopem = $sth->{ChopBlanks};
	my $no_indics = (($stmthash->{ActivityType} eq 'Exec MLOAD') ||
		$recmode || ($stmthash->{ActivityType} eq 'Echo') ||
		($iobj->[19] == 6));
	if (defined($colary)) {
		map { @$_ = (undef) x $loopcnt; } @$colary;
	}
	my $use_arm = ($Config{archname}=~/^arm-linux/i) ? 1 : undef;
	my $i;
	my $deccvt =
		($sth->{tdat_no_bigint} || (!$has_bigint)) ? \&cvt_dec2flt :
		($^O eq 'MSWin32') ? \&cvt_dec2bigint :
		\&cvt_eval_dec2bigint;
	my $utf8 = $sthp->[23]{_utf8};
	my $vtext = $sth->{tdat_vartext_out};
	for (my $k = 0; $k < $loopcnt; $k++) {
		@row = $vtext ? (('') x $sth->{NUM_OF_FIELDS}) :
			((undef) x $sth->{NUM_OF_FIELDS});
		if (ref $data) {
			$data = $tmpary[$k] if defined($colary);
			$fpos = defined($issum) ? $$actsumstarts[$issum] : $actstarts;
			$lastpos = $fpos + $numflds - 1;
			@row[$fpos..$lastpos] = @$data;
			$#row = $numflds - 1
				if ($#row < $numflds-1);
			foreach $i ($fpos..$lastpos) {
				next unless defined($row[$i]);
				$row[$i] = Encode::decode_utf8($row[$i])
					if $utf8;
				$row[$i] =~ s/\s+$//
					if $chopem;
				next if defined($vtext);
				$colary->[$i][$k] = $row[$i] if $$colary[$i];
			}
			if (defined($vtext)) {
				$row[0] = join($vtext, @row);
				$numflds--;
				@row[1..$numflds] = (undef) x $numflds;
				$numflds++;
				$colary->[0][$k] = $row[0] if $$colary[0];
			}
			next;
		}
		$data = substr($tmpary[$k], 2, length($tmpary[$k]) - 3)
			if defined($colary);
		$pos = 0;
		$indstr = substr($data, 0, $ibytes),
		$data = substr($data, $ibytes)
			unless $no_indics;
		@indics = $no_indics ? (0) : unpack('C*', $indstr);
		$unpackstr=~tr/A/a/;
		$fpos = defined($issum) ? $$actsumstarts[$issum] : $actstarts;
		splice(@row, $fpos, $numflds, unpack($unpackstr, $data));
		$#row = $sth->{NUM_OF_FIELDS} - 1
			if ($#row < $sth->{NUM_OF_FIELDS}-1);
		for (my $i = 0; $i < $numflds; $i++, $fpos++) {
			my $ftype = $$ftypes[$fpos];
			$row[$fpos] = ($vtext ? '' : undef), next
				if defined($indics[$i>>3]) &&
					($indics[$i>>3] & $td_indicbits[($i & 7)]);
			$row[$fpos] =
				$deccvt->($row[$fpos], $$fprec[$fpos], $$fscale[$fpos])
				if ($ftype == 3);
			$row[$fpos] = cvt_arm_flt($row[$fpos])
				if $use_arm && ($ftype == 6);
			if (($ftype == 1) || ($ftype == 12)) {
				$row[$fpos] = Encode::decode_utf8($row[$fpos])
					if $utf8;
				$row[$fpos] =~ s/\s+$//
					if $chopem;
			}
			next if defined($vtext);
			$colary->[$i][$k] = $row[$fpos] if $$colary[$i];
		}
		if (defined($vtext)) {
			$row[0] = join($vtext, @row);
			$numflds--;
			@row[1..$numflds] = (undef) x $numflds;
			$numflds++;
			$colary->[0][$k] = $row[0] if $$colary[0];
		}
	}
	return $rec ? \@row : $sth->_set_fbav(\@row);
}
*fetchrow_arrayref = \&fetch;
sub STORE {
	my ($sth, $attr, $val) = @_;
	return $sth->SUPER::STORE($attr, $val)
		unless ($attr=~/^(tdat)?_/) ;
	$sth->{$attr} = $val;
	return 1;
}
sub tdat_get_param_values {
	my $sth = shift;
print "we got to get_param_values\n";
	return undef unless $sth->{NUM_OF_PARAMS};
	my $sthp = $sth->{_p};
	my $numParam = $sth->{NUM_OF_PARAMS};
	my $params = $sthp->[5];
	my %pval = ();
	if ($sthp->[15]) {
		map { $pval{$_+1} = $params->[$_]; } (0..$numParam-1);
		return \%pval;
	}
	my $pnames = $sthp->[21];
	map { $pval{$pnames->[$_]} = $params->[$_]; } (0..$#$pnames);
	return \%pval;
}
sub tdat_get_param_types {
	my $sth = shift;
	return undef unless $sth->{NUM_OF_PARAMS};
	my $sthp = $sth->{_p};
	my $numParam = $sth->{NUM_OF_PARAMS};
	my $ptypes = $sthp->[2];
	my $plens = $sthp->[9];
	my $pnames = $sthp->[21];
	my $callparms = $sthp->[4];
	my $name;
	my %pval = ();
	foreach (0..$numParam-1) {
		$name = $pnames ? $pnames->[$_] : $_+1;
		$pval{$name} = {
			TYPE => ($ptypes->[$_] || SQL_UNKNOWN_TYPE),
		};
		$pval{$name}->{IN_OR_OUT} = ($callparms->[$_] & 2) ?
			(($callparms->[$_] & 4) ? 'INOUT' : 'IN') : 'OUT'
			if $callparms;
		next unless $ptypes->[$_] && $td_type_dbi2hasprec{$ptypes->[$_]};
		$pval{$name}->{PRECISION} = $plens->[$_];
		$pval{$name}->{PRECISION} = ($plens->[$_] >> 8) && 0xFF,
		$pval{$name}->{SCALE} = $plens->[$_] & 0xFF
			if ($ptypes->[$_] == 3);
	}
	return \%pval;
}
sub FETCH {
	my ($sth, $attr) = @_;
	return ($attr eq 'tdat_param_types') ?
		tdat_get_param_types($sth) : $sth->{$attr}
		if ($attr =~ /^(tdat)?_/);
	return ($attr eq 'ParamTypes') ? tdat_get_param_types($sth) :
		$sth->SUPER::FETCH($attr);
}
sub rows {
	$_[0]->{_p}[13];
}
sub finish {
	my $sthp = $_[0]->{_p};
	my $iobj = $sthp->[11];
	$iobj->io_finish($_[0]) if $iobj;
	$sthp->[22] = 1;
	$_[0]->{Active} = $sthp->[26] = undef;
	$sthp->[17] = undef;
	$sthp->[19] = -1;
	delete $_[0]->{tdat_more_results};
	$_[0]->SUPER::finish;
	1;
}
sub cancel {
	my $sthp = $_[0]->{_p};
	my $iobj = $sthp->[11];
	$iobj->io_cancel($_[0]) if $iobj;
	unless ($_[0]->{tdat_nowait}) {
		$sthp->[22] = 1;
		$_[0]->{Active} = $sthp->[26] = undef;
		$sthp->[17] = undef;
		$sthp->[19] = -1;
	}
	1;
}
sub DESTROY {
	my ($sth) = @_;
	my $sthp = $sth->{_p};
	my $dbh = $sthp->[23];
	$sth->finish
		if $sthp->[26] && (! $dbh->{_ignore_destroy});
	delete $dbh->{_stmts}{$sth->{CursorName}}
		if $sth->{CursorName};
	$sthp->[23] = undef;
	$sthp->[11] = undef;
	$sthp->[17] = undef;
	delete $sth->{_p};
}
sub tdat_CharSet {
	return $_[0]->{_p}[23]{tdat_charset};
}
sub map_type2str {
	my ($sth) = @_;
	return undef unless $sth->{NUM_OF_FIELDS};
	my $types = $sth->{TYPE};
	my $precs = $sth->{PRECISION};
	my $scales = $sth->{SCALE};
	my @typestrs = ();
	foreach my $i (0..$#$types) {
		my $type = $td_type_dbi2str{$types->[$i]};
		push (@typestrs, "DECIMAL($$precs[$i],$$scales[$i])"), next
			if ($types->[$i] == 3);
		$type=~s/\(\)([^\(]+)\(\)/\($$precs[$i]\)$1\($$scales[$i]\)/,
		push (@typestrs, $type),
		next
			if $td_type_dbi2hasscale{$types->[$i]};
		$type .= "($$precs[$i])"
			if $td_type_dbi2hasprec{$types->[$i]};
		push (@typestrs, $type);
	}
	return \@typestrs;
}
1;
package DBD::Teradata::ReqFactory;
use strict;
use warnings;
sub new {
	my $class = shift;
	my $self = {
		noprepopts => pack('SSa10', 85, 14, 'RS'),
		prepopts => pack('SSa10', 85, 14, 'RP'),
		execopts => pack('SSa10', 85, 14, 'RE'),
		indicopts => pack('SSa10', 85, 14, 'IE'),
		tsrpcl => pack('SSSC', 128, 7, 1, 1)
	};
	return bless $self, $class;
}
sub simpleRequest {
	my ($self, $iobj, $respsz) = @_;
	my $reqlen = 4 + length($_[3]) + 6;
	my $reqmsg = $iobj->io_buildtdhdr(5, $reqlen);
	return undef unless $reqmsg;
	substr($reqmsg, 52, $reqlen) =
		pack('SSA* SSS',
			1,
			4 + length($_[3]),
			$_[3],
			4,
			6,
			$respsz);
	return $reqmsg;
}
sub continueReq {
	my ($self, $iobj, $reqno, $keepresp, $respsz) = @_;
	my $reqmsg = $iobj->io_buildtdhdr(6, 6, $reqno);
	return undef unless $reqmsg;
	substr($reqmsg, 52, 6) =
		pack('SSS', ($keepresp ? 5 : 4), 6, $respsz);
	return $reqmsg;
}
sub prepareRequest {
	my ($self, $iobj, $rowid, $usingvars, $respsz) = @_;
	my $reqlen = 14 + 4 + length($_[5]) + 6;
	$reqlen += 4 + length($rowid)
		if $rowid;
	my $reqmsg = $iobj->io_buildtdhdr(5, $reqlen);
	return undef unless $reqmsg;
	my $reqpos = 52;
	substr($reqmsg, $reqpos, 14) = $usingvars ?
		$self->{prepopts} : $self->{noprepopts};
	$reqpos += 14;
	substr($reqmsg, $reqpos, 4+length($_[5])) =
		pack('SSa*', 1, 4 + length($_[5]), $_[5]);
	$reqpos += 4 + length($_[5]);
	substr($reqmsg, $reqpos, 4 + length($rowid)) =
		pack('SSA*', 120, 4 + length($rowid), $rowid),
	$reqpos += 4 + length($rowid)
		if $rowid;
	substr($reqmsg, $reqpos, 6) = pack('SSS', 4, 6, $respsz);
	return $reqmsg;
}
sub spRequest {
	my ($self, $iobj, $sz, $pos, $segment, $sth, $respsz) = @_;
	my $reqlen = 7 + 4 + $sz + 6;
	$reqlen += 6 + 14
		unless $pos;
	my $reqmsg = $iobj->io_buildtdhdr(5, $reqlen);
	return undef unless $reqmsg;
	my $bufpos = 52;
	substr($reqmsg, $bufpos, 7) =
		pack('SSSC', 128, 7, $segment, (($pos + $sz < length($sth->{Statement})) ? 0 : 1));
	$bufpos += 7;
	substr($reqmsg, $bufpos, 14) = pack('SSa10', 85, 14, 'IE'),
	$bufpos += 14
		unless $pos;
	substr($reqmsg, $bufpos, 4 + $sz) =
		pack('SSA*', 69, 4 + $sz, substr($sth->{Statement}, $pos, $sz));
	$bufpos += 4 + $sz;
	substr($reqmsg, $bufpos, 6) = pack('SSAA',
		129, 6,
		($sth->{tdat_sp_print} ? 'Y' : 'N'),
		($sth->{tdat_sp_save} ? 'Y' : 'N')),
	$bufpos += 6
		unless $pos;
	substr($reqmsg, $bufpos, 6) = pack('SSS', 4, 6, $respsz);
	$pos += $sz;
	return ($reqmsg, $pos);
}
sub sqlRequest {
	my ($self, $iobj, $sth, $forCursor, $rowid, $modepcl, $keepresp, $respsz) = @_;
	my $reqlen = 4 + length($_[8]) + 6 +
		((defined($_[9]) && length($_[9])) ? 4 + length($_[9]) : 0) +
		((defined($_[10]) && length($_[10])) ? 4 + length($_[10]) : 0) +
		($forCursor ? 4 + length($rowid) : 0) +
		($sth->{tdat_mload} ? 14 : 0);
	return $iobj->io_set_error('Request length exceeds 64K limit.')
		if ($reqlen > 64256);
	my $reqmsg = $iobj->io_buildtdhdr(5, $reqlen);
	return undef unless $reqmsg;
	my $bufpos = 52;
	my $reqpcl =
		$sth->{tdat_formatted} ? 13 :
		$sth->{tdat_mload} ? 1 :
		69;
	substr($reqmsg, $bufpos, 4 + length($_[8])) =
		pack('SSA*', $reqpcl, 4 + length($_[8]), $_[8]);
	$bufpos += 4 + length($_[8]);
	substr($reqmsg, $bufpos, 4 + length($_[9])) =
		pack('SSa*', 71, length($_[9]) + 4, $_[9]),
	$bufpos += (4 + length($_[9]))
		if defined($_[9]) && ($_[9] ne '');
	substr($reqmsg, $bufpos, 4 + length($_[10])) =
		pack('SSa*', $modepcl, length($_[10]) + 4, $_[10]),
	$bufpos += (4 + length($_[10]))
		if defined($_[10]) && ($_[10] ne '');
	substr($reqmsg, $bufpos, 4 + length($rowid)) =
		pack('SSa*', 120, length($rowid) + 4, $rowid) ,
	$bufpos += (4 + length($rowid))
		if $rowid;
	substr($reqmsg, $bufpos, 6) =
		pack('SSS', (($keepresp) ? 5 : 4), 6,
			($sth->{tdat_mload} ? 4096 : $respsz));
	return $reqmsg;
}
sub finishRequest {
	my ($self, $iobj, $kind, $reqno) = @_;
	my $reqmsg = $iobj->io_buildtdhdr($kind, 4, $reqno);
	return undef unless $reqmsg;
	substr($reqmsg, 52, 4) =
		pack('SS', ($kind == 7) ? 6 : 7, 4);
	return $reqmsg;
}
sub rewindRequest {
	my ($self, $iobj, $reqno, $respsz) = @_;
	my $reqmsg = $iobj->io_buildtdhdr(6, 10, $reqno);
	return undef unless $reqmsg;
	$respsz = 64256 if ($respsz > 64256);
	substr($reqmsg, 52, 10) =
		pack('SS SSS',
			31,
			4,
			5,
			6,
			$respsz);
	return $reqmsg;
}
1;
package DBD::Teradata::APHReqFactory;
use base('DBD::Teradata::ReqFactory');
use strict;
use warnings;
sub new {
	my $class = shift;
	my $self = {
		noprepopts => pack('SSLa10', 85 | 0x8000, 0, 18, 'RS'),
		prepopts => pack('SSLa10', 85 | 0x8000, 0, 18, 'RP'),
		execopts => pack('SSLa10', 85 | 0x8000, 0, 18, 'RE'),
		indicopts => pack('SSLa10', 85 | 0x8000, 0, 18, 'IE'),
		tsrpcl => pack('SSLSC', 128 | 0x8000, 0, 11, 1, 1)
	};
	return bless $self, $class;
}
sub simpleRequest {
	my ($self, $iobj, $respsz) = @_;
	my $reqlen = 8 + length($_[3]) + 10;
	my $reqmsg = $iobj->io_buildtdhdr(5, $reqlen);
	return undef unless $reqmsg;
	substr($reqmsg, 52, $reqlen) =
		pack('SSLA* SSLS',
			1 | 0x8000,
			0,
			8 + length($_[3]),
			$_[3],
			4 | 0x8000,
			0,
			10,
			$respsz);
	return $reqmsg;
}
sub continueReq {
	my ($self, $iobj, $reqno, $keepresp, $respsz) = @_;
	my $reqmsg = $iobj->io_buildtdhdr(6, 10, $reqno);
	return undef unless $reqmsg;
	substr($reqmsg, 52, 10) =
		pack('SSLS', ($keepresp ? 5 : 4) | 0x8000, 0, 10, $respsz);
	return $reqmsg;
}
sub prepareRequest {
	my ($self, $iobj, $rowid, $usingvars, $respsz) = @_;
	my $reqlen = 18 + 8 + length($_[5]) + 10;
	$reqlen += 8 + length($rowid)
		if $rowid;
	my $reqmsg = $iobj->io_buildtdhdr(5, $reqlen);
	return undef unless $reqmsg;
	my $reqpos = 52;
	substr($reqmsg, $reqpos, 18) = $usingvars ? $self->{prepopts} : $self->{noprepopts};
	$reqpos += 18;
	substr($reqmsg, $reqpos, 8+length($_[5])) =
		pack('SSLa*', 1 | 0x8000, 0, 8 + length($_[5]), $_[5]);
	$reqpos += 8 + length($_[5]);
	substr($reqmsg, $reqpos, 8 + length($rowid)) =
		pack('SSLA*', 120 | 0x8000, 0, 8 + length($rowid), $rowid),
	$reqpos += 8 + length($rowid)
		if $rowid;
	substr($reqmsg, $reqpos, 10) =
		pack('SSLS', 4 | 0x8000, 0, 10, $respsz);
	return $reqmsg;
}
sub sqlRequest {
	my ($self, $iobj, $sth, $forCursor, $rowid, $modepcl, $keepresp, $respsz) = @_;
	my $reqlen = 8 + length($_[8]) + 10 +
		((defined($_[9]) && length($_[9])) ? 8 + length($_[9]) : 0) +
		((defined($_[10]) && length($_[10])) ? 8 + length($_[10]) : 0) +
		($forCursor ? 8 + length($rowid) : 0) +
		($sth->{tdat_mload} ? 18 : 0);
	my $reqmsg = $iobj->io_buildtdhdr(5, $reqlen);
	return undef unless $reqmsg;
	my $bufpos = 52;
	my $reqpcl =
		$sth->{tdat_formatted} ? 13 :
		$sth->{tdat_mload} ? 1 :
		69;
	substr($reqmsg, $bufpos, 8 + length($_[8])) =
		pack('SSLA*', $reqpcl | 0x8000, 0, 8 + length($_[8]), $_[8]);
	$bufpos += 8 + length($_[8]);
	substr($reqmsg, $bufpos, 8 + length($_[9])) =
		pack('SSLa*', 71 | 0x8000, 0, length($_[9]) + 8, $_[9]),
	$bufpos += (8 + length($_[9]))
		if defined($_[9]) && ($_[9] ne '');
	substr($reqmsg, $bufpos, 8 + length($_[10])) =
		pack('SSLa*', $modepcl | 0x8000, 0, length($_[10]) + 8, $_[10]),
	$bufpos += (8 + length($_[10]))
		if defined($_[10]) && ($_[10] ne '');
	substr($reqmsg, $bufpos, 8 + length($rowid)) =
		pack('SSLa*', 120 | 0x8000, 0, length($rowid) + 8, $rowid) ,
	$bufpos += (8 + length($rowid))
		if $rowid;
	substr($reqmsg, $bufpos, 10) =
		pack('SSLS', (($keepresp) ? 5 : 4) | 0x8000, 0, 10,
		($sth->{tdat_mload} ? 4096 : $respsz));
	return $reqmsg;
}
sub finishRequest {
	my ($self, $iobj, $kind, $reqno) = @_;
	my $reqmsg = $iobj->io_buildtdhdr($kind, 8, $reqno);
	return undef unless $reqmsg;
	substr($reqmsg, 52, 8) =
		pack('SSL', 0x8000 | (($kind == 7) ? 6 : 7), 0, 8);
	return $reqmsg;
}
sub rewindRequest {
	my ($self, $iobj, $reqno, $respsz) = @_;
	my $reqmsg = $iobj->io_buildtdhdr(6, 18, $reqno);
	return undef unless $reqmsg;
	substr($reqmsg, 52, 18) =
		pack('SSL SSLS',
			31 | 0x8000,
			0,
			8,
			5 | 0x8000,
			0,
			10,
			$respsz);
	return $reqmsg;
}
1;
package DBD::Teradata::BigAPHReqFactory;
use base('DBD::Teradata::APHReqFactory');
use strict;
use warnings;
sub continueReq {
	my ($self, $iobj, $reqno, $keepresp, $respsz) = @_;
	my $reqmsg = $iobj->io_buildtdhdr(6, 12, $reqno);
	return undef unless $reqmsg;
	substr($reqmsg, 52, 12) =
		pack('SSLL', ($keepresp ? 154 : 153) | 0x8000, 0, 12, $respsz);
	return $reqmsg;
}
sub prepareRequest {
	my ($self, $iobj, $rowid, $usingvars, $respsz) = @_;
	my $reqlen = 18 + 8 + length($_[5]) + 12;
	$reqlen += 8 + length($rowid)
		if $rowid;
	my $reqmsg = $iobj->io_buildtdhdr(5, $reqlen);
	return undef unless $reqmsg;
	my $reqpos = 52;
	substr($reqmsg, $reqpos, 18) = ($usingvars) ?
		$self->{prepopts} : $self->{noprepopts};
	$reqpos += 18;
	substr($reqmsg, $reqpos, 8+length($_[5])) =
		pack('SSLa*', 1 | 0x8000, 0, 8 + length($_[5]), $_[5]);
	$reqpos += 8 + length($_[5]);
	substr($reqmsg, $reqpos, 8 + length($rowid)) =
		pack('SSLA*', 120 | 0x8000, 0, 8 + length($rowid), $rowid),
	$reqpos += 8 + length($rowid)
		if $rowid;
	substr($reqmsg, $reqpos, 12) =
		pack('SSLL', 153 | 0x8000, 0, 12, $respsz);
	return $reqmsg;
}
sub sqlRequest {
	my ($self, $iobj, $sth, $forCursor, $rowid, $modepcl, $keepresp, $respsz) = @_;
	my $reqlen = 8 + length($_[8]) + 12 +
		((defined($_[9]) && length($_[9])) ? 8 + length($_[9]) : 0) +
		((defined($_[10]) && length($_[10])) ? 8 + length($_[10]) : 0) +
		($forCursor ? 8 + length($rowid) : 0) +
		($sth->{tdat_mload} ? 18 : 0);
	my $reqmsg = $iobj->io_buildtdhdr(5, $reqlen);
	return undef unless $reqmsg;
	my $bufpos = 52;
	my $reqpcl =
		$sth->{tdat_formatted} ? 13 :
		$sth->{tdat_mload} ? 1 :
		69;
	substr($reqmsg, $bufpos, 8 + length($_[8])) =
		pack('SSLA*', $reqpcl | 0x8000, 0, 8 + length($_[8]), $_[8]);
	$bufpos += 8 + length($_[8]);
	substr($reqmsg, $bufpos, 8 + length($_[9])) =
		pack('SSLa*', 71 | 0x8000, 0, length($_[9]) + 8, $_[9]),
	$bufpos += (8 + length($_[9]))
		if defined($_[9]) && ($_[9] ne '');
	substr($reqmsg, $bufpos, 8 + length($_[10])) =
		pack('SSLa*', $modepcl | 0x8000, 0, length($_[10]) + 8, $_[10]),
	$bufpos += (8 + length($_[10]))
		if defined($_[10]) && ($_[10] ne '');
	substr($reqmsg, $bufpos, 8 + length($rowid)) =
		pack('SSLa*', 120 | 0x8000, 0, length($rowid) + 8, $rowid) ,
	$bufpos += (8 + length($rowid))
		if $rowid;
	substr($reqmsg, $bufpos, 12) =
		pack('SSLL', (($keepresp) ? 154 : 153) | 0x8000, 0, 12,
		($sth->{tdat_mload} ? 4096 : $respsz));
	return $reqmsg;
}
sub rewindRequest {
	my ($self, $iobj, $reqno, $respsz) = @_;
	my $reqmsg = $iobj->io_buildtdhdr(6, 20, $reqno);
	return undef unless $reqmsg;
	substr($reqmsg, 52, 20) =
		pack('SSL SSLL',
			31 | 0x8000,
			0,
			8,
			154 | 0x8000,
			0,
			12,
			$respsz);
	return $reqmsg;
}
1;
package DBD::Teradata::impl;
use IO::Socket;
use Socket;
use DBI qw(:sql_types);
use Time::HiRes qw(time sleep);

use DBD::Teradata qw(
	%td_type_code2str
	%td_type_str2baseprec
	%td_type_str2basescale
	%td_lob_scale
	@td_decszs
	%td_type_str2dbi
	%td_type_str2size
	%td_type_str2pack
	%td_type_str2stringtypes
	%td_type_str2binarytypes
	%td_type_dbi2stringtypes
	%td_type_dbi2str
	%td_activity_types
	%td_sqlstates
	@td_indicbits
	@td_indicmasks
	@td_decstrs
	@td_decscales
	@td_decfactors
	%td_type_dbi2preconly
	%td_type_dbi2hasprec
	%td_type_dbi2hasscale
	%td_type_dbi2pack
	%td_type_code2dbi
	%td_type_dbi2code
);

use strict;
use warnings;
my %stmt_abbrv = (
'INS', 'Insert',
'UPD','Update',
'DEL','Delete',
'CT','Create Table',
'CV','Create View',
'CD','Create Database'
);
my %rawmodes = ( 'RecordMode', 3, 'IndicatorMode', 68);
my $req_template = "\3\1" . ("\0" x 50);
my %hostcache = ();
my $has_cli = 1;
sub new {
	my ($class, $host, $port, $user, $auth, $dbname, $attrs) = @_;
	my $obj = [ ];
    bless $obj, $class;
	$obj->io_init;
	$obj->[9] = $hostchars;
	$obj->[3] = $attrs->{tdat_respsize};
	$obj->[39] = $attrs->{tdat_reqsize};
	return (undef,
		$obj->[18],
		$obj->[17],
		$obj->[24])
		unless $obj->io_connect($host, $port, $user, $auth, $dbname, $attrs);
    return ($obj, 0, '', '');
}
sub _getPclHeader {
	my ($f, $l) = unpack('SS', substr($_[0], $_[1], 4));
	return ($f & 0x8000) ?
		($f & 0x00FF, unpack('L', substr($_[0], $_[1]+4, 4)), 8) :
		($f, $l, 4);
}
sub io_init {
	my $obj = shift;
	$obj->[13] = 0;
	$obj->[2] = 0;
	$obj->[4] = 0;
	$obj->[5] = 0;
	$obj->[20] = undef;
	$obj->[3] = undef;
	$obj->[23] = 0;
	$obj->[15] = undef;
	$obj->[16] = undef;
	$obj->[32] = undef;
	$obj->[14] = 1;
	$obj->[1] = { };
	unless ($inited) {
		$debug = $ENV{TDAT_DBD_DEBUG} || 0;
		if ($debug) {
			eval {
				require DBD::Teradata::Diagnostic;
				import DBD::Teradata::Diagnostic qw(io_hexdump io_hdrdump io_pcldump);
			};
		}
		DBI->trace_msg(
"DBD::Teradata init: platform = $platform, debug = $debug,
charset = $hostchars, ph size = $phdfltsz, response buf size = $maxbufsz\n", 1);
		substr($req_template, 5, 1) = pack('C', $platform);
		substr($req_template, 37, 1) = pack('C', $hostchars);
		$inited = 1;
	}
	srand(time);
	return 1;
}
sub io_get_error {
	return ($_[0]->[18], $_[0]->[17], $_[0]->[24]);
}
sub io_set_error {
	my $obj = shift;
	($obj->[18], $obj->[17], $obj->[24]) =
		($#_ == 2) ? @_ :
		($#_ == 1) ? (@_,
			(($_[0] > 999) ?
				(exists $td_sqlstates{$_[0]} ? $td_sqlstates{$_[0]} : "T$_[0]") : 'S1000')) :
		(-1, $_[0], 'S1000');
	return undef;
}
sub io_buildtdhdr {
	my ($obj, $kind, $len, $reqno) = @_;
	return $obj->io_set_error('Large requests not supported prior to V2R5.0')
		if (($kind == 5) || ($kind == 6)) &&
			($len > 65535) && ($obj->[40] < 5000000);
	my $charset = ($kind == 1) ? 0 : $obj->[9];
	my $hostbyte = ($kind == 9) ? 1 : $platform;
	$obj->[2] = 0 if ($kind == 3);
	$obj->[2]++ if ($kind == 5) || ($kind == 8);
	my $reqmsg;
	if ($_[4]) {
		$obj->io_init_reqbuf($reqno, $len, $kind, $hostbyte, $charset, $_[4]);
	}
	else {
		$len += 52;
		$reqmsg = pack("a$len", '');
		$len -= 52;
		$obj->io_init_reqbuf($reqno, $len, $kind, $hostbyte, $charset, $reqmsg);
	}
	return $reqmsg || 1
		if ($kind == 10) || ($kind == 9);
	if ($obj->[4] == 0xffffffff) {
		$obj->[5]++;
		$obj->[4] = 0;
	}
	else { $obj->[4]++; }
	return $reqmsg || 1;
}
sub io_init_reqbuf {
	my ($obj, $reqno, $len, $kind, $hostbyte, $charset) = @_;
	substr($_[6], 0, 52) = $req_template;
	substr($_[6], 2, 1) = pack('C', $kind);
	if ($len > 65535) {
		substr($_[6], 4, 1) = pack('C', ($len >> 16) & 255);
		substr($_[6], 8, 2) = pack('n', $len & 65535);
	}
	else {
		substr($_[6], 8, 2) = pack('n', $len);
	}
	substr($_[6], 5, 1) = pack('C', $hostbyte);
	substr($_[6], 27, 11) = pack('CL N C C', 0, 1, 0, 0, 0),
	return 1
		if ($kind == 10);
	substr($_[6], 20, 4) = pack('N', $obj->[13]);
	substr($_[6], 27, 11) = pack('CN N C C',
		$obj->[5], $obj->[4],
		((($kind == 6) || ($kind == 7)) ? $reqno : $obj->[2]),
		0, $charset);
	return 1;
}
sub io_clisend {
	my $obj = shift;
	my ($reqid, $err, $errstr) =
		$obj->[15]->cli_send_request(@_, $obj->[3]);
	DBI->trace_msg("Can't send: $!\n", 1),
	$obj->[15]->cli_disconnect,
	return $obj->io_set_error($err, $errstr, '08C01')
		if $err;
	$obj->[23] = $reqid;
	return $_[0];
}
sub io_set_respsz {
	my $max = (($_[0]->[19] == 1) && ($_[0]->[40] >= 6000000)) ?
		2097152 : 64256;
	$_[0]->[3] = $_[1]
		if ($_[1]=~/^\d+$/) && ($_[1] >= 64000) && ($_[1] < $max);
	return $_[0]->[3];
}
sub io_set_reqsz {
	my $max = (($_[0]->[40] >= 6000000) ||
		(($_[0]->[19] == 1) && ($_[0]->[40] >= 5000000))) ?
		2097152 : 64256;
	$_[0]->[39] = $_[1]
		if ($_[1]=~/^\d+$/) && ($_[1] >= 256) && ($_[1] < $max);
	return $_[0]->[39];
}
sub io_update_version {
	my ($obj, $versnum) = @_;
	$obj->[38] =
		($versnum < 5000000) ? DBD::Teradata::ReqFactory->new() :
		($versnum < 6010000) ? DBD::Teradata::APHReqFactory->new() :
							DBD::Teradata::BigAPHReqFactory->new()
		if ($obj->[19] == 1);
	$obj->[40] = $versnum;
	return $obj if ($versnum >= 6000000);
	$obj->[39] = 64256
		if ($obj->[39] > 64256);
	$obj->[3] = 64256
		if ($obj->[3] > 64256);
}
sub io_tdsend {
	my ($obj, $msg, $encrypt, $keepresp) = @_;
	my $n = 0;
	if ($debug) {
		DBI->trace_msg("Sending request\n", 2);
		DBI->trace_msg(io_hdrdump('Request msg header',
			substr($msg, 0, 52)), 1);
		DBI->trace_msg(io_pcldump(
			substr($msg, 52), length($msg) - 52), 1);
	}
	if ($obj->[34] && $encrypt) {
		$msg = $obj->[34]->encrypt_request($msg);
		DBI->trace_msg(io_hdrdump('(Encrypted) Request msg header',
			substr($msg, 0, 52)), 1),
		DBI->trace_msg(io_pcldump(
			substr($msg, 52), length($msg) - 52, 1), 1)
			if $debug;
	}
	my $kind = unpack('C', substr($msg, 2, 1));
	if (($kind != 7) && ($kind != 9) && $obj->[23]) {
		my $rspmsg = '';
		return undef unless $obj->io_getcliresp;
		$obj->[14] = 0;
	}
	return $obj->io_clisend(length($msg), $keepresp, $msg)
		;
}
sub io_quicksend {
	my $obj = shift;
	my ($len, $keepresp) = @_;
	my $n = 0;
	if ($debug) {
		DBI->trace_msg("Sending request\n", 2);
		DBI->trace_msg(io_hdrdump('Request msg header', substr($_[2], 0, 52)), 1);
		DBI->trace_msg(io_pcldump(substr($_[2], 52), $len - 52), 1);
	}
	if ($obj->[23]) {
		return undef unless $obj->io_getcliresp;
		$obj->[14] = 0;
	}
	return $obj->io_clisend(@_)
		;
}
sub io_getcliresp {
	my ($obj, $sth) = @_;
	my $hdr = '';
	my $reqno = $obj->[23];
	my ($err, $errstr) =
		$obj->[15]->cli_get_response(\$hdr, $reqno,
			(defined($sth) && $sth->{tdat_keepresp}), -1);
	DBI->trace_msg($errstr),
	$obj->[15]->cli_disconnect,
	return $obj->io_set_error($err, $errstr, '08S01')
		if $err;
	DBI->trace_msg("<*** CLI Response for Request $reqno ***>\n"),
	DBI->trace_msg(io_pcldump(
		substr($hdr, 52), length($hdr) - 52), 1)
		if $debug;
	$obj->[23] = 0;
	return $obj->io_scan_response(\$hdr, $reqno);
}
sub io_scan_response {
	my ($obj, $hdr, $reqno) = @_;
	my $sth = ($obj->[1]) ?
		$obj->[1]{$reqno} : undef;
	my $islastresp;
	my $isfailed;
	my $pos = 52;
	my $rsplen = length($$hdr);
	while ($pos < $rsplen) {
		my ($f, $l, $pclhdrsz) = _getPclHeader($$hdr, $pos);
		$pos += $l;
		$islastresp = 1,
		last
			if ($f == 12);
		$isfailed = 1
			if ($f == 9);
	}
	if ($sth) {
		my $sthp = $sth->{_p};
		$sthp->[22] = $islastresp ||
			($isfailed && ($obj->[10] ne 'ANSI'));
		$sthp->[24] = $isfailed;
		if ((! $sthp->[17]) ||
			($sthp->[19] >= length($sthp->[17]))) {
			$sthp->[17] = $hdr;
			$sthp->[19] = 52;
		}
		else {
			${$sthp->[17]} .= substr($$hdr, 52);
		}
	}
	my ($f, $l, $pclhdrsz) = _getPclHeader($$hdr, 52);
	if (($f == 9) || ($f == 49)) {
		my ($tderr, $tdelen) =
			unpack('SS', substr($$hdr, 52+$pclhdrsz+4, 4));
		my $tdemsg = substr($$hdr, 52+$pclhdrsz+8, $tdelen);
		DBI->trace_msg("ERROR\: $tdemsg\n", 2);
		$obj->io_set_error($tderr, $tdemsg);
		$islastresp = ($f == 9);
	}
	$obj->[15]->cli_end_request($reqno)
		if ($islastresp || $isfailed) &&
			(! $obj->[31]{tdat_keepresp})
			;
	return $hdr;
}
sub io_ping {
	my $reqmsg = $req_template . "\0\0\0\0";
	substr($reqmsg, 2, 1) = pack('C', 9);
	substr($reqmsg, 9, 1) = "\4";
	substr($reqmsg, 52, 4) = pack('SS', 32, 4);
	return $_[0]->io_tdsend($reqmsg);
}
sub io_tddo {
	my ($obj, $dbreq, $dbdata, $outrecs) = @_;
	$obj->[18] = undef;
	my $reqmsg = $obj->[38]->simpleRequest($obj, $obj->[3], $dbreq);
	return undef unless $reqmsg;
	$obj->io_tdsend($reqmsg) or return undef;
	my $rspmsg = $obj->io_getcliresp;
	return undef
		unless $rspmsg;
	my ($f, $l, $pclhdrsz) = _getPclHeader($$rspmsg, 52);
	my $pos = 52 + $pclhdrsz;
	$obj->[11] = 0
		if ($obj->[10] ne 'ANSI') && ($f == 9);
	return undef if ($f != 8) || ($l < 4);
	my ($stmtno, $rowcnt, $warncode, $fldcount, $activity, $warnlen) =
		unpack('SLSSSS', substr($$rspmsg, $pos, 14));
	$obj->io_set_error($warncode, substr($$rspmsg, $pos + 14, $warnlen))
		if $warnlen;
	$pos += ($l - $pclhdrsz);
	($f, $l, $pclhdrsz) = _getPclHeader($$rspmsg, $pos);
	push(@$outrecs, substr($$rspmsg, $pos+$pclhdrsz, $l-$pclhdrsz)),
	$pos += $l,
	($f, $l, $pclhdrsz) = _getPclHeader($$rspmsg, $pos)
		while (($f == 10) && $outrecs);
	DBI->trace_msg("Session $obj->[13] executed $dbreq\n", 1)
		if $debug;
	return $rowcnt;
}
sub io_tdcontinue {
	my ($obj, $sth, $nowait) = @_;
		my $rspmsg;
		my ($err, $errstr) =
			$obj->[15]->cli_get_response(\$rspmsg,
				$sth->{_p}[12], $sth->{tdat_keepresp}, -1);
		return $obj->io_set_error($err, $errstr)
			if $err;
		return \$rspmsg;
}

sub io_socket {
	my ($obj, $dbsys, $port) = @_;
	my ($inetaddr, $dest, $connfd);
	my $tsys = uc $dbsys;
	$tsys=~s/cop\d+$//i;
	$inetaddr = inet_aton($tsys);

	unless ($hostcache{$tsys}) {
		my $maxcop;
		my $host;
		foreach $host (keys %ENV) {
			$maxcop = $ENV{$host}, last
				if (uc $host eq $tsys);
		}
		$maxcop = 1 unless $maxcop;
		$hostcache{$tsys} = $maxcop;
	}
	my $cop = ($hostcache{$tsys} == 1) ? 1 :
		int(rand($hostcache{$tsys})) + 1;
	$inetaddr = inet_aton($tsys . 'COP' . $cop);

	return $obj->io_set_error(-1, 'Unable to get host address.', '08001')
		unless $inetaddr;
	$dest = sockaddr_in($port, $inetaddr);
	return $obj->io_set_error(-1, 'Unable to get host address.', '08001')
		unless $dest;
	return $obj->io_set_error(-1, "Unable to allocate a socket: $!.", '08001')
		unless socket($connfd, PF_INET, SOCK_STREAM, getprotobyname('tcp'));
	close($connfd),
	return $obj->io_set_error(-1, "Unable to connect: $!", '08001')
		unless connect($connfd, $dest);
	setsockopt($connfd, SOL_SOCKET, SO_KEEPALIVE, pack('l', 1));
	$obj->[15] = $connfd;
	return $connfd;
}

sub io_getconfig {
	my ($obj, $dbsys, $port, $attr) = @_;
	$obj->[18] = -1;
	$obj->[24] = 'S1000';
	$obj->[17] = '';
	my $c;
	my $r = 3;
	$r-- until ($r == 0) || ($c = $obj->io_socket($dbsys, $port));
	return undef unless $c;
	$obj->[4] = int(rand(time()))+1;
	$obj->[5] = 0;
	$obj->[40] = 0;
	my $cfgpos = 52;
	my $cfgreq = $obj->io_buildtdhdr(10, 0);
	if ($debug) {
		DBI->trace_msg("Sending request\n", 2);
		DBI->trace_msg(io_hdrdump('Request msg header', substr($_[2], 0, 52)), 1);
	}
	my $n = send($c, $cfgreq, 0);
	DBI->trace_msg("Can't send: $!\n", 1),
	close($c),
	return $obj->io_set_error(-1, 'System error: unable to send', '08C01')
		unless defined($n);

	DBI->trace_msg("Only sent $n bytes!\n", 1),
	close($c),
	return $obj->io_set_error(-1, 'System error: unable to send', '08C01')
		if ($n != 52);

	DBI->trace_msg("Request sent\n", 2) if $debug;

	my $rspmsg = '';
	my $hdrlen = 0;
	my $rsplen = 8192;
	my $hdr = '';

	DBI->trace_msg("Rcving Header\n", 2) if $debug;

	while ($hdrlen < 52) {
		unless (recv($c, $rspmsg, $rsplen, 0)) {
			DBI->trace_msg(
"System error: can't recv msg header $!;\n rcvd $hdrlen bytes.\n", 2),
			close($c),
			return $obj->io_set_error(-1,
				"System error: can't recv msg header $!; closing connection.", '08S01')
				unless defined($rspmsg) && ($rspmsg ne '');
		}
		$hdr .= $rspmsg;
		$hdrlen += length($rspmsg);
	}
	DBI->trace_msg(io_hdrdump('Response msg header', substr($hdr, 0, 52)), 1) if $debug;
	my ($tdver, $tdclass, $tdkind, $tdenc, $tdchksum, $tdbytevar,
		$tdwordvar, $tdmsglen) = unpack('C6Sn', $hdr);

	DBI->trace_msg("Invalid response message header; closing connection.", 2),
	close($c),
	return $obj->io_set_error(-1, 'Invalid response message header; closing connection.', '08S01')
		if ($tdver !=  3) || ($tdclass !=  2);
	$tdmsglen -= ($hdrlen - 52) if ($hdrlen > 52);
	$hdr .= "\0" x $tdmsglen if ($tdmsglen > 0);
	my $lrspmsg = 0;
	while ($tdmsglen > 0) {
		unless (recv($c, $rspmsg, $tdmsglen, 0)) {

			$hdrlen = length($rspmsg),
			DBI->trace_msg(
		"System error: can't recv msg body$!;\n rcvd $hdrlen bytes.\n", 2),
			close($c),
			return $obj->io_set_error(-1, "System error: can't recv() msg body; closing connection.", '08S01')
				unless defined($rspmsg) && length($rspmsg);
		}
		$lrspmsg = length($rspmsg);

		DBI->trace_msg("GOT $lrspmsg BYTES, NEEDED $tdmsglen\n",2)
			if $debug && ($lrspmsg < $tdmsglen);

		substr($hdr, $hdrlen, length($rspmsg)) = $rspmsg;
		$tdmsglen -= $lrspmsg;
		$hdrlen += $lrspmsg;
	}

	close($c);
	DBI->trace_msg(io_pcldump(substr($hdr, 52), length($hdr) - 52, 0), 1)
		if $debug;

	my ($f, $l)  = unpack('SS', substr($hdr, $cfgpos));
	return $obj->io_set_error(-1,
"Unknown response parcel $f recv'd during CONFIG; closing connection.",
		'08C01')
		if ($f != 43) || ($l < 4);
	$cfgpos += 14;
	my $pe_cnt = unpack('S', substr($hdr, $cfgpos));
	$cfgpos += 2 + ($pe_cnt * 4);
	my $amp_cnt = unpack('S', substr($hdr, $cfgpos));
	$cfgpos += 2 + ($amp_cnt * 2);
	my $dflt_charset = unpack('C', substr($hdr, $cfgpos));
	$cfgpos += 2;
	my $charset_cnt = unpack('S', substr($hdr, $cfgpos));
	$cfgpos += 2 + ($charset_cnt * 32) + 6;
	my $defmode = unpack('A', substr($hdr, $cfgpos));
	$defmode = ($defmode eq 'A') ? 'ANSI' : 'TERADATA';
	$attr->{tdat_mode} = $defmode
		if ($attr->{tdat_mode} eq 'DEFAULT');
	return $obj->io_set_error(-1,
		"Only DBC/SQL sessions allowed in ANSI mode; closing connection.",
		'08C01')
		if ($attr->{tdat_mode} eq 'ANSI') && ($attr->{tdat_utility} ne 'DBC/SQL');
	$obj->[10] = $attr->{tdat_mode};
	($obj->[7], $obj->[8]) =
		($attr->{tdat_mode} eq 'ANSI') ?
			('COMMIT WORK', 'ROLLBACK WORK') : ('ET', 'ABORT');

	return $dflt_charset;
}

sub io_connect {
	my ($obj, $dbsys, $port, $username, $password, $dbname, $attr) = @_;
	$obj->[18] = -1;
	$obj->[24] = 'S1000';
	$obj->[17] = '';
	my $dflt_charset = $obj->io_getconfig($dbsys, $port, $attr) or
		return undef;
	$obj->[40] = 0;
	my $rspmsg;
	$obj->[19] = 1;
	$obj->[20] = $attr->{tdat_lsn} || undef;
	my $lgnsrc = $attr->{tdat_logonsrc};
	unless ($lgnsrc) {
		my $uid = getlogin || getpwuid $< || '????';
		$dbsys .= ' ' x (12 - length($dbsys))
			if (length($dbsys) < 12);
		my $app = $0;
		$app = substr($app, 0, 20)
			if (length($app) > 20);
		$app .= ' ' x (4 - length($app))
			if (length($app) < 4);
		$lgnsrc = "$dbsys  $$  $uid  $app  01  LSS";
	}
	$password = '' unless defined($password);
	my $charset = $attr->{tdat_charset};
	$obj->[9] =
		(($obj->[9] & 128) ? 128 : 0) |
			(
			(! $charset)			? $dflt_charset :
			($charset eq 'UTF8')	? 63 :
			($charset eq 'ASCII')	? 127 : 64);
	$attr->{tdat_charset} = $charset =
		(($dflt_charset & 127) == 63) ? 'UTF8' :
		(($dflt_charset & 127) == 127) ? 'ASCII' : 'EBCDIC'
		unless $charset;
	$obj->[25] = (($obj->[9] & 127) == 63);

	$dbsys=~s/COP\d+\s*$//i;
	my $logonstr = "$dbsys/$username,$password";
	my ($hostid, $sessno, $version);
	($obj->[15], $obj->[18], $obj->[17],
		$hostid, $sessno, $version) =
			DBD::Teradata::Cli->new(
				$logonstr, $attr->{tdat_mode}, $lgnsrc, $obj->[9], $debug);
	$obj->[24] = '08C01',
	return undef
		if defined($obj->[18]);
	$obj->[13] = $sessno;
	$obj->[29] = $hostid & 0x3FF;
	$obj->[28] = "V2R$version";
	$obj->[21] = $1,
	$obj->[27] = $2,
	$obj->[36] = $3,
	$obj->[37] = $4,
	$obj->[40] = ($1 * 1000000) + ($2 * 10000) + ($3 * 100) + $4
		if ($version=~/^(\d+)[A-Za-z]*\.(\d+)\.(\d+)\.(\d+)/);
	DBI->trace_msg(
		"Session $$obj[13] connected via CLI for $$obj[28]\n", 1)
		if $debug;
	$obj->[2] = 1;
	$obj->[14] = 0;

	DBI->trace_msg("Session $$obj[13] connected\n", 1) if $debug;
	$obj->[38] =
		(($obj->[40] < 5000000) ||
			($obj->[19] != 1) ||
			defined($attr->{tdat_lsn})) ?
			DBD::Teradata::ReqFactory->new() :
		($obj->[40] < 6010000) ?
			DBD::Teradata::APHReqFactory->new() :
			DBD::Teradata::BigAPHReqFactory->new();
	$obj->[18] = 0;
	$obj->[24] = '00000';
	$obj->[11] = 0;
	$obj->io_tddo("DATABASE $dbname", '')
		if $dbname;
	return $obj->[13];
}
sub io_disconnect {
	my ($obj) = @_;
	unless ($obj->[31]{_logged_off}) {
			$obj->[15]->cli_disconnect();
		$obj->[15] = undef;
		DBI->trace_msg("Logged off session $obj->[13]\n", 1) if $debug;
	}
	$obj->[1] = undef;
	$obj->[31] = undef;
	$obj->[18] = undef;
	$obj->[17] = undef;
	$obj->[24] = undef;
	return 1;
}
sub io_parse_using {
	my ($req, $typeary, $typelen, $ipackstr, $nameary) = @_;
	$$ipackstr = '';
	my $remnant = ', ' . uc $req;
	while ($remnant=~/^\s*,\s*(\w+)\s+((DOUBLE\s+PRECISION)|CHARACTER|TIMESTAMP|INTERVAL|VARCHAR|VARBYTE|GRAPHIC|DECIMAL|NUMERIC|SMALLINT|BYTEINT|INTEGER|FLOAT|CHAR|BYTE|REAL|DATE|TIME|INT|DEC)(.*)$/i) {
		my $name = uc $1;
		my $vtype = uc $2;
		$remnant = $4;
		$vtype = 'FLOAT' if ($vtype=~/^(DOUBLE\s+PRECISION)|REAL$/i);
		$vtype = 'DEC' if ($vtype=~/^DECIMAL|NUMERIC/i);
		$vtype = 'CHAR' if ($vtype eq 'CHARACTER');
		$vtype = 'INT' if ($vtype eq 'INTEGER');
		push @$nameary, $name;
		my ($prec, $scale);
		unless ($vtype=~/^INTERVAL|DEC|TIME|TIMESTAMP$/i) {
			push(@$typeary, $td_type_str2dbi{$vtype}),
			push(@$typelen, $td_type_str2size{$vtype}),
			$remnant=~s/^[^,]+(,.*)$/$1/,
			next
				unless defined($td_type_str2baseprec{$vtype});
			$prec = $td_type_str2baseprec{$vtype};
			if ($remnant && ($remnant=~/^\s*\(\s*(\d+)\s*\)(.*)$/)) {
				$prec = $1;
				$remnant = $2;
			}
			push @$typeary, $td_type_str2dbi{$vtype};
			push @$typelen, $prec;
			$remnant=~s/^[^,]+(,.*)$/$1/;
			next;
		}
		if (($vtype eq 'TIMESTAMP') || ($vtype eq 'TIME')) {
			$prec = $td_type_str2baseprec{$vtype};
			if ($remnant && ($remnant=~/^(\s*\(\s*(\d+)\s*\))?(\s+WITH\s+TIME\s+ZONE)?(.*)$/)) {
				$prec = $2 if defined($1);
				$vtype .= ' WITH TIME ZONE' if defined($3);
				$remnant = $4;
			}
			push @$typeary, $td_type_str2dbi{$vtype};
			push @$typelen, $td_type_str2size{$vtype} + ($prec ? 1 + $prec : 0);
			$remnant=~s/^[^,]+(,.*)$/$1/;
			next;
		}
		elsif ($vtype eq 'DEC') {
			$prec = $td_type_str2baseprec{DEC};
			$scale = $td_type_str2basescale{DEC};
			if ($remnant && ($remnant=~/^\s*\(\s*(\d+)\s*(,\s*(\d+)\s*)?\)(.*)$/)) {
				$prec = $1;
				$scale = $3 if defined($2);
				$remnant = $4;
			}
			push @$typelen, (($prec * 256) + $scale);
			push @$typeary, $td_type_str2dbi{'DEC'};
			$remnant=~s/^[^,]+(,.*)$/$1/;
			next;
		}
		return undef
			unless $remnant && ($remnant=~/^\s*(YEAR|MONTH|DAY|HOUR|MINUTE|SECOND)(.*)$/);
		my $intvl = $1;
		$remnant = $2;
		$prec = $td_type_str2baseprec{$intvl};
		$scale = 0;
		if ($intvl eq 'SECOND') {
			if ($remnant && ($remnant=~/^\s*\(\s*(\d+)(\s*,\s*(\d+))?\s*\)(.*)$/)) {
				$prec = $1;
				$scale = defined($3) ? $3 : 6;
				$remnant = $4;
			}
			push @$typelen,
			$td_type_str2size{"INTERVAL SECOND"} + $prec + ($scale ? $scale + 1 : 0);
			push @$typeary, $td_type_str2dbi{"INTERVAL SECOND"};
			$remnant=~s/^[^,]+(,.*)$/$1/;
			next;
		}
		push(@$typelen, $td_type_str2size{"INTERVAL $intvl"} + $prec),
		push(@$typeary, $td_type_str2dbi{"INTERVAL $intvl"}),
		$remnant=~s/^[^,]+(,.*)$/$1/,
		next
			unless $remnant &&
				($remnant=~/^(\s*\(\s*(\d+)\s*\))?(\s+TO\s+(MONTH|HOUR|MINUTE|(SECOND(\s*\(\s*(\d+)\s*\))?)))?(.*)$/) &&
				(defined($1) || defined($3));
		$vtype = defined($3) ? defined($5) ? "INTERVAL $intvl TO SECOND" :
			"INTERVAL $intvl TO $4" : "INTERVAL $intvl";
		$prec = $2 if defined($1);
		$scale = defined($5) ? (defined($7) ? $7 : $td_type_str2basescale{SECOND}) : 0;
		push @$typelen, $td_type_str2size{$vtype} + $prec + ($scale ? 1 + $scale : 0);
		push @$typeary, $td_type_str2dbi{$vtype};
		$remnant=~s/^[^,]+(,.*)$/$1/;
	}
	my $prec = 0;
	my $i = 0;
	my $pstr;
	$$ipackstr = '';
	while ($i < scalar(@$typeary)) {
		$prec = ($$typeary[$i] == 3) ?
			$td_decszs[($$typelen[$i] >> 8) & 31] : $$typelen[$i];
		$pstr = $td_type_dbi2pack{$$typeary[$i]};
		$$ipackstr .= " $pstr";
		$$ipackstr .= $prec if (uc $pstr eq 'A') || ($pstr eq 'U');
		$i++;
	}
	return scalar @$typeary;
}
sub io_parse_call {
	my ($obj, $stmt, $parmdesc) = @_;
	return undef unless ($stmt=~/^\s*CALL\s+([^\s\(]+)\s*(\(.+\))?\s*;?$/i);
	my ($spname, $parmList) = (uc $1, $2);
	$parmList=~s/^\((.+)\)$/$1/;
	$parmList=~s/^\s+//;
	$parmList=~s/\s+$//;
	if ($parmList ne '') {
		$parmList=~s/DEC(IMAL)?\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)/DEC($2;$3)/ig;
		my $phCount = ($parmList=~tr/\?//);
		my @parmAry = split(',', $parmList);
		for (my $i = 0; $i <= $#parmAry; $i++) {
			$parmAry[$i]=~s/;/,/g;
			$parmAry[$i]=~s/^\s+//;
			$parmAry[$i]=~s/\s+$//;
			$$parmdesc[$i] = 3, next
				if ($parmAry[$i]=~/(\?|\:\w+)/);
			$$parmdesc[$i] = 4, next
				if (uc $parmAry[$i] ne 'NULL') && ($parmAry[$i]=~/^[_A-Za-z]\w+/);
			$$parmdesc[$i] = 2;
		}
	}
	1;
}
sub io_prepare {
	my ($obj, $dbh, $make_sth, $dbreq, $rowid, $attribs, $compatible, $passthru) = @_;
	$compatible = '999.0' unless defined $compatible;
	my @ptypes = ();
	my @plens = ();
	my $usephs = 0;
	my @usenames = ();
	my @stmtinfo = (undef);
	my $ipackstr = '';
	$obj->[18] = 0;
	$obj->[24] = '00000';
	$obj->[17] = '';
	my $tmpreq = $dbreq;
	$tmpreq=~s/\s+WHERE\s+CURRENT\s+OF\s+[^\s;]+(\s*;)?\s*$/ WHERE CURRENT/ig;
	$tmpreq =~s/'[^']+'/''/g;
	$tmpreq=~s/\-\-.*\r/ /g;
	$tmpreq=~s/\/\*.*?\\*\// /g;
	my $datainfo = '';
	$ipackstr = '';
	$usephs = ($tmpreq =~ tr/\?//);
	return $obj->io_set_error('Placeholders not supported for utility applications.')
		if $usephs && (($obj->[19] != 1) || $obj->[20]);
	my $usingvars = 0;
	$tmpreq = uc $2,
	$usingvars = io_parse_using($1, \@ptypes, \@plens, \$ipackstr, \@usenames)
		if ($tmpreq=~/^USING\s*\((.+)\)\s*((SELECT|EXECUTE|LOCKING|IGNORE|INSERT|UPDATE|DELETE|MERGE|ABORT|EXEC|LOCK|MARK|CALL|INS|UPD|SEL|DEL|DO)\s+(.+))$/i);
	return $obj->io_set_error('Invalid USING clause.')
		if ($usingvars == -1);
	return $obj->io_set_error('Can\'t mix USING clause and placeholders in same statement.')
		if ($usephs > 0) && ($usingvars > 0);
	if ($usephs) {
		@ptypes = ((12) x $usephs);
		@plens = (($phdfltsz) x $usephs);
		$ipackstr = 'S/a* ' x $usephs;
	}
	unless ($compatible lt '2.1') {
		$tmpreq = $9
			while ($tmpreq=~/^LOCK(ING)?(((\s+TABLE|DATABASE|VIEW)?\s+\S+)|ROW|)(\s+(FOR|IN))?\s+\S+(\s+MODE)?(\s+NOWAIT)?\s+(.+)$/i);
		my @s = split(';', $tmpreq);
		my $i = 1;
		my $t;
		foreach $t (@s) {
			last unless ($t=~/^\s*(DATABASE|COLLECT|REPLACE|MODIFY|REVOKE|UPDATE|INSERT|DELETE|CREATE|MERGE|ALTER|GRANT|DROP|GIVE|UPD|INS|DEL|[CRD][TVMP]|SET)\s+(VOLATILE\s+|GLOBAL\s+TEMPORARY\s+)?(MULTISET\s+|SET\s+)?(\S+)(\s+(\S+))?/i);
			my ($keywd, $keytyp, $keyqual) = (uc $1, uc $4, uc $6);
			last
				if (($keywd eq 'REPLACE') || ($keywd eq 'CREATE')) &&
					(($keytyp eq 'MACRO') || ($keytyp eq 'PROCEDURE'));
			$stmtinfo[$i]->{ActivityType} =
				(($keywd eq 'SET') || ($keytyp eq 'JOIN') || ($keytyp eq 'HASH')) ?
					join(' ', ucfirst (lc $keywd), ucfirst(lc $keytyp), ucfirst(lc $keyqual)) :
				(($keywd=~/^CREATE|DROP|RENAME|REPLACE|ALTER|COLLECT|MODIFY$/) ||
					(($keywd eq 'DELETE') && (($keytyp eq 'DATABASE') || ($keytyp eq 'JOURNAL')))) ?
					ucfirst (lc $keywd) . ' ' . ucfirst(lc $keytyp) :
				exists $stmt_abbrv{$keywd} ?
					$stmt_abbrv{$keywd} :
					ucfirst(lc $keywd);
			$stmtinfo[$i]->{ActivityCount} = 0;
			$i++;
		}
		return &$make_sth(
			$dbh,
			{
			%$attribs,
			Statement => $dbreq,
			tdat_stmt_info => \@stmtinfo,
			NUM_OF_FIELDS => 0,
			NUM_OF_PARAMS => (($usingvars > 0) ? $usingvars : $usephs),
			_ptypes => \@ptypes,
			_plens => \@plens,
			_packstr => $ipackstr,
			_usenames => \@usenames,
			_usephs => $usephs
			}
		)
			if ($i > $#s+1);
	}
	@stmtinfo = (undef);
	my @parmdesc = ();
	my ($parmnum, $phnum) = (0,0);
	my $is_a_call = undef;
	if ($tmpreq=~/^\s*CALL\s+/i) {
		return undef
			unless $obj->io_parse_call($tmpreq, \@parmdesc);
		$is_a_call = 1;
	}
	my $reqmsg = $obj->[38]->prepareRequest($obj, $rowid,
		$usingvars, $obj->[3], $dbreq);
	return $obj->io_set_error('System error: can\'t send() PREPARE request.')
		unless $obj->io_quicksend(length($reqmsg), undef, $reqmsg);
	my $rspmsg = $obj->io_getcliresp;
	return undef unless $rspmsg ;
	my $rsplen = length($$rspmsg);
	$$passthru = $$rspmsg
		if defined($passthru);
	my ($f, $l, $tderr, $tdelen);
	my ($stmtno, $rowcnt, $warncode, $fldcount, $activity, $warnlen, $pcl);
	my $nextcol = 0;
	my $curpos = 52;
	my $pclhdrsz = 4;
	my %sthargs = (
		%$attribs,
		Statement => $dbreq,
		tdat_stmt_info => [ undef ],
		NAME => [],
		TYPE => [],
		PRECISION => [],
		SCALE => [],
		NULLABLE => [],
		tdat_TYPESTR => [],
		tdat_TITLE => [],
		tdat_FORMAT => [],
		_unpackstr => [],
		_ptypes => \@ptypes,
		_plens => \@plens,
		_packstr => $ipackstr,
		_usenames => \@usenames,
		_usephs => $usephs,
		_parmdesc => \@parmdesc,
		_parmmap => {},
		_parmnum => \$parmnum,
		_phnum => \$phnum,
	);
	my $stmtinfo = $sthargs{tdat_stmt_info};
	while ($curpos < $rsplen) {
		($f, $l, $pclhdrsz) = _getPclHeader($$rspmsg, $curpos);
		$curpos += $l , next
			if (($f == 11) || ($f == 12));
		if ($f == 8) {
			($stmtno, $rowcnt, $warncode, $fldcount, $activity, $warnlen) =
				unpack('SLSSSS', substr($$rspmsg, $curpos+$pclhdrsz, 14));
			$stmtinfo->[$stmtno]{ActivityType} = ($td_activity_types{$activity}) ?
				$td_activity_types{$activity} : 'Unknown';
			$stmtinfo->[$stmtno]{ActivityCount} = $rowcnt;
			$sthargs{tdat_unpackstr}[$nextcol] = '';
			$stmtinfo->[$stmtno]{Warning} = "Warning $warncode: " .
				substr($rspmsg, 18, $warnlen)
				if $warnlen;
			$curpos += $l;
			next;
		}
		if (($f == 9) || ($f == 49)) {
			($stmtno, $rowcnt, $tderr, $tdelen) =
				unpack('SSSS', substr($$rspmsg, $curpos+$pclhdrsz, 8));
			my $tdemsg = substr($$rspmsg, $curpos+$pclhdrsz+8, $tdelen);
			DBI->trace_msg("ERROR $tderr\: $tdemsg\n", 2);
			$obj->io_set_error($tderr,
				(($f == 9) ? 'Failure' : 'Error') .
					" $tderr\: $tdemsg on Statement $stmtno.");
			$stmtinfo->[$stmtno]{SummaryStarts} =
				$stmtinfo->[$stmtno]{SummaryEnds} =
				$stmtinfo->[$stmtno]{StartAt} =
				$stmtinfo->[$stmtno]{EndsAt} = undef;
			return undef;
		}
		return $obj->io_set_error("Invalid parcel stream: got $f when PREPINFO expected.")
			if ($f != 86);
		$nextcol = $obj->io_proc_prepinfo(
			substr($$rspmsg, $curpos+$pclhdrsz, $l - $pclhdrsz),
			$stmtno, \%sthargs, $activity, $is_a_call, $nextcol);
		$curpos += $l;
	}
	DBI->trace_msg("Session $obj->[13] PREPAREd $dbreq\n", 1)
		if $debug;
	$$passthru = undef
		if defined($passthru);
	$sthargs{NUM_OF_FIELDS} = scalar @{$sthargs{NAME}};
	$sthargs{NUM_OF_PARAMS} = $usingvars || $usephs;
	return &$make_sth($dbh, \%sthargs);
}
sub io_proc_prepinfo {
	my ($obj, $pcl, $stmtno, $sthargs, $activity, $is_a_call, $nextcol) = @_;
	my $curpos = 0;
	my ($sumcnt, $colcnt) = unpack('SS', substr($pcl, 8, 4));
	my $packstr = '';
	my $stmtinfo = $sthargs->{tdat_stmt_info}[$stmtno];
	$stmtinfo->{StartsAt} = $stmtinfo->{StartsAt} = undef,
	return $nextcol
		unless $colcnt || $sumcnt;
	my ($phnum, $parmnum, $parmdesc, $parmmap) =
		($sthargs->{_phnum}, $sthargs->{_parmnum}, $sthargs->{_parmdesc}, $sthargs->{_parmmap});
	my ($datatype, $datalen, $cname, $cfmt, $ctitle);
	$curpos += 12;
	$stmtinfo->{StartsAt} = $nextcol;
	$stmtinfo->{EndsAt} = $nextcol + $colcnt - 1;
	my $nextsum = 0;
	$stmtinfo->{SummaryStarts} = [ 0 ],
	$stmtinfo->{SummaryEnds} = [ 0 ]
		if $sumcnt;
	while (1) {
		for (my $i = 0; $i < $colcnt; $i++, $nextcol++) {
			($datatype, $datalen, $cname, $cfmt, $ctitle) =
				unpack('SS S/a S/a S/a', substr($pcl, $curpos));
			$curpos += (4 +
				2 + length($cname) +
				2 + length($cfmt) +
				2 + length($ctitle));
			if ($activity == 105) {
				$datatype -= 500;
				if ($is_a_call) {
					$$phnum++
						if ($$parmdesc[$$parmnum] & 1);
					$$parmnum++,
					$nextcol--,
					next
						unless ($datatype & 3);
					$$parmdesc[$$parmnum] |= 4;
					$$parmmap{$$phnum} = $nextcol
						if ($$parmdesc[$$parmnum] & 1);
					$$parmnum++;
					$stmtinfo->{EndsAt} = $nextcol;
				}
				$datatype &= 0xfffc;
			}
			$sthargs->{NAME}[$nextcol] = ($cname eq '') ?
				(($ctitle eq '') ? "COLUMN$nextcol" : $ctitle) :
				$cname;
			my $ttype = $sthargs->{TYPE}[$nextcol] =
				$td_type_code2dbi{$datatype & 0xfffe};
			$sthargs->{NULLABLE}[$nextcol] = ($activity == 105) ?
				1 : $datatype & 1;
			$sthargs->{tdat_TITLE}[$nextcol] = $ctitle;
			$cfmt = uc $cfmt;
			$cfmt = '-(' . (length($1) + 1) . ")$2"
				if ($cfmt=~/^(-+)(.*)/);
			$sthargs->{tdat_FORMAT}[$nextcol] = $cfmt;
			my $prec = $sthargs->{PRECISION}[$nextcol] = ($ttype == 3) ?
				(($datalen >> 8) & 31) : $datalen;
			my $scale = $sthargs->{SCALE}[$nextcol] = ($ttype == 3) ?
				($datalen & 255) : 0;
			my $len = ($ttype == 3) ? $td_decszs[$prec] : $datalen;
			$packstr .=
				(($ttype == -2) || ($ttype == 3)) ? "a$len " :
				(($ttype == 1)								? "A$len " :
					($td_type_dbi2pack{$ttype}) . ' ');
			$sthargs->{tdat_FORMAT}[$nextcol] = "6($prec)"
				if ($ttype == -2) || ($ttype == -3);
			my $typestr = $td_type_dbi2str{$ttype};
			$typestr .= '(' . $prec .
				(($ttype == 3) ? ", $scale)" : ')')
				if $td_type_str2baseprec{$typestr};
			$sthargs->{tdat_TYPESTR}[$nextcol] = $typestr;
			DBI->trace_msg(
				($ttype != 3) ?
		"$sthargs->{NAME}[$nextcol]\: $ttype LENGTH $prec\n" :
		"$sthargs->{NAME}[$nextcol]\: DECIMAL($prec, $scale) LENGTH $td_decszs[$len]\n",
					1)
				if $debug;
		}
		my $packidx = $nextsum ? $stmtinfo->{SummaryStarts}[$nextsum - 1] : $stmtinfo->{StartsAt};
		$packstr=~s/\*//g;
		$sthargs->{_unpackstr}[$packidx] = $packstr;
		$packstr = '';
		last unless $sumcnt;
		$colcnt = unpack('S', substr($pcl, $curpos));
		$stmtinfo->{SummaryStarts}[$nextsum] = $nextcol;
		$stmtinfo->{SummaryEnds}[$nextsum] = $nextcol + $colcnt - 1;
		$nextsum++;
		$curpos += 2;
		$sumcnt--;
	}
	return $nextcol;
}
sub io_execute {
	my ($obj, $sth, $datainfo, $indicdata, $rowid) = @_;
	$obj->[18] = 0;
	$obj->[24] = '00000';
	$obj->[17] = '';
	my $stmtinfo = $sth->{tdat_stmt_info};
	my $stmtno = $sth->{tdat_stmtno};
	my $nowait = $sth->{tdat_nowait};
	my $stmt = $sth->{Statement} || '';
	my $keepresp = ($sth->{tdat_keepresp} || ($stmt=~/\s+FOR\s+CURSOR\s*$/i));
	my $rawmode = $sth->{tdat_raw_in};
	my $reqmsg = '';
	my $reqlen = 0;
	my $modepcl = ($rawmode && defined($rawmodes{$rawmode})) ?
		$rawmodes{$rawmode} : 68;
	my $partition = $obj->[19];
	my $reqfac = $obj->[38];
	$stmt=~s/\s+WHERE\s+CURRENT\s+OF\s+([^\s;]+)\s*;?\s*$/ WHERE CURRENT/i;
	my $forCursor = ($stmt=~/\s+WHERE\s+CURRENT$/i) && $rowid;
	if (($partition == 1) ||
		(($partition == 6) && ($stmt ne ';'))) {
		$reqlen = 4 + length($stmt) + 6 +
			((defined($datainfo) && length($datainfo)) ? 4 + length($datainfo) : 0) +
			((defined($indicdata) && length($indicdata)) ? 4 + length($indicdata) : 0) +
			($forCursor ? 4 + length($rowid) : 0) +
			($sth->{tdat_mload} ? 14 : 0);
		if ($reqlen > 65535) {
			$reqlen += 4 + 4 + (length($datainfo) ? 4 : 0) +
				(length($indicdata) ? 4 : 0) + (($forCursor && $rowid) ? 4 : 0);
			$obj->[26] = 1;
		}
		else {
			$obj->[26] = undef;
		}
	}
	if ($sth->{Statement}=~/^\s*(CREATE|REPLACE)\s+PROCEDURE\s+/i) {
		my $pos = 0;
		my $segment = 1;
		my $len = length($sth->{Statement});
		my $sz = 0;
		while ($len) {
			$sz = ($len > 64000) ? 64000 : $len;
			$len -= $sz;
			($reqmsg, $pos) = $reqfac->spRequest($obj, $sz, $pos, $segment, $sth, $obj->[3]);
			$segment++;
			my $treqno = $obj->[2];
			$obj->io_quicksend(length($reqmsg), undef, $reqmsg) or return undef;
			$obj->[1]{$treqno} = $sth;
			$sth->{_p}[12] = $treqno;
			last unless $len;
			return undef unless defined($obj->io_Realize($sth));
		}
		return ($nowait ? -1 : $obj->io_Realize($sth));
	}
	return $obj->io_set_error('Maximum request size exceeded.')
		if ($obj->[40] < 5000000) && ($reqlen > 65535);
	if ($partition == 1) {
		$reqmsg = $reqfac->sqlRequest($obj, $sth, $forCursor, $rowid, $modepcl, $keepresp,
			$obj->[3], $stmt, $datainfo, $indicdata);
	}
	delete $obj->[1]{$_}
		foreach (keys %{$obj->[1]});
	my $treqno = $obj->[2];
	if (($partition == 5) || ($partition == 4)) {
		$obj->io_quicksend($obj->[32], undef, $obj->[16])
			or return undef;
	}
	else {
		$obj->io_tdsend($reqmsg) or return undef;
	}
	$obj->[1]{$treqno} = $sth;
	$sth->{_p}[12] = $treqno;
	return ($nowait) ? -1 : $obj->io_Realize($sth);
}
sub io_fetch {
	my ($obj, $sth, $ary, $retstr) = @_;
	$obj->[18] = 0;
	$obj->[24] = '00000';
	$obj->[17] = '';
	my $sthp = $sth->{_p};
	return 0 unless $sthp->[17];
	my $maxlen = ($ary) ? $sthp->[14] : 1;
	my $stmtno = $sth->{tdat_stmt_num};
	my ($f, $l, $failed) = (0,0,0,0);
	my $rspmsg = $sthp->[17];
	my $pos = $sthp->[19];
	my $rsplen = ($$rspmsg) ? length($$rspmsg) : 0;
	my $partition = $obj->[19];
	my $stmtinfo = $sth->{tdat_stmt_info};
	my $stmthash = ($stmtno) ? $$stmtinfo[$stmtno] : undef;
	my $endstmt = 0;
	my $total_activity = 0;
	my $arycnt = 0;
	if ($pos >= $rsplen) {
		$rspmsg = $obj->io_tdcontinue($sth, 0);
		return 0 unless $$rspmsg;
		$sthp->[17] = $rspmsg;
		$rsplen = length($$rspmsg);
		$obj->io_tdcontinue($sth, 1)
			if (! $sthp->[22]) && $obj->[14];
		$pos = 52;
	}
	my ($pclhdrsz, $rowcnt, $tderr, $fldcount, $activity, $tdelen, $tdemsg);
	($f, $l, $pclhdrsz) = _getPclHeader($$rspmsg, $pos);
	$sth->{tdat_more_results} = 1;
	while (($f != 10) && ($f != 105)) {
		$sthp->[19] = $pos + $l;
		if ($f == 12) {
			$sthp->[17] = undef;
			$sthp->[19] = 0;
			$sth->{tdat_more_results} = 0;
			$obj->io_tddo('COMMIT WORK'),
			$obj->[11] = 0
				if ($obj->[10] eq 'ANSI') &&
					$obj->[11] && $obj->[31]{AutoCommit};
			$sth->{tdat_more_results} = 0,
			delete $obj->[1]{$sthp->[12]},
			$sthp->[12] = 0,
				unless ($obj->[19] == 3) ||
					$sth->{tdat_keepresp};
			return $total_activity;
		}
		elsif (($f == 9) || ($f == 49)) {
			($stmtno, $rowcnt, $tderr, $tdelen) =
				unpack('SSSS', substr($$rspmsg, $pos+$pclhdrsz, 8));
			$tdemsg = substr($$rspmsg, $pos+$pclhdrsz+8, $tdelen);
			DBI->trace_msg("ERROR $tderr\: $tdemsg\n", 2);
			$obj->io_set_error($tderr,
				(($f == 9) ? 'Failure' : 'Error') .
					" $tderr\: $tdemsg on Statement $stmtno.");
			$sth->{tdat_stmt_num} = $stmtno;
			$stmthash = $$stmtinfo[$stmtno];
			$stmthash->{ErrorCode} = $tderr;
			$stmthash->{ErrorMessage} = $tdemsg;
			$obj->[11] = 0
				if ($obj->[10] ne 'ANSI');
			delete $obj->[1]{$sthp->[12]},
			$sthp->[12] = 0,
			$sthp->[17] = undef,
			$sthp->[19] = 0,
			$sth->{tdat_more_results} = 0,
			$sthp->[22] = 1,
			return undef
				if ($obj->[10] ne 'ANSI') ||
					($stmtno == $#{$sth->{tdat_stmt_info}});
		}
		elsif ($f == 8) {
			($stmtno, $rowcnt, $tderr, $fldcount, $activity, $tdelen) =
				unpack('SLSSSS', substr($$rspmsg, $pos+$pclhdrsz, 14));
			$stmtno++ unless $stmtno;
			$stmthash = $$stmtinfo[$stmtno];
			$stmthash->{ActivityType} = ($td_activity_types{$activity}) ?
				$td_activity_types{$activity} : 'Unknown';
			$stmthash->{ActivityCount} = $rowcnt;
			$total_activity += $rowcnt;
			delete $stmthash->{Warning};
			$stmthash->{Warning} =
	"Warning $tderr\: " . substr($$rspmsg, $pos+$pclhdrsz+14, $tdelen)
				if $tdelen;
			$sth->{tdat_stmt_num} = $stmtno;
		}
		elsif ($f == 17) {
			($stmtno, $fldcount, $rowcnt, $activity, $tderr, $tdelen) =
				unpack('SSLSSS', substr($$rspmsg, $pos+$pclhdrsz, 14));
			$stmtno++ unless $stmtno;
			$stmthash = $$stmtinfo[$stmtno];
			$stmthash->{ActivityType} = ($td_activity_types{$activity}) ?
				$td_activity_types{$activity} : 'Unknown';
			$stmthash->{ActivityCount} = $rowcnt;
			$total_activity += $rowcnt;
			delete $stmthash->{Warning};
			$stmthash->{Warning} =
		"Warning $tderr\: " . substr($$rspmsg, $pos+$pclhdrsz+14, $tdelen)
				if $tdelen;
			$sth->{tdat_stmt_num} = $stmtno;
		}
		elsif ($f == 33) {
			$stmthash->{IsSummary} = (unpack('S',
				substr($$rspmsg, $pos+$pclhdrsz)) - 1);
			$stmthash->{SummaryPosition} = [ ],
			$stmthash->{SummaryPosStart} = [ ]
				unless defined($stmthash->{SummaryPosition});
		}
		elsif ($f == 35) {
			delete $stmthash->{IsSummary};
		}
		elsif ($f == 46) {
			my $sumpos = $stmthash->{SummaryPosition};
			my $sumstart = $stmthash->{SummaryPosStart};
			push(@$sumstart, scalar(@$sumpos));
		}
		elsif ($f == 34) {
			my $sumpos = $stmthash->{SummaryPosition};
			push(@$sumpos, (unpack('S', substr($$rspmsg, $pos+$pclhdrsz))));
		}
		elsif ($f == 29) {
			$stmthash->{Prompt} = 1;
			$obj->[6] = 1;
		}
		elsif ($f == 11) {
			delete $stmthash->{SummaryPosStart};
			delete $stmthash->{SummaryPosition};
			$endstmt = 1;
		}
		elsif (($f == 71) && (exists $stmthash->{ActivityType}) &&
			(($stmthash->{ActivityType} eq 'Help') ||
			($stmthash->{ActivityType} eq 'Call') ||
			($stmthash->{ActivityType} eq 'Monitor SQL') ||
			(($stmthash->{ActivityType} eq 'Monitor Session') &&
				($stmtno > 1)))) {
			my $rc = $obj->io_proc_datainfo($sth,
				substr($$rspmsg, $pos+$pclhdrsz, $l - $pclhdrsz),
					$stmtno);
			DBI->trace_msg("ERROR -1: DATAINFO for unexpected statement\n", 2),
			return $obj->io_set_error("Failure -1: DATAINFO for unexpected Statement $stmtno.")
				if ($rc == -1);
			DBI->trace_msg("ERROR -2: DATAINFO does not match defined fields.\n", 2),
			return $obj->io_set_error(-2,
				"Failure -2: DATAINFO does not match defined fields for Statement $stmtno.")
				if ($rc == -2);
		}
		elsif ($f == 121) {
			$sthp->[6] = substr($$rspmsg, $pos+$pclhdrsz,
				$l - $pclhdrsz) . pack('L', $sthp->[12]);
		}
		elsif (($f == 20) ||
			($f == 22) ||
			($f == 24)) {
			$sthp->[25] = 1;
		}
		elsif (($f == 21) ||
			($f == 23) ||
			($f == 25)) {
			$sthp->[25] = undef;
		}
		elsif ($f == 18) {
			push @{$sthp->[7]},
				substr($$rspmsg, $pos+$pclhdrsz, $l - $pclhdrsz)
				unless $sthp->[25];
		}
		elsif ($f == 19) {
			push @{$sthp->[7]}, undef
				unless $sthp->[25];
		}
		elsif ($f == 27) {
			last unless $retstr;
			$sthp->[7] = [ ];
			$arycnt++ if defined($ary);
		}
		elsif ($f == 28) {
			last if $endstmt;
			$$retstr = $sthp->[7],
			$sthp->[19] = $pos + $l,
			$sthp->[7] = undef,
			return 1
				unless defined($ary);
			push (@$ary, $sthp->[7]);
			$f = 32;
			$sthp->[7] = undef;
			$sthp->[19] = $pos + $l,
			$#$ary = $maxlen - 1,
			return $maxlen
				if ($arycnt == $maxlen);
		}
		elsif (($f != 71) &&
			($f != 47) && ($f != 26)) {
			$obj->io_set_error("Received bad parcel $f.");
			delete $obj->[1]{$sthp->[12]};
			$sthp->[12] = 0;
			$sthp->[17] = undef;
			$sthp->[19] = 0;
			$sth->{tdat_more_results} = 0;
			return undef;
		}
		$pos += $l;
		if (($pos >= $rsplen) && ( ! $sthp->[22])) {
			$rspmsg = $obj->io_tdcontinue($sth, 0);
			return 0 unless $rspmsg;
			$sthp->[17] = $rspmsg;
			$rsplen = length($$rspmsg);
			$pos = 52;
			$obj->io_tdcontinue($sth, 1)
				if (! $sthp->[22]) && $obj->[14];
			$pos = 52;
		}
		($f, $l, $pclhdrsz) = _getPclHeader($$rspmsg, $pos);
	}
	$sthp->[19] = $pos,
	return $total_activity
		unless $retstr;
	if ($endstmt) {
		$sthp->[19] = $pos;
		return 0
			unless defined($ary) && $arycnt;
		push (@$ary, $sthp->[7]);
		$sthp->[7] = undef;
		$sthp->[19] = $pos + $l;
		$#$ary = $arycnt - 1;
		return $arycnt;
	}
	if (defined($ary)) {
		$#$ary = $arycnt - 2,
		return $arycnt
			if $sthp->[7];
		my $i = 0;
		while (($i < $maxlen) && ($pos < $rsplen) && ($f == 10)) {
	 		$$ary[$i] = pack('Sa*c', $l-$pclhdrsz,
	 			substr($$rspmsg, $pos+$pclhdrsz, $l - $pclhdrsz), 10),
			$pos += $l;
			($f, $l, $pclhdrsz) = _getPclHeader($$rspmsg, $pos)
				unless ($pos >= $rsplen);
			$i++;
		}
		$sthp->[19] = $pos;
		$#$ary = $i-1;
		return $i;
	}
	$sthp->[19] = $pos + $l,
	return 0
		if $sthp->[7];
	$$retstr = substr($$rspmsg, $pos+$pclhdrsz, $l - $pclhdrsz);
	$sthp->[19] = $pos + $l;
	return 1;
}
sub io_commit {
	while ($_[0]->[11]) {
		return undef
			unless defined($_[0]->io_tddo($_[0]->[7]));
		$_[0]->[11] = 0;
	}
	return 1;
}
sub io_rollback {
	return $_[0]->io_tddo($_[0]->[8]);
}
sub io_err {
	return $_[0]->[18];
}
sub io_errstr {
	return $_[0]->[17];
}
sub io_state {
	return $_[0]->[24];
}
sub io_finish {
	my ($obj, $sth) = @_;
	my $reqno = $sth->{_p}[12];
	my $running = (($reqno) && ($obj->[23] == $reqno));
	return 1 if (! $running) && $sth->{_p}[22] &&
		(! $sth->{tdat_keepresp});
	if ($obj->[15]) {
			$obj->[15]->cli_end_request($reqno);
	}
	delete $obj->[1]{$reqno};
	return 1;
}
sub io_cancel {
	my ($obj, $sth) = @_;
	my $reqno = $sth->{_p}[12];
	my $running = ($reqno && ($obj->[23] == $reqno));
	return 1 if (! $running) && $sth->{_p}[22] &&
		(! $sth->{tdat_keepresp});
		($running) ? $obj->[15]->cli_abort_request($reqno) :
			$obj->[15]->cli_end_request($reqno);
	$obj->io_getcliresp,
	delete $obj->[1]{$reqno}
		unless $sth->{tdat_nowait};
	return 1;
}
sub io_FirstAvailList {
	my ($sesslist, $timeout) = @_;
	my $i = 0;
	my $rmask = '';
	my $wmask = '';
	my $emask = '';
	my ($rout, $wout, $eout);
	my %fdhash = ();
	my @avails = ();
	my @clilist = ();
	my %seshash = ();
	foreach my $obj (@$sesslist) {
		$i++, next unless defined($obj);
		$fdhash{$obj} = $i++,
		vec($rmask, $obj, 1) = 1,
		next
			unless (ref $obj);
		push(@avails, $i++),
		next
			unless $obj->[23];
		push (@clilist, $i++);
	}
	return ($#avails < 0) ? undef : @avails
		if ($rmask eq '') && ($#clilist < 0);
	my $started = time();
	$timeout = undef
		if defined($timeout) && ($timeout < 0);
	my $lcltimeout = ($#clilist >= 0) ? 0 : $timeout;
	if ($rmask ne '') {
		$wmask = 0;
		$emask = $rmask;
		my $n = select($rout=$rmask, undef, $eout=$emask, $lcltimeout);
		return ($#avails < 0) ? undef : @avails
			if ($n <= 0) && ($#clilist < 0);
		foreach (keys(%fdhash)) {
			push(@avails, $fdhash{$_})
				if vec($rout, $_, 1) || vec($eout, $_, 1);
		}
	}
	return (($#avails >= 0) ? @avails : undef)
		unless ($#clilist >= 0);
	my @sesobjs = ();
	my ($obj, $reqid, $keepresp);
	$obj = $sesslist->[$_],
	$reqid = $obj->[23],
	$keepresp = ($obj->[1] && (exists $obj->[1]{$reqid})) ?
		$obj->[1]{$reqid}{tdat_keepresp} : undef,
	push(@sesobjs,
		$_,
		$obj->[15],
		$reqid,
		$keepresp)
		foreach (@clilist);
	my @list = DBD::Teradata::Cli::cli_wait_for_response($timeout, @sesobjs);
	push @avails, @list;
	return ($#avails >= 0) ? @avails : undef;
}
sub io_Realize {
	my ($obj, $sth) = @_;
	my $rspmsg = $obj->io_getcliresp($sth);
	return undef unless $rspmsg;
	$obj->io_tdcontinue($sth, 1)
		if (! $sth->{_p}[22]) && $obj->[14];
	my $rc = $obj->io_fetch($sth, undef, undef);
	$sth->{Active} = undef,
	return undef
		unless defined($rc);
	return $rc;
}
sub io_proc_datainfo {
	my ($obj, $sth, $pcl, $stmtno) = @_;
	my $flds = 2 * unpack('S', $pcl);
	my $descr = "S$flds";
	$flds /= 2;
	my @diflds = unpack($descr, substr($pcl,2));
	my @ftype = ();
	my @ftypestr = ();
	my @fprec = ();
	my @fscale = ();
	my @fnullable = ();
	my @packstrs = ();
	my $prec = 0;
	my $stmtinfo = $sth->{tdat_stmt_info};
	my $names = $sth->{NAME};
	my $stmthash = $$stmtinfo[$stmtno];
	return -1 unless $stmthash;
	my ($i, $j, $t);
	my $starts = $stmthash->{StartsAt};
	for ($i = $starts, $j = 0; $i < ($starts + $flds);
		$i++, $j += 2) {
		$t = $diflds[$j],
		$diflds[$j] = (($t & 0xFF)<<8) + ($t>>8),
		$t = $diflds[$j + 1],
		$diflds[$j + 1] = (($t & 0xFF)<<8) + ($t>>8)
			if ($diflds[$j] > 1300);
		$diflds[$j] -= 500 if ($diflds[$j] > 800);
		$diflds[$j] &= 0xfffd;
		last unless defined($td_type_code2str{($diflds[$j] & 0xfffe)});
		if ($i > $stmthash->{EndsAt}) {
			print "Got $flds valid fields, but expected only ",
				($stmthash->{EndsAt} - $starts + 1),
				" expected.\n";
			return -2;
		}
		$ftype[$i] = $td_type_code2dbi{($diflds[$j] & 0xfffe)};
		$ftypestr[$i] = $td_type_code2str{($diflds[$j] & 0xfffe)};
		$fnullable[$i] = ($diflds[$j] & 1);
		my $len = $diflds[$j+1];
		$fprec[$i] = ($ftype[$i] == 3) ?
			(($len >> 8) & 0xFF) : $len;
		$fscale[$i] = ($ftype[$i] == 3) ? ($len & 0xFF) : 0;
		$prec = ($ftype[$i] == 3) ?
			$td_decszs[(($len >> 8) & 31)] : $len;
		$packstrs[$starts] .=
			(($ftype[$i] == -2) || ($ftype[$i] == 3)) ?
				"a$prec " :
			($ftype[$i] == 1) ? "A$prec " :
				$td_type_dbi2pack{$ftype[$i]} . ' ';
		$ftypestr[$i] .= '(' . $fprec[$i] .
			(($ftype[$i] == 3) ? "$fscale[$i])" : ')')
			if defined($td_type_str2baseprec{$ftypestr[$i]});
	}
	$sth->{TYPE} = \@ftype;
	$sth->{PRECISION} = \@fprec;
	$sth->{SCALE} = \@fscale;
	$sth->{NULLABLE} = \@fnullable;
	$sth->{tdat_TYPESTR} = \@ftypestr;
	$sth->{_p}[10] = \@packstrs;
	return $flds;
}
sub io_rewind {
	my ($obj, $sth) = @_;
	return undef
		unless ($obj->[19] == 1) &&
			$sth->{_p}[26] && $sth->{tdat_keepresp};
	my $reqno = $sth->{_p}[12];
	$obj->[14] = 0;
	return undef if $obj->[23] && (! $obj->io_getcliresp);
	$sth->{_p}[17] = undef;
	$sth->{_p}[19] = undef;
	my $reqmsg = $obj->[38]->rewindRequest($obj, $reqno, $obj->[3])
		or return undef;
	$obj->io_tdsend($reqmsg) or return undef;
	return $sth->{tdat_nowait} ? -1 : $obj->io_Realize($sth);
}
sub io_clone {
	$inited = 0;
	return 1;
}
1;

=pod

=head1 NAME

DBD::Teradata - DBI driver for Teradata

=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect('dbi:Teradata:hostname', 'user', 'password');

See L<DBI> for more information.

=head1 DESCRIPTION

Refer to the included doc/index.html, or
L<http://www.presicient.com/tdatdbd> for detailed information.

B<NOTE>: This version has been deprecated in favor of the more complete
and maintained GPL version available at L<http://www.presicient.com/tdatdbd>.

=head2 PREREQUISITES

Install Perl (minimum version 5.8).

Build, test and install the DBI module (minimum version 1.36).

Remember to *read* the DBI README, this README, and the included
doc/index.html CAREFULLY!

I had a lot of info to distill, and POD, though quaint and
convenient for READMEs like this, just isn't as expressive
as HTML...hence doc/index.html. Please refer to doc/index.html for
detailed usage information.

=head2 *** BUILDING:

=head3 NOTE

The provided test suite is not suitable for normal Perl
"make test", as it requires a Teradata database and a username
and password for an account with various privileges (e.g.,
CREATE PROCEDURE).

After installing, you can verify the install by running

	perl t/test.pl <host> <user> <password>

where <host> is the name of your Teradata server. NOTE that
CLI does NOT support numeric IP addresses, nor addresses with the
COPn suffix already applied, i.e.,

	perl t/test.pl 129.123.345.78 dbc dbc   # WRONG

	perl t/test.pl DBCCOP1 dbc dbc          # WRONG

	perl t/test.pl DBC dbc dbc              # RIGHT!

=head3 Building For Microsoft Windows

You'll need the nmake utility, available with the various
Visual Studio tools. You'll also need to make sure your
command prompt is configured to find nmake; see the Visual
Studio documents for how to do that.

To build:

    perl Makefile.pl	# use a perl that's in your PATH
    nmake
    nmake install


=head3 Building For UNIX/Linux

    perl Makefile.pl	# use a perl that's in your PATH
    make
    make install

=head2 IF YOU HAVE PROBLEMS

Please read the doc/index.html file which includes important
information, including tips and workarounds for various
platform-specific problems.

=head2 SUPPORT INFORMATION

For the latest DBD::Teradata information, please see
L<http://www.presicient.com/tdatdbd.html>.

Bug reports/Comments/suggestions/enhancement requests may be sent to
L<mailto:support@presicient.com>.

B<Please note:> This free version of DBD::Teradata is a minimal
implementation of the commercially supported version. Refer to
L<http://www.presicient.com/tdatdbd> for details on the differences.

=head3 MAILING LISTS

As a user or maintainer of a local copy of DBD::Teradata, you need
to be aware of the following addresses:

The DBI mailing lists located at

	dbi-announce@perl.org          for announcements
	dbi-dev@perl.org               for developer/maintainer discussions
	dbi-users@perl.org             for end user level discussion and help

Refer to L<http://dbi.perl.org/support/> for details on subscribing to these lists.

=head2 COPYRIGHT, AUTHOR, and LICENSE

Copyright(C) 2001-2007, Presicient Corporation, USA.
All rights reserved.

Permission is granted to use this software according to the terms of the
L<Perl Artistic License|perlartistic>, as specified in the Perl README file,
B<with the exception> that commercial redistribution, either
electronic or via physical media, as either a standalone package,
or incorporated into a third party product, requires prior
written approval of the copyright holder.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Presicient Corp. reserves the right to provide support for this software
to individual sites under a separate (possibly fee-based)
agreement.

Teradata(R) is a registed trademark of NCR Corporation.

=cut
package DBD::Teradata::Diagnostic;
use Time::HiRes qw(time);
use Exporter;
our @ISA = qw(Exporter);
use strict;
use warnings;
our @EXPORT    = qw(
	io_hexdump
	io_hdrdump
	io_pcldump);
our @EXPORT_OK = qw(
	@td_pclstrings
	%td_msgkind_map);
our @td_pclstrings = qw(
Unknown PclREQUEST PclRSUP PclDATA PclRESP PclKEEPRESP PclABORT PclCANCEL
PclSUCCESS PclFAILURE PclRECORD PclENDSTATEMENT PclENDREQUEST PclFMREQ
PclFMRSUP PclVALUE PclNULLVALUE PclOK PclFIELD PclNULLFIELD PclTITLESTART
PclTITLEEND PclFORMATSTART PclFORMATEND PclSIZESTART PclSIZEEND PclSIZE
PclRECSTART PclRECEND PclPROMPT PclENDPROMPT PclREWIND PclNOP PclWITH
PclPOSITION PclENDWITH PclLOGON PclLOGOFF PclRUN PclRUNRESP PclUCABORT
PclHOSTSTART PclCONFIG PclCONFIGRESP PclSTATUS PclIFPSWITCH PclPOSSTART
PclPOSEND PclBULKRESP PclERROR PclDATE PclROW PclHUTCREDBS PclHUTDBLK
PclHUTDELTBL PclHUTINSROW PclHUTRBLK PclHUTSNDBLK PclENDACCLOG PclHUTRELDBCLK
PclHUTNOP PclHUTBLD PclHUTBLDRSP PclHUTGETDDT PclHUTGETDDTRSP PclHUTIDX
PclHUTIDXRSP PclFIELDSTATUS PclINDICDATA PclINDICREQ Unknown PclDATAINFO
PclIVRSUP Unknown Unknown Unknown Unknown Unknown Unknown Unknown Unknown
Unknown Unknown Unknown Unknown PclOPTIONS PclPREPINFO Unknown PclCONNECT
PclLSN PclCOMMIT Unknown Unknown Unknown Unknown Unknown Unknown Unknown
Unknown Unknown PclASSIGN PclASSIGNRSP PclMLOADCTRL Unknown PclMLOAD PclERRORCNT
PclSESSINFO PclSESSINFORESP Unknown Unknown Unknown Unknown Unknown Unknown
PclSESSOPT PclVOTEREQUEST PclVOTETERM PclCMMT2PC PclABRT2PC PclFORGET
PclCURSORHOST PclCURSORDBC PclFLAGGER PclXINDICREQ PclPREPINFOX Unknown Unknown
Unknown PclMULTITSR PclSPL PclSSOAUTHREQ PclSSOAUTHRESP PclSSOREQ PclSSODOMAIN
PclSSORESP PclSSOAUTHINFO PclUSERNAMEREQ PclUSERNAMERESP Unknown Unknown
PclMULTIPARTDATA PclENDMULTIPARTDATA PclMULTIPARTINDICDATA PclENDMULTIPARTINDICDATA
PclMULTIPARTREC PclENDMULTIPARTREC PclDATAINFOX PclMULTIPARTRSUP PclMULTIPARTREQ
PclELICITDATAMAILBOX PclELICITDATA PclELICITFILE PclELICITDATARECVD PclBIGRESP
PclBIGKEEPRESP Unknown Unknown PclSETPOSITION PclROWPOSITION PclOFFSETPOSITION
Unknown Unknown Unknown PclRESULTSUMMARY PclERRORINFO PclGTWCONFIG PclCLIENTCONFIG
PclAUTHMECH
);

our %td_msgkind_map = qw(
1 COPKINDASSIGN 2 COPKINDREASSIGN 3 COPKINDCONNECT 4 COPKINDRECONNECT 5 COPKINDSTART
6 COPKINDCONTINUE 7 COPKINDABORT 8 COPKINDLOGOFF 9 COPKINDTEST 10 COPKINDCONFIG
11 COPKINDAUTHMETHOD 12 COPKINDSSOREQ 13 COPKINDELICITDATA 255 COPKINDDIRECT
);
our @ebcdics = (
((0) x 64), 1, ((0) x 9), ((1) x 5), 0, 1,
((0) x 9), ((1) x 8), ((0) x 8), ((1) x 6),
((0) x 10), ((1) x 6), 0, ((1) x 9), ((0) x 7),
((1) x 9), ((0) x 7), ((1) x 9), 0,0,0,1, ((0) x 15),
1,0,0, ((1) x 10), ((0) x 6), ((1) x 10), ((0) x 6),
1, 0, ((1) x 8), ((0) x 6), ((1) x 10), ((0) x 6)
);
sub io_hexdump {
	my ($hdr, $buf) = @_;
	my $i = 0;
	my $hexbuf = '';
	my $alphabuf = '';
	my $cval = '';
	my $outstr = $hdr . ":\n";
	for ($i = 0; $i < length($buf); $i++) {
		$outstr .= "$hexbuf	$alphabuf\n",
		$hexbuf = '', $alphabuf = ''
			if ($i%16  == 0);
		$hexbuf .= ' ' . unpack('H2', substr($buf, $i, 1));
		$cval = unpack('C', substr($buf, $i, 1));
			$alphabuf .= ((($cval > 127) || ($cval < 32)) ? '.' : chr($cval));
	}
	$outstr .= "$hexbuf	$alphabuf\n" if (length($hexbuf) > 0);
	$outstr .= "\n";
	return $outstr;
}
sub _fractime {
	my @t = split(/\./, time());
	my $p = scalar localtime($t[0]);
	$p=~s/^\w+\s+(.+?)\s+\d+$/At $1.$t[1]/;
	return $p;
}
sub io_hdrdump {
	my ($hdr, $buf) = @_;
	my $i = 0;
	my $hexbuf = '';
	my $alphabuf = '';
	my $cval = '';
	my ($req, $kind) = unpack('CC', substr($buf, 1, 2));
	$req = ($req == 1) ? 'Sending' : 'Received';
	$kind = $td_msgkind_map{$kind} || 'Unknown kind';
	my ($seg, $len) = unpack('Cxxxn', substr($buf, 4, 6));
	$len += ($seg << 16);
	my ($tdsess, $tdauth1, $tdauth2, $reqno) = unpack('N LL N', substr($buf, 20));
	my $outstr = _fractime() . "\n$hdr $req $kind Session $tdsess Request $reqno: $len bytes:\n";
	for ($i = 0; $i < length($buf); $i++) {
		$outstr .= "$hexbuf	$alphabuf\n",
		$hexbuf = '', $alphabuf = ''
			if ($i%16  == 0);
		$hexbuf .= ' ' . unpack('H2', substr($buf, $i, 1));
		$cval = unpack('C', substr($buf, $i, 1));
			$alphabuf .= ((($cval > 127) || ($cval < 32)) ? '.' : chr($cval));
	}
	$outstr .= "$hexbuf	$alphabuf\n" if (length($hexbuf) > 0);
	return $outstr;
}
sub io_pcldump {
	my ($buf, $len, $encrypted) = @_;
	my $i = 0;
	my $hexbuf = '';
	my $alphabuf = '';
	my ($flavor, $pcllen) = (0,0);
	my $cval;
	my $outstr = '';
	my $pos = 0;
	my $pclhdrsz = 4;
	my $aph = undef;
	while ($pos < $len) {
		$aph = "\n";
		if ($encrypted) {
			$outstr .= "Encrypted Data:\n";
			for ($i = 0; $i < $len; $i++) {
				$outstr .= "$hexbuf	$alphabuf\n" ,
				($hexbuf, $alphabuf) = ('', '')
					if ($i%16 == 0);
				$hexbuf .= ' ' . unpack('H2', substr($buf, $pos + $i, 1));
				$cval = unpack('C', substr($buf, $pos + $i, 1));
				$alphabuf .= (($cval > 127) || ($cval < 32)) ? '.' : chr($cval);
			}
			$outstr .= "$hexbuf	$alphabuf\n" if (length($hexbuf) > 0);
			$hexbuf = '';
			$alphabuf = '';
			$pos += $len;
		}
		else {
			($flavor, $pcllen) = unpack('SS', substr($buf, $pos, 4));
			$pclhdrsz = 4;
			$flavor &= 0x00FF,
			$aph = "\n(APH)",
			$pcllen = unpack('L', substr($buf, $pos+4, 4)),
			$pclhdrsz = 8
				if ($flavor & 0x8000);
			$outstr .= ($flavor <= $#td_pclstrings) ?
				"$aph Parcel $td_pclstrings[$flavor] length $pcllen:\n" :
				"Unknown parcel $flavor length $pcllen:\n";
			$pcllen -= $pclhdrsz;
			$pos += $pclhdrsz;
			for ($i = 0; $i < $pcllen; $i++) {
				$outstr .= "$hexbuf	$alphabuf\n" ,
				($hexbuf, $alphabuf) = ('', '')
					if ($i%16 == 0);
				$hexbuf .= ' ' . unpack('H2', substr($buf, $pos + $i, 1));
				$cval = unpack('C', substr($buf, $pos + $i, 1));
				$alphabuf .= (($cval > 127) || ($cval < 32)) ? '.' : chr($cval);
			}
			$outstr .= "$hexbuf	$alphabuf\n" if (length($hexbuf) > 0);
			$hexbuf = '';
			$alphabuf = '';
			$pos += $pcllen;
		}
	}
	return $outstr . "\n";
}
1;package DBD::Teradata::GetInfo;
use strict;
use DBD::Teradata;
my $sql_driver = 'Teradata';
my $sql_driver_ver = '1.50';
my @Keywords = qw(
ABORT
ABORTSESSION
ABS
ACCESS
ACCESS_LOCK
ACCOUNT
ACOS
ACOSH
ADD_MONTHS
ADMIN
AFTER
AGGREGATE
ALIAS
ALLOCATION
ALWAYS
AMP
ANALYSIS
ANSIDATE
ASCII
ASIN
ASINH
ATAN
ATAN2
ATANH
ATOMIC
ATTR
ATTRIBUTES
ATTRS
AVE
AVERAGE
BEFORE
BLOB
BT
BUT
BYTE
BYTEINT
BYTES
CALL
CALLED
CASESPECIFIC
CASE_N
CD
CHANGERATE
CHAR2HEXINT
CHARACTERS
CHARS
CHARSET_COLL
CHECKPOINT
CHECKSUM
CLASS
CLOB
CLUSTER
CM
COLLECT
COLUMNSPERINDEX
COMMENT
COMPRESS
CONVERT_TABLE_HEADER
CORR
COS
COSH
COSTS
COVAR_POP
COVAR_SAMP
CS
CSUM
CT
CUBE
CV
CYCLE
DATA
DATABASE
DATABLOCKSIZE
DATEFORM
DBC
DEGREES
DEL
DEMOGRAPHICS
DENIALS
DETERMINISTIC
DIAGNOSTIC
DIGITS
DISABLED
DO
DUAL
DUMP
EACH
EBCDIC
ECHO
ELSEIF
ENABLED
EQ
ERROR
ERRORFILES
ERRORTABLES
ET
EXCL
EXCLUSIVE
EXIT
EXP
EXPIRE
EXPLAIN
FALLBACK
FASTEXPORT
FOLLOWING
FORMAT
FREESPACE
FUNCTION
GE
GENERATED
GIVE
GRAPHIC
GROUPING
GT
HANDLER
HASH
HASHAMP
HASHBAKAMP
HASHBUCKET
HASHROW
HELP
HIGH
HOST
IF
IFP
INCONSISTENT
INCREMENT
INDEXESPERTABLE
INITIATE
INOUT
INS
INSTEAD
INTEGERDATE
ITERATE
JIS_COLL
JOURNAL
KANJI1
KANJISJIS
KBYTE
KBYTES
KEEP
KILOBYTES
KURTOSIS
LATIN
LE
LEAVE
LIMIT
LN
LOADING
LOCATOR
LOCK
LOCKEDUSEREXPIRE
LOCKING
LOG
LOGGING
LOGON
LONG
LOOP
LOW
LT
MACRO
MATCHED
MAVG
MAXCHAR
MAXIMUM
MAXLOGONATTEMPTS
MAXVALUE
MCHARACTERS
MDIFF
MEDIUM
MERGE
MINCHAR
MINDEX
MINIMUM
MINUS
MINVALUE
MLINREG
MLOAD
MOD
MODE
MODIFIED
MODIFY
MONITOR
MONRESOURCE
MONSESSION
MSUBSTR
MSUM
MULTINATIONAL
MULTISET
NAME
NAMED
NE
NEW
NEW_TABLE
NOWAIT
NULLIFZERO
OBJECTS
OFF
OLD
OLD_TABLE
ORDERED_ANALYTIC
OUT
OVER
OVERRIDE
PARAMETER
PARTITION
PARTITIONED
PASSWORD
PERCENT
PERCENT_RANK
PERM
PERMANENT
PRECEDING
PRIVATE
PROFILE
PROPORTIONAL
PROTECTED
PROTECTION
QUALIFIED
QUALIFY
QUANTILE
QUERY
RADIANS
RANDOM
RANDOMIZED
RANGE
RANGE_N
RANK
RECALC
REFERENCING
REGR_AVGX
REGR_AVGY
REGR_COUNT
REGR_INTERCEPT
REGR_R2
REGR_SLOPE
REGR_SXX
REGR_SXY
REGR_SYY
RELEASE
RENAME
REPEAT
REPLACE
REPLACEMENT
REPLICATION
REPOVERRIDE
REQUEST
RESTART
RESTORE
RESUME
RET
RETRIEVE
RETURNS
REUSE
REVALIDATE
RIGHTS
ROLE
ROLLFORWARD
ROLLUP
ROW
ROWID
ROW_NUMBER
SAMPLE
SAMPLEID
SAMPLES
SEARCHSPACE
SEL
SETRESRATE
SETS
SETSESSRATE
SHARE
SHOW
SIN
SINH
SKEW
SOUNDEX
SPECCHAR
SPECIFIC
SPOOL
SQLEXCEPTION
SQLTEXT
SQRT
SS
START
STARTUP
STAT
STATEMENT
STATISTICS
STATS
STDDEV_POP
STDDEV_SAMP
STEPINFO
STRING_CS
STYLE
SUBSCRIBER
SUBSTR
SUMMARY
SUSPEND
SYSTEM
SYSTEMTEST
TAN
TANH
TBL_CS
TD_GENERAL
TERMINATE
TEXT
THRESHOLD
TITLE
TPA
TRACE
TRANSLATE_CHK
TRIGGER
TYPE
UC
UNBOUNDED
UNDEFINED
UNDO
UNICODE
UNTIL
UPD
UPPERCASE
USE
VARBYTE
VARGRAPHIC
VAR_POP
VAR_SAMP
VOLATILE
WAIT
WHILE
WIDTH_BUCKET
WITHOUT
ZEROIFNULL
);
sub sql_keywords {
    return join ',', @Keywords;
}
sub sql_data_source_name {
    my $dbh = shift;
    return "dbi:$sql_driver:" . $dbh->{Name};
}
sub sql_server_name {
    my $dbh = shift;
    return $dbh->{Name};
}
sub sql_dbms_ver {
    my $dbh = shift;
    return $dbh->{tdat_version};
}
sub sql_charset {
    my $dbh = shift;
    return $dbh->{tdat_charset};
}
sub sql_user_name {
    my $dbh = shift;
    return $dbh->{CURRENT_USER} || $dbh->{Username};
}
our %info = (
     13 => \&sql_server_name,
     18 => \&sql_dbms_ver,
     20 => 'Y',
     19 => 'N',
      0 => 0,
    116 => 0,
      1 => 16,
    169 => 127,
    117 => 0,
     86 => 3,
  10021 => 2,
    120 => 6,
    121 => 11,
     82 => 0,
    114 => 0,
  10003 => 'N',
     41 => '',
     42 => '',
     92 => 0,
  10004 => \&sql_charset,
     87 => 'Y',
     22 => 0,
     53 => 0,
     54 => 265217,
     55 => 12569,
     56 => 1832891,
     57 => 33033,
     58 => 1581503,
     59 => 8639,
     60 => 8639,
     48 => 1,
    173 => '-1',
     61 => 1679807,
    123 => 1073951,
    124 => 549663,
     71 => 265217,
     62 => 1832891,
     63 => 1581503,
     64 => 8639,
     65 => 1581503,
     66 => 65961,
     67 => 230145,
     68 => 1581503,
     69 => 265217,
     70 => 1832891,
    122 => '-1',
    125 => '-1',
    126 => '-1',
     74 => 1,
    127 => 0,
    128 => 0,
    129 => 0,
    130 => 0,
    131 => 7,
    132 => '-1',
    133 => 0,
    134 => 3,
     23 => 2,
     24 => 2,
  10001 => 1,
      2 => \&sql_data_source_name,
     25 => 'N',
    119 => 65535,
     17 => 'Teradata',
    170 => 3,
     26 => 8,
     26 => 8,
  10002 => '-256',
      3 => 1,
      4 => 1,
      6 => $INC{'DBD/Teradata.pm'},
     77 => '03.52',
      7 => $sql_driver_ver,
    136 => 0,
    137 => 0,
    138 => 0,
    139 => 0,
    140 => 0,
    141 => '-1',
    142 => 0,
    143 => '-1',
    144 => 0,
    145 => 0,
     27 => 'Y',
      8 => 1,
     84 => 0,
    146 => 0,
    147 => 0,
     81 => 11,
     88 => 2,
     28 => 4,
     29 => '"',
    148 => '-1',
    149 => 0,
    172 => '-1',
     73 => 'Y',
    150 => 0,
    151 => 0,
     89 => \&sql_keywords,
    113 => 'Y',
     78 => 1,
     34 => 0,
     97 => 0,
     98 => 64,
     99 => 0,
    100 => 2048,
    101 => 2048,
     30 => 30,
      1 => 16,
     31 => 30,
      0 => 0,
  10005 => 30,
    102 => 0,
    104 => '-1280',
     32 => 30,
    105 => 1047500,
  20000 => '-1',
  20001 => '-1',
  20002 => '-1',
    106 => 0,
     35 => 30,
    107 => 30,
  10022 => '-1',
    112 => 62000,
     34 => 0,
    108 => 31000,
     97 => 0,
     98 => 64,
     99 => 0,
    100 => 2048,
    101 => 2048,
     30 => 30,
      1 => 16,
     31 => 30,
      0 => 0,
  10005 => 30,
    102 => 0,
     32 => 30,
     33 => 30,
     34 => 0,
    104 => '-1280',
    103 => '',
     32 => 30,
    105 => 1047500,
    106 => 0,
     35 => 30,
    107 => 30,
     37 => 'Y',
     36 => 'Y',
    111 => 'N',
     75 => 1,
     85 => 1,
     49 => 85249,
      9 => 2,
    152 => 1,
     12 => 1,
     15 => 1,
     73 => 'Y',
    115 => 127,
     90 => 'N',
     38 => 'Y',
    115 => 127,
     39 => 'DATABASE',
     91 => 31,
    153 => 2,
    154 => 2,
     80 => 0,
     79 => 1,
     21 => 'Y',
     40 => 'MACRO|PROCEDURE',
    114 => 0,
     41 => '',
     42 => '',
     92 => 0,
     93 => 4,
     11 => 'N',
     39 => 'DATABASE',
     91 => 31,
     43 => 3,
     44 => 1,
     14 => '\\',
     94 => '#$',
    155 => 7,
    156 => 0,
    157 => 0,
    158 => '-1',
    159 => 63,
    160 => '-1',
    161 => '-1',
    162 => 32144,
    163 => 0,
    164 => '-1',
    165 => 15,
    118 => '-1',
    166 => 2,
    167 => 0,
    168 => 0,
     83 => 0,
     50 => 7229,
     95 => 23,
     51 => 1,
     45 => 'TABLE',
    109 => 351,
    110 => 350,
     52 => 2064383,
     46 => 1,
     72 => 9,
     46 => 1,
     72 => 9,
     96 => 3,
     96 => 3,
     47 => \&sql_user_name,
  10000 => '-256',
);
1;

package DBD::Teradata::TypeInfo;
require Exporter;
require DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw(type_info_all);
use DBI qw(:sql_types);
our $type_info_all = [
        {
            TYPE_NAME          =>  0,
            DATA_TYPE          =>  1,
            COLUMN_SIZE        =>  2,
            LITERAL_PREFIX     =>  3,
            LITERAL_SUFFIX     =>  4,
            CREATE_PARAMS      =>  5,
            NULLABLE           =>  6,
            CASE_SENSITIVE     =>  7,
            SEARCHABLE         =>  8,
            UNSIGNED_ATTRIBUTE =>  9,
            FIXED_PREC_SCALE   => 10,
            AUTO_UNIQUE_VALUE  => 11,
            LOCAL_TYPE_NAME    => 12,
            MINIMUM_SCALE      => 13,
            MAXIMUM_SCALE      => 14,
            SQL_DATA_TYPE      => 15,
            SQL_DATETIME_SUB   => 16,
            NUM_PREC_RADIX     => 17,
            INTERVAL_PRECISION => 18,
        },
        [ "BYTEINT",                  -6,                  3,    undef,        undef,               undef,             1,0,2,0,    0,0,"BYTEINT",                  0,    0,    -6,  undef,10,undef, ],
        [ "VARBYTE",                  -3,                64000,"'",          "'XB",               "max length",      1,0,0,undef,0,0,"VARBYTE",                  undef,undef,-3,undef,0, undef, ],
        [ "BYTE",                     -2,                   64000,"'",          "'XB",               "max length",      1,0,0,undef,0,0,"BYTE",                     undef,undef,-2,   undef,0, undef, ],
        [ "CHAR",                     1,                     64000,"'",          "'",                 "max length",      1,1,3,undef,0,0,"CHAR",                     undef,undef,1,     undef,0, undef, ],
        [ "DECIMAL",                  3,                  18,   undef,        undef,               "precision, scale",1,0,2,0,    0,0,"DECIMAL",                  0,    18,   3,  undef,10,undef, ],
        [ "INTEGER",                  4,                  10,   undef,        undef,               undef,             1,0,2,0,    0,0,"INTEGER",                  0,    0,    4,  undef,10,undef, ],
        [ "SMALLINT",                 5,                 5,    undef,        undef,               undef,             1,0,2,0,    0,0,"SMALLINT",                 0,    0,    5, undef,10,undef, ],
        [ "FLOAT",                    6,                    15,   undef,        undef,               undef,             1,0,2,0,    0,0,"FLOAT",                    undef,undef,6,    undef,2, undef, ],
        [ "DATE",                     91,                10,   undef,        undef,               undef,             1,0,2,undef,0,0,"DATE",                     0,    0,    9,     1,    0, undef, ],
        [ "TIME",                     92,                8,    undef,        undef,               undef,             1,0,2,undef,0,0,"TIME",                     0,    0,    9,     2,    0, undef, ],
        [ "TIMESTAMP",                93,           26,   "TIMESTAMP '","'",                 "scale",           1,0,2,undef,0,0,"TIMESTAMP",                0,    6,    9,     3,    0, undef, ],
        [ "VARCHAR",                  12,                  64000,"'",          "'",                 "max length",      1,1,3,undef,0,0,"VARCHAR",                  undef,undef,12,  undef,0, undef, ],
        [ "INTERVAL YEAR",            101,            4,    "INTERVAL '", "' YEAR",            "precision",       1,0,2,undef,0,0,"INTERVAL YEAR",            undef,undef,10,     1,    0, 2,     ],
        [ "INTERVAL MONTH",           102,           4,    "INTERVAL '", "' MONTH",           "precision",       1,0,2,undef,0,0,"INTERVAL MONTH",           undef,undef,10,     2,    0, 2,     ],
        [ "INTERVAL DAY",             103,             4,    "INTERVAL '", "' DAY",             "precision",       1,0,2,undef,0,0,"INTERVAL DAY",             undef,undef,10,     3,    0, 2,     ],
        [ "INTERVAL HOUR",            104,            4,    "INTERVAL '", "' HOUR",            "precision",       1,0,2,undef,0,0,"INTERVAL HOUR",            undef,undef,10,     4,    0, 2,     ],
        [ "INTERVAL MINUTE",          105,          4,    "INTERVAL '", "' MINUTE",          "precision",       1,0,2,undef,0,0,"INTERVAL MINUTE",          undef,undef,10,     5,    0, 2,     ],
        [ "INTERVAL SECOND",          106,          11,   "INTERVAL '", "' SECOND",          "precision, scale",1,0,2,undef,0,0,"INTERVAL SECOND",          0,    6,    10,     6,    0, 2,     ],
        [ "INTERVAL YEAR TO MONTH",   107,   7,    "INTERVAL '", "' YEAR TO MONTH",   "precision",       1,0,2,undef,0,0,"INTERVAL YEAR TO MONTH",   undef,undef,10,     7,    0, 2,     ],
        [ "INTERVAL DAY TO HOUR",     108,     7,    "INTERVAL '", "' DAY TO HOUR",     "precision",       1,0,2,undef,0,0,"INTERVAL DAY TO HOUR",     undef,undef,10,     8,    0, 2,     ],
        [ "INTERVAL DAY TO MINUTE",   109,   10,   "INTERVAL '", "' DAY TO MINUTE",   "precision",       1,0,2,undef,0,0,"INTERVAL DAY TO MINUTE",   undef,undef,10,     9,    0, 2,     ],
        [ "INTERVAL DAY TO SECOND",   110,   20,   "INTERVAL '", "' DAY TO SECOND",   "precision",       1,0,2,undef,0,0,"INTERVAL DAY TO SECOND",   0,    6,    10,     10,   0, 2,     ],
        [ "INTERVAL HOUR TO MINUTE",  111,  7,    "INTERVAL '", "' HOUR TO MINUTE",  "precision",       1,0,2,undef,0,0,"INTERVAL HOUR TO MINUTE",  undef,undef,10,     11,   0, 2,     ],
        [ "INTERVAL HOUR TO SECOND",  112,  17,   "INTERVAL '", "' HOUR TO SECOND",  "precision",       1,0,2,undef,0,0,"INTERVAL HOUR TO SECOND",  0,    6,    10,     12,   0, 2,     ],
        [ "INTERVAL MINUTE TO SECOND",113,14,   "INTERVAL '", "' MINUTE TO SECOND","precision",       1,0,2,undef,0,0,"INTERVAL MINUTE TO SECOND",0,    6,    10,     13,   0, 2,     ],
    ];
1;
package DBD::Teradata::Cli;
use Time::HiRes qw(time sleep);
use Exporter;
BEGIN {
	our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = ();
our %EXPORT_TAGS = (
	tdcli_errors => [
	],
);
Exporter::export_tags(keys %EXPORT_TAGS);
}
our $VERSION = '1.52';
use strict;
use warnings;
our %dbc_ctxts = ();
sub CLONE {
	map { $_->[1] = 0; } values %dbc_ctxts;
	%dbc_ctxts = ();
}
sub new {
	my ($class, $logonstr, $mode, $logonsrc, $charset, $debug) = @_;
	my $obj = [ ];
	bless $obj, $class;
	my ($errno, $errstr, $dbc, $hostid, $sessno, $version) =
		(0, '', undef, undef, undef, undef);
	print "cli_connect: initing\n"
		if $debug;
	$dbc = tdxs_init_dbcarea($debug);
	return (undef, -1, "Cannot init dbcarea")
		unless $dbc;
	$obj->[4] = $debug;
	print "cli_connect: connecting $logonstr\n"
		if $debug;
	my $partition = 'DBC/SQL         ';
	my $lsn = 0;
	my $runstring = pack('A16 L S S', $partition, 0, 0, 0);
	($sessno, $hostid, $version, $lsn, $errno, $errstr) =
		tdxs_get_connection($dbc, $logonstr, $mode, $runstring, $logonsrc, $charset);
	unless ($errno) {
		$obj->[1] = $dbc;
		print "cli_connect: connected\n" if $debug;
		$obj->[5] = $sessno;
		$dbc_ctxts{"$sessno\_$$"} = $obj;
		return ($obj, undef, undef, $hostid, $sessno, $version);
	}
	print "cli_connect: didn't connect: $errstr\n"
		if $debug;
	return ($obj, $errno, $errstr, undef, undef, undef, undef);
}
sub cli_get_tdat_release {
	return tdxs_get_tdat_release($_[0]->[1]);
}
sub cli_set_debug {
	tdxs_set_debug($_[0]->[1], $_[1]);
	$_[0]->[4] = $_[1];
}
sub cli_disconnect {
	my ($err, $errstr);
	$err = tdxs_cleanup($_[0]->[1], $errstr)
		if $_[0]->[1];
	$_[0]->[3] = undef;
	$_[0]->[1] = undef;
	delete $dbc_ctxts{$_[0]->[5] . "_$$"};
	1;
}
sub cli_test_leak {
	my $sql = 'sel user,date,time' . (' ' x 4000);
	my $req = pack('a* SSa10 SS a* SS S',
		"\0" x 52,
		85, 14, 'RE',
		1, 4 + length($sql), $sql,
		4, 4 + 2, 64000);
	tdxs_test_leak($_[0]->[1], $req, $_[1]);
}
sub cli_send_request {
	my $obj = shift;
	print "cli_send_request: sending\n"
		if $obj->[4];
	my ($reqid, $err, $errstr) = tdxs_send_request($obj->[1], @_);
	print "cli_send_request: request $reqid sent\n"
		unless $err || (! $obj->[4]);
	$obj->[2] = $reqid unless $err;
	return ($reqid, $err, $errstr);
}
sub cli_has_response {
	my ($obj, $wait) = @_;
	print "cli_has_response: checking for response\n"
		if $obj->[4];
	my $buffer;
	unless (defined($obj->[2])) {
		print "cli_has_response: session not active\n"
			if $obj->[4];
		return undef;
	}
	if (defined($obj->[3])) {
		print "cli_has_response: return old response for $obj->[2]\n"
			if $obj->[4];
		return $obj->[3]->[3];
	}
	my $reqid = $obj->[2];
	my ($err, $errstr) = $obj->cli_get_response(\$buffer, $reqid, undef, $wait);
 	if ($err && ($err == 211)) {
		print "cli_has_response: no response for $reqid\n"
			if $obj->[4];
		return undef;
	}
	print "cli_has_response: got a response for $reqid\n"
		if $obj->[4];
	$obj->[3] = [ $err, $errstr, $buffer, $reqid ];
	return $reqid;
}
sub cli_get_response {
	my ($obj, $buffer, $reqid, $keepresp, $wait) = @_;
	my ($err, $errstr);
	my $debug = $obj->[4];
	print 'cli_get_response: getting ', ($keepresp ? 'KEEPRESP' : 'RESP'), " response for $reqid\n"
		if $debug;
	return (208, '208: No data received from dbc.')
		if ($obj->[2] && ($obj->[2] != $reqid));
	if ($obj->[3] &&
		($obj->[3]->[3] == $reqid)) {
		print "cli_get_response: returning stored response\n"
			if $debug;
		($err, $errstr, $$buffer, $reqid) = @{$obj->[3]};
		$obj->[3] = undef;
		return ($err, $errstr);
	}
	print "cli_get_response: getting response\n"
		if $debug;
	unless ($wait) {
		($err, $errstr) = tdxs_get_response($obj->[1], $$buffer, $reqid, $keepresp, $wait);
		$obj->[2] = $reqid
			if ($err && ($err == 211));
		print "cli_get_response: got response length ", length($$buffer), "\n"
			unless ($err || (! $debug));
		return ($err, $errstr);
	}
	my $started = time();
	while (($wait < 0) || ((time() - $started) < $wait)) {
		($err, $errstr) = tdxs_get_response($obj->[1], $$buffer, $reqid, $keepresp, ($wait < 0));
		last unless (($err == 211) || ($err == 208));
	}
	$obj->[2] = $reqid
		if ($err && ($err == 211));
	print "cli_get_response: got response length ", length($$buffer), "\n"
		unless ($err || (! $debug));
	return ($err, $errstr);
}
sub cli_end_request {
	my ($obj, $reqid) = @_;
	print "cli_end_request: Ending request $reqid\n"
		if $obj->[4];
	my ($err, $errstr) = tdxs_end_request($obj->[1], $reqid);
	($err, $errstr) = (0, undef)
		if ($err == 305);
	print "end_request failed: $err $errstr\n"
		if ($obj->[4] && $err);
	$obj->[3] = undef
		if ($obj->[3] &&
			($obj->[3]->[3] == $reqid));
	$obj->[2] = undef
		if ($obj->[2] &&
			($obj->[2] == $reqid));
	return ($err, $errstr)
}
sub cli_abort_request {
	print "cli_abort_request: Aborting request $_[1]\n"
		if $_[0]->[4];
	return tdxs_abort_request($_[0]->[1], $_[1]);
}
sub cli_wait_for_response {
	my $timeout = shift;
	my $started = time();
	my @ready = ();
	my ($id, $obj, $reqid, $keepresp);
	while ((!defined($timeout)) || ($timeout > (time() - $started))) {
		my $i = 0;
		while ($i < scalar @_) {
			my $buffer;
			($id, $obj, $reqid, $keepresp) = @_[$i .. $i + 3];
			my ($err, $errstr) =
				tdxs_get_response($obj->[1], $buffer, $reqid, $keepresp, undef);
	 		next
	 			if ($err && ($err == 211));
			print 'cli_has_response: got a response for ', $reqid, "\n"
				if $obj->[4];
			push @ready, $id;
			$obj->[3] = [ $err, $errstr, $buffer, $reqid ];
			$i += 4;
		}
		return @ready if scalar @ready;
		select(undef, undef, undef, 0.05);
	}
	return ();
}
sub DESTROY {
	my ($err, $errstr);
	return 1 unless $dbc_ctxts{$_[0]->[5] . "_$$"};
	$err = tdxs_cleanup($_[0]->[1], $errstr)
		if $_[0]->[1];
	$_[0]->[3] = undef;
	$_[0]->[1] = undef;
	delete $dbc_ctxts{$_[0]->[5] . "_$$"};
}
require XSLoader;
XSLoader::load('DBD::Teradata', $VERSION);
1;
