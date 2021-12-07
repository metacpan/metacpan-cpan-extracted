use MooseX::Declare;

class t::Create with t::lib::Base {
    use Test::More;

    method _build_wanted_events { [ qw(create) ] }

    method do_test {
        $self->op('touch', 'foo');
        $self->op('mkdir', 'dir');
        $self->op('mkdir', 'dir/subdir');
        $self->op('touch', $_) for qw(dir/subdir/thing dir/thing_in_here bar);
        ok $self->exists($_), "$_ created ok" for
          qw(foo dir dir/subdir dir/subdir/thing dir/thing_in_here bar);
    }

    method check_result {
        is_deeply [map {$_->[1]} @{$self->state}],
          [qw{foo dir dir/subdir dir/subdir/thing dir/thing_in_here bar}],
            'got correct list of created files';
    }
}
