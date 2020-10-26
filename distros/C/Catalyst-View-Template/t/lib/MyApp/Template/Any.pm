use strict; use warnings;

package MyApp::Template::Any;

use MRO::Compat ();

use File::Spec ();
use Template ();
BEGIN { our @ISA = 'Template' }

sub new {
	my $class = shift;
	$_[0]{'INCLUDE_PATH'} = File::Spec->catdir(qw( t lib MyApp alt_root ));
	$_[0]{'POST_CHOMP'} = 1;
	$class->next::method( @_ );
}

1;
