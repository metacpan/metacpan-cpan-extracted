use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

subtest 'rule parsing' => sub {
    # check(<zone>, <hasdst>, <outer>, <inner>)
    # outer/inner: [<gmt_offset>, <abbrev>, <end>, <isdst>]
    # end: [<mon>, <week>, <wday>, <hour>, <min>, <sec>]
    wrong('A');
    wrong('MSK');
    check('MSK-1', 0, [3600]);
    check('MSK2', 0, [-7200]);
    check('MSK+3', 0, [-10800]);
    check('MSK-4MSD', 0, [14400]);
    wrong('MSK-4:');
    check('MSK-4:20', 0, [15600]);
    wrong('MSK-4:20:');
    check('MSK-4:20:08', 0, [15608]);
    wrong('MSK-4:20:01:');
    check('MSK-4:20:08MSA', 0, [15608]);
    wrong('MSK-4MSD,');
    wrong('MSK-4MSD,asdfdasfds');
    wrong('MSK-4MSD,M3.1.0');
    wrong('MSK-4MSD,M3.1.0,M10.5.0,');
    check('MSK-4MSD,M3.1.0,M10.5.0', 1, [14400, 'MSK', [2,1,0,2,0,0], 0], [18000, 'MSD', [9,5,0,2,0,0], 1]);
    check('MSK-4MSD,M3.1.0,M10.5.0/3', 1, [14400, 'MSK', [2,1,0,2,0,0], 0], [18000, 'MSD', [9,5,0,3,0,0], 1]);
    check('MSK-4MSD,M3.1.0,M10.5.0/3:15', 1, [14400, 'MSK', [2,1,0,2,0,0], 0], [18000, 'MSD', [9,5,0,3,15,0], 1]);
    check('MSK-4MSD,M3.1.0,M10.5.0/3:15:02', 1, [14400, 'MSK', [2,1,0,2,0,0], 0], [18000, 'MSD', [9,5,0,3,15,2], 1]);
    check('MSK-4MSD,M3.1.0/1,M10.5.0/3:15:02', 1, [14400, 'MSK', [2,1,0,1,0,0], 0], [18000, 'MSD', [9,5,0,3,15,2], 1]);
    check('MSK-4MSD,M3.1.0/1:59,M10.5.0/3:15:02', 1, [14400, 'MSK', [2,1,0,1,59,0], 0], [18000, 'MSD', [9,5,0,3,15,2], 1]);
    check('MSK-4MSD,M3.1.0/1:59:58,M10.5.0/3:15:02', 1, [14400, 'MSK', [2,1,0,1,59,58], 0], [18000, 'MSD', [9,5,0,3,15,2], 1]);
    wrong('MSK-4MSD,M3.1.0/1:59:58,M10.5.0/3:15:02:');
    wrong('MSK-4MSD,M3.1.0/1:59:58,M10.5.0/3:15:');
    wrong('MSK-4MSD,M3.1.0/1:59:58,M10.5.0/3:');
    wrong('MSK-4MSD,M3.1.0/1:59:58,M10.5.0/');
    wrong('MSK-4MSD,M3.1.0/1:59:,M10.5.0');
    wrong('MSK-4MSD,M3.1.0/1:,M10.5.0');
    wrong('MSK-4MSD,M3.1.0/,M10.5.0');
    check('MSK-4MSD,M3.1.0/-1,M10.5.0');
    wrong('MSK-4MSD,M3.0.0,M10.5.0');
    wrong('MSK-4MSD,M3.6.0,M10.5.0');
    wrong('MSK-4MSD,M3.0.0,M13.5.0');
    wrong('MSK-4MSD,M3.0.0,M0.5.0');
    wrong('MSK-4MSD,M3.1.-1,M0.5.0');
    wrong('MSK-4MSD,M3.1.7,M0.5.0');
    wrong('MSK-4-5');
    check('<MSK-4>-5', 0, [18000, 'MSK-4']);
    wrong(':MSK-4');
    wrong('MS1K-4');
    wrong('SK-4');
};

subtest 'timezones parsing' => sub {
    my $lzname = Date::tzname();
    my $zone = tzget();
    ok($zone);
    ok($zone->is_local);
    is($zone->name, $lzname);
    is(ref($zone->export->{transitions}), 'ARRAY');
    
    foreach my $zname (Date::available_zones()) {
        say "$zname";
        $zone = tzget($zname);
        ok($zone, "info is present ($zname)");
        if ($zone->name eq $lzname) {
            ok($zone->is_local, "zone is local ($zname)");
        } else {
            ok(!$zone->is_local, "zone is not local ($zname)");
        }
        is($zone->name, $zname, "info is correct ($zname)");
        is(ref($zone->export->{transitions}), 'ARRAY', "transitions are present ($zname)");
    }
};

done_testing();

sub wrong {
    my $zone = shift;
	isnt(tzget($zone)->name, $zone);
}

sub check {
    my $zname = shift;
	my $zone = tzget($zname);
	is($zone->name, $zname, "check[$zname]-name");
	ok(!$zone->is_local);
	return unless @_;
	
	my $info = $zone->export;
	my $hasdst = shift;
	ok($hasdst ? $info->{future}{hasdst} : !$info->{future}{hasdst}, "check[$zname]-hasdst");
	return unless @_;

	check_tzrulezone($info->{future}{outer}, shift(), "check[$zname]-outer-");
	return unless @_;

	check_tzrulezone($info->{future}{inner}, shift(), "check[$zname]-inner-");
}

sub check_tzrulezone {
    my ($info, $data, $nameprefix) = @_;
	my @data = @$data;
	
	my $off = shift @data;
	is($info->{gmt_offset}, $off, $nameprefix."gmtoff");
	return unless @data;
	
	my $abbrev = shift @data;
	is($info->{abbrev}, $abbrev, $nameprefix."abbrev");
	return unless @data;
	
	for (1) {
		my @end = @{shift @data};
		my $mon = shift @end;
		is($info->{end}{mon}, $mon, $nameprefix."endmon");
		last unless @end;
		
		my $week = shift @end;
		is($info->{end}{week}, $week, $nameprefix."endweek");
		last unless @end;
		
		my $wday = shift @end;
		is($info->{end}{day}, $wday, $nameprefix."endwday");
		last unless @end;
		
		my $hour = shift @end;
		is($info->{end}{hour}, $hour, $nameprefix."endhour");
		last unless @end;
		
		my $min = shift @end;
		is($info->{end}{min}, $min, $nameprefix."endmin");
		last unless @end;
		
		my $sec = shift @end;
		is($info->{end}{sec}, $sec, $nameprefix."endsec");
	}
	return unless @data;
	
	my $isdst = shift @data;
	ok($isdst ? $info->{isdst} : !$info->{isdst}, $nameprefix."isdst");
}
