use v5.40;
use feature 'class';
no warnings 'experimental::class';

class t::CLI {

    use App::Gimei::Runner;
    use Capture::Tiny qw(capture);

    field $stdout        : param : reader;
    field $stderr        : param : reader;
    field $exit_code     : param : reader;
    field $error_message : param : reader;

    sub run ( $class, @args ) {
        my %param;

        my @capture = capture {
            my $code = eval { App::Gimei::Runner->new->execute(@args) };
            $param{exit_code}     = $code;
            $param{error_message} = $@;
        };

        return $class->new( %param, stdout => $capture[0], stderr => $capture[1] );
    }
}

1;
