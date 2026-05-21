use strict;
use warnings;
use Test::More;
use Data::Path::XS qw(
    path_get path_set path_delete path_exists
    patha_get patha_set patha_delete patha_exists
    path_compile pathc_get pathc_set pathc_delete pathc_exists
);
use Data::Path::XS ':keywords';

# Pin the exact croak messages emitted by the XS layer. These are part of
# the behavioural contract: third-party code matches them with eval/qr,
# and refactors that change the wording must also bump documentation.

sub croaks_like {
    my ($code, $re, $name) = @_;
    eval { $code->(); 1 } and do { fail("$name: did not croak"); return };
    like($@, $re, $name);
}

# ---- root ----
croaks_like(sub { path_set({}, '', 1) },        qr/^Cannot set root\b/,   'path_set empty path');
croaks_like(sub { path_delete({}, '') },        qr/^Cannot delete root\b/,'path_delete empty path');
croaks_like(sub { patha_set({}, [], 1) },       qr/^Cannot set root\b/,   'patha_set empty arrayref');
croaks_like(sub { patha_delete({}, []) },       qr/^Cannot delete root\b/,'patha_delete empty arrayref');
croaks_like(sub { pathc_set({}, path_compile(''), 1) },
                                                qr/^Cannot set root\b/,   'pathc_set with empty compiled');
croaks_like(sub { pathc_delete({}, path_compile('')) },
                                                qr/^Cannot delete root\b/,'pathc_delete with empty compiled');

# pathset/pathdelete keyword — compile-time empty-path croak
eval q{ use Data::Path::XS ':keywords'; sub { pathset $_[0], "", 1 } };
like($@, qr/^Cannot set root\b/, 'kw pathset constant "" — compile-time croak');

croaks_like(sub { my $d = {}; my $p = ""; pathset $d, $p, 1 },
                                                qr/^Cannot set root\b/,   'kw pathset dynamic ""');
croaks_like(sub { my $d = {}; my $p = ""; pathdelete $d, $p },
                                                qr/^Cannot delete root\b/,'kw pathdelete dynamic ""');

# ---- bad navigation ----
croaks_like(sub { path_set('not-a-ref', '/x', 1) },
                                                qr/^Cannot navigate to path\b/,
                                                'path_set on non-ref data');
croaks_like(sub { path_set([1,2,3], '/x/y', 1) },
                                                qr/^Cannot navigate to path\b/,
                                                'path_set string key on array intermediate');
croaks_like(sub { my $d = {}; my $p = "/x"; pathset 'not-a-ref', $p, 1 },
                                                qr/^Cannot navigate to path\b/,
                                                'kw pathset dynamic on non-ref');

# ---- invalid array index (final key) ----
croaks_like(sub { path_set({arr=>[1,2,3]}, '/arr/key', 1) },
                                                qr/^Invalid array index\b/,
                                                'path_set non-numeric final key on array');
croaks_like(sub { pathc_set({arr=>[1,2,3]}, path_compile('/arr/key'), 1) },
                                                qr/^Invalid array index\b/,
                                                'pathc_set non-numeric final key on array');
croaks_like(sub { patha_set({arr=>[1,2,3]}, ['arr','key'], 1) },
                                                qr/^Invalid array index\b/,
                                                'patha_set non-numeric final key on array');

# ---- compiled-path validation ----
croaks_like(sub { pathc_get({a=>1}, 'not a ref') },     qr/^Not a compiled path\b/, 'pathc_get non-ref');
croaks_like(sub { pathc_get({a=>1}, [1,2,3]) },         qr/^Not a compiled path\b/, 'pathc_get arrayref');
croaks_like(sub { pathc_get({a=>1}, {x=>1}) },          qr/^Not a compiled path\b/, 'pathc_get hashref');
croaks_like(sub { pathc_get({a=>1}, bless [], 'Data::Path::XS::Compiled') },
                                                qr/^Not a compiled path\b/,
                                                'pathc_get bless-as-Compiled garbage');

# ---- tied containers ----
package T::Hash {
    sub TIEHASH { bless {}, shift }
    sub FETCH { undef } sub STORE { } sub EXISTS { 0 } sub DELETE { undef }
    sub FIRSTKEY { } sub NEXTKEY { }
}
tie my %th, 'T::Hash';
croaks_like(sub { path_set(\%th, '/x', 1) },    qr/tied|magical/i, 'path_set tied hash');
croaks_like(sub { patha_set(\%th, ['x'], 1) },  qr/tied|magical/i, 'patha_set tied hash');
croaks_like(sub { pathc_set(\%th, path_compile('/x'), 1) },
                                                qr/tied|magical/i, 'pathc_set tied hash');
croaks_like(sub { my $d = \%th; my $p = "/x"; pathset $d, $p, 1 },
                                                qr/tied|magical/i, 'kw pathset dynamic tied hash');

done_testing;
