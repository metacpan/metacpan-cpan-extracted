
use Apache::ASP::CGI;
use strict;
$SIG{__DIE__} = \&Carp::confess;

my @dbms = qw( MLDBM::Sync::SDBM_File DB_File GDBM_File );
my $dbm_ok;
for my $dbm ( @dbms ) {
    eval "use $dbm";
    if(! $@) {
	$dbm_ok = $dbm;
#	print STDERR $dbm_ok."\n";
	last;
    }
}
return unless $dbm_ok;

&Apache::ASP::CGI::do_self(
			   CacheSize => '1K',  # auto cleanup after test		  
			   CacheDB => $dbm_ok,
			   UseStrict => 1,
			   NoState => 1,
#			   Debug => -3,
			   # CacheDir can be set separately from StateDir
			   StateDir => '.state',
			   CacheDir => '.cache',
);

__END__

<% 
my $asp = $Server->{asp};
my $cache_lock = ".cache/cache/Response.lock";

my $reset_cache_counts = sub { map { $asp->{'cache_count_'.$_} = 0 } 
			       qw( fetch miss store expires last_modified_expires ) 
			       };
my $check_cache_counts = sub {
    my($error, %args) = @_;
    for my $key ( keys %args ) {
	my $asp_key = 'cache_count_'.$key;
	$t->eok($asp->{$asp_key} == $args{$key},
		"$error cache test: $asp_key is $asp->{$asp_key}, should be $args{$key}"
		);
	
    }
};

my $out_length = 2000;
my $script = qq[<\%\= 
		"1234" x 500
		%\>];

# BASIC
for(1..3) {
    my $out = $Response->TrapInclude({
	File => \$script,
	Cache => 1,
	Expires => 3600,
	LastModified => time()-10,
	Key => $0,
    });
    $t->eok(length($$out) == $out_length, "Output length from include should be $out_length, found: ".length($$out));
}

&$check_cache_counts("BASIC", fetch => 2, miss => 1, store => 1);
&$reset_cache_counts;

$t->eok(-e $cache_lock, "Cache lock test");

# EXPIRES PAST
for(1..3) {
    my $out = $Response->TrapInclude({
	File => \$script,
	Cache => 1,
	Expires => -1,
	Key => $0,
    });
    $t->eok(length($$out) == $out_length, "Output length from include should be $out_length, found: ".length($$out));
}
&$check_cache_counts("EXPIRES", expires => 3, store => 3);
&$reset_cache_counts;

# EXPIRES FUTURE, first is new, second should be cached, third should expire
for(1..3) {
    my $out = $Response->TrapInclude({
	File => \$script,
	Cache => 1,
	Expires => 2,
	Key => [ 'EXPIRES FUTURE' ],
    });
    if($_ == 2) { sleep 2; };
    $t->eok(length($$out) == $out_length, "Output length from include should be $out_length, found: ".length($$out));
};
&$check_cache_counts("EXPIRES FUTURE", miss => 1, fetch => 1, expires => 1, store => 2);
&$reset_cache_counts;

# LAST MODIFIED EXPIRE/CACHE
for my $last_modified ( time + 10, Apache::ASP::Date::time2str(time + 10), time-10, Apache::ASP::Date::time2str(time-10) ) {
    my $out = $Response->TrapInclude({
	File => \$script,
	Cache => 1,
	Key => [ 'EXPIRES FUTURE' ],
	LastModified => $last_modified,
    });
    $t->eok(length($$out) == $out_length, "Output length from include should be $out_length, found: ".length($$out));
}
&$check_cache_counts("LAST MODIFED EXPIRES", last_modified_expires => 2, store => 2, fetch => 2);
&$reset_cache_counts;

# CLEAR
for (1,0,1,0,1) {
    my $out = $Response->TrapInclude({
	File => \$script,
	Cache => 1,
	Key => [ 'EXPIRES FUTURE' ],
	Clear => $_,
    });
    $t->eok(length($$out) == $out_length, "Output length from include should be $out_length, found: ".length($$out));
}
&$check_cache_counts("CLEAR", store => 3, fetch => 2);
&$reset_cache_counts;

# KEY
for (1,0,1,0,1) {
    my $out = $Response->TrapInclude({
	File => \$script,
	Cache => 1,
	Key => { 'KEY TEST' => $_ },
    });
    $t->eok(length($$out) == $out_length, "Output length from include should be $out_length, found: ".length($$out));
}
&$check_cache_counts("CLEAR", miss => 2, store => 2, fetch => 3);
&$reset_cache_counts;

# NORMAL + RV
for my $arg (1,0,1,0,1,0,1) {
    my @rv = $Response->Include({
	File => 'cache_test.inc',
	Cache => 1,
    }, $arg, $arg);
    $Response->Debug("return values from cached include: ",@rv);
    $t->eok((grep($_ eq $arg, @rv)) == 2, "Return values from caching include");
    my $out = $Response->{BinaryRef};
    $$out =~ s/\s+//isg;
    $t->eok(length($$out) == $out_length, "Output length from include should be $out_length, found: ".length($$out));
    $Response->Clear;
}
&$check_cache_counts("CLEAR", miss => 2, store => 2, fetch => 5);
&$reset_cache_counts;

# KEY CHECK 2
for my $arg ({ arg => 1 }, { arg => 1 }, { arg => 1 }, { arg => 2 }) {
    my @rv = $Response->Include({
	File => 'cache_test.inc',
	Cache => 1,
	Key => $arg
	}, $arg );
    my $out = $Response->{BinaryRef};
    $$out =~ s/\s+//isg;
    $t->eok(length($$out) == $out_length, "Output length from include should be $out_length, found: ".length($$out));
    $Response->Clear;
}
&$check_cache_counts("CLEAR", miss => 2, store => 2, fetch => 2);
&$reset_cache_counts;

$asp->{r}->register_cleanup(sub { -e $cache_lock && die("cache lock $cache_lock still exists after cleanup") });

%>


