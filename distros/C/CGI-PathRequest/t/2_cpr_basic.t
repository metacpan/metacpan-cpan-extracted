use Test::Simple 'no_plan';
use strict;
use Cwd;
use lib './lib';
use CGI::PathRequest;
CGI::PathRequest::DEBUG = 1;
use Smart::Comments '###';
$ENV{DOCUMENT_ROOT} = cwd()."/t/public_html";


my $rels = [

	{ 
		exists => 1,
		rel_path => 'demo', 
		is_root => 0,
		is_empty_dir=>0,
		is_dir => 1,
		is_file => 0,
		is_binary=> 1,
		is_image => 0,
		is_text => 0, 
		abs_path => $ENV{DOCUMENT_ROOT}.'/demo',
		rel_loc => '',
		abs_loc => $ENV{DOCUMENT_ROOT}.'',
		ext => undef,
		mime_type => undef,
		has_lsd => 1,
		has_lsf => 1,
		has_ls => 1,

	},
	{ 
		exists => 1,
		rel_path => 'demo/hellokitty.gif', 
		is_dir => 0,
		is_root => 0,
		is_empty_dir=>undef,
		is_file => 1,
		is_binary=> 1,
		is_image => 1,
		is_text => 0,
		abs_path => $ENV{DOCUMENT_ROOT}.'/demo/hellokitty.gif',
		rel_loc => 'demo',
		abs_loc => $ENV{DOCUMENT_ROOT}.'/demo',
		ext => 'gif',
		mime_type => 'image/gif',
		has_lsd => undef,
		has_lsf => undef,
		has_ls => undef,

	},



	
	{ 
		exists => 1,
		rel_path => 'demo/civil.txt', 
		is_dir => 0,	
		is_file => 1,
		is_root => 0,
		is_binary=> 0,
		is_empty_dir=>undef,
		is_image => 0,
		is_text => 1,
		abs_path => $ENV{DOCUMENT_ROOT}.'/demo/civil.txt',
		rel_loc => 'demo',
		abs_loc => $ENV{DOCUMENT_ROOT}.'/demo',
		ext => 'txt',
		mime_type => 'text/plain',
		has_lsd => undef,
		has_lsf => undef,
		has_ls => undef,

	},


	{ 
		exists => 1,
		rel_path => 'demo/subdee1', 
		is_dir => 1,	
		is_file => 0,
		is_root => 0,
		is_empty_dir=>1,
		is_binary=> 1,
		is_image => 0,
		is_text => 0,
		abs_path => $ENV{DOCUMENT_ROOT}.'/demo/subdee1' ,
		rel_loc => 'demo',		
		abs_loc => $ENV{DOCUMENT_ROOT}.'/demo',
		ext => undef,
		mime_type => undef,
		has_lsd => 0,
		has_lsf => 0,
		has_ls => 0,

	},

	{ 
		exists => 0,
		rel_path => 'demo/subd23ee', 
	},


];

# for testing empty dir
mkdir($ENV{DOCUMENT_ROOT}.'/demo/subdee1');		

for (@{$rels}){
	my $test = $_;

	my $test_rel_path = $test->{rel_path};
	### $test_rel_path
	
	my $r;
	

	if ($test->{exists}){
		ok( $r = new CGI::PathRequest({ rel_path=> $test->{rel_path} }),'construct instance for: '.$test->{rel_path});	
		ok( $r->exists ,'exists() ');
	} 
	
	else {
      ### no existy
		$r = new CGI::PathRequest({ rel_path=> $test->{rel_path} });
      ok( !$r );
      next;
   
	#	if ($r->set($ENV{DOCUMENT_ROOT}.'/'.$test->{rel_path})) { print "--\n r is defined --$$test{rel_path}\n";}
		#ok( !$r ,'constructor must fail to return object on non existant resource');
		#next;	
	}	

	
		
	
	ok($r->is_dir == $test->{is_dir},'is_dir()');

	if (defined $test->{is_empty_dir}){
		ok($r->is_empty_dir == $test->{is_empty_dir},
			"is_empty_dir()");
	} else {
		ok(!$r->is_empty_dir, 'should not be empty dir');
		
	}

	if ($test->{is_dir}){
		ok($r->is_dir, 'is_dir()');

		$$test{has_ls} ? ok( scalar @{$r->ls} > 0 ) : ok( scalar @{$r->ls} == 0);
		$$test{has_lsd} ? ok( scalar @{$r->lsd} > 0 ) : ok( scalar @{$r->lsd} == 0);
		$$test{has_lsf} ? ok( scalar @{$r->lsf} > 0 ) : ok( scalar @{$r->lsf} == 0);	
		
	}
	
	ok($r->is_root == $test->{is_root}, "is_root(),  control:$$test{is_root} returned:".$r->is_root);
	ok($r->is_file == $test->{is_file}, 'is_file()');
	
	ok($r->is_binary == $test->{is_binary},'is_binary()');
	ok($r->is_image == $test->{is_image},'is_image()');
	ok($r->abs_path eq $test->{abs_path},'abs_path()') or print STDERR ' abs_path '.$r->abs_path." should be $$test{abs_path}\n";
	ok($r->rel_path eq $test->{rel_path},'rel_path()') or print STDERR ' rel_path '.$r->rel_path." should be $$test{rel_path}\n";
	ok($r->abs_loc eq $test->{abs_loc},'abs_loc()') or print STDERR ' abs_loc '.$r->abs_loc." should be $$test{abs_loc}\n";
	ok($r->rel_loc eq $test->{rel_loc},'rel_loc()') or print STDERR ' rel_loc '.$r->rel_loc." should be $$test{rel_loc}\n";	
	ok($r->is_text == $test->{is_text},'is_text()');

	if ( defined $test->{ext} ){
		ok($r->ext eq $test->{ext},'ext()') or print STDERR " ext was ".$r->ext." should be $$test{ext}\n";;
	} else {
		ok(!$r->ext,'ext');
	}
	
	#ok($r->mime_type eq $test->{mime_type},'mime type') or print STDERR ' mime_type was '.$r->mime_type . " should be $$test{mime_type}\n";
	if ($test->{mime_type}){
		ok($r->mime_type, " mime_type: ".$r->mime_type);
	} 
	else {
		#print STDERR $r->mime_type."\n";
		ok(!$r->mime_type, 'no mime type' );
	 
	
	}

print STDERR "\n\n";	
}
	
rmdir($ENV{DOCUMENT_ROOT}.'/demo/subdee1');		



open(FILE, ">$ENV{DOCUMENT_ROOT}/temp.html");
print FILE "<p>html</p>";
close FILE;
my $f = new CGI::PathRequest("$ENV{DOCUMENT_ROOT}/temp.html");
ok($f, 'instance of html');

my $is_html =  $f->is_html;

## $is_html

ok($f->is_html);
unlink $f->abs_path;
