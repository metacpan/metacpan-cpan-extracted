package t::000_basic::Config::IPFilter;
{
    use strict;
    use warnings;
    our $MAJOR = 0; our $MINOR = 74; our $DEV = 13; our $VERSION = sprintf('%0d.%03d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);
    use Test::More;
    use parent 'Test::Class';
    use lib '../../../lib', '../../lib', '../lib', 'lib';

    #
    sub class    {'Config::IPFilter'}
    sub new_args { [] }

    #
    sub startup : Tests(startup => 3) {
        my $self = shift;
        use_ok $self->class;
        can_ok $self->class, 'new';
        $self->{'ip_filter'} = new_ok $self->class, $self->new_args;
    }

    sub setup : Test(setup) {
        my $self = shift;
    }

    sub test_rules : Test( no_plan ) {
        my $s = shift;
        my $f = $s->{'ip_filter'};
        ok $f->is_empty, 'IPFilter has no rules yet';
        isa_ok $f->add_rule('127.0.0.1', '128.32.236.226', 44, 'Test A'),
            'Config::IPFilter::Rule', 'new rule A';
        is $f->count_rules, 1, 'There is now one rule';
        isa_ok $f->add_rule('127.0.0.1', '128.32.236.226', 21, 'Test B'),
            'Config::IPFilter::Rule', 'new rule B';
        is $f->count_rules, 2, 'There are now two rules';
        is_deeply $f->rules,
            [bless({access_level => 44,
                    description  => 'Test A',
                    lower        => "\0\0\0\0\0\0\0\0\0\0\0\0\x7F\0\0\1",
                    upper        => "\0\0\0\0\0\0\0\0\0\0\0\0\x80 \xEC\xE2",
                   },
                   'Config::IPFilter::Rule'
             ),
             bless({access_level => 21,
                    description  => 'Test B',
                    lower        => "\0\0\0\0\0\0\0\0\0\0\0\0\x7F\0\0\1",
                    upper        => "\0\0\0\0\0\0\0\0\0\0\0\0\x80 \xEC\xE2",
                   },
                   'Config::IPFilter::Rule'
             )
            ],
            'rules were loaded correctly';
    }

    #
    __PACKAGE__->runtests() if !caller;
}
1;
