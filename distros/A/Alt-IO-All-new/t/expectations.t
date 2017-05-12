use lib 'inc';
use TestML;

TestML->new(
    testml => join('', <DATA>),
    bridge => 'TestMLBridge',
)->run;

{
    package TestMLBridge;
    use TestML::Base;
    extends 'TestML::Bridge';
    use TestML::Util;

    sub setup {
        my ($self, $cmd) = @_;
        $cmd = $cmd->value;
        `$cmd`;
        str;
    }
    sub eval_perl {
        my ($self, $setup, $perl, $expect) = @_;
        $perl = $perl->value;
        # eval $perl;
        $expect = $expect->value;
        die $expect;
    }
}

__DATA__
%TestML 0.1.0

Plan = 4;

setup(*setup).eval_perl(*perl, *expect).Catch == *expect;

setup('rm -f foo');

=== foo doesn't exist
--- setup: rm -f foo
--- perl: io('foo')->appends
--- expect: throws exception

=== foo does exist
--- setup: touch foo
--- perl: io('foo')->create
--- expect: throws exception

# maybe require ->strict for those two:

=== foo doesn't exist
--- setup: rm foo
--- perl: io('foo')->strict->append
--- expect: definitely dies

=== foo does exist
--- setup: touch foo
--- perl: io('foo')->strict->create
--- expect: definitely dies

