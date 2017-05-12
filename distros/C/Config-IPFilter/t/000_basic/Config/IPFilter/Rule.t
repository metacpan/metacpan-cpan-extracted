package t::000_basic::Config::IPFilter::Rule;
{
    use strict;
    use warnings;
    our $MAJOR = 0; our $MINOR = 74; our $DEV = 13; our $VERSION = sprintf('%0d.%03d' . ($DEV ? (($DEV < 0 ? '' : '_') . '%03d') : ('')), $MAJOR, $MINOR, abs $DEV);
    use Test::More;
    use parent 'Test::Class';
    use lib '../../../../lib', 'lib';

    #
    sub class {'Config::IPFilter::Rule'}

    sub new_args {
        (lower        => '127.0.0.1',
         upper        => '127.0.0.5',
         description  => 'Testing',
         access_level => 559
        );
    }

    sub deeply {
        my %d = new_args;
        require Config::IPFilter::Types;
        map { $_ = Config::IPFilter::Types::ip2paddr($_) } $d{'lower'},
            $d{'upper'};
        bless \%d, class;
    }

    #
    sub startup : Tests( startup => 3 ) {
        my $self = shift;
        use_ok $self->class;
        can_ok $self->class, 'new';
        $self->{'rule'} = new_ok $self->class, [$self->new_args];
    }

    sub setup : Test( setup ) {
        my $self = shift;
    }

    sub test_deeply : Test( 1 ) {
        my $s = shift;
        my $r = $s->{'rule'};
        is_deeply $r, $s->deeply, 'internals check out';
    }

    sub attributes : Test( 6 ) {
        my $s = shift;
        my $r = $s->{'rule'};
        require Config::IPFilter::Types;
        is $r->$_(),
            Config::IPFilter::Types::ip2paddr({$s->new_args}->{$_}),
            $_ . ' limit checks out'
            for qw[lower upper];
        is $r->$_(), {$s->new_args}->{$_}, $_ . ' checks out'
            for qw[access_level description];
        is $r->lower_as_string(), {$s->new_args}->{'lower'},
            'lower_as_string checks out';
        is $r->upper_as_string(), {$s->new_args}->{'upper'},
            'upper_as_string checks out';
    }

    sub in_range : Test( 2 ) {
        my $s = shift;
        my $r = $s->{'rule'};
        ok $r->in_range('127.0.0.2'), '127.0.0.2 is in range';
        ok !$r->in_range('127.0.0.9'), '127.0.0.9 is beyond range';
    }

    sub z_access_level : Test( 4 ) {
        my $s       = shift;
        my $r       = $s->{'rule'};
        my $initial = $r->access_level;
        $r->increase_access_level();
        is $r->access_level, $initial + 1,
            '->increase_access_level( ) increased the access_level by 1';
        $r->increase_access_level(2);
        is $r->access_level, $initial + 3,
            '->increase_access_level( 2 ) increased the access_level by 2';
        $r->decrease_access_level(3);
        is $r->access_level, $initial,
            '->decrease_access_level( 3 ) returns access_level to the original value';
        $r->set_access_level(655);
        is $r->access_level, 655,
            '->set_access_level( 655 ) sets access_level to 655';
    }

    sub _as_string : Test( 1 ) {
        my $s = shift;
        my $r = $s->{'rule'};
        like $r->_as_string,
            qr[^127\.0\.0\.1\s+-\s+127\.0\.0\.5\s*,\s+559\s*,\s+Testing$],
            '->_as_string is as okay';
    }

    #
    __PACKAGE__->runtests() if !caller;
}
1;
