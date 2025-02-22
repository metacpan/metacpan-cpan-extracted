use strict;
use warnings;

use App::CPAN::Get;
use Cwd;
use English;
use Error::Pure::Utils qw(clean);
use File::Object;
use File::Spec::Functions qw(abs2rel catfile);
use File::Temp qw(tempdir);
use HTTP::Response;
use Perl6::Slurp qw(slurp);
use Test::LWP::UserAgent;
use Test::More 'tests' => 8;
use Test::NoWarnings;
use Test::Output;
use Test::Warn;

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::CPAN::Get->new->run;
		return;
	},
	$right_ret,
	'Run help (-h).',
);

# Test.
@ARGV = ();
$right_ret = help();
stderr_is(
	sub {
		App::CPAN::Get->new->run;
		return;
	},
	$right_ret,
	'Run help (no module name).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::CPAN::Get->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

# Test.
@ARGV = (
	'App::CPAN::Search',
);
$right_ret = <<'END';
Module 'App::CPAN::Search' doesn't exist.
END
eval {
	App::CPAN::Get->new(
		'lwp_user_agent' => Test::LWP::UserAgent->new,
	)->run;
};
is($EVAL_ERROR, "Module 'App::CPAN::Search' doesn't exist.\n",
	"Module 'App::CPAN::Search' doesn't exist.");
clean();

# Test.
@ARGV = (
	'App::CPAN::Search',
);
my $user_agent = Test::LWP::UserAgent->new;
my $content = <<'END';
{
   "release" : "App-CPAN-Search-0.09",
   "checksum_sha256" : "7239ce1154a4002b9b461e5ad80a50ac21b9477b7f000a6a89f924e546e7a63d",
   "version" : "0.09",
   "status" : "latest",
   "date" : "2023-01-23T17:24:56",
   "download_url" : "https://cpan.metacpan.org/authors/id/S/SK/SKIM/App-CPAN-Search-0.09.tar.gz",
   "checksum_md5" : "798a40ee72e0078a8f960186d94eb4b4"
}
END
$user_agent->map_response(
	qr(https://fastapi\.metacpan\.org/v1/download_url/App::CPAN::Search),
	HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/json; charset=utf-8'], $content),
);
$user_agent->map_response(
	qr{https://cpan\.metacpan\.org/authors/id/S/SK/SKIM/App-CPAN-Search-0\.09\.tar\.gz},
	HTTP::Response->new('200', 'OK', ['Content-Type' => 'application/x-gzip'], 'test content'),
);
$right_ret = <<'END';
Package on 'https://cpan.metacpan.org/authors/id/S/SK/SKIM/App-CPAN-Search-0.09.tar.gz' was downloaded.
END
my $tmp_dir = tempdir('CLEANUP' => 1);
my $act_dir = getcwd();
chdir $tmp_dir;
stdout_is(
	sub {
		App::CPAN::Get->new(
			'lwp_user_agent' => $user_agent,
		)->run;
	},
	$right_ret,
	'File saved.',
);
my $tmp_file_content = slurp(catfile($tmp_dir, 'App-CPAN-Search-0.09.tar.gz'));
is($tmp_file_content, 'test content', 'Check content of downloaded file.');
chdir $act_dir;

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-f] [-h] [--version] module_name[module_version]
	-f		Force download and rewrite of existing file.
	-h		Print help.
	--version	Print version.
	module_name	Module name. e.g. App::Pod::Example
	module_version	Module version. e.g. \@1.23, ~1.23 etc.
END

	return $help;
}
