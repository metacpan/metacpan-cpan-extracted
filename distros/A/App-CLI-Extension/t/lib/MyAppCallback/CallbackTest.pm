package MyAppCallback::CallbackTest;

use strict;
use base qw(App::CLI::Command);
use constant options => ("callback=s" => "callback");

sub run {

    my($self, @args) = @_;
    if ($self->exists_callback($self->{callback})) {
        $self->exec_callback($self->{callback});
    }
}
1;

