use FindBin;
use lib "$FindBin::Bin/lib";
use strict;
use warnings;
use Test::More;
use Catalyst::Test 'TestApp';
use Data::Dumper;
use HTTP::Request::Common;   # reqd for POST requests

eval "use PHP 0.14";
if ($@) {
   plan skip_all => "PHP 0.14 needed for testing";
}

BEGIN {
    no warnings 'redefine';
    *Catalyst::Test::local_request = sub {
	my ($class, $req) = @_;
	my $app = ref($class) eq "CODE" ? $class : $class->_finalized_psgi_app;
	my $ret;
	require Plack::Test;
	Plack::Test::test_psgi(
	    app => sub { $app->( %{ $_[0] } ) },
	    client => sub { $ret = shift->{request} } );
	return $ret;
    };
}

my $entrypoint = "http://localhost/foo";

sub array {
    return { @_ };
}

{

    # how to do a request that simulates a file upload??
    my $size = -s "t/testapp.conf";
    my $response = request POST 'http://localhost/handle_upload.php', 
    	Content_Type => 'form-data',
    	Content => [
	    my_file => [ "t/testapp.conf", "test_file_name", "Content-type" => "text/plain; charset=UTF-8" ]
	];

    my $content = eval { $response->content };

    ok( $response, 'response ok for POST with file upload' );
    ok( $content,  'got content for POST with file upload' );
    ok( $content =~ /\$_FILES =/, 'content looks like correct format' );
    ok( $content =~ /\bmy_file\b/, 'content got correct file upload param name' );
    ok( $content =~ /\bname\b.*test_file_name/, 'file upload recorded filename' );
    ok( $content =~ /\bsize\b\D*(\d+)/ && $1 == $size,
	'file upload recorded correct file size' );
    my $tmp_name = PHP::eval_return( "\$_FILES['my_file']['tmp_name']" );
    ok( $tmp_name, "can recover file temp name $tmp_name from PHP" );
    ok( PHP::eval_return( "is_uploaded_file('$tmp_name')" ),
	"PHP believes $tmp_name is uploaded file" );

### files may be deleted when the request is complete.
### need to perform the test inside PHP to read, move file
#    ok( PHP::eval_return( "is_file('$tmp_name')" ),
#	"PHP believes $tmp_name is file" );
#    ok( -f $tmp_name, "Perl believes $tmp_name is a file" );

    ### multiple uploads

    my $size2 = -s "MANIFEST";
    $response = request POST 'http://localhost/handle_upload.php', 
    	Content_Type => 'form-data',
    	Content => [
	    foo => 123,
	    my_file1 => [ "t/testapp.conf", "test_file_namex", 
			  "Content-type" => "text/plain; charset=UTF-8" ],
	    my_file2 => [ "MANIFEST", "manifest", 
			  "Content-type" => "application/octet-stream" ],
	    bar => 19,
	];
    $content = eval { $response->content };
    ok( $response, 'response ok for POST with file upload' );
    ok( $content,  'got content for POST with file upload' );
    ok( $content =~ /\$_FILES =/, 'content looks like correct format' );
    ok( $content =~ /\bmy_file1\b/, 'content got correct 1st file upload param name' );
    ok( $content =~ /\bmy_file2\b/, 'content got correct 2nd file upload param name' );
    ok( $content =~ /my_file1.*\bname\b\W*test_file_namex/s, 'file upload recorded filename1' );
    ok( $content =~ /my_file2.*\bname\b\W*manifest/s, 'file upload recorded filename2' );
    ok( $content =~ /size\D*$size\b/,
	'file upload recorded correct file1 size' );
    ok( $content =~ /size\D*$size2\b/,
	'file upload recorded correct file2 size' );
    ok( PHP::eval_return( q^is_uploaded_file($_FILES['my_file1']['tmp_name'])^ ),
	"PHP believes file1 is uploaded file" );
    ok( PHP::eval_return( q^is_uploaded_file($_FILES['my_file2']['tmp_name'])^ ),
	"PHP believes file2 is uploaded file" );

    ### array upload

    my $size3 = -s "Makefile.PL";
    $response = request POST 'http://localhost/handle_upload.php', 
    	Content_Type => 'form-data',
    	Content => [
	    foo => 123,
	    'farray[]' => [ "t/testapp.conf", "test_file_namex", 
			  "Content-type" => "text/plain; charset=UTF-8" ],
	    'farray[]' => [ "MANIFEST", "manifest", 
			  "Content-type" => "application/octet-stream" ],
	    'farray[]' => [ "Makefile.PL", "makefile_pl", 
			  "Content-type" => "application/octet-stream" ],
	    bar => 19,
	];
    $content = eval { $response->content };

    ok( $response, 'got response for array upload' );
    ok( $content,  'got content for array upload' );
    ok( $content =~ /\bfarray\W+array\b/s, 'farray param is an array' );
    ok( $content =~ /\btmp_name\W+array/s &&
	$content =~ /\berror\W+array/s &&
	$content =~ /\bname\W+array/s &&
	$content =~ /\bsize\W+array/s, 'upload data is in arrays' );

    my ($sizes) = $content =~ /\bsize\W+array(.*?)\)/s;
    ok( $sizes =~ /\b0\W+$size\b/, 'got right size for file 1' );
    ok( $sizes =~ /\b1\W+$size2\b/, 'got right size for file 2' );
    ok( $sizes =~ /\b2\W+$size3\b/, 'got right size for file 3' );
    ok( PHP::eval_return( q^is_uploaded_file($_FILES['farray']['tmp_name'][0])^ ),
	"PHP believes file[0] is uploaded file" );
    ok( PHP::eval_return( q^is_uploaded_file($_FILES['farray']['tmp_name'][2])^ ),
	"PHP believes file[2] is uploaded file" );


    ####################################################

    $response = request POST 'http://localhost/output_upload.php', 
    	Content_Type => 'form-data',
    	Content => [
	    foo => 123,
	    'output' => [ "t/testapp.conf", "test_file_namex", 
			  "Content-type" => "text/plain; charset=UTF-8" ],
	];
    $content = eval { $response->content };
    ok( $response, 'response from output_upload.php ok' );
    ok( $content,  'content avaialble from output_upload.php' );

    ok( $content =~ /is_uploaded_file \[1\] result = 1/,
	'php reports file uploaded successfully' );
    ok( $content =~ /move_uploaded_file result = 1/,
	'php reports file upload file moved successfully' );
    ok( $content =~ /is_uploaded_file \[2\] result = 0/,
	'php reports file not found after it was moved' );
    my ($len) = $content =~ /length read = (\d+)/;
    ok( $len ne '', 'php reports file length' );
    ok( $len == -s "t/testapp.conf",
	'php length agrees with known file length' );

#   diag $content;

}

done_testing();
