use ExtUtils::MakeMaker;

WriteMakefile(
    'AUTHOR'            => 'Ilya Lityuga, Randall Whitman',
    'NAME'		=> 'Business::OnlinePayment::Beanstream',
    'VERSION'	        => '0.02',
    'PREREQ_PM'		=> {
       'Business::OnlinePayment' => 0,
       # for BOP:HTTPS - ?
       'URI::Escape' => 0,
    }, 
);
