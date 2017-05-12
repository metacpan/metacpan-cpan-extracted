package inc::TestImageMakeMaker;
use Moose;

extends qw( Dist::Zilla::Plugin::MakeMaker::Awesome );


override _build_WriteMakefile_args => sub { +{
    %{ super() },
} };

override _build_WriteMakefile_dump => sub {
	my $str = super();
	$str .= <<'END';
use lib 'lib';
use lib 't/lib';
use Module::Load;
load 'Data::TestImage';
load 'StubTestImage';
$WriteMakefileArgs{CONFIGURE} = sub {
	my $install_these = $ENV{PERL_DATA_TESTIMAGE_INSTALL} // "USC::SIPI=miscellaneous";
	my @install = split ' ', $install_these;
	for my $package (@install) {
		my ($module_part,$args) = split "=", $package, 2;
		my $module = "Data::TestImage::DB::$module_part";
		load $module;
		$module->install_package($args, verbose => 1);
	}
	return {};
};
END
	$str;
};

__PACKAGE__->meta->make_immutable;
