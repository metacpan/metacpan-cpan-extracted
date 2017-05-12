use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::Startup;
use base 'Apache::SWIT::Maker::Skeleton';

sub output_file { return 'conf/startup.pl'; }

sub template { return <<'ENDM'; }
use strict;
use warnings FATAL => 'all';

BEGIN {
	use File::Basename qw(dirname);
	use Cwd qw(abs_path);
	unshift @INC, abs_path(dirname(__FILE__) . "/../lib");
}

use Apache::SWIT::Template;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Const -compile => qw(:common);

use Apache2::ServerRec ();
use Apache2::ServerUtil ();
use Apache2::Connection ();
use Apache2::Log ();

use APR::Table ();

use HTML::Tested::Seal;
use File::Slurp;
use HTML::Tested qw(HT HTV);
use HTML::Tested::JavaScript qw(HTJ);
use Apache::SWIT::DB::Connection;
use HTML::Tested::List;
use Apache::SWIT;

eval "use " . HTV() . "::$_" for qw(Marked Form Hidden Submit EditBox Link
					Upload DropDown PasswordBox CheckBox);

HTML::Tested::Seal->instance(read_file($INC[0] . '/../conf/seal.key'));

$Apache::SWIT::TEMPLATE = Apache::SWIT::Template->new;
$Apache::SWIT::TEMPLATE->preload_all;

1;
ENDM

1;
