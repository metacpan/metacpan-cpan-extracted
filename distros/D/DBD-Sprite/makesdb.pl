#!/usr/bin/perl

$dbname = shift (@ARGV) || prompt("Database name");
&usage()  unless ($dbname =~ /^\w+$/);

open (SDB, ">>${dbname}.sdb")  || die "Could not open database \"${dbname}.sdb\"!\n";

if ($ARGV[0])
{
	$cryptedpswd = crypt($ARGV[1], substr($ARGV[0],0,2));
	print SDB <<END_REC;
$ARGV[2]/*$ARGV[3]
$ARGV[0]
$cryptedpswd
$ARGV[5]
$ARGV[4]
END_REC
}
else
{
	do
	{
		$dbuser = prompt("\nDatabase user");
		goto DONE  unless ($dbuser =~ /^\w+$/);
		$dbpswd = prompt("User password");
		goto DONE  unless ($dbpswd =~ /^\w+$/);
		$dbpath = prompt("Database path");
		$dbpath = '.'  unless ($dbpath);
		$dbpath =~ s#/$##;	
		$dbext  = prompt("Table file extension (default .stb)");
		$dbext = '.stb'  unless ($dbext);
		$rdelim = prompt("Record delimiter (default \\r\\n)");
		$rdelim = '\r\n'  unless ($rdelim);
		$fdelim = prompt("Field delimiter (default ::)");
		$fdelim = '::'  unless ($fdelim);
		$cryptedpswd = crypt($dbpswd, substr($dbuser,0,2));
		print SDB <<END_REC;
$dbpath/*$dbext
$dbuser
$cryptedpswd
$fdelim
$rdelim
END_REC
	}
	while (1);
}

DONE: ;

exit (0);

sub prompt
{
        my ($pmpt,$dflt) = @_;

        my ($t);
        print "$pmpt: ";

        $t = <>;
        chomp($t);
        $t = $dflt  unless ($t =~ /\S/);
        return $t;
}

sub usage
{
	print "..usage:  $0 [dbname [user password path ext rec_sep field_sep]]\n";
	print "\nCreates / adds users to a Sprite database.\n\n";
	exit (1);
}
