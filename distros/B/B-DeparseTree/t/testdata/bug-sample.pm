1;
__DATA__
# Elements of %# should not be confused with $#{ array }
() = ${#}{'foo'};
####
# SKIP ?$] < 5.017004 && "lexical subs not implemented on this Perl version"
# TODO unimplemented in B::Deparse; RT #116553
# lexical "state" subroutine
use feature 'state', 'lexical_subs';
no warnings 'experimental::lexical_subs';
state sub f {}
print f();
