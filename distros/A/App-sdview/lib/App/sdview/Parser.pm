#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;
use utf8;

use Object::Pad 0.55;  # :reader on array

package App::sdview::Parser 0.05;
role App::sdview::Parser;

use String::Tagged;

# This package is empty but provides a bunch of helper classes

class App::sdview::Para::Heading :strict(params) {
   has $level :param :reader;
   has $text  :param :reader;

   method type { "head" . $level }
}

class App::sdview::Para::Plain :strict(params) {
   has $text :param :reader;

   method type { "plain" }
}

class App::sdview::Para::Verbatim :strict(params) {
   has $text :param :reader;

   method type { "verbatim" }
}

class App::sdview::Para::List :strict(params) {
   has $listtype :param :reader;
   has $indent   :param :reader;
   has $initial  :param :reader = 1;  # for number lists

   has @items           :reader;

   method push_item ( $item ) { push @items, $item; }

   method type { "list-$listtype" }
}

class App::sdview::Para::ListItem :strict(params) {
   has $listtype :param :reader;
   has $term :param :reader = undef;
   has $text :param :reader;

   method type { "item" }
}

class App::sdview::Para::Table :strict(params) {
   method type { "table" }

   has @rows :reader;

   ADJUSTPARAMS ( $params ) {
      @rows = ( delete $params->{rows} )->@*;
   }
}

class App::sdview::Para::TableCell isa App::sdview::Para::Plain :strict(params) {
   has $align :param :reader;

   method type { "table-cell" }
}

0x55AA;
