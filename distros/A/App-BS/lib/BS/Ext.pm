use Object::Pad ':experimental(:all)';

package BS::Ext;

role BS::Ext : does(BS::Common);

use utf8;
use v5.40;

method $parse_line : common : required;

method $filter_output : common : required;
