use v5.40;

package t::CLI;

use App::Gimei::Runner;
use Capture::Tiny qw(capture);
use Class::Tiny   qw(stdout stderr exit_code error_message);

sub run ( $class, @args ) {
    my $self = $class->new;

    my @capture = capture {
        my $code = eval { App::Gimei::Runner->new->execute(@args) };
        $self->exit_code($code);
        $self->error_message($@);
    };
    $self->stdout( $capture[0] );
    $self->stderr( $capture[1] );

    return $self;
}

1;
