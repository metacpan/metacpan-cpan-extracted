use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'B::ConstOptree',
	VERSION_FROM => 'ConstOptree.pm',
	AUTHOR => 'Alexey Tourbin <at@altlinux.org>',
	ABSTRACT => 'Optree constant folding for $^O, $^V, and $]',
);
