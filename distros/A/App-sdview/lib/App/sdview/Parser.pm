#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

use v5.26;
use utf8;

use Object::Pad 0.73 ':experimental(init_expr adjust_params)';

package App::sdview::Parser 0.09;
role App::sdview::Parser;

use String::Tagged;

# This package is empty but provides a bunch of helper classes

class App::sdview::Para::Heading :strict(params) {
   field $level :param :reader;
   field $text  :param :reader;

   method type { "head" . $level }
}

class App::sdview::Para::Plain :strict(params) {
   field $text   :param :reader;
   field $indent :param :reader = 0;

   method type { "plain" }
}

class App::sdview::Para::Verbatim :strict(params) {
   field $text   :param :reader;
   field $indent :param :reader = 0;

   method type { "verbatim" }
}

class App::sdview::Para::List :strict(params) {
   # "bullet" | "number" | "text"
   field $listtype :param :reader;
   field $indent   :param :reader;
   field $initial  :param :reader = 1;  # for number lists

   field @items           :reader;

   method push_item ( $item ) { push @items, $item; }

   method type { "list-$listtype" }
}

class App::sdview::Para::ListItem :strict(params) {
   field $listtype :param :reader;
   field $term     :param :reader = undef;
   field $text     :param :reader;

   method type { "item" }
}

class App::sdview::Para::Table :strict(params) {
   method type { "table" }

   field @rows :reader;

   ADJUST :params ( :$rows ) {
      @rows = $rows->@*;
   }
}

class App::sdview::Para::TableCell :isa(App::sdview::Para::Plain) :strict(params) {
   field $align :param :reader;

   method type { "table-cell" }
}

0x55AA;
