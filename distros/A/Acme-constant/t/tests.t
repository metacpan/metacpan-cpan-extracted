use strictures 1;
use Test::More tests => 27;
use utf8;

BEGIN {
    require_ok 'Acme::constant';
    use_ok 'Acme::constant', A => 'B';
    use_ok 'Acme::constant', B => 1, 2, 3;
    use_ok 'if', 1, 'Acme::constant', C => 8;
    use_ok 'if', 0, 'Acme::constant', D => 16;
    # π needs to be quoted in order to not confuse PPI.
    use_ok 'Acme::constant', "π", 4 * atan2 1, 1;
    use_ok 'Acme::constant', "\0" => "NULL";
    use_ok 'Acme::constant', STRUCTURE => [1, {2 => 3}]
}
is A, 'B', 'Scalar is properly declared';
is_deeply [B], [1, 2, 3], 'Array is properly declared';
is((B)[0], 1, 'Can access single element in declared array');

A = 42;
is A, 42, 'Scalar is properly redeclared';

(B) = (4, 5, 6);
is_deeply [B], [4, 5, 6], 'Array is properly redeclared';
is((B)[2], 6, 'Can access single element in redeclared array');

ok defined &C, 'C is defined';
is C, 8, 'Constant can be declared dynamically';

ok !defined &D, 'D is not defined';

(A) = (1, 2);
is_deeply [A], [1, 2], 'Can change scalar into array';

(A) = 3;
is_deeply A, 3, 'Can change array into scalar';

is substr("π"->(), 0, 7), '3.14159', 'Can use funny names for constants';

is "\0"->(), 'NULL', 'Can use non-word names for constants';

"\0"->() = 20;
is "\0"->(), 20, 'Can assign to non-word names';

is_deeply STRUCTURE, [1, {2 => 3}], 'Can put complex structures as references';

STRUCTURE->[0] = 4;
is_deeply STRUCTURE, [4, {2 => 3}], 'Can modify array references';

STRUCTURE->[1]{2} = 7;
is_deeply STRUCTURE, [4, {2 => 7}], 'Can modify hash references';

push @{(STRUCTURE)}, 'hello';
is_deeply STRUCTURE, [4, {2 => 7}, 'hello'], 'Can push to arrays';

$#{(STRUCTURE)} = 0;
is_deeply STRUCTURE, [4], 'Can change length of array reference in structure';
