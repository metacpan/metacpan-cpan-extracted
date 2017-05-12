use Contextual::Return;
use Test::More 'no_plan';

my @todo_list = ( 'eat', 'drink', 'be merry' );

sub interp_explicit {
    return (
        SCALAR { scalar @todo_list }      # In scalar context: how many?
        LIST   { @todo_list        }      # In list context: what are they?

        SCALARREF { \scalar @todo_list }  # Scalar context value as ref
        ARRAYREF  { \@todo_list        }  # List context value as array ref
    );
}

sub interp_implicit {
    return (
        SCALAR { scalar @todo_list }      # In scalar context: how many?
        LIST   { @todo_list        }      # In list context: what are they?
    );
}

sub interp_num {
    return (
        NUM   { scalar @todo_list }      # In num context: how many?
        LIST  { @todo_list        }      # In list context: what are they?
    );
}

sub interp_str {
    return (
        NUM   { @todo_list + 1    }      # In num context: how many + 1?
        STR   { scalar @todo_list }      # In str context: how many?
        LIST  { @todo_list        }      # In list context: what are they?
    );
}


is "There are ${interp_explicit()} ToDo tasks: @{interp_explicit()}",
   'There are 3 ToDo tasks: eat drink be merry'
                                                => 'Explicit interpolators';

is "There are ${interp_implicit()} ToDo tasks: @{interp_implicit()}",
   'There are 3 ToDo tasks: eat drink be merry'
                                                => 'Implicit interpolators';

is "There are ${interp_num()} ToDo tasks: @{interp_num()}",
   'There are 3 ToDo tasks: eat drink be merry'
                                                => 'Numeric interpolators';

is "There are ${interp_str()} ToDo tasks: @{interp_str()}",
   'There are 3 ToDo tasks: eat drink be merry'
                                                => 'String interpolators';

is 0+${interp_str()}, "4"                   => 'Smart numbers';
is "".${interp_str()}, "3"                  => 'Smart strings';
