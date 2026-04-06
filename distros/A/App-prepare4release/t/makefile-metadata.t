#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(ok done_testing);
use Test2::Tools::Compare qw(is like);
use File::Path qw(make_path);
use File::Spec ();
use File::Temp qw(tempdir);

use App::prepare4release;

my $tmp = tempdir( CLEANUP => 1 );

my $mf = File::Spec->catfile( $tmp, 'Makefile.PL' );
open my $fm, '>:encoding(UTF-8)', $mf or die $!;
print {$fm} <<'MK';
use 5.010;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME             => 'Old::Name',
    VERSION_FROM     => 'lib/Old.pm',
    AUTHOR           => 'Old Author',
    ABSTRACT         => 'old abstract',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.010001',
);
MK
close $fm;

my $content = do {
	open my $fh, '<:encoding(UTF-8)', $mf or die $!;
	local $/;
	<$fh>;
};

my $cfg = {
	author         => 'New Author <new@example.com>',
	abstract       => 'New abstract text',
	module_name    => 'My::Dist',
	version_from   => 'lib/My/Dist.pm',
	min_perl_version => '5.020',
	license        => 'perl_5',
	exe_files      => [ 'bin/my-tool', 'bin/other' ],
};

my ( $new, $changed ) = App::prepare4release->ensure_makefile_metadata_from_config(
	$mf, $content, $cfg, 0 );

ok( $changed, 'metadata patch reported changes' );
like( $new, qr/AUTHOR\s*=>\s*'New Author <new\@example\.com>'/, 'AUTHOR' );
like( $new, qr/ABSTRACT\s*=>\s*'New abstract text'/, 'ABSTRACT' );
like( $new, qr/NAME\s*=>\s*'My::Dist'/, 'NAME from module_name' );
like( $new, qr/VERSION_FROM\s*=>\s*'lib\/My\/Dist\.pm'/, 'VERSION_FROM' );
like( $new, qr/MIN_PERL_VERSION\s*=>\s*'5\.020'/, 'MIN_PERL_VERSION' );
like( $new, qr/LICENSE\s*=>\s*'perl_5'/, 'LICENSE' );
like( $new, qr/EXE_FILES\s*=>\s*\[\s*'bin\/my-tool'\s*,\s*'bin\/other'\s*\]/, 'EXE_FILES' );

# Insert-only key when missing from WriteMakefile
{
	my $mf2 = File::Spec->catfile( $tmp, 'Makefile2.PL' );
	open my $f2, '>:encoding(UTF-8)', $mf2 or die $!;
	print {$f2} <<'MK2';
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'X::Y',
    VERSION_FROM => 'lib/X/Y.pm',
);
MK2
	close $f2;
	my $c2 = do {
		open my $h, '<:encoding(UTF-8)', $mf2 or die $!;
		local $/;
		<$h>;
	};
	my ( $n2, $ch2 ) = App::prepare4release->ensure_makefile_metadata_from_config(
		$mf2, $c2, { author => 'Inserted Author' }, 0 );
	ok( $ch2, 'insert AUTHOR when absent' );
	like( $n2, qr/AUTHOR\s*=>\s*'Inserted Author'/, 'AUTHOR inserted before closing paren' );
}

done_testing;
