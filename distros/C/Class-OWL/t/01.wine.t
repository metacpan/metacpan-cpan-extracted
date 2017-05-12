#use Test::More skip_all => 'debug strange 255 exit code';
use Test::More tests => 1;

# this works but it still fails - will debug
use Class::OWL
	package => 'Wine', 
	url => 'http://www.w3.org/TR/2004/REC-owl-guide-20040210/wine.rdf';

is(Wine::Wine->meta->_type->as_string,'http://www.w3.org/TR/2003/PR-owl-guide-20031209/wine#Wine',"type as expected");
