use strict;
use warnings;
use Test::More tests => 6;

my $required = {
	'Moose' => "1.2.1",
	'MooseX::NonMoose' => 0.17,
	'Catalyst::Runtime' => 5.80030,
	'Catalyst::Model::DBIC::Schema' => 0.48,
	'DBIx::Class' => 0.08126,
	'SQL::Translator' => 0.11007,
};
foreach (keys %$required ){
#my $line = 
eval	"use " . $_ . " " . $required->{$_} . ";";

#eval $line;
	delete $required->{$_} unless $@;
}

my $message;
if(%$required){
	$message = 
"\n###################################################################
# THE FOLLOWING MODULES ARE REQUIRED TO RUN THE TEST APPLICATION: #
###################################################################
\n";


	foreach (keys %$required){
		my $module = $_;
		my $version = $required->{$module};
		$message.= "  $module\t (>= $version)\n";
	}

	$message.= "

 If you see this message, the included Catalyst Test Application 
 can not load due to missing dependencies.

 If all tests in resultroles-basic.t passed, the module will 
 most likely work correct on your computer. 

 To test the module with a small Catalyst Application, install 
 the packages listed above and run 'make test' again.

###################################################################";

		diag $message;
}


SKIP: {
	      skip 'missing dependencies',6 if %$required;



	      use lib "t/lib";

	      use_ok('MyAppCreateDB'); # fill database

#try to load the application
	      use_ok("Catalyst::Test", "MyApp") ;

	      my $id = 1;

	      my $response = request('/books/authors_by_id/'.$id);
	      ok( $response->is_success , qq 'Request for "/books/authors_by_id/$id" ') ;
	      ok( $response->content =~ /authors for book id \d+: (\w+\s\w+(,\s){0,1})*/,
			      qq 'Request for "/books/authors_by_id/$id" '
		) ;

	      my $a_count = get("/books/author_count/$id");
	      ok( 
			      $a_count =~ /Book with id \d+ has \d+ authors/, 
			      qq 'get "/books/author_count/$id" ' 
		) ;

	      my $related = get("/books/related_books/".$id);
	      ok( 
			      $related =~ /related books for id \d+: ((\w+\s)+\((\w+\s\w+(,\s){0,1})+\))*/, 
			      qq 'get "/books/related_books/$id" '  
		) ;

      }
#done_testing();
