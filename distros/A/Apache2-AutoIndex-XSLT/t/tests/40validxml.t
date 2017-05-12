use strict;
use warnings FATAL => 'all';
  
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET_BODY';

plan tests => 1, have_module qw(XML::Validate);

my $validator;
if (eval { $validator = new XML::Validate(Type => 'BestAvailable'); }) {
	my $url = '/test/';
	my $data = GET_BODY $url;
	my $error = '';
	unless ($validator->validate($data)) {
		my $message = $validator->last_error()->{message} || '';
		my $line = $validator->last_error()->{line} || '';
		my $column = $validator->last_error()->{column} || '';
		$error = "Error: $message at line $line, column $column";
	}
	ok t_cmp($error, '', 'no xml validation errors');

} else {
	skip "Incomplete XML::Validate installation";
}
  

