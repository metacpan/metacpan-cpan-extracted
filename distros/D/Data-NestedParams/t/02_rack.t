use strict;
use warnings;
use utf8;
use Test::Base::Less;
use Data::NestedParams;
use Data::Dumper ();

# Test case taken from [spec_utils.rb](https://github.com/rack/rack/blob/master/test/spec_utils.rb#L126)

filters {
    input => [qw(eval)],
    expected => [qw(eval)],
};

sub ddf {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    Data::Dumper::Dumper(@_);
}

for (blocks) {
    my $input = $_->input;
    my $expected = $_->expected;

    diag "===";
    diag "--- input: " . ddf($input);
    diag "--- expected: " . ddf($expected);

    my $got = expand_nested_params($input);
    diag "--- got: " . ddf($got);
    is_deeply( $got, $expected );
}

done_testing;

=pod

    lambda { "x[y]=1&x[y]z=2") }.
      should.raise(TypeError).
      message."expected Hash (got String) for param `y'"

    lambda { "x[y]=1&x[]=1") }.
      should.raise(TypeError).
      message.should.match(/expected Array \(got [^)]*\) for param `x'/)

    lambda { "x[y]=1&x[y][][w]=2") }.
      should.raise(TypeError).
      message."expected Array (got String) for param `y'"
=cut

__END__
===
--- input: ['foo']
--- expected: {'foo' => undef}

===
--- input: ['foo','']
--- expected: {'foo' => ''}

===
--- input: ['foo','bar']
--- expected: {'foo' => 'bar'}

===
--- input: ['foo','"bar"']
--- expected: {'foo' => '"bar"'}

===
--- input: ['foo','bar','foo','quux']
--- expected: {'foo' => 'quux'}

===
--- input: ['foo','','foo','']
--- expected: {'foo' => ''}

===
--- input: ['foo',1,'bar',2]
--- expected: {'bar' => '2','foo' => '1'}

===
--- input: ['foo','1','bar',2]
--- expected: {'foo' => '1','bar' => '2'}

===
--- input: ['foo','bar','baz','']
--- expected: {'baz' => '','foo' => 'bar'}

===
--- input: ['my weird field','q1!2"\'w$5&7/z8)?']
--- expected: {'my weird field' => 'q1!2"\'w$5&7/z8)?'}

===
--- input: ['a','b','pid=1234',1023]
--- expected: {'a' => 'b','pid=1234' => '1023'}

===
--- input: ['foo[]',undef]
--- expected: {'foo' => [undef]}

===
--- input: ['foo[]','']
--- expected: {'foo' => ['']}

===
--- input: ['foo[]','bar']
--- expected: {'foo' => ['bar']}

===
--- input: ['foo[]','bar','foo',undef]
--- expected: {'foo' => undef}

===
--- input: ['foo[]','bar','foo[',undef]
--- expected: {'foo' => ['bar'],'foo[' => undef}

===
--- input: ['foo[]','bar','foo[','baz']
--- expected: {'foo[' => 'baz','foo' => ['bar']}

===
--- input: ['foo[]','bar','foo[]',undef]
--- expected: {'foo' => ['bar',undef]}

===
--- input: ['foo[]','bar','foo[]','']
--- expected: {'foo' => ['bar','']}

===
--- input: ['foo[]',1,'foo[]',2]
--- expected: {'foo' => ['1','2']}

===
--- input: ['foo','bar','baz[]',1,'baz[]',2,'baz[]',3]
--- expected: {'foo' => 'bar','baz' => ['1','2','3']}

===
--- input: ['foo[]','bar','baz[]',1,'baz[]',2,'baz[]',3]
--- expected: {'baz' => ['1','2','3'],'foo' => ['bar']}

===
--- input: ['x[y][z]',1]
--- expected: {'x' => {'y' => {'z' => '1'}}}

===
--- input: ['x[y][z][]',1]
--- expected: {'x' => {'y' => {'z' => ['1']}}}

===
--- input: ['x[y][z]',1,'x[y][z]',2]
--- expected: {'x' => {'y' => {'z' => '2'}}}

===
--- input: ['x[y][z][]',1,'x[y][z][]',2]
--- expected: {'x' => {'y' => {'z' => ['1','2']}}}

===
--- input: ['x[y][][z]','1']
--- expected: {'x' => {'y' => [{'z' => '1'}]}}

===
--- input: ['x[y][][z][]',1]
--- expected: {'x' => {'y' => [{'z' => ['1']}]}}

===
--- input: ['x[y][][z]',1,'x[y][][w]',2]
--- expected: {'x' => {'y' => [{'z' => '1','w' => '2'}]}}

===
--- input: ['x[y][][v][w]',1]
--- expected: {'x' => {'y' => [{'v' => {'w' => '1'}}]}}

===
--- input: ['x[y][][z]',1,'x[y][][v][w]',2]
--- expected: {'x' => {'y' => [{'z' => '1','v' => {'w' => '2'}}]}}

===
--- input: ['x[y][][z]',1,'x[y][][z]',2]
--- expected: {'x' => {'y' => [{'z' => '1'},{'z' => '2'}]}}

===
--- input: ['x[y][][z]',1,'x[y][][w]','a','x[y][][z]',2,'x[y][][w]',3]
--- expected: {'x' => {'y' => [{'z' => '1','w' => 'a'},{'z' => '2','w' => '3'}]}}

