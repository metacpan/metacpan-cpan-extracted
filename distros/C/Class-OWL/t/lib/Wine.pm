package Wine;
use lib qw(lib);
use Class::OWL 
	url => 'http://www.w3.org/TR/2004/REC-owl-guide-20040210/wine.rdf',
	namespaces => {
					wine => 'http://www.w3.org/TR/2003/PR-owl-guide-20031209/wine#',
				};
				
1;