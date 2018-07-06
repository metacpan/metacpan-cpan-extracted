package B::DeparseTree::OPflags;
our($VERSION, @EXPORT, @ISA);
@ISA = qw(Exporter);
$VERSION = '3.2.0';

# Various operator flag bits
use constant ASSIGN =>  2;        # has OP= variant
use constant LIST_CONTEXT => 4;   # Assignment is in list context
use constant POSTFIX => 1;        # operator can be used as postfix operator
use constant SWAP_CHILDREN => 1;  # children of op should be reversed

# Copied from B/const-xs.inc. Perl 5.16 doesn't have this
use constant SVpad_STATE => 11;
use constant SVpad_TYPED => 8;

@EXPORT = qw(
    ASSIGN
    LIST_CONTEXT
    POSTFIX
    SWAP_CHILDREN
    SVpad_STATE
    SVpad_TYPED
    );


1;
