use Object::Pad ':experimental(:all)';

package BS::Ext::User 0.01;
role BS::Ext::User : does(BS::Common);

use utf8;
use v5.40;

use Const::Fast;
use Syntax::Keyword::MultiSub;

field $parse_line : mutator : inheritable;
field $filter_output : mutator : inheritable;

#method $parse_line : common ($line, %opts) {
#    ...;
#};

#method $filter_output : common {
#    ...;
#};

#multi sub is_locked ($pacman_dir = "") {
#  BS::Ext::pacman->sync
#}
