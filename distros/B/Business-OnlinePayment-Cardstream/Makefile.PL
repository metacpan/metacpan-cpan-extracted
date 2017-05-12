use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'	=>	'Business::OnlinePayment::Cardstream',
	'VERSION_FROM'	=>	'Cardstream.pm',
	'AUTHOR'	=>	'Craig R. Belcham <crb@cardstream.com>',
	'dist'		=>	{CI	=>	'ci -l'},
);



