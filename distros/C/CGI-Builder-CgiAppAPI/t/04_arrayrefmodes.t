use Test::More tests => 6;

use CGI;


# Prevent output to STDOUT
$ENV{CGI_APP_RETURN_ONLY} = 1;


BEGIN{ chdir './t'} ;
use lib 'test';
   use TestApp8  ;

# Test array-ref mode
{
	my $ta_obj = TestApp8->new();
	my $output = $ta_obj->run();

	# Did the run-mode work?
	like($output, qr/^Content\-Type\:\ text\/html/);
	like($output, qr/Hello\ World\:\ testcgi1\_mode\ OK/);
}


{
	my $q = CGI->new({rm=>testcgi2_mode});
	my $ta_obj = TestApp8->new(QUERY=>$q);
	my $output = $ta_obj->run();

	# Did the run-mode work?
	like($output, qr/^Content\-Type\:\ text\/html/);
	like($output, qr/Hello\ World\:\ testcgi2\_mode\ OK/);
}


{
	my $q = CGI->new({rm=>testcgi3_mode});
	my $ta_obj = TestApp8->new(QUERY=>$q);
	my $output = $ta_obj->run();

	# Did the run-mode work?
	like($output, qr/^Content\-Type\:\ text\/html/);
	like($output, qr/Hello\ World\:\ testcgi3\_mode\ OK/);
}


###############
####  EOF  ####
###############
