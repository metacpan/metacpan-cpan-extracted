##
## db_file.t
##
## $Id: odbm_file.t,v 1.1 2002/07/19 20:41:56 tony Exp $
##

use strict;
BEGIN { @AnyDBM_File::ISA = qw(ODBM_File); }
BEGIN {
    eval { require ODBM_File; };
    if ($@) {
	print "1..0 # ODBM_File is not installed\n";
	exit(0);
    }
}
use Test;
use Fcntl;
BEGIN { plan test => 12; }

use DBM::Any;
ok(1);

# Create.
my $x = new DBM::Any('foo', O_CREAT|O_RDWR, 0600);
ok(ref $x, 'DBM::Any');

# Put one key, retrieve it back.
$x->put('foo', 'bar');
ok($x->get('foo'), 'bar');

# Put a bunch of keys...
$x->put('baz', 'garply');
$x->put('zot', 'quux');
$x->put('blurfl', 'corge');
$x->put('wibble', 'wobble');

# ...and read them back with keys;
my @k = sort $x->keys();
ok(scalar @k, 5);
ok(&aeq(\@k, [ qw(baz blurfl foo wibble zot) ]));

# ...and read them back with values;
my @v = sort $x->values();
ok(scalar @v, 5);
ok(&aeq(\@v, [ qw(bar corge garply quux wobble) ]));

# Read back pairs with each.
my ($k, $v);
my @p;
while (($k, $v) = $x->each()) {
    push @p, [ $k, $v ];
}
ok(scalar @p, 5);

# Existence.
ok($x->exists('foo'));
ok(not $x->exists('bar'));

# Deletion.
$x->delete('zot');
ok(not $x->exists('zot'));

# Close.
$x->close();
unlink('foo');
ok(not -f 'foo');

sub aeq {
    my ($a, $b) = @_;
    return undef if (@$a != @$b);
    for my $i (0..$#{$a}) {
	if ($a->[$i] ne $b->[$i]) {
	    return undef;
	}
    }
    return 1;
}
