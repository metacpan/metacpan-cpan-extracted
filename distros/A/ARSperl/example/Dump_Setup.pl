#!/usr/local/bin/perl
#
# $Header: /cvsroot/arsperl/ARSperl/example/Dump_Setup.pl,v 1.3 1999/06/14 17:07:39 jcmurphy Exp $
#
# EXAMPLE
#    Dump_Setup.pl [username] [password] [path]
#
# DESCRIPTION
#    Log onto the server and export all schemas, filters, etc.
# 
# NOTES
#    This might require special permission for the username you login as
#
# AUTHOR
#    joel murphy
#
# 03/14/96
#
# $Log: Dump_Setup.pl,v $
# Revision 1.3  1999/06/14 17:07:39  jcmurphy
# added some login error checking
#
# Revision 1.2  1998/12/11 15:24:38  jcmurphy
# adjustments to GetListSchema for >=3.0 systesm
#
# Revision 1.1  1996/11/21 20:13:50  jcmurphy
# Initial revision
#
#

use ARS;

$rcs = "/usr/local/bin";
$ci = "$rcs/ci";
$perm = 0755;

($ACCOUNT, $PASSWORD, $path) = @ARGV;
chomp($path = `pwd`) if (!$path);
$c = ars_Login("localhost",$ACCOUNT,$PASSWORD);
die "login error: $ars_errstr\n" unless defined($c);

@schema = ars_GetListSchema($c, 0, 1024);
@active = ars_GetListActiveLink($c);
@filter = ars_GetListFilter($c);
@escal = ars_GetListEscalation($c);
@menu = ars_GetListCharMenu($c);
@admin_ext = ars_GetListAdminExtension($c);

# Warning! this might make several names map to the same file
sub name_to_path {
    my $name = shift;
    $name =~ s/ /_/g;
    $name =~ s/\//:/g;
    return $name;
}

sub dump_type {
    my ($path, $type, $names) = @_;
    
    if (! -d "$path") {
	mkdir "$path", $perm || die "can't create directory $path";
	mkdir "$path/RCS", $perm || die "can't create directory $path/RCS";
    }
    foreach $name (@$names) {
	$val = ars_Export($c,"",$type,$name);
	$val =~ s/^#.*/#/gm;  # get rid of comments with export date
	$name = name_to_path($name);
	open DUMP, "> $path/$name" || die "can't write file $path/$name";
	print DUMP $val;
	close DUMP;
	$name =~ s/'/'\\''/;
	system("$ci -l -q '$path/$name'");
    }
}

dump_type("$path/schema", "Schema", \@schema);
dump_type("$path/active", "Active_Link", \@active);
dump_type("$path/filter", "Filter", \@filter);
dump_type("$path/escalation", "Escalation", \@escal);
dump_type("$path/menu", "Char_Menu", \@menu);
dump_type("$path/admin_ext", "Admin_Ext", \@admin_ext);


