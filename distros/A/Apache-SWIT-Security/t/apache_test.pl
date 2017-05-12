use T::TempDB;
do "t/apache_test_run.pl";
unlink($_) for glob('t/logs/kids_are_clean.*');
