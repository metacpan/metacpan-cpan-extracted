#!/usr/bin/perl -w
use Data::Dumper;
use lib '../lib';
use Asterisk::config;

my $rc = new Asterisk::config(file=>'sip.conf',keep_resource_array=>0);

$rc->assign_matchreplace(match=>'host=>dynamic',replace=>'host=192.168.0.1;dynamic');

$rc->assign_replacesection(section=>'[unsection]',data=>['type=friend','secret=123456']);

$rc->assign_delsection(section=>'tempsection');

$rc->assign_addsection(section=>'gan');

$rc->assign_append(point=>'down',section=>'gan',data=>'allow=h263');

$rc->assign_editkey(section=>'trunka',key=>'type',new_value=>'peer');

$rc->assign_delkey(section=>'general',key=>'allow');

#$rc->assign_cleanfile();

# new_file can save data to newfile
$rc->save_file(new_file=>'new.conf');

