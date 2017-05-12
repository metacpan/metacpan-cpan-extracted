use Bubblegum;
use Test::More;

ok ! main->isa('Moo::Object'), 'class not an object';

can_ok 'Bubblegum::Object::String', 'append';
subtest 'test the append method' => sub {
    my $string = 'firstname';
    is 'firstname lastname', $string->append('lastname'); # firstname lastname
    is 'firstname lastname', $string; # firstname lastname
};

can_ok 'Bubblegum::Object::String', 'codify';
subtest 'test the codify method' => sub {
    my $string = '$b > $a';
    is ref $string->codify, 'CODE';
    is 1, $string->codify->(0, 1); # 1
    is '', $string->codify->(1, 1); # 0
    $string = '$b > $a && !$c';
    is ref $string->codify, 'CODE';
    is 1, $string->codify->(0, 1, 0); # 1
    is '', $string->codify->(1, 1, 1); # 0
};

can_ok 'Bubblegum::Object::String', 'concat';
subtest 'test the concat method' => sub {
    my $string = 'ABC';
    is 'ABCDEFGHI', $string->concat('DEF', 'GHI'); # ABCDEFGHI
    is 'ABCDEFGHI', $string; # ABCDEFGHI
};

can_ok 'Bubblegum::Object::String', 'contains';
subtest 'test the contains method' => sub {
    my $string = 'Nullam ultrices placerat nibh vel malesuada.';
    is 1, $string->contains('trices'); # 1; true
    is 0, $string->contains('itrices'); # 0; false
    is 1, $string->contains(qr/trices/); # 1; true
    is 0, $string->contains(qr/itrices/); # 0; false
};

can_ok 'Bubblegum::Object::String', 'eq';
subtest 'test the eq method' => sub {
    my $string = 'User';
    is 0, $string->eq('user'); # 0; false
    is 1, $string->eq('User'); # 1; true
};

can_ok 'Bubblegum::Object::String', 'eqtv';
subtest 'test the eqtv method' => sub {
    my $string = '123';
    is 1, $string->eqtv('123'); # 1; true
    is 0, $string->eqtv(123); # 0; false
};

can_ok 'Bubblegum::Object::String', 'format';
subtest 'test the format method' => sub {
    my $string = 'bobama';
    is '/home/bobama/etc', $string->format('/home/%s/etc'); # /home/bobama/etc
    is '/home/bobama/etc', $string->format('/home/%s/%s', 'etc'); # /home/bobama/etc
};

can_ok 'Bubblegum::Object::String', 'gt';
subtest 'test the gt method' => sub {
    my $string = 'abc';
    is 1, $string->gt('ABC'); # 1; true
    is 0, $string->gt('abc'); # 0; false
};

can_ok 'Bubblegum::Object::String', 'gte';
subtest 'test the gte method' => sub {
    my $string = 'abc';
    is 1, $string->gte('abc'); # 1; true
    is 1, $string->gte('ABC'); # 1; true
    is 0, $string->gte('abcd'); # 0; false
};

can_ok 'Bubblegum::Object::String', 'lt';
subtest 'test the lt method' => sub {
    my $string = 'ABC';
    is 1, $string->lt('abc'); # 1; true
    is 0, $string->lt('ABC'); # 0; false
};

can_ok 'Bubblegum::Object::String', 'lte';
subtest 'test the lte method' => sub {
    my $string = 'ABC';
    is 1, $string->lte('abc'); # 1; true
    is 1, $string->lte('ABC'); # 1; true
    is 0, $string->lte('AB'); # 0; false
};

can_ok 'Bubblegum::Object::String', 'ne';
subtest 'test the ne method' => sub {
    my $string = 'User';
    is  1, $string->ne('user'); # 1; true
    is  0, $string->ne('User'); # 0; false
};

can_ok 'Bubblegum::Object::String', 'camelcase';
subtest 'test the camelcase method' => sub {
    my $string = 'hello world';
    is 'HelloWorld', $string->camelcase; # HelloWorld
    is 'HelloWorld', $string; # HelloWorld
    $string = 'HELLO WORLD';
    is 'HelloWorld', $string->camelcase; # HelloWorld
    is 'HelloWorld', $string; # HelloWorld
};

can_ok 'Bubblegum::Object::String', 'chomp';
subtest 'test the chomp method' => sub {
    my $string = "name, age, dob, email\n";
    is 'name, age, dob, email', $string->chomp; # name, age, dob, email
    is 'name, age, dob, email', $string; # name, age, dob, email
};

can_ok 'Bubblegum::Object::String', 'chop';
subtest 'test the chop method' => sub {
    my $string = "this is just a test.";
    is 'this is just a test', $string->chop; # this is just a test
    is 'this is just a test', $string; # this is just a test
};

can_ok 'Bubblegum::Object::String', 'hex';
subtest 'test the hex method' => sub {
    my $string = '0xaf';
    is 175, $string->hex; # 175
};

can_ok 'Bubblegum::Object::String', 'index';
subtest 'test the index method' => sub {
    my $string = 'unexplainable';
    is 2, $string->index('explain'); # 2
    is 2, $string->index('explain', 0); # 2
    is 2, $string->index('explain', 1); # 2
    is 2, $string->index('explain', 2); # 2
    is -1, $string->index('explain', 3); # -1
    is -1, $string->index('explained'); # -1
};

can_ok 'Bubblegum::Object::String', 'lc';
subtest 'test the lc method' => sub {
    my $string = 'EXCITING';
    is 'exciting', $string->lc; # exciting
};

can_ok 'Bubblegum::Object::String', 'lcfirst';
subtest 'test the lcfirst method' => sub {
    my $string = 'EXCITING';
    is 'eXCITING', $string->lcfirst; # eXCITING
};

can_ok 'Bubblegum::Object::String', 'length';
subtest 'test the length method' => sub {
    my $string = 'longggggg';
    is 9, $string->length; # 9
};

can_ok 'Bubblegum::Object::String', 'lines';
subtest 'test the lines method' => sub {
    my $string = "who am i?\nwhere am i?\nhow did I get here";
    is_deeply $string->lines, # ['who am i?','where am i?','how did I get here']
        ['who am i?','where am i?','how did I get here'];
};

can_ok 'Bubblegum::Object::String', 'lowercase';
subtest 'test the lowercase method' => sub {
    my $string = 'EXCITING';
    is 'exciting', $string->lowercase; # exciting
};

can_ok 'Bubblegum::Object::String', 'replace';
subtest 'test the replace method' => sub {
    my $string;

    $string = 'Hello World';
    is $string->replace('World', 'Universe'),
        'Hello Universe'; # Hello Universe

    $string = 'Hello World';
    is $string->replace('world', 'Universe', 'i'),
        'Hello Universe'; # Hello Universe

    $string = 'Hello World';
    is $string->replace(qr/world/i, 'Universe'),
        'Hello Universe'; # Hello Universe

    $string = 'Hello World';
    is $string->replace(qr/.*/, 'Nada'),
        'Nada'; # Nada
};

can_ok 'Bubblegum::Object::String', 'reverse';
subtest 'test the reverse method' => sub {
    my $string = 'dlrow ,olleH';
    is 'Hello, world', $string->reverse; # Hello, world
};

can_ok 'Bubblegum::Object::String', 'rindex';
subtest 'test the rindex method' => sub {
    my $string = 'explain the unexplainable';
    is 14, $string->rindex('explain'); # 14
    is 0, $string->rindex('explain', 0); # 0
    is 14, $string->rindex('explain', 21); # 14
    is 14, $string->rindex('explain', 22); # 14
    is 14, $string->rindex('explain', 23); # 14
    is 14, $string->rindex('explain', 20); # 14
    is 14, $string->rindex('explain', 14); # 14
    is 0, $string->rindex('explain', 13); # 0
    is 0, $string->rindex('explain', 0); # 0
    is -1, $string->rindex('explained'); # -1
};

can_ok 'Bubblegum::Object::String', 'snakecase';
subtest 'test the snakecase method' => sub {
    my $string = 'hello world';
    is 'helloWorld', $string->snakecase; # helloWorld
    is 'helloWorld', $string; # helloWorld
};

can_ok 'Bubblegum::Object::String', 'split';
subtest 'test the split method' => sub {
    my $string = 'name, age, dob, email';
    is_deeply $string->split(qr/\,\s*/), # ['name', 'age', 'dob', 'email']
        ['name', 'age', 'dob', 'email'];
    is_deeply $string->split(qr/\,\s*/, 2), # ['name', 'age, dob, email']
        ['name', 'age, dob, email'];
    is_deeply $string->split(', '), # ['name', 'age', 'dob', 'email']
        ['name', 'age', 'dob', 'email'];
    is_deeply $string->split(', ', 2), # ['name', 'age, dob, email']
        ['name', 'age, dob, email'];
};

can_ok 'Bubblegum::Object::String', 'strip';
subtest 'test the strip method' => sub {
    my $string = 'one,  two,  three';
    is 'one, two, three', $string->strip; # one, two, three
    is 'one, two, three', $string; # one, two, three
};

can_ok 'Bubblegum::Object::String', 'titlecase';
subtest 'test the titlecase method' => sub {
    my $string = 'mr. wellington III';
    is 'Mr. Wellington III', $string->titlecase; # Mr. Wellington III
    is 'Mr. Wellington III', $string; # Mr. Wellington III
};

can_ok 'Bubblegum::Object::String', 'to_array';
subtest 'test the to_array method' => sub {
    my $string = 'uniform';
    is_deeply $string->to_array, ['uniform']; # ['uniform']
};

can_ok 'Bubblegum::Object::String', 'to_code';
subtest 'test the to_code method' => sub {
    my $string = 'uniform';
    is 'CODE', ref $string->to_code; # sub { 'uniform' }
    is 'uniform', $string->to_code->(); # uniform
};

can_ok 'Bubblegum::Object::String', 'to_hash';
subtest 'test the to_hash method' => sub {
    my $string = 'uniform';
    is_deeply $string->to_hash, # { 'uniform' => 1 }
        { 'uniform' => 1 };
};

can_ok 'Bubblegum::Object::String', 'to_number';
subtest 'test the to_number method' => sub {
    my $string = 'uniform';
    is 0, $string->to_number; # 0

    $string = '123';
    is 123, $string->to_number; # 123
};

can_ok 'Bubblegum::Object::String', 'to_string';
subtest 'test the to_string method' => sub {
    my $string = 'uniform';
    is 'uniform', $string->to_string; # uniform
};

can_ok 'Bubblegum::Object::String', 'trim';
subtest 'test the trim method' => sub {
    my $string = ' system is   ready   ';
    is 'system is   ready', $string->trim; # system is   ready
    is 'system is   ready', $string; # system is   ready
};

can_ok 'Bubblegum::Object::String', 'uc';
subtest 'test the uc method' => sub {
    my $string = 'exciting';
    is 'EXCITING', $string->uc; # EXCITING
};

can_ok 'Bubblegum::Object::String', 'ucfirst';
subtest 'test the ucfirst method' => sub {
    my $string = 'exciting';
    is 'Exciting', $string->ucfirst; # Exciting
};

can_ok 'Bubblegum::Object::String', 'uppercase';
subtest 'test the uppercase method' => sub {
    my $string = 'exciting';
    is 'EXCITING', $string->uppercase; # EXCITING
};

can_ok 'Bubblegum::Object::String', 'words';
subtest 'test the words method' => sub {
    my $string = "is this a bug we're experiencing";
    is_deeply $string->words, # ["is","this","a","bug","we're","experiencing"]
        ["is","this","a","bug","we're","experiencing"];
};

done_testing;
