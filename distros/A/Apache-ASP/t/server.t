use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(NoState => 1, Debug => 0);
$SIG{__DIE__} = \&Carp::confess;

__END__

<% use lib '.';	use T;	$t =T->new(); %>

<% 
my $encode = $Server->URLEncode("test data");
if($encode eq 'test%20data') {
	$t->ok();
} else {
	$t->not_ok('URLEncode not working');
}

$Server->Config('Global', '.');
$t->eok(sub { $Server->Config('Global') eq '.' }, 
	'Global must be defined as . for test'
	);
my $config = $Server->Config;
$t->eok($config->{Global} eq '.', 'Full config as hash');
$t->eok($Server->URL('test.asp', { 'test ' => ' value ' } )
	eq 'test.asp?test%20=%20value%20',
	'basic $Server->URL() encoding did not work'
	);
$t->eok($Server->URL('test.asp', { 'test' => ['value', 'value2'] })
	eq 'test.asp?test=value&test=value2',
	'multi params $Server->URL() encoding did not work'
	);
$t->eok($Server->URL('test.asp')
	eq 'test.asp',
	'no args $Server->URL() encoding did not work'
	);

my $html = q(&"<>'abc);
my $final = '&amp;&quot;&lt;&gt;&#39;abc';
my $result = $Server->HTMLEncode($html);
$t->eok($result eq $final, "\$Server->HTMLEncode('$html')");
my $ref_result = $Server->HTMLEncode(\$html);
$t->eok(\$html eq $ref_result, "\$Server->HTMLEncode(\\\$html) should output same ref as going in");
$t->eok($html eq $final, "$html does not equal $final");
$t->eok($Server->MapInclude('server.t') eq './server.t', "Find executing script in Includes path");
$t->eok($Server->File =~ /server.t$/, "\$Server->File does not match");

#use Benchmark;
#my $htmlbig = '&"<>' x 25000;
#timethis(10, sub { my $copy = $htmlbig; $copy = $Server->HTMLEncode($copy) });
#timethis(10, sub { my $copy = $htmlbig; $Server->HTMLEncode(\$copy) });

$Server->Transfer('transfer.inc');
%>
