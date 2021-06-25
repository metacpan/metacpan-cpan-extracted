#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;
use utf8;

use Object::Pad 0.41;

package App::sdview::Parser 0.01;
role App::sdview::Parser;

use String::Tagged;

# This package is empty but provides a bunch of helper classes

class App::sdview::Para::Heading {
   has $level :param :reader;
   has $text  :param :reader;

   method type { "head" . $level }
}

class App::sdview::Para::Plain {
   has $text :param :reader;

   method type { "plain" }
}

class App::sdview::Para::Verbatim {
   has $text :param :reader;

   method type { "verbatim" }
}

class App::sdview::Para::List {
   has $listtype :param :reader;
   has $indent   :param :reader;

   has @items; # would love to :reader this
   method items { @items }
   method push_item ( $item ) { push @items, $item; }

   method type { "list-$listtype" }
}

class App::sdview::Para::ListItem {
   has $text :param :reader;

   # TODO: Do we remember the list's type?
   method type { "item" }
}

0x55AA;
