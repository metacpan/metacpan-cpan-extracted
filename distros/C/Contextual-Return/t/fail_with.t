use Contextual::Return qw< FAIL FAIL_WITH >;
use Carp;

my $FAIL_SPEC_ref;

sub set_up_1 {
    package Other;
    use Contextual::Return;
    use Carp;

    $FAIL_SPEC_ref = {
        good => sub { BOOL { 0     } DEFAULT { croak 'good'} },
        bad  => sub { BOOL { 1     } DEFAULT { ()          } },
        ugly => sub { BOOL { undef } DEFAULT { confess 'ugly'} },
    };

    Contextual::Return::FAIL_WITH $FAIL_SPEC_ref, qw(oh be a good boy);

    sub fail_auto_message {
        return FAIL;
    }
}

set_up_1();

use Test::More qw( no_plan );

sub eval_nok(&$$) {
    my ($block, $exception_pat, $message) = @_;
    my (undef, $file, $line) = caller;
    eval { $block->() };
    my $exception = $@;
    ok $exception => $message;
    like $exception, qr/\Q$exception_pat\E at \Q$file\E line $line/ => "Right message";
}


if ( Other::fail_auto_message() ) {
    ok 0    => 'Unexpected succeeded in bool context';
}
else {
    ok 1    => 'Failed as expected in bool context';
}

eval_nok { Other::fail_auto_message() } 'good' => 'Exception thrown in void context';

eval_nok { () = Other::fail_auto_message() } 'good' => 'Exception thrown in list context';

eval_nok { my $x = Other::fail_auto_message(); $x+1 } 'good' => 'Exception thrown in num context';

eval_nok { my $x = Other::fail_auto_message(); $x.'a' } 'good' => 'Exception thrown in str context';

sub set_up_2 {
    package Other;
    my $LINE = (caller)[2];
    local $SIG{__WARN__} = sub {
       my $message = shift;
       ::is $message,
            'FAIL handler for package Other redefined at '.__FILE__
            ." line $LINE\n"
                => 'Redefinition warning as expected'
    };
    Contextual::Return::FAIL_WITH -fail => $FAIL_SPEC_ref, qw(if you fail good -fail bad);
}

set_up_2();

if ( Other::fail_auto_message() ) {
    ok 1    => 'Succeeded as expected in bool context';
}
else {
    ok 0    => 'Unexpected failed in bool context';
}

my @results = Other::fail_auto_message();
ok @results == 0  => 'Returned empty list in list context';

sub set_up_3 {
    package Other;
    my $LINE = (caller)[2];
    local $SIG{__WARN__} = sub {
       my $message = shift;
       ::is $message,
            'FAIL handler for package Other redefined at '.__FILE__
            ." line $LINE\n"
                => 'Redefinition warning as expected'
    };
    eval {
        Contextual::Return::FAIL_WITH -fail => $FAIL_SPEC_ref, -fail => 'unknown';
    };
    my $exception = $@;
    ::ok $exception  => "Unknown FAIL handler, as expected";
    ::like $exception, qr/Invalid option: -fail => unknown/
                     => 'Correct exception thrown';

    local $SIG{__WARN__} = sub {
       my $message = shift;
       ::is $message,
            'FAIL handler for package Other redefined at '.__FILE__
            ." line $LINE\n"
                => 'Redefinition warning as expected'
    };
    Contextual::Return::FAIL_WITH -fail => {}, -fail => sub { undef };
}

set_up_3();

if ( Other::fail_auto_message() ) {
    ok 0    => 'Unexpected succeeded in bool context';
}
else {
    ok 1    => 'Failed as expected in bool context';
}

my $result = Other::fail_auto_message();
ok !defined $result => 'Scalar context was undef';

my @results2 = Other::fail_auto_message();
ok @results2 == 1        => 'Returned one-elem list in list context';
ok !defined $results2[0] => 'One-elem was undef';
