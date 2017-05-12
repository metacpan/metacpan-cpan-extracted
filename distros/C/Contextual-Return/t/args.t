use Contextual::Return;

sub foo {
    return
        VOID      { $_[1] = 99 }
        BOOL      { @_ > 0 }
        LIST      { (@_) x 2 }
        NUM       { scalar @_ }
        STR       { join '|', @_ }
        SCALAR    { $_[0] }
        SCALARREF { my $var = $_[0]; \$var }
        HASHREF   { { args => \@_} }
        ARRAYREF  { \@_ }
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
