######################################################################
# Makefile.PL for Date::Manip
######################################################################

use strict;
use warnings;
use 5.006;
use ExtUtils::MakeMaker 6.67_01;

my %IsWin32 = map { $_ => 1 } qw( MSWin32 NetWare symbian );
my $IsWin32 = 1   if ($IsWin32{ $^O });
my $Pvers   = $];
my $ConvVers= $ExtUtils::MakeMaker::VERSION;

my %module_prereq = (
   'Carp'                     => '0',
   'Cwd'                      => '0',
   'Data::Dumper'             => '0',
   'Encode'                   => '0',
   'File::Find'               => '0',
   'File::Spec'               => '0',
   'IO::File'                 => '0',
   'Storable'                 => '0',
   'utf8'                     => '0',
);

if      ($IsWin32  &&  $Pvers >= 5.020) {
   $module_prereq{'Win32::TieRegistry'} = 0.28;
} elsif ($IsWin32) {
   $module_prereq{'Win32::TieRegistry'} = 0;
}

my %script_prereq = (
);

my %test_prereq = (
   'Test::Inter'              => '0',
   'Test::More'               => '0',
);

my %config_prereq = (
   'ExtUtils::MakeMaker'      => '6.67_01',
);

%module_prereq = (%module_prereq,%script_prereq);
my $EU_MM_V    = $ExtUtils::MakeMaker::VERSION;
$EU_MM_V       =~ s/_//g;
if ($EU_MM_V < 6.64) {
   %config_prereq = (%config_prereq,%test_prereq);
}

WriteMakefile(
   NAME             => "Date::Manip",
   VERSION          => "6.60",
   ABSTRACT         => "Date manipulation routines",
   LICENSE          => "perl",
   ($EU_MM_V >= 6.48
    ? (MIN_PERL_VERSION => "5.006")
    : ()),
   AUTHOR           => "Sullivan Beck (sbeck\@cpan.org)",
   "dist"           => {COMPRESS=>"gzip",SUFFIX=>"gz"},
   PL_FILES         => {},
   PREREQ_PM        => \%module_prereq,
   ($EU_MM_V >= 6.52
    ? (CONFIGURE_REQUIRES => \%config_prereq)
    : ()),
   ($EU_MM_V >= 6.64
    ? (TEST_REQUIRES   => \%test_prereq)
    : ()),
   ($EU_MM_V > 6.45
    ? (META_ADD => {
          provides     => {
             'Date::Manip' => {
                file    => 'Manip.pm',
                version => '6.60',
             },
             'Date::Manip::Base' => {
                file    => 'Base.pm',
                version => '6.60',
             },
             'Date::Manip::DM5' => {
                file    => 'DM5.pm',
                version => '6.60',
             },
             'Date::Manip::DM5abbrevs' => {
                file    => 'DM5abbrevs.pm',
                version => '6.60',
             },
             'Date::Manip::DM6' => {
                file    => 'DM6.pm',
                version => '6.60',
             },
             'Date::Manip::Date' => {
                file    => 'Date.pm',
                version => '6.60',
             },
             'Date::Manip::Delta' => {
                file    => 'Delta.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::catalan' => {
                file    => 'catalan.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::danish' => {
                file    => 'danish.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::dutch' => {
                file    => 'dutch.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::english' => {
                file    => 'english.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::finnish' => {
                file    => 'finnish.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::french' => {
                file    => 'french.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::german' => {
                file    => 'german.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::index' => {
                file    => 'index.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::italian' => {
                file    => 'italian.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::norwegian' => {
                file    => 'norwegian.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::polish' => {
                file    => 'polish.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::portugue' => {
                file    => 'portugue.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::romanian' => {
                file    => 'romanian.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::russian' => {
                file    => 'russian.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::spanish' => {
                file    => 'spanish.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::swedish' => {
                file    => 'swedish.pm',
                version => '6.60',
             },
             'Date::Manip::Lang::turkish' => {
                file    => 'turkish.pm',
                version => '6.60',
             },
             'Date::Manip::Obj' => {
                file    => 'Obj.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off000' => {
                file    => 'off000.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off001' => {
                file    => 'off001.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off002' => {
                file    => 'off002.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off003' => {
                file    => 'off003.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off004' => {
                file    => 'off004.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off005' => {
                file    => 'off005.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off006' => {
                file    => 'off006.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off007' => {
                file    => 'off007.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off008' => {
                file    => 'off008.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off009' => {
                file    => 'off009.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off010' => {
                file    => 'off010.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off011' => {
                file    => 'off011.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off012' => {
                file    => 'off012.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off013' => {
                file    => 'off013.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off014' => {
                file    => 'off014.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off015' => {
                file    => 'off015.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off016' => {
                file    => 'off016.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off017' => {
                file    => 'off017.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off018' => {
                file    => 'off018.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off019' => {
                file    => 'off019.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off020' => {
                file    => 'off020.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off021' => {
                file    => 'off021.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off022' => {
                file    => 'off022.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off023' => {
                file    => 'off023.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off024' => {
                file    => 'off024.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off025' => {
                file    => 'off025.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off026' => {
                file    => 'off026.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off027' => {
                file    => 'off027.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off028' => {
                file    => 'off028.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off029' => {
                file    => 'off029.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off030' => {
                file    => 'off030.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off031' => {
                file    => 'off031.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off032' => {
                file    => 'off032.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off033' => {
                file    => 'off033.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off034' => {
                file    => 'off034.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off035' => {
                file    => 'off035.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off036' => {
                file    => 'off036.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off037' => {
                file    => 'off037.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off038' => {
                file    => 'off038.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off039' => {
                file    => 'off039.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off040' => {
                file    => 'off040.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off041' => {
                file    => 'off041.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off042' => {
                file    => 'off042.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off043' => {
                file    => 'off043.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off044' => {
                file    => 'off044.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off045' => {
                file    => 'off045.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off046' => {
                file    => 'off046.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off047' => {
                file    => 'off047.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off048' => {
                file    => 'off048.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off049' => {
                file    => 'off049.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off050' => {
                file    => 'off050.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off051' => {
                file    => 'off051.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off052' => {
                file    => 'off052.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off053' => {
                file    => 'off053.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off054' => {
                file    => 'off054.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off055' => {
                file    => 'off055.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off056' => {
                file    => 'off056.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off057' => {
                file    => 'off057.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off058' => {
                file    => 'off058.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off059' => {
                file    => 'off059.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off060' => {
                file    => 'off060.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off061' => {
                file    => 'off061.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off062' => {
                file    => 'off062.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off063' => {
                file    => 'off063.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off064' => {
                file    => 'off064.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off065' => {
                file    => 'off065.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off066' => {
                file    => 'off066.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off067' => {
                file    => 'off067.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off068' => {
                file    => 'off068.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off069' => {
                file    => 'off069.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off070' => {
                file    => 'off070.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off071' => {
                file    => 'off071.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off072' => {
                file    => 'off072.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off073' => {
                file    => 'off073.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off074' => {
                file    => 'off074.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off075' => {
                file    => 'off075.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off076' => {
                file    => 'off076.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off077' => {
                file    => 'off077.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off078' => {
                file    => 'off078.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off079' => {
                file    => 'off079.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off080' => {
                file    => 'off080.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off081' => {
                file    => 'off081.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off082' => {
                file    => 'off082.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off083' => {
                file    => 'off083.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off084' => {
                file    => 'off084.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off085' => {
                file    => 'off085.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off086' => {
                file    => 'off086.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off087' => {
                file    => 'off087.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off088' => {
                file    => 'off088.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off089' => {
                file    => 'off089.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off090' => {
                file    => 'off090.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off091' => {
                file    => 'off091.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off092' => {
                file    => 'off092.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off093' => {
                file    => 'off093.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off094' => {
                file    => 'off094.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off095' => {
                file    => 'off095.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off096' => {
                file    => 'off096.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off097' => {
                file    => 'off097.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off098' => {
                file    => 'off098.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off099' => {
                file    => 'off099.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off100' => {
                file    => 'off100.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off101' => {
                file    => 'off101.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off102' => {
                file    => 'off102.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off103' => {
                file    => 'off103.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off104' => {
                file    => 'off104.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off105' => {
                file    => 'off105.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off106' => {
                file    => 'off106.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off107' => {
                file    => 'off107.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off108' => {
                file    => 'off108.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off109' => {
                file    => 'off109.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off110' => {
                file    => 'off110.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off111' => {
                file    => 'off111.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off112' => {
                file    => 'off112.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off113' => {
                file    => 'off113.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off114' => {
                file    => 'off114.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off115' => {
                file    => 'off115.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off116' => {
                file    => 'off116.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off117' => {
                file    => 'off117.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off118' => {
                file    => 'off118.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off119' => {
                file    => 'off119.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off120' => {
                file    => 'off120.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off121' => {
                file    => 'off121.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off122' => {
                file    => 'off122.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off123' => {
                file    => 'off123.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off124' => {
                file    => 'off124.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off125' => {
                file    => 'off125.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off126' => {
                file    => 'off126.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off127' => {
                file    => 'off127.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off128' => {
                file    => 'off128.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off129' => {
                file    => 'off129.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off130' => {
                file    => 'off130.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off131' => {
                file    => 'off131.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off132' => {
                file    => 'off132.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off133' => {
                file    => 'off133.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off134' => {
                file    => 'off134.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off135' => {
                file    => 'off135.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off136' => {
                file    => 'off136.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off137' => {
                file    => 'off137.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off138' => {
                file    => 'off138.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off139' => {
                file    => 'off139.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off140' => {
                file    => 'off140.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off141' => {
                file    => 'off141.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off142' => {
                file    => 'off142.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off143' => {
                file    => 'off143.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off144' => {
                file    => 'off144.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off145' => {
                file    => 'off145.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off146' => {
                file    => 'off146.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off147' => {
                file    => 'off147.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off148' => {
                file    => 'off148.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off149' => {
                file    => 'off149.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off150' => {
                file    => 'off150.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off151' => {
                file    => 'off151.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off152' => {
                file    => 'off152.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off153' => {
                file    => 'off153.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off154' => {
                file    => 'off154.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off155' => {
                file    => 'off155.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off156' => {
                file    => 'off156.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off157' => {
                file    => 'off157.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off158' => {
                file    => 'off158.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off159' => {
                file    => 'off159.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off160' => {
                file    => 'off160.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off161' => {
                file    => 'off161.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off162' => {
                file    => 'off162.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off163' => {
                file    => 'off163.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off164' => {
                file    => 'off164.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off165' => {
                file    => 'off165.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off166' => {
                file    => 'off166.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off167' => {
                file    => 'off167.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off168' => {
                file    => 'off168.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off169' => {
                file    => 'off169.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off170' => {
                file    => 'off170.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off171' => {
                file    => 'off171.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off172' => {
                file    => 'off172.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off173' => {
                file    => 'off173.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off174' => {
                file    => 'off174.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off175' => {
                file    => 'off175.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off176' => {
                file    => 'off176.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off177' => {
                file    => 'off177.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off178' => {
                file    => 'off178.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off179' => {
                file    => 'off179.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off180' => {
                file    => 'off180.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off181' => {
                file    => 'off181.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off182' => {
                file    => 'off182.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off183' => {
                file    => 'off183.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off184' => {
                file    => 'off184.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off185' => {
                file    => 'off185.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off186' => {
                file    => 'off186.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off187' => {
                file    => 'off187.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off188' => {
                file    => 'off188.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off189' => {
                file    => 'off189.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off190' => {
                file    => 'off190.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off191' => {
                file    => 'off191.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off192' => {
                file    => 'off192.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off193' => {
                file    => 'off193.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off194' => {
                file    => 'off194.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off195' => {
                file    => 'off195.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off196' => {
                file    => 'off196.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off197' => {
                file    => 'off197.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off198' => {
                file    => 'off198.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off199' => {
                file    => 'off199.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off200' => {
                file    => 'off200.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off201' => {
                file    => 'off201.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off202' => {
                file    => 'off202.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off203' => {
                file    => 'off203.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off204' => {
                file    => 'off204.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off205' => {
                file    => 'off205.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off206' => {
                file    => 'off206.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off207' => {
                file    => 'off207.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off208' => {
                file    => 'off208.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off209' => {
                file    => 'off209.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off210' => {
                file    => 'off210.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off211' => {
                file    => 'off211.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off212' => {
                file    => 'off212.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off213' => {
                file    => 'off213.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off214' => {
                file    => 'off214.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off215' => {
                file    => 'off215.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off216' => {
                file    => 'off216.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off217' => {
                file    => 'off217.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off218' => {
                file    => 'off218.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off219' => {
                file    => 'off219.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off220' => {
                file    => 'off220.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off221' => {
                file    => 'off221.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off222' => {
                file    => 'off222.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off223' => {
                file    => 'off223.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off224' => {
                file    => 'off224.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off225' => {
                file    => 'off225.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off226' => {
                file    => 'off226.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off227' => {
                file    => 'off227.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off228' => {
                file    => 'off228.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off229' => {
                file    => 'off229.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off230' => {
                file    => 'off230.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off231' => {
                file    => 'off231.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off232' => {
                file    => 'off232.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off233' => {
                file    => 'off233.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off234' => {
                file    => 'off234.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off235' => {
                file    => 'off235.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off236' => {
                file    => 'off236.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off237' => {
                file    => 'off237.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off238' => {
                file    => 'off238.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off239' => {
                file    => 'off239.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off240' => {
                file    => 'off240.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off241' => {
                file    => 'off241.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off242' => {
                file    => 'off242.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off243' => {
                file    => 'off243.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off244' => {
                file    => 'off244.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off245' => {
                file    => 'off245.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off246' => {
                file    => 'off246.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off247' => {
                file    => 'off247.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off248' => {
                file    => 'off248.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off249' => {
                file    => 'off249.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off250' => {
                file    => 'off250.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off251' => {
                file    => 'off251.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off252' => {
                file    => 'off252.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off253' => {
                file    => 'off253.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off254' => {
                file    => 'off254.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off255' => {
                file    => 'off255.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off256' => {
                file    => 'off256.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off257' => {
                file    => 'off257.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off258' => {
                file    => 'off258.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off259' => {
                file    => 'off259.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off260' => {
                file    => 'off260.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off261' => {
                file    => 'off261.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off262' => {
                file    => 'off262.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off263' => {
                file    => 'off263.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off264' => {
                file    => 'off264.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off265' => {
                file    => 'off265.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off266' => {
                file    => 'off266.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off267' => {
                file    => 'off267.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off268' => {
                file    => 'off268.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off269' => {
                file    => 'off269.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off270' => {
                file    => 'off270.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off271' => {
                file    => 'off271.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off272' => {
                file    => 'off272.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off273' => {
                file    => 'off273.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off274' => {
                file    => 'off274.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off275' => {
                file    => 'off275.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off276' => {
                file    => 'off276.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off277' => {
                file    => 'off277.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off278' => {
                file    => 'off278.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off279' => {
                file    => 'off279.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off280' => {
                file    => 'off280.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off281' => {
                file    => 'off281.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off282' => {
                file    => 'off282.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off283' => {
                file    => 'off283.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off284' => {
                file    => 'off284.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off285' => {
                file    => 'off285.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off286' => {
                file    => 'off286.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off287' => {
                file    => 'off287.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off288' => {
                file    => 'off288.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off289' => {
                file    => 'off289.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off290' => {
                file    => 'off290.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off291' => {
                file    => 'off291.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off292' => {
                file    => 'off292.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off293' => {
                file    => 'off293.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off294' => {
                file    => 'off294.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off295' => {
                file    => 'off295.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off296' => {
                file    => 'off296.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off297' => {
                file    => 'off297.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off298' => {
                file    => 'off298.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off299' => {
                file    => 'off299.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off300' => {
                file    => 'off300.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off301' => {
                file    => 'off301.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off302' => {
                file    => 'off302.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off303' => {
                file    => 'off303.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off304' => {
                file    => 'off304.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off305' => {
                file    => 'off305.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off306' => {
                file    => 'off306.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off307' => {
                file    => 'off307.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off308' => {
                file    => 'off308.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off309' => {
                file    => 'off309.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off310' => {
                file    => 'off310.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off311' => {
                file    => 'off311.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off312' => {
                file    => 'off312.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off313' => {
                file    => 'off313.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off314' => {
                file    => 'off314.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off315' => {
                file    => 'off315.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off316' => {
                file    => 'off316.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off317' => {
                file    => 'off317.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off318' => {
                file    => 'off318.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off319' => {
                file    => 'off319.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off320' => {
                file    => 'off320.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off321' => {
                file    => 'off321.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off322' => {
                file    => 'off322.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off323' => {
                file    => 'off323.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off324' => {
                file    => 'off324.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off325' => {
                file    => 'off325.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off326' => {
                file    => 'off326.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off327' => {
                file    => 'off327.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off328' => {
                file    => 'off328.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off329' => {
                file    => 'off329.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off330' => {
                file    => 'off330.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off331' => {
                file    => 'off331.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off332' => {
                file    => 'off332.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off333' => {
                file    => 'off333.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off334' => {
                file    => 'off334.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off335' => {
                file    => 'off335.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off336' => {
                file    => 'off336.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off337' => {
                file    => 'off337.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off338' => {
                file    => 'off338.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off339' => {
                file    => 'off339.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off340' => {
                file    => 'off340.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off341' => {
                file    => 'off341.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off342' => {
                file    => 'off342.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off343' => {
                file    => 'off343.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off344' => {
                file    => 'off344.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off345' => {
                file    => 'off345.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off346' => {
                file    => 'off346.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off347' => {
                file    => 'off347.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off348' => {
                file    => 'off348.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off349' => {
                file    => 'off349.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off350' => {
                file    => 'off350.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off351' => {
                file    => 'off351.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off352' => {
                file    => 'off352.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off353' => {
                file    => 'off353.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off354' => {
                file    => 'off354.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off355' => {
                file    => 'off355.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off356' => {
                file    => 'off356.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off357' => {
                file    => 'off357.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off358' => {
                file    => 'off358.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off359' => {
                file    => 'off359.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off360' => {
                file    => 'off360.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off361' => {
                file    => 'off361.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off362' => {
                file    => 'off362.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off363' => {
                file    => 'off363.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off364' => {
                file    => 'off364.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off365' => {
                file    => 'off365.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off366' => {
                file    => 'off366.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off367' => {
                file    => 'off367.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off368' => {
                file    => 'off368.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off369' => {
                file    => 'off369.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off370' => {
                file    => 'off370.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off371' => {
                file    => 'off371.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off372' => {
                file    => 'off372.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off373' => {
                file    => 'off373.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off374' => {
                file    => 'off374.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off375' => {
                file    => 'off375.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off376' => {
                file    => 'off376.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off377' => {
                file    => 'off377.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off378' => {
                file    => 'off378.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off379' => {
                file    => 'off379.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off380' => {
                file    => 'off380.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off381' => {
                file    => 'off381.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off382' => {
                file    => 'off382.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off383' => {
                file    => 'off383.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off384' => {
                file    => 'off384.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off385' => {
                file    => 'off385.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off386' => {
                file    => 'off386.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off387' => {
                file    => 'off387.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off388' => {
                file    => 'off388.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off389' => {
                file    => 'off389.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off390' => {
                file    => 'off390.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off391' => {
                file    => 'off391.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off392' => {
                file    => 'off392.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off393' => {
                file    => 'off393.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off394' => {
                file    => 'off394.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off395' => {
                file    => 'off395.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off396' => {
                file    => 'off396.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off397' => {
                file    => 'off397.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off398' => {
                file    => 'off398.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off399' => {
                file    => 'off399.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off400' => {
                file    => 'off400.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off401' => {
                file    => 'off401.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off402' => {
                file    => 'off402.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off403' => {
                file    => 'off403.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off404' => {
                file    => 'off404.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off405' => {
                file    => 'off405.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off406' => {
                file    => 'off406.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off407' => {
                file    => 'off407.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off408' => {
                file    => 'off408.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off409' => {
                file    => 'off409.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off410' => {
                file    => 'off410.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off411' => {
                file    => 'off411.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off412' => {
                file    => 'off412.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off413' => {
                file    => 'off413.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off414' => {
                file    => 'off414.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off415' => {
                file    => 'off415.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off416' => {
                file    => 'off416.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off417' => {
                file    => 'off417.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off418' => {
                file    => 'off418.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off419' => {
                file    => 'off419.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off420' => {
                file    => 'off420.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off421' => {
                file    => 'off421.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off422' => {
                file    => 'off422.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off423' => {
                file    => 'off423.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off424' => {
                file    => 'off424.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off425' => {
                file    => 'off425.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off426' => {
                file    => 'off426.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off427' => {
                file    => 'off427.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off428' => {
                file    => 'off428.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off429' => {
                file    => 'off429.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off430' => {
                file    => 'off430.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off431' => {
                file    => 'off431.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off432' => {
                file    => 'off432.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off433' => {
                file    => 'off433.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off434' => {
                file    => 'off434.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off435' => {
                file    => 'off435.pm',
                version => '6.60',
             },
             'Date::Manip::Offset::off436' => {
                file    => 'off436.pm',
                version => '6.60',
             },
             'Date::Manip::Recur' => {
                file    => 'Recur.pm',
                version => '6.60',
             },
             'Date::Manip::TZ' => {
                file    => 'TZ.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::a00' => {
                file    => 'a00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afabid00' => {
                file    => 'afabid00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afaccr00' => {
                file    => 'afaccr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afalgi00' => {
                file    => 'afalgi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afbiss00' => {
                file    => 'afbiss00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afcair00' => {
                file    => 'afcair00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afcasa00' => {
                file    => 'afcasa00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afceut00' => {
                file    => 'afceut00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afel_a00' => {
                file    => 'afel_a00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afjoha00' => {
                file    => 'afjoha00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afkhar00' => {
                file    => 'afkhar00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aflago00' => {
                file    => 'aflago00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afmapu00' => {
                file    => 'afmapu00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afmonr00' => {
                file    => 'afmonr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afnair00' => {
                file    => 'afnair00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afndja00' => {
                file    => 'afndja00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aftrip00' => {
                file    => 'aftrip00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aftuni00' => {
                file    => 'aftuni00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::afwind00' => {
                file    => 'afwind00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amadak00' => {
                file    => 'amadak00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amanch00' => {
                file    => 'amanch00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amarag00' => {
                file    => 'amarag00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amasun00' => {
                file    => 'amasun00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amatik00' => {
                file    => 'amatik00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ambahi00' => {
                file    => 'ambahi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ambahi01' => {
                file    => 'ambahi01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ambarb00' => {
                file    => 'ambarb00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ambele00' => {
                file    => 'ambele00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ambeli00' => {
                file    => 'ambeli00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ambeul00' => {
                file    => 'ambeul00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amblan00' => {
                file    => 'amblan00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amboa_00' => {
                file    => 'amboa_00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ambogo00' => {
                file    => 'ambogo00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ambois00' => {
                file    => 'ambois00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ambuen00' => {
                file    => 'ambuen00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcamb00' => {
                file    => 'amcamb00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcamp00' => {
                file    => 'amcamp00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcanc00' => {
                file    => 'amcanc00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcara00' => {
                file    => 'amcara00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcata00' => {
                file    => 'amcata00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcaye00' => {
                file    => 'amcaye00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcent00' => {
                file    => 'amcent00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amchic00' => {
                file    => 'amchic00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amchih00' => {
                file    => 'amchih00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcord00' => {
                file    => 'amcord00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcost00' => {
                file    => 'amcost00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcres00' => {
                file    => 'amcres00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcuia00' => {
                file    => 'amcuia00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amcura00' => {
                file    => 'amcura00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amdanm00' => {
                file    => 'amdanm00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amdaws00' => {
                file    => 'amdaws00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amdaws01' => {
                file    => 'amdaws01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amdenv00' => {
                file    => 'amdenv00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amdetr00' => {
                file    => 'amdetr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amedmo00' => {
                file    => 'amedmo00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ameiru00' => {
                file    => 'ameiru00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amel_s00' => {
                file    => 'amel_s00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amfort00' => {
                file    => 'amfort00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amfort01' => {
                file    => 'amfort01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amglac00' => {
                file    => 'amglac00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amgodt00' => {
                file    => 'amgodt00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amgoos00' => {
                file    => 'amgoos00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amgran00' => {
                file    => 'amgran00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amguat00' => {
                file    => 'amguat00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amguay00' => {
                file    => 'amguay00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amguya00' => {
                file    => 'amguya00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amhali00' => {
                file    => 'amhali00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amhava00' => {
                file    => 'amhava00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amherm00' => {
                file    => 'amherm00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amindi00' => {
                file    => 'amindi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aminuv00' => {
                file    => 'aminuv00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amiqal00' => {
                file    => 'amiqal00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amjama00' => {
                file    => 'amjama00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amjuju00' => {
                file    => 'amjuju00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amjune00' => {
                file    => 'amjune00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amknox00' => {
                file    => 'amknox00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amla_p00' => {
                file    => 'amla_p00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amla_r00' => {
                file    => 'amla_r00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amlima00' => {
                file    => 'amlima00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amlos_00' => {
                file    => 'amlos_00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amloui00' => {
                file    => 'amloui00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammace00' => {
                file    => 'ammace00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammana00' => {
                file    => 'ammana00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammana01' => {
                file    => 'ammana01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammare00' => {
                file    => 'ammare00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammart00' => {
                file    => 'ammart00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammata00' => {
                file    => 'ammata00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammaza00' => {
                file    => 'ammaza00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammend00' => {
                file    => 'ammend00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammeno00' => {
                file    => 'ammeno00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammeri00' => {
                file    => 'ammeri00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammetl00' => {
                file    => 'ammetl00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammexi00' => {
                file    => 'ammexi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammiqu00' => {
                file    => 'ammiqu00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammonc00' => {
                file    => 'ammonc00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammont00' => {
                file    => 'ammont00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammont01' => {
                file    => 'ammont01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ammont02' => {
                file    => 'ammont02.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amnass00' => {
                file    => 'amnass00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amnew_00' => {
                file    => 'amnew_00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amnew_01' => {
                file    => 'amnew_01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amnipi00' => {
                file    => 'amnipi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amnome00' => {
                file    => 'amnome00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amnoro00' => {
                file    => 'amnoro00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amojin00' => {
                file    => 'amojin00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ampana00' => {
                file    => 'ampana00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ampang00' => {
                file    => 'ampang00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ampara00' => {
                file    => 'ampara00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ampete00' => {
                file    => 'ampete00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amphoe00' => {
                file    => 'amphoe00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amport00' => {
                file    => 'amport00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amport01' => {
                file    => 'amport01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amport02' => {
                file    => 'amport02.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ampuer00' => {
                file    => 'ampuer00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ampunt00' => {
                file    => 'ampunt00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amrain00' => {
                file    => 'amrain00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amrank00' => {
                file    => 'amrank00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amreci00' => {
                file    => 'amreci00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amregi00' => {
                file    => 'amregi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amreso00' => {
                file    => 'amreso00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amrio_00' => {
                file    => 'amrio_00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amrio_01' => {
                file    => 'amrio_01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amsalt00' => {
                file    => 'amsalt00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amsan_00' => {
                file    => 'amsan_00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amsan_01' => {
                file    => 'amsan_01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amsant00' => {
                file    => 'amsant00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amsant01' => {
                file    => 'amsant01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amsant02' => {
                file    => 'amsant02.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amsao_00' => {
                file    => 'amsao_00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amscor00' => {
                file    => 'amscor00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amsitk00' => {
                file    => 'amsitk00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amst_j00' => {
                file    => 'amst_j00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amswif00' => {
                file    => 'amswif00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amtegu00' => {
                file    => 'amtegu00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amtell00' => {
                file    => 'amtell00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amthul00' => {
                file    => 'amthul00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amthun00' => {
                file    => 'amthun00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amtiju00' => {
                file    => 'amtiju00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amtoro00' => {
                file    => 'amtoro00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amtucu00' => {
                file    => 'amtucu00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amushu00' => {
                file    => 'amushu00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amvanc00' => {
                file    => 'amvanc00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amveva00' => {
                file    => 'amveva00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amvinc00' => {
                file    => 'amvinc00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amwhit00' => {
                file    => 'amwhit00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amwina00' => {
                file    => 'amwina00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amwinn00' => {
                file    => 'amwinn00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amyaku00' => {
                file    => 'amyaku00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::amyell00' => {
                file    => 'amyell00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ancase00' => {
                file    => 'ancase00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::andavi00' => {
                file    => 'andavi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::andumo00' => {
                file    => 'andumo00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::anmacq00' => {
                file    => 'anmacq00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::anmaws00' => {
                file    => 'anmaws00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::anpalm00' => {
                file    => 'anpalm00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::anroth00' => {
                file    => 'anroth00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ansyow00' => {
                file    => 'ansyow00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::antrol00' => {
                file    => 'antrol00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::anvost00' => {
                file    => 'anvost00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asalma00' => {
                file    => 'asalma00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asamma00' => {
                file    => 'asamma00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asanad00' => {
                file    => 'asanad00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asaqta00' => {
                file    => 'asaqta00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asaqto00' => {
                file    => 'asaqto00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asashg00' => {
                file    => 'asashg00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asatyr00' => {
                file    => 'asatyr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asbagh00' => {
                file    => 'asbagh00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asbaku00' => {
                file    => 'asbaku00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asbang00' => {
                file    => 'asbang00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asbarn00' => {
                file    => 'asbarn00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asbeir00' => {
                file    => 'asbeir00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asbish00' => {
                file    => 'asbish00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asbrun00' => {
                file    => 'asbrun00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aschit00' => {
                file    => 'aschit00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aschoi00' => {
                file    => 'aschoi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ascolo00' => {
                file    => 'ascolo00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asdama00' => {
                file    => 'asdama00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asdhak00' => {
                file    => 'asdhak00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asdili00' => {
                file    => 'asdili00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asduba00' => {
                file    => 'asduba00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asdush00' => {
                file    => 'asdush00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asfama00' => {
                file    => 'asfama00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asgaza00' => {
                file    => 'asgaza00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ashebr00' => {
                file    => 'ashebr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asho_c00' => {
                file    => 'asho_c00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ashong00' => {
                file    => 'ashong00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ashovd00' => {
                file    => 'ashovd00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asirku00' => {
                file    => 'asirku00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asjaka00' => {
                file    => 'asjaka00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asjaya00' => {
                file    => 'asjaya00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asjeru00' => {
                file    => 'asjeru00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::askabu00' => {
                file    => 'askabu00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::askamc00' => {
                file    => 'askamc00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::askara00' => {
                file    => 'askara00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::askath00' => {
                file    => 'askath00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::askhan00' => {
                file    => 'askhan00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::askolk00' => {
                file    => 'askolk00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::askras00' => {
                file    => 'askras00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::askual00' => {
                file    => 'askual00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::askuch00' => {
                file    => 'askuch00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asmaca00' => {
                file    => 'asmaca00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asmaga00' => {
                file    => 'asmaga00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asmaka00' => {
                file    => 'asmaka00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asmani00' => {
                file    => 'asmani00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asnico00' => {
                file    => 'asnico00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asnovo00' => {
                file    => 'asnovo00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asnovo01' => {
                file    => 'asnovo01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asomsk00' => {
                file    => 'asomsk00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asoral00' => {
                file    => 'asoral00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aspont00' => {
                file    => 'aspont00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aspyon00' => {
                file    => 'aspyon00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asqata00' => {
                file    => 'asqata00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asqyzy00' => {
                file    => 'asqyzy00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asriya00' => {
                file    => 'asriya00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::assakh00' => {
                file    => 'assakh00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::assama00' => {
                file    => 'assama00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asseou00' => {
                file    => 'asseou00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asshan00' => {
                file    => 'asshan00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::assing00' => {
                file    => 'assing00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::assred00' => {
                file    => 'assred00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::astaip00' => {
                file    => 'astaip00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::astash00' => {
                file    => 'astash00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::astbil00' => {
                file    => 'astbil00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::astehr00' => {
                file    => 'astehr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asthim00' => {
                file    => 'asthim00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::astoky00' => {
                file    => 'astoky00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::astoms00' => {
                file    => 'astoms00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asulaa00' => {
                file    => 'asulaa00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asurum00' => {
                file    => 'asurum00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asustm00' => {
                file    => 'asustm00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asvlad00' => {
                file    => 'asvlad00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asyaku00' => {
                file    => 'asyaku00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asyang00' => {
                file    => 'asyang00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asyeka00' => {
                file    => 'asyeka00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::asyere00' => {
                file    => 'asyere00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::atazor00' => {
                file    => 'atazor00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::atberm00' => {
                file    => 'atberm00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::atcana00' => {
                file    => 'atcana00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::atcape00' => {
                file    => 'atcape00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::atfaro00' => {
                file    => 'atfaro00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::atmade00' => {
                file    => 'atmade00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::atreyk00' => {
                file    => 'atreyk00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::atsout00' => {
                file    => 'atsout00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::atstan00' => {
                file    => 'atstan00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::auadel00' => {
                file    => 'auadel00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aubris00' => {
                file    => 'aubris00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aubrok00' => {
                file    => 'aubrok00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aucurr00' => {
                file    => 'aucurr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::audarw00' => {
                file    => 'audarw00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aueucl00' => {
                file    => 'aueucl00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::auhoba00' => {
                file    => 'auhoba00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aulind00' => {
                file    => 'aulind00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aulord00' => {
                file    => 'aulord00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aumelb00' => {
                file    => 'aumelb00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::aupert00' => {
                file    => 'aupert00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ausydn00' => {
                file    => 'ausydn00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::b00' => {
                file    => 'b00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::c00' => {
                file    => 'c00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::cet00' => {
                file    => 'cet00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::d00' => {
                file    => 'd00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::e00' => {
                file    => 'e00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eet00' => {
                file    => 'eet00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmt00' => {
                file    => 'etgmt00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm00' => {
                file    => 'etgmtm00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm01' => {
                file    => 'etgmtm01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm02' => {
                file    => 'etgmtm02.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm03' => {
                file    => 'etgmtm03.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm04' => {
                file    => 'etgmtm04.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm05' => {
                file    => 'etgmtm05.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm06' => {
                file    => 'etgmtm06.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm07' => {
                file    => 'etgmtm07.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm08' => {
                file    => 'etgmtm08.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm09' => {
                file    => 'etgmtm09.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm10' => {
                file    => 'etgmtm10.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm11' => {
                file    => 'etgmtm11.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm12' => {
                file    => 'etgmtm12.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtm13' => {
                file    => 'etgmtm13.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp00' => {
                file    => 'etgmtp00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp01' => {
                file    => 'etgmtp01.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp02' => {
                file    => 'etgmtp02.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp03' => {
                file    => 'etgmtp03.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp04' => {
                file    => 'etgmtp04.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp05' => {
                file    => 'etgmtp05.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp06' => {
                file    => 'etgmtp06.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp07' => {
                file    => 'etgmtp07.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp08' => {
                file    => 'etgmtp08.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp09' => {
                file    => 'etgmtp09.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp10' => {
                file    => 'etgmtp10.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::etgmtp11' => {
                file    => 'etgmtp11.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euamst00' => {
                file    => 'euamst00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euando00' => {
                file    => 'euando00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euastr00' => {
                file    => 'euastr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euathe00' => {
                file    => 'euathe00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eubelg00' => {
                file    => 'eubelg00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euberl00' => {
                file    => 'euberl00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eubrus00' => {
                file    => 'eubrus00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eubuch00' => {
                file    => 'eubuch00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eubuda00' => {
                file    => 'eubuda00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euchis00' => {
                file    => 'euchis00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eucope00' => {
                file    => 'eucope00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eudubl00' => {
                file    => 'eudubl00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eugibr00' => {
                file    => 'eugibr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euhels00' => {
                file    => 'euhels00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euista00' => {
                file    => 'euista00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eukali00' => {
                file    => 'eukali00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eukiev00' => {
                file    => 'eukiev00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eukiro00' => {
                file    => 'eukiro00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eulisb00' => {
                file    => 'eulisb00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eulond00' => {
                file    => 'eulond00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euluxe00' => {
                file    => 'euluxe00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eumadr00' => {
                file    => 'eumadr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eumalt00' => {
                file    => 'eumalt00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eumins00' => {
                file    => 'eumins00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eumona00' => {
                file    => 'eumona00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eumosc00' => {
                file    => 'eumosc00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euoslo00' => {
                file    => 'euoslo00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eupari00' => {
                file    => 'eupari00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euprag00' => {
                file    => 'euprag00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euriga00' => {
                file    => 'euriga00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eurome00' => {
                file    => 'eurome00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eusama00' => {
                file    => 'eusama00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eusara00' => {
                file    => 'eusara00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eusimf00' => {
                file    => 'eusimf00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eusofi00' => {
                file    => 'eusofi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eustoc00' => {
                file    => 'eustoc00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eutall00' => {
                file    => 'eutall00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::eutira00' => {
                file    => 'eutira00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euulya00' => {
                file    => 'euulya00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euuzhg00' => {
                file    => 'euuzhg00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euvien00' => {
                file    => 'euvien00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euviln00' => {
                file    => 'euviln00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euvolg00' => {
                file    => 'euvolg00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euwars00' => {
                file    => 'euwars00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euzapo00' => {
                file    => 'euzapo00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::euzuri00' => {
                file    => 'euzuri00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::f00' => {
                file    => 'f00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::g00' => {
                file    => 'g00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::h00' => {
                file    => 'h00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::i00' => {
                file    => 'i00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::inchag00' => {
                file    => 'inchag00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::inchri00' => {
                file    => 'inchri00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::incoco00' => {
                file    => 'incoco00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::inkerg00' => {
                file    => 'inkerg00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::inmahe00' => {
                file    => 'inmahe00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::inmald00' => {
                file    => 'inmald00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::inmaur00' => {
                file    => 'inmaur00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::inreun00' => {
                file    => 'inreun00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::k00' => {
                file    => 'k00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::l00' => {
                file    => 'l00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::m00' => {
                file    => 'm00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::met00' => {
                file    => 'met00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::n00' => {
                file    => 'n00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::o00' => {
                file    => 'o00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::p00' => {
                file    => 'p00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paapia00' => {
                file    => 'paapia00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paauck00' => {
                file    => 'paauck00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paboug00' => {
                file    => 'paboug00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pachat00' => {
                file    => 'pachat00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pachuu00' => {
                file    => 'pachuu00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paeast00' => {
                file    => 'paeast00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paefat00' => {
                file    => 'paefat00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paende00' => {
                file    => 'paende00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pafaka00' => {
                file    => 'pafaka00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pafiji00' => {
                file    => 'pafiji00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pafuna00' => {
                file    => 'pafuna00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pagala00' => {
                file    => 'pagala00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pagamb00' => {
                file    => 'pagamb00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paguad00' => {
                file    => 'paguad00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paguam00' => {
                file    => 'paguam00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pahono00' => {
                file    => 'pahono00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pakiri00' => {
                file    => 'pakiri00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pakosr00' => {
                file    => 'pakosr00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pakwaj00' => {
                file    => 'pakwaj00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pamaju00' => {
                file    => 'pamaju00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pamarq00' => {
                file    => 'pamarq00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::panaur00' => {
                file    => 'panaur00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paniue00' => {
                file    => 'paniue00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::panorf00' => {
                file    => 'panorf00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::panoum00' => {
                file    => 'panoum00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::papago00' => {
                file    => 'papago00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::papala00' => {
                file    => 'papala00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::papitc00' => {
                file    => 'papitc00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::papohn00' => {
                file    => 'papohn00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::paport00' => {
                file    => 'paport00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pararo00' => {
                file    => 'pararo00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::patahi00' => {
                file    => 'patahi00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::patara00' => {
                file    => 'patara00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::patong00' => {
                file    => 'patong00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pawake00' => {
                file    => 'pawake00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::pawall00' => {
                file    => 'pawall00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::q00' => {
                file    => 'q00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::r00' => {
                file    => 'r00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::s00' => {
                file    => 's00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::t00' => {
                file    => 't00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::u00' => {
                file    => 'u00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::ut00' => {
                file    => 'ut00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::utc00' => {
                file    => 'utc00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::v00' => {
                file    => 'v00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::w00' => {
                file    => 'w00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::wet00' => {
                file    => 'wet00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::x00' => {
                file    => 'x00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::y00' => {
                file    => 'y00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ::z00' => {
                file    => 'z00.pm',
                version => '6.60',
             },
             'Date::Manip::TZ_Base' => {
                file    => 'TZ_Base.pm',
                version => '6.60',
             },
             'Date::Manip::TZdata' => {
                file    => 'TZdata.pm',
                version => '6.60',
             },
             'Date::Manip::Zones' => {
                file    => 'Zones.pm',
                version => '6.60',
             },

          },
       }
      )
    : ()),

   ($EU_MM_V > 6.46
    ? (META_MERGE => {
          'meta-spec'  => {
             version   => 2,
          },
          resources    => {
             repository => {
                type => 'git',
                web  => 'https://github.com/SBECK-github/Date-Manip',
                url  => 'git://github.com/SBECK-github/Date-Manip.git',
             },
          },
       }
      )
    : ()),

   EXE_FILES        => [
                        'examples/dm_date',
                        'examples/dm_zdump',

                       ],

   MAN1PODS => {
      'examples/dm_date' => 'blib/man1/dm_date.1',
      'examples/dm_zdump' => 'blib/man1/dm_zdump.1',
   },


);
