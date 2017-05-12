BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use Apache::Htaccess;
$loaded = 1;
print "ok\n";

my $obj = Apache::Htaccess->new("htaccess");
if($obj) {
	print "ok\n";
} else {
	print "not ok\n";
}

if($obj->global_requires('admin','0','1')) { print "ok\n"; }
else { print "not ok\n"; }

if($obj->directives('CheckSpelling' => 'on')) { print "ok\n"; }
else { print "not ok\n"; }

if($obj->requires('admin.cgi','admin','3')) { print "ok\n"; }
else { print "not ok\n"; }

if($obj->save()) { print "ok 6\n"; }
else { print "not ok\n"; }

if(-e 'htaccess') { print "ok 7\n"; }
else { print "not ok\n"; }

if( (stat('htaccess'))[7] > 0 ) { print "ok 8\n"; }
else { print "not ok\n"; }

