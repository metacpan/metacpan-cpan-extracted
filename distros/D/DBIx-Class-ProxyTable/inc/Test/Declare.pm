#line 1
package Test::Declare;
use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.02';

my @test_more_exports;
my @test_more_method;
BEGIN {
    @test_more_method = qw(
        use_ok require_ok
        eq_array eq_hash eq_set
        can_ok
    );
    @test_more_exports = (qw(
        skip todo todo_skip
        pass fail
        plan
        diag
        BAIL_OUT
        $TODO
    ),@test_more_method);
}

use Test::More import => \@test_more_exports;
use Test::Exception;
use Test::Warn;
use Test::Output;
use Test::Deep;

my @test_wrappe_method = qw(
    cmp_ok ok dies_ok throws_ok
    is isnt is_deeply like unlike
    isa_ok cmp_deeply re cmp_bag
    prints_ok stderr_ok
    warning_like warnings_like warning_is warnings_are
    stdout_is stdout_isnt stdout_like stdout_unlike
    stderr_is stderr_isnt stderr_like stderr_unlike
    combined_is combined_isnt combined_like combined_unlike
    output_is output_isnt output_like output_unlike
);

my @test_method = (@test_wrappe_method, @test_more_method);

our @EXPORT = (@test_more_exports, @test_wrappe_method, qw/
    init cleanup run test describe blocks
/);

my $test_block_name;
sub test ($$) { ## no critic
    $test_block_name = shift;
    shift->();
}

{
    no strict 'refs'; ## no critic
    for my $sub (qw/init cleanup/) {
        *{"Test\::Declare\::$sub"} = sub (&) {
            shift->();
        };
    }
}

sub run (&) { shift } ## no critic

sub describe ($$) { ## no critic
    shift; shift->();
}

use PPI;
sub PPI::Document::find_test_blocks {
    my $self = shift;
    my $blocks = $self->find(
        sub {
            $_[1]->isa('PPI::Token::Word')
            and
            grep { $_[1]->{content} eq $_ } @test_method
        }
    )||[];
    return @$blocks
}
sub blocks {
    my @caller = caller;
    my $file = $caller[1];
    my $doc = PPI::Document->new($file) or die $!;
    return scalar( $doc->find_test_blocks );
}

## Test::More wrapper
{
    no strict 'refs'; ## no critic
    for my $sub (qw/is is_deeply like isa_ok isnt unlike/) {
        *{"Test\::Declare\::$sub"} = sub ($$;$) {
            my ($actual, $expected, $name) = @_;
            my $test_more_code = "Test\::More"->can($sub);
            goto $test_more_code, $actual, $expected, $name||$test_block_name;
        }
    }

}

sub cmp_ok ($$$;$) { ## no critic
    my ($actual, $operator, $expected, $name) = @_;
    my $test_more_code = "Test\::More"->can('cmp_ok');
    goto $test_more_code, $actual, $operator, $expected, $name||$test_block_name;
}

sub ok ($;$) { ## no critic
    my ($test, $name) = @_;
    my $test_more_code = "Test\::More"->can('ok');
    goto $test_more_code, $test, $name||$test_block_name;
}

1;

__END__
