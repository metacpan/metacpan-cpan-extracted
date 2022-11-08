use strict;
use warnings;

use App::Kramerius::To::Images;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use HTTP::Response;
use Test::File::Contents;
use Test::LWP::UserAgent;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Output;

# Test.
my $page_uuid = '11a7ffc0-c61e-11e6-ac1c-001018b5eb5c';
my $useragent = Test::LWP::UserAgent->new;
my $uri = 'kramerius.mzk.cz/search/api/v5.0/item/uuid:'.$page_uuid.'/children';
$useragent->map_response(
	qr{$uri},
	HTTP::Response->new(
		'200',
		'OK',
		['Content-Type' => 'application/json;charset=utf-8'],
		'[]',
	),
);
my $temp_dir = tempdir('CLEANUP' => 1);
my $obj = App::Kramerius::To::Images->new(
	'dir_to_store_files' => $temp_dir,
	'lwp_user_agent' => $useragent,
);
@ARGV = (
	'mzk',
	$page_uuid,
);
my $right_ret = <<'END';
11a7ffc0-c61e-11e6-ac1c-001018b5eb5c: ?
END
stdout_is(
	sub {
		$obj->run;
		return;
	},
	$right_ret,
	"Run with listing of 'mzk' Kramerius system.",
);
$right_ret = <<'END';
mzk
11a7ffc0-c61e-11e6-ac1c-001018b5eb5c
END
file_contents_eq(catfile($temp_dir, 'ROOT'), $right_ret, 'Content of ROOT file.');
$right_ret = <<"END";
$page_uuid.jpg
END
chomp $right_ret;
file_contents_eq(catfile($temp_dir, 'LIST'), $right_ret, 'Content of LIST file.');
$right_ret = <<'END';
[]
END
chomp $right_ret;
file_contents_eq(catfile($temp_dir, $page_uuid.'.json'), $right_ret,
	'Content of '.$page_uuid.'.json file.');
