package MyAppCallback::Plugin::Callback;

use strict;

sub setup {

    my($self, @argv) = @_;
    $self->new_callback("any_phase");
    $self->add_callback("any_phase", \&_test_callback1);
    $self->add_callback("any_phase", \&_test_callback2);
    $self->maybe::next::method(@argv);
}

sub _test_callback1 {

    my($self, @args) = @_;
    $main::RESULT{_test_callback1} = "any_phase execute 1";
}

sub _test_callback2 {

    my($self, @args) = @_;
    $main::RESULT{_test_callback2} = "any_phase execute 2";
}

1;
