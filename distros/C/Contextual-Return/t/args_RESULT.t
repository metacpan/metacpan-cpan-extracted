use Contextual::Return;

sub foo {
    return
        VOID      { RESULT { $_[1] = 99 }; undef }
        BOOL      { RESULT { @_ > 0 }; undef }
        LIST      { RESULT { (@_) x 2 }; undef }
        NUM       { RESULT { scalar @_ }; undef }
        STR       { RESULT { join '|', @_ }; undef }
        SCALAR    { RESULT { $_[0] }; undef }
        SCALARREF { RESULT { my $var = $_[0]; \$var }; undef }
        HASHREF   { RESULT { { args => \@_} }; undef }
        ARRAYREF  { RESULT { \@_ }; undef }
    ;
}

package Other;
use Test::More 'no_plan';

my @arg_lists = (
    [99],
    [],
    [99..101],
);

for my $arg_list (@arg_lists) {
    my $call = 'foo(' . join(q{,}, @{$arg_list}) . ')';

    is_deeply [ ::foo(@{$arg_list}) ],
              [(@{$arg_list})x2]         
                                                => "list test on $call";

    is do{ ::foo(@{$arg_list}) ? 'true' : 'false' },
       do{ @{$arg_list} ? 'true' : 'false' }
                                                => "boolean test on $call";

    is 0+::foo(@{$arg_list}), 0+@{$arg_list}
                                                => "number test on $call";

    is "" . ::foo(@{$arg_list}),
       join('|',@{$arg_list})
                                                => "string test on $call";

    is ${::foo(@{$arg_list})},
       $arg_list->[0]
                                                => "scalar test on $call";

    is_deeply \%{::foo(@{$arg_list})},
              { args => $arg_list }
                                                => "hash test on $call";

    is_deeply \@{::foo(@{$arg_list})},
              \@{$arg_list}
                                                => "array test on $call";
}

my @real_args = 1..3;
::foo(@real_args);
is_deeply \@real_args, [1,99,3]                 => "arg changes stick"
