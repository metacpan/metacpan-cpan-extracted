use Object::Pad ':experimental(:all)';

package App::BS::pkgbuild;

class App::BS::pkgbuild : isa(App::BS::CLI);

use utf8;
use v5.40;

use BS::Common;
use BS::Ext::expac;
use BS::Ext::pacsift;
use File::chdir;
use List::Util qw(all uniqstr);

# This will probably satisify BS::Package's constructor args with we keep
# either of them around
class PKGBUILD::Stub : does(BS::Common) {

    field $pkgbase : param : reader = '';

    field $pkgname_param : param;
    field @pkgname : reader = ();

    field $pkgver : param : reader  = '';
    field $pkgdesc : param : reader = '';
    field $source : param           = [];

    field $pkgres : param;    # R
};

class PKGBUILD::Results : does(BS::Common) {
    field @results     = ();
    field %pkgbase_res = ();

    method first ( $by, $name ) {

    }
};

class PKGBUILD::Builder : does(BS::Common) : does(BS::Package::Meta) {
    field $pkgbuild : param : reader = '';
    field $pkgres : param : reader   = ();
};

field @queue;

#field @pkgres = ();    # This should probably be a hash of some sort?
#                       # Need to think about how many could be cached
#                       # per build tree

#field $current_pkgres : reader;

#method add_pkgres($pkgres, %opts) {
#    #push @pkgres, $pkgres;
#}

#method pkgres_rm ($pkgres, %opts) {
#  die unless $pkgres isa PKGBUILD::STUB &&  all {... }
#    $pkgres->fields->@{qw(pkgname source checksums)}}
#}

method fetch_aur_pkg : common ($pkgbase, %opts) {

}

method sync_pkgbuild : common ($repo, $pkgbase, %opts) {

}

method query_expac : common ($pkgstar, $userrepo_aref,%opts ) {

}

# These aren't separately named because of an Object::Pad restriction, but to
# better get across in very few words the differences and implications of using
# either

#method select_pkgres : common (%opts) {

#}

#method $select_pkgres (%opts) { return $$pkgres{} };

method change_pkgres(%opts) {
    ...

    # Will probably remain instance method since non-interactive/declarative
    # builds are planned for the first release
}

#method run : common ($pkgstr, $constructor_opts //= {}, %run_opts //= ()) {
#    ...;
#}
