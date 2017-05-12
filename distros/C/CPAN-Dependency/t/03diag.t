use strict;
use Test::More;


BEGIN {
    plan skip_all => "Test::Warn required for testing warnings"
        unless eval "use Test::Warn; 1";
}
eval "use CPAN::Dependency";

plan tests => 10;

# create an object
my $cpandep = undef;
warning_is {
    $cpandep = new CPAN::Dependency blah => 1
} "warning: Unknown option 'blah': ignoring", 
  "passing unknown option to new()";

is( $@, ''                                  , "object created"               );
ok( defined $cpandep                        , "object is defined"            );
ok( $cpandep->isa('CPAN::Dependency')       , "object is of expected type"   );
is( ref $cpandep, 'CPAN::Dependency'        , "object is of expected ref"    );

for my $attr (qw(process skip)) {
    warning_is {
        $cpandep->$attr
    } "error: No argument given to attribute $attr()", 
      "checking warning of attribute $attr"
}

for my $func (qw(save_deps_tree load_deps_tree load_cpants_db)) {
    warning_is {
        $cpandep->$func
    } "error: No argument given to function $func()", 
      "checking warning of function $func"
}

