package Algorithm::Classifier::IsolationForest::App;

use 5.006;
use strict;
use warnings;
use App::Cmd::Setup -app;

sub global_opt_spec {
	return ( [ 'help|h' => "This usage screen." ], [ 'version|v' => "This usage screen." ], );
}

1;
