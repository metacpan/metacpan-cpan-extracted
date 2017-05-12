use Contextual::Return qw< FAIL FAIL_WITH >;

use Test::More;

plan tests => 19;

sub eval_nok(&$$) {
    my ($block, $exception_pat, $message) = @_;
    my (undef, $file, $line) = caller;
    eval { $block->() };
    my $exception = $@;
    ok $exception => $message;
    like $exception, qr/\Q$exception_pat\E at \Q$file\E line $line/ => "Right message";
}


sub fail_with_message {
    return FAIL { 'fail_with_message() failed' }
}

if ( my $result = ::fail_with_message() ) {
    ok 0    => 'Unexpected succeeded in bool context';
}
else {
    ok 1    => 'Failed as expected in bool context';
    like $result->error, qr/^fail_with_message\(\) failed/ => 'Failed with expected message';
}

eval_nok { fail_with_message() }
    'fail_with_message() failed' => 'Exception thrown in void context';

eval_nok { () = fail_with_message() }
    'fail_with_message() failed' => 'Exception thrown in list context';

eval_nok { my $x = fail_with_message(); $x+1 }
    'fail_with_message() failed' => 'Exception thrown in num context';

eval_nok { my $x = fail_with_message(); $x.'a' }
    'fail_with_message() failed' => 'Exception thrown in str context';


sub fail_auto_message {
    return FAIL;
}

if ( ::fail_auto_message() ) {
    ok 0    => 'Unexpected succeeded in bool context';
}
else {
    ok 1    => 'Failed as expected in bool context';
}

eval_nok { fail_auto_message() }
    'Call to main::fail_auto_message() failed' => 'Exception thrown in void context';

eval_nok { () = fail_auto_message() }
    'Call to main::fail_auto_message() failed' => 'Exception thrown in list context';

eval_nok { my $x = fail_auto_message(); $x+1 }
    'Call to main::fail_auto_message() failed' => 'Exception thrown in num context';

eval_nok { my $x = fail_auto_message(); $x.'a' }
    'Call to main::fail_auto_message() failed' => 'Exception thrown in str context';

done_testing;
