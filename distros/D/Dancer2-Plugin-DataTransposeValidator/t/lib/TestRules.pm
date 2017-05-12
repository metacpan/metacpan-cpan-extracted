package TestRules;

sub login {
    my $foo_validator = shift;
    +{
        options => {
            stripwhite          => 1,
            collapse_whitespace => 1,
            requireall          => 1,
            unknown             => "fail",
        },
        prepare => {
            email => {
                validator => "String",
            },
            foo => {
                validator => $foo_validator,
            },
            password => {
                validator => {
                    class   => "PasswordPolicy",
                    options => {
                        disabled => {
                            username => 1,
                        },
                    },
                },
            },
        }
    }
}

1;
