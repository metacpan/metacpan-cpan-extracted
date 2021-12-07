use MooseX::Declare;

class t::MoveDir with t::lib::Base {
    use Test::More;

    method _build_wanted_events { [ qw(create move) ] }

    method do_test {
        $self->op('mkdir', 'foo');
        ok $self->exists('foo'), 'made foo';
        my $foo = $self->exists('foo');
        my $bar = $foo->parent->file('bar');

        $self->op('touch', 'foo/1');

        $self->begin;
        ok( rename($foo, $bar), 'rename foo to bar' );
        ok $self->exists('bar'), 'bar exists';
        ok $self->exists('bar/1'), 'bar/1 went with it';

        $self->op('touch', 'bar/2');
        ok $self->exists('bar/2'), 'made bar/2';
    }

    method check_result {
        is_deeply $self->state,
          [[qw/create foo/],[qw(create foo/1)], [qw/move foo bar/], [qw(create bar/2)]],
            'got expected notifications';
    }
}
