# $Id: load.t,v 1.2 2002/01/07 15:29:26 jgsmith Exp $

BEGIN { print "1..1\n"; }

no warnings;

eval {
    use Apache::Handlers qw: :;
};

if($@) {
    print "not ok 1";
} else {
    print "ok     1";
}

1;
