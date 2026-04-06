#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use Test2::Tools::Compare qw(is like);
use File::Spec ();
use File::Temp qw(tempdir);

use App::prepare4release;

my $root = tempdir( CLEANUP => 1 );

for my $content ( '', "  \n\t  " ) {
	my $path = File::Spec->catfile( $root, 'prepare4release.json' );
	open my $fh, '>:encoding(UTF-8)', $path or die $!;
	print {$fh} $content;
	close $fh;

	my $cfg = App::prepare4release->load_config_file($path);
	ok( ref $cfg eq 'HASH', 'load_config_file accepts empty-ish JSON file' );
	is( scalar keys %$cfg, 0, 'empty file yields empty object' );
}

# Malformed JSON must not throw; warn once and yield {}.
{
	my $path = File::Spec->catfile( $root, 'prepare4release.bad.json' );
	open my $fh, '>:encoding(UTF-8)', $path or die $!;
	print {$fh} <<'JSON';
{
	"author": "Sergey Kovalev <skov@cpan.org>"
	"git": {
		"author": "neo1ite",
		"repo": "neo1ite/Modern-OpenAPI-Generator"
	}
}
JSON
	close $fh;

	my @warn;
	local $SIG{__WARN__} = sub { push @warn, $_[0] };

	my $cfg = App::prepare4release->load_config_file($path);
	ok( ref $cfg eq 'HASH', 'invalid JSON still returns a hashref' );
	is( scalar keys %$cfg, 0, 'invalid JSON yields empty object' );
	ok( scalar @warn, 'invalid JSON produces a warning' );
	like(
		$warn[0],
		qr/prepare4release\.json: invalid JSON/,
		'warning mentions invalid JSON'
	);
}

done_testing;
