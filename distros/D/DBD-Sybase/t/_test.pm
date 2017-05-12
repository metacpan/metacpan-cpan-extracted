# $Id: _test.pm,v 1.2 2007/03/01 17:17:44 mpeppler Exp $

package _test;

$|=1; #keep stdout in sync with stderr

my ($Uid, $Pwd, $Srv, $Db);

sub load_data {
    my @dirs = ('./.', './..', './../..', './../../..');
    foreach (@dirs)
    {
	if(-f "$_/PWD")
	{
	    open(PWD, "$_/PWD") || die "$_/PWD is not readable: $!\n";
	    while(<PWD>)
	    {
		chop;
		s/^\s*//;
		next if(/^\#/ || /^\s*$/);
		($l, $r) = split(/=/);
		$Uid = $r if($l eq UID);
		$Pwd = $r if($l eq PWD);
		$Srv = $r if($l eq SRV);
		$Db = $r if($l eq DB);
	    }
	    close(PWD);
	    last;
	}
    }
}

sub get_info {
    load_data();
    $Db = 'tempdb' unless $Db;
    return ($Uid, $Pwd, $Srv, $Db);
}

1;
