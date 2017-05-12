package inc::MakeMaker;

use Moose;
use Devel::CheckLib;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;
	my $template  = "use Devel::CheckLib;\n";
	$template .= "check_lib_or_exit(libpath => '/usr/lib/llvm-3.5/lib', lib => 'clang');\n";

	return $template.super();
};

override _build_WriteMakefile_args => sub {
	return +{
		%{ super() },
		LIBS	=> '-L/usr/lib/llvm-3.5/lib -lclang',
		INC	=> '-I. -I/usr/lib/llvm-3.5/include',
		OBJECT	=> '$(O_FILES)',
	}
};

__PACKAGE__ -> meta -> make_immutable;
