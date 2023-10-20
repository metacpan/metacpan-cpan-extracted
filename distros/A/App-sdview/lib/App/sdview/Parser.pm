#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.800 ':experimental(adjust_params)';
use Object::Pad::FieldAttr::Checked;

package App::sdview::Parser 0.13;
role App::sdview::Parser;

use String::Tagged;
use Types::Standard;

my $ListType;
BEGIN {
   $ListType = Types::Standard::Enum[qw( bullet number text )];
}

# This package is empty but provides a bunch of helper classes

class App::sdview::Para::Heading :strict(params) {
   use Types::Standard qw( InstanceOf Num );

   field $level :param :reader :Checked(Num);
   field $text  :param :reader :Checked(InstanceOf['String::Tagged']);

   method type { "head" . $level }
}

class App::sdview::Para::Plain :strict(params) {
   use Types::Standard qw( InstanceOf Num );

   field $text   :param :reader :Checked(InstanceOf['String::Tagged']);
   field $indent :param :reader :Checked(Num) = 0;

   method type { "plain" }
}

class App::sdview::Para::Verbatim :strict(params) {
   use Types::Standard qw( Maybe Str InstanceOf Num );

   field $language :param :reader :Checked(Maybe[Str]) = undef;
   field $text     :param :reader :Checked(InstanceOf['String::Tagged']);
   field $indent   :param :reader :Checked(Num) = 0;

   method type { "verbatim" }
}

class App::sdview::Para::List :strict(params) {
   use Types::Standard qw( Num );

   field $listtype :param :reader :Checked($ListType);
   field $indent   :param :reader :Checked(Num);
   field $initial  :param :reader :Checked(Num) = 1;  # for number lists

   field @items           :reader;

   method push_item ( $item ) { push @items, $item; }

   method type { "list-$listtype" }
}

class App::sdview::Para::ListItem :strict(params) {
   use Types::Standard qw( InstanceOf Maybe );

   field $listtype :param :reader :Checked($ListType);
   field $term     :param :reader :Checked(Maybe[InstanceOf['String::Tagged']]) = undef;
   field $text     :param :reader :Checked(InstanceOf['String::Tagged']);

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
   use Types::Standard qw( Enum );

   field $align :param :reader :Checked(Enum[qw( left centre right )]);

   method type { "table-cell" }
}

0x55AA;
