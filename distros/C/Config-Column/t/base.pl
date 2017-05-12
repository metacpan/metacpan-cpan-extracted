use utf8;
use strict;
use warnings;
use Test::More;

our $set = {
datafile => 'column.pson',
};

sub initdata{
	my $datafile = shift;
	my $data;
	open my $fh,'<:encoding(utf8)',$Bin.'/'.$datafile;
	flock $fh,1;
	{
		local $/ = undef;
		$data = eval <$fh>;
	}
	close $fh;
	return $data;
}

sub testmulticond{
	my $initdatafile = shift;
	my $datafilename = shift;
	my $encoding = shift;
	my $order = shift;
	my $delimiter = shift;
	note('type '.$datafilename);
	for my $index (0,1,'',undef){
		for my $linedelimiter ("\n","\r","\0",'|-|',':_','',undef){
			my $datafile = $datafilename .
				'_index-' . (defined $index ? $index ne '' ? $index : 'empty' : 'undef') .
				'_linedelimiter-' . (defined $linedelimiter ? $linedelimiter ne '' ? ord $linedelimiter : 'empty' : 'undef') .
				'.dat';
			testmain($initdatafile,$datafile,$encoding,$order,$delimiter,$index,$linedelimiter);
		}
	}
}

sub testmain{
	my $initdatafile = shift;
	my $datafile = shift;
	my $encoding = shift;
	my $order = shift;
	my $delimiter = shift;
	my $index = shift;
	my $linedelimiter = shift;
	note('-- set start');
	my $sdata = initdata($initdatafile);
	is(ref $sdata,'ARRAY','sample data loaded.');
	unshift @$sdata,{} if defined $index && $index eq 1;
	is($#$sdata,2+(defined $index && $index =~ /^\d+$/ ? $index : 0),'sample data condition.');
	my $cc = Config::Column->new($FindBin::Bin.'/'.$datafile,$encoding,$order,$delimiter,$index,$linedelimiter);
	$index = 0 unless defined $index && $index =~ /^\d+$/;
	isa_ok($cc,'Config::Column','new()');
	is($cc->write_data($sdata),1,'write_data(sample data)');
	my $data = $cc->read_data();
	is(ref $data,'ARRAY','read_data()');
	#return;
	is($#$data,2+$index,'read_data()');
	is($data->[0]->{host},undef,'data check') if $index eq 1;
	is($data->[0+$index]->{host},'localhost','data check');
	is($data->[0+$index]->{subject},'Config::Columnリリース','data check');
	is($data->[2+$index]->{mail},'info/at/narazaka.net','data check');
	is($cc->write_data($data),1,'write_data()');
	is($cc->add_data_last({name => '編集', subject => '', date => '2013/03/05 (月) 18:33:00', value => '一年ぶりか……。', mail => '', url => '', key => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', host => 'narazaka.net', addr => '192.168.0.1'}),1,'add_data_last() and read_data_num()');
	is($cc->add_data_last([
		{name => 'さくら', subject => '', date => '2013/03/07 (月) 08:16:17', value => 'そうだね。', mail => '', url => '', key => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', host => 'narazaka.net', addr => '192.168.0.1'},
		{name => '編集', subject => '', date => '2013/03/09 (月) 18:15:02', value => '誰やねん。', mail => '', url => '', key => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', host => 'narazaka.net', addr => '192.168.0.1'},
	]),1,'add_data_last() and read_data_num()');
	$data = $cc->read_data();
	is(ref $data,'ARRAY','read_data()');
	is($#$data,5+$index,'read_data()');
	is($data->[0]->{host},undef,'data check') if $index eq 1;
	is($data->[0+$index]->{host},'localhost','data check');
	is($data->[0+$index]->{subject},'Config::Columnリリース','data check');
	is($data->[2+$index]->{mail},'info/at/narazaka.net','data check');
	is($data->[3+$index]->{name},'編集','data check');
	is($data->[4+$index]->{name},'さくら','data check');
	is($data->[5+$index]->{value},'誰やねん。','data check');
	splice @$data,2+$index,1;
	is($#$data,4+$index,'after splice');
	my ($ret,$fh) = $cc->write_data($data,undef,1);
	is($#$data,4+$index,'after write_data()');
	is($data->[2+$index]->{value},'一年ぶりか……。','after write_data()');
	is($ret,1,'write_data()');
	is(ref $fh,'GLOB','keep file handle');
	seek $fh,0,0;
	my ($data2) = $cc->read_data($fh,1);
	seek $fh,0,0;
	my $data3 = $cc->read_data($fh,1);
	seek $fh,0,0;
	my ($ret2,$fh2) = $cc->read_data($fh,1);
	is(ref $data2,'ARRAY','read_data()');
	is(ref $data3,'GLOB','read_data()');
	is(ref $ret2,'ARRAY','read_data()');
	is(ref $fh2,'GLOB','read_data()');
	truncate $fh2,0;
	seek $fh2,3,0;
	my ($ret3,$fh3) = $cc->write_data($data2,$fh2,1,1);
	is($ret3,1,'write_data()');
	is(ref $fh3,'GLOB','write_data() noempty');
	isnt(getc $fh3,1,'write_data() noempty');
	seek $fh3,3,0;
	my ($ret4) = $cc->read_data($fh3,1);
	is($ret4->[2+$index]->{value},'一年ぶりか……。','after write_data() noempty');
	pop @$data2;
	is($#$data2,3+$index,'poped');
	is($cc->write_data($data2,$fh),1,'write_data()');
	is($cc->read_data_num(),3+$index,'read_data_num()');
	is($cc->add_data({name => 'うにゅう', subject => '', date => '2013/03/10 (月) 08:17:27', value => 'ぐんにょり。', mail => '', url => '', key => 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', host => 'narazaka.net', addr => '192.168.0.1'},$cc->read_data_num + 1),1,'add_data()');
	my ($data4,$fh4) = $cc->read_data(undef,1);
	is($#$data4,4+$index,'read_data()');
	is(ref $fh4,'GLOB','read_data()');
	seek $fh4,0,0;
	is($cc->read_data_num($fh4),4+$index,'read_data_num()');
	is($data4->[4+$index]->{value},'ぐんにょり。','data check');
	$data4->[0+$index] = {};
	is($cc->write_data($data4),1,'write_data(sample data)');
	my $data5 = $cc->read_data();
	is(ref $data5,'ARRAY','read_data()');
	is($data5->[2+$index]->{name},'編集','data check');
	note('-- set end');
}

1;
