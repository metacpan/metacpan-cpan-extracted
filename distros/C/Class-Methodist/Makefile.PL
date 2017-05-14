use 5.008003;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME => 'Class::Methodist',
   VERSION => 1.6,
   PREREQ_PM => {
		 Class::ISA => 0,
		 Class::Singleton => 0,
		 Test::Exception => 0,
		 Test::More => 0,
		}
  );
