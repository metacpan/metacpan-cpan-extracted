require CGI::Auth; 

my $authdir = 't/auth';

my $auth = CGI::Auth->new({
	-authdir                => $authdir,
	-formaction             => "myscript.pl",
	-authfields             => [
		{id => 'user', display => 'User Name', hidden => 0, required => 1},
		{id => 'pw', display => 'Password', hidden => 1, required => 1},
	],
});
$auth->check;

print $auth->data( 'sess_file' );
