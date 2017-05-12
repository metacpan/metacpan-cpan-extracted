use ExtUtils::MakeMaker;

my $me = "lib/Bluepay/Bluepay20DailyReport.pm";

WriteMakefile(
    'NAME'		=> 'Bluepay::Bluepay20DailyReport',
    'VERSION_FROM'	=> $me, 
    'PREREQ_PM'		=> { 
                     'Digest::MD5' => 2.36,
					 'LWP::UserAgent' => 5.81,
				     'URI::Escape' => 1.36,
				     'Text::CSV' => 1.04,
                           },
    ($] < 5.005 ? () : (
       ABSTRACT_FROM => $me, 
       AUTHOR     => 'Christopher Kois <cpkois@cpan.org>') 
    ),
);
