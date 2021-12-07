use MooseX::Declare;

class t::MoveFile with t::lib::Base {
    use Test::More;

    method _build_wanted_events { [ qw(create move) ] }

    method do_test {
        $self->op('touch', 'foo');
        ok $self->exists('foo'), 'made foo';
        my $foo = $self->exists('foo');
        my $bar = $foo->parent->file('bar');

        $self->begin;
        ok( rename($foo, $bar), 'rename foo to bar' );
        ok $self->exists('bar'), 'bar exists';
    }

    method check_result {
        is_deeply $self->state,
          [[qw/create foo/],[qw/move foo bar/]];
    }
}
