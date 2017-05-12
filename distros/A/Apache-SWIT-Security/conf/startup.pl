use strict;
use warnings FATAL => 'all';

BEGIN {
	use File::Basename qw(dirname);
	use Cwd qw(abs_path);
	unshift @INC, abs_path(dirname(__FILE__) . "/../lib");
}

use Template;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Const -compile => qw(FORBIDDEN OK REDIRECT);

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
$Apache::SWIT::TEMPLATE = Template->new({ ABSOLUTE => 1
		, INCLUDE_PATH => ($INC[0] . "/..") })
	or die "Unable to create template object";

1;
