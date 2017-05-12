package Wine;
use lib qw(lib);
use XML::CommonNS qw(FOAF);
use Class::OWL 
	url => 'http://xmlns.com/foaf/0.1/index.rdf',
	namespaces => {
		foaf => '$FOAF',
	},
	debug => 1;
				
1;
