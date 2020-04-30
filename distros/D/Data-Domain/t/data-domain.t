#!perl
use strict;
use warnings;

use lib "../lib";

use Test::More tests => 20;
use Test::NoWarnings;

BEGIN { use_ok( 'Data::Domain', qw/:all/ );}
diag( "Testing Data::Domain $Data::Domain::VERSION, Perl $], $^X" );

my $dom;
my $msg;


#----------------------------------------------------------------------
# Shortcuts
#----------------------------------------------------------------------
subtest "Shortcuts" => sub {
  plan tests => 32;

  $dom = True;
  ok($dom->inspect(undef), "True / undef");
  ok(!$dom->inspect(1), "True / 1");
  ok($dom->inspect(0), "True / 0");

  $dom = False;
  ok(!$dom->inspect(undef), "False / undef");
  ok($dom->inspect(1), "False / 1");
  ok(!$dom->inspect(0), "False / 0");

  $dom = True(-optional => 1);
  ok(!$dom->inspect(undef), "True-optional / undef");
  ok(!$dom->inspect(1), "True-optional / 1");
  ok($dom->inspect(0), "True-optional / 0");

  $dom = Defined;
  ok($dom->inspect(undef), "Defined / undef");
  ok(!$dom->inspect(1), "Defined / 1");
  ok(!$dom->inspect(0), "Defined / 0");

  $dom = Undef;
  ok(!$dom->inspect(undef), "Undef / undef");
  ok($dom->inspect(1), "Undef / 1");
  ok($dom->inspect(0), "Undef / 0");

  $dom = Blessed;
  ok(!$dom->inspect($dom), "Blessed / obj");
  ok($dom->inspect(1),     "Blessed / scalar");

  $dom = Unblessed;
  ok($dom->inspect($dom), "Unblessed / obj");
  ok(!$dom->inspect(1),   "Unblessed / scalar");

  $dom = Regexp;
  ok($dom->inspect('foo'),           "Regexp / string");
  ok(!$dom->inspect(qr/foo/),        "Regexp / regexp");

  $dom = Obj;
  ok($dom->inspect('Data::Domain'),  "Obj / class");
  ok(!$dom->inspect($dom),           "Obj / obj");

  $dom = Class;
  ok($dom->inspect($dom),            "Class / obj");
  ok($dom->inspect('Foo'),           "Class / scalar");
  ok(!$dom->inspect('Data::Domain'), "Class / class");

  $dom = Ref;
  ok(!$dom->inspect({}),             "Ref / ref");
  ok($dom->inspect('Foo'),           "Ref / scalar");
  ok($dom->inspect(undef),           "Ref / undef");

  $dom = Unref;
  ok($dom->inspect({}),              "Unref / ref");
  ok(!$dom->inspect('Foo'),          "Unref / scalar");
  ok(!$dom->inspect(undef),          "Unref / undef");

};


#----------------------------------------------------------------------
# Whatever
#----------------------------------------------------------------------
subtest "Whatever" => sub {
  plan tests => 15;

  $dom = Whatever;
  ok(!$dom->inspect(undef), "Whatever / undef");
  ok(!$dom->inspect(1), "Whatever / 1");
  ok(!$dom->inspect(0), "Whatever / 0");


  $dom = Whatever(-defined => 1, -true => 0);
  ok($dom->inspect(undef), "Whatever-defined-false / undef");
  ok($dom->inspect(1), "Whatever-defined-false / 1");
  ok(!$dom->inspect(0), "Whatever-defined-false / 0");

  $dom = Whatever(-isa => "Data::Domain");
  ok(!$dom->inspect($dom), "Whatever-isa / ok");

  $dom = Whatever(-isa => "Foo::Bar");
  ok($dom->inspect($dom), "Whatever-isa / fail");

  $dom = Whatever(-can => "inspect");
  ok(!$dom->inspect($dom), "Whatever-can / inspect");

  $dom = Whatever(-can => [qw/inspect msg subclass/]);
  ok(!$dom->inspect($dom), "Whatever-can / inspect msg subclass");

  $dom = Whatever(-can => [qw/dance sing/]);
  ok($dom->inspect($dom), "Whatever-can / dance sing");

  $dom = Whatever(-does => 'HASH');
  ok(!$dom->inspect($dom), "Whatever-does hash/dom");
  ok($dom->inspect(''), "Whatever-does hash/scalar");

  $dom = Whatever(-matches => [qw/foo bar/]);
  ok(!$dom->inspect('foo'), "Whatever-matches /foo");
  ok($dom->inspect('buz'),  "Whatever-matches /buz");

  # TODO : CHECK isweak, readonly, tainted
};

#----------------------------------------------------------------------
# Empty
#----------------------------------------------------------------------
subtest "Empty" => sub {
  plan tests => 7;
  $dom = Empty(-messages => 'your data is wrong');
  ok($dom->inspect(0),     "Empty, false val");
  ok($dom->inspect(1),     "Empty, true val");
  ok($dom->inspect(undef), "Empty, undef val");
  ok($dom->inspect(),      "Empty, no val");
  ok($dom->inspect({}),    "Empty, hashref");
  $msg = $dom->inspect([]);
  ok($msg,                 "Empty, arrayref");
  is($msg, 'Empty: your data is wrong', "msg for Empty");
};

#----------------------------------------------------------------------
# Num
#----------------------------------------------------------------------

subtest "Num" => sub {
  plan tests => 11;
  $dom = Num;
  ok(!$dom->inspect(-3.33), "Num / ok");
  ok($dom->inspect(undef), "Num / undef");
  ok($dom->inspect("foo"), "Num / string");

  $dom = Num(-range => [-1, 1], -not_in => [0.5, 0.7]);
  ok(!$dom->inspect(-1), "Num / bounds");
  ok(!$dom->inspect(0), "Num / bounds");
  ok(!$dom->inspect(1), "Num / bounds");
  ok($dom->inspect(-2), "Num / bounds");
  ok($dom->inspect(2), "Num / bounds");
  ok($dom->inspect(0.5), "Num / excl. set");
  ok($dom->inspect(0.7), "Num / excl. set");

  $dom = eval {Num(-range => [5, 2])};
  ok(!$dom && $@ =~ m(min/max), "Num invalid min/max");
};


#----------------------------------------------------------------------
# Int & Nat
#----------------------------------------------------------------------

subtest "Int&Nat" => sub {
  plan tests => 7;

  $dom = Int;
  ok(!$dom->inspect(1234), "Int / ok");
  ok(!$dom->inspect(-1234), "Int / ok");
  ok($dom->inspect(3.33), "Int / float");
  ok($dom->inspect(undef), "Int / undef");

  $dom = Nat;
  ok(!$dom->inspect(1234), "Nat / ok");
  ok(!$dom->inspect(0),    "Nat / 0");
  ok($dom->inspect(-1234), "Nat / negative num");
};

#----------------------------------------------------------------------
# Date
#----------------------------------------------------------------------

subtest "Date" => sub {
  plan tests => 10;

  #$dom = Date;
  $dom = "Data::Domain::Date"->new; # try the full OO API
  ok(!$dom->inspect('01.02.2003'), "Date / ok");
  ok($dom->inspect('foo'), "Date / fail");
  ok($dom->inspect('31.02.2003'), "Date / fail");

  $dom = Date(-range => ['01.01.2001', 'today'], 
              -not_in => [qw/02.02.2002 yesterday/]);
  ok($dom->inspect('01.01.1991'), "Date / bounds");
  ok($dom->inspect('01.01.2991'), "Date / bounds");
  ok(!$dom->inspect('01.01.2001'), "Date / bounds");
  ok($dom->inspect('02.02.2002'), "Date / excl. set");

  $dom = eval {Date(-range => [qw/01.02.2003 03.02.2001/])};
  ok(!$dom && $@ =~ m(min/max), "Date invalid min/max");

  "Data::Domain::Date"->parser(sub {     # strict format dd.mm.yyyy
    my $date = shift;
    $date =~ /^(\d\d)\.(\d\d)\.(\d\d\d\d)$/
      or return; 
    return ($3, $2, $1);
  });
  $dom = Date;

  ok(! $dom->inspect('03.03.2003'), "strict date");
  ok($dom->inspect('3.3.2003'), "no short date");
};


#----------------------------------------------------------------------
# Time
#----------------------------------------------------------------------
subtest "Time" => sub {
  plan tests => 7;

  $dom = Time;
  ok(!$dom->inspect('10:14'), "Time / ok");
  ok($dom->inspect('foobar'), "Time / invalid");
  ok($dom->inspect('25:99'), "Time / invalid");

  $dom = Time(-range => ['08:00', '16:00']);
  ok(!$dom->inspect('12:12'), "Time / ok bounds");
  ok($dom->inspect('06:12'), "Time / bounds");
  ok($dom->inspect('23:12'), "Time / bounds");

  $dom = eval {Time(-range => ['05:00', '02:00'])};
  ok(!$dom && $@ =~ m(min/max), "Time invalid min/max");
};


#----------------------------------------------------------------------
# String
#----------------------------------------------------------------------
subtest "String" => sub {
  plan tests => 15;

  $dom = String;
  ok($dom->inspect(undef),            "String / undef");
  ok($dom->inspect({}),               "String / ref");
  ok($dom->inspect(bless({}, 'Foo')), "String / objref");
  ok(!$dom->inspect("foo"),           "String / ok");
  my $fake_string = FakeString->new(qw/a b c/); # FakeString : at end of file
  ok(!$dom->inspect($fake_string), "String / obj with stringification");

  $dom = String(qr/^(foo|bar)$/);
  ok(!$dom->inspect("foo"), "String / regex");
  ok(!$dom->inspect("bar"), "String / regex");
  ok($dom->inspect("fail"), "String / regex");


  $dom = String(-regex      => qr/^foo/,
                -antiregex  => qr/bar/,
                -length     => [5, 10],
                -range      => ['fooAB', 'foozz'],
                -not_in     => [qw/foo_foo_foo foo_foo_bar/],
               );
  ok(!$dom->inspect("foo_foo"), "String / ok regex");
  ok($dom->inspect("foo_bar"), "String / antiregex");
  ok($dom->inspect("foo_foo_foo"), "String / excl. set");
  ok($dom->inspect("foo_"), "String / too short");
  ok($dom->inspect("foo_much_too_long_string"), "String / too long");
  ok($dom->inspect("foo_much_too_long_string"), "String / too long");

  $dom = eval {String(-length => [5, 2])};
  ok(!$dom && $@ =~ m(min/max), "String invalid min/max length");
};


#----------------------------------------------------------------------
# Handle
#----------------------------------------------------------------------
subtest "Handle" => sub {
  plan tests => 3;

  $dom = Handle;
  ok(!$dom->inspect(*STDOUT),  "Handle/stdout 1");
  ok(!$dom->inspect(\*STDOUT), "Handle/stdout 2");
  ok($dom->inspect("STDOUT"),  "Handle/string");

};


#----------------------------------------------------------------------
# Enum
#----------------------------------------------------------------------

subtest "Enum" => sub {
  plan tests => 3;

  $dom = Enum(qw/foo bar buz/);
  ok(!$dom->inspect("foo"), "Enum ok");
  ok($dom->inspect("foobar"), "Enum fail");

  ok(! eval{$dom = Enum(qw/foo bar/, undef);},
     "Enum: undef not allowed in list" );
};


#----------------------------------------------------------------------
# List
#----------------------------------------------------------------------

subtest "List" => sub {
  plan tests => 26;

  $dom = List;
  ok(!$dom->inspect([]), "List ok");
  ok(!$dom->inspect([1 .. 4]), "List ok");
  ok($dom->inspect("foobar"), "List fail");

  $dom = List(Int, Num, String(-optional => 1));
  ok(!$dom->inspect([1, 2, 3]), "List items ok");
  ok(!$dom->inspect([1, 2.5, "foo"]), "List items ok");
  ok(!$dom->inspect([1, 2.5, "foo", "bar"]), "List items ok");
  ok($dom->inspect([1.5, 2, "foo", "bar"]), "List items fail");
  ok($dom->inspect([1]), "List fail");
  ok($dom->inspect([]), "List fail2");
  ok(!$dom->inspect([1, 2]), "List optional");
  ok($dom->inspect([1, 2, {}]), "List wrong optional");

  $dom = List(-size => [2, 5], -all => Int);
  ok(!$dom->inspect([1, 2, 3]), "List ok");
  ok($dom->inspect([1]), "List min_size");
  ok($dom->inspect([1 .. 6]), "List max_size");
  ok($dom->inspect([1, 2, 3, "foo"]), "List not all");

  $dom = List(-size => [2, 5], -any => Int);
  ok(!$dom->inspect([1, 2, 3]), "List ok");
  ok($dom->inspect([qw/foo bar buz/]), "List not any");
  ok(!$dom->inspect([qw/foo bar buz/, 3]), "List any");

  $dom = List(-items => [String, Num], 
              -any => Int);
  ok($dom->inspect(['foo', 2]), "List + items not any");
  ok(!$dom->inspect(['foo', 2, 3]), "List + items any 1");
  ok(!$dom->inspect(['foo', 2, 'foo', 'bar', 3]), "List + items any 2");

  $dom = List(-items => [String, Num], 
              -any => [String(qr/^foo/), Int(-range => [1, 10])]);
  ok($dom->inspect(['foo', 2, undef, 'foobar']), "List 2 anys nok 1");
  ok($dom->inspect(['foo', 2, 3, 'bar', 'bie']), "List 2 anys nok 2");
  ok(!$dom->inspect(['foo', 2, 3, 'foobar']), "List 2 anys ok 1");
  ok(!$dom->inspect(['foo', 2, undef, 3, 'foobar']), "List 2 anys ok 2");

  $dom = eval {List(-items => [String, Num], -size => [5, 2])};
  ok(!$dom && $@ =~ m(min/max), "List invalid min/max size");
};

#----------------------------------------------------------------------
# Struct
#----------------------------------------------------------------------

subtest "Struct" => sub {
  plan tests => 20;

  $dom = Struct;
  ok(!$dom->inspect({}), "Struct ok");
  ok($dom->inspect([]), "Struct fail list");
  ok($dom->inspect(undef), "Struct fail undef");
  ok($dom->inspect(123), "Struct fail scalar");

  $dom = Struct(int => Int, str => String, num => Num(-optional => 1));
  ok(!$dom->inspect({int => 3, str => "foo"}), "Struct ok");
  ok(!$dom->inspect({int => 3, str => "foo", bar => 123}), "Struct more fields");
  ok(!$dom->inspect({int => 3, str => "foo", num => 123}), "Struct ok num");
  ok($dom->inspect({int => "foo", str => 3, num => 123}), "Struct fail");

  $dom = Struct(-exclude => [qw/foo bar/], int => Int);
  ok(!$dom->inspect({int => 3, foobar => 4}), "Struct foobar");
  ok($dom->inspect({int => 3, foo => 4}), "Struct foo");

  $dom = Struct(-fields => [int => Int], 
                -exclude => qr/foo|bar/);
  ok($dom->inspect({int => 3, foobar => 4}), "Struct foobar");
  ok($dom->inspect({int => 3, foo => 4}), "Struct foo");
  ok(!$dom->inspect({int => 3, other => 4}), "Struct other");

  $dom = Struct(-fields => {int => Int}, 
                -exclude => '*');
  ok(!$dom->inspect({int => 3}), "Struct ok");
  ok($dom->inspect({int => 3, foobar => 4}), "Struct foobar");
  ok($dom->inspect({int => 3, foo => 4}), "Struct foo");
  ok($dom->inspect({int => 3, other => 4}), "Struct other");


  $dom = Struct(-keys   => List(-all => String(qr/^[abc]/)),
                -values => List(-any => Int));
  ok(!$dom->inspect({a => 123, b => 456}), "Struct -keys & -values");
  ok($dom->inspect({x => 123, y => 456}), "Struct invalid key");
  ok($dom->inspect({a => "foo", b => "bar"}), "Struct invalid value");
};

#----------------------------------------------------------------------
# One_of
#----------------------------------------------------------------------

subtest "One_of" => sub {
  plan tests => 5;

  $dom = One_of(String(qr/^[AEIOU]/), Int(-min => 0));
  ok(!$dom->inspect("Alleluia"), "One_of ok1");
  ok(!$dom->inspect(1234), "One_of ok2");
  ok($dom->inspect("hello, world"), "One_of fail string");
  ok($dom->inspect(undef), "One_of fail undef");
  ok($dom->inspect(-789), "One_of fail neg. num");
};

#----------------------------------------------------------------------
# All_of
#----------------------------------------------------------------------

subtest "All_of" => sub {
  plan tests => 3;

  $dom = All_of(String(qr/[24680]/), Int(-min => 0));
  ok(!$dom->inspect(1234), "All_of, positive and contains even digit");
  ok($dom->inspect(135),   "All_of, positive without even digit");
  ok($dom->inspect(-24),   "All_of, negative with even digit");
};


#----------------------------------------------------------------------
# Overloads
#----------------------------------------------------------------------

subtest "Overloads" => sub {
  plan tests => 4;
  use experimental 'smartmatch';

  $dom = Unblessed;
  my $string = "$dom";
  like($string, qr/Whatever/, "stringify");

  ok(1 ~~ $dom,       "Smart match OK");
  ok(!($dom ~~ $dom), "Smart match KO");
  like($Data::Domain::MESSAGE, qr/blessed/, "Smart match message");
};



#----------------------------------------------------------------------
# context and lazy constructors
#----------------------------------------------------------------------

subtest "Lazy" => sub {
  plan tests => 10;

  $dom = Struct(
    d_begin => Date,
    d_end   => sub {my $context = shift;
                    Date(-min => $context->{flat}{date_begin})},
   );

  ok(!$dom->inspect({d_begin => '01.01.2001', 
                     d_end   => '02.02.2002'}), "Dates order ok");

  ok(!$dom->inspect({d_begin => '03.03.2003', 
                     d_end   => '02.02.2002'}), "Dates order fail");


  sub clone { # can't remember which CPAN module implements cloning
    my $node = shift;
    for (ref $node) {
      /ARRAY/ and return [map {clone($_)} @$node];
      /HASH/  and do { my $r = {};
                       $r->{$_} = clone($node->{$_}) foreach keys %$node;
                       return $r; };
      /^$/    and return $node;
      die "cloning incorrect data";
    }
  }

  my $context;
  $dom = Struct(
       foo => List(Whatever, 
                   Whatever, 
                   Struct(bar => sub {$context = clone(shift); String;})
                  )
       );
  my $data   = {foo => [undef, 99, {bar => "hello, world"}]};
  $dom->inspect($data);

  my $proof_context  = {
      root => {foo => [undef, 99, {bar => 'hello, world'}]},
      path => ['foo', 2, 'bar'],
      flat => { bar => 'hello, world'},
    };
  $proof_context->{flat}{foo} 
    = $proof_context->{list} 
    = $proof_context->{root}{foo};
  is_deeply($context, $proof_context, "context");


  my $some_cities = {
     Switzerland => [qw/Genève Lausanne Bern Zurich Bellinzona/],
     France      => [qw/Paris Lyon Marseille Lille Strasbourg/],
     Italy       => [qw/Milano Genova Livorno Roma Venezia/],
  };
  $dom = Struct(
     country => Enum(keys %$some_cities),
     city    => sub {
        my $context = shift;
        Enum(-values => $some_cities->{$context->{flat}{country}});
      });

  ok(!$dom->inspect({country => 'Switzerland', city => 'Genève'}), "city ok");
  ok($dom->inspect({country => 'France', city => 'Genève'}), "city fail");


  $dom = List(-all => sub {
        my $context = shift;
        my $index = $context->{path}[-1];
        return $index == 0 ? Int
                           : Int(-min => $context->{list}[$index-1]);
      });
  ok(!$dom->inspect([1, 1, 2, 3, 5, 8, 13]), "order ok");
  ok($dom->inspect([1, 1, 2, 5, 3, 8, 13]), "order fail");

  $dom = One_of(Num, Struct(op    => String(qr(^[-+*/]$)),
                            left  => sub {$dom},
                            right => sub {$dom}));

  ok(!$dom->inspect({
    op => '*',
    left => {op => '+', left => 4, right => 5},
    right => 9
   }), "recursive ok");

  ok($dom->inspect({
    op => '*',
    left => {op => '+', left => 4, right => 5},
    right => {}
   }), "recursive fail");

  # check $MAX_DEEP
  my $infinite = {op => '+', left => 123};
  $infinite->{right} = $infinite;
  eval {$dom->inspect($infinite)};
  my $err = $@;
  like($err, qr/MAX_DEEP/, 'limited deepness');
};




#----------------------------------------------------------------------
# messages
#----------------------------------------------------------------------

subtest "messages" => sub {
  plan tests => 6;

  Data::Domain->messages("français");

  $dom = Int;
  $msg = $dom->inspect("foobar");
  is($msg, "Int: nombre incorrect", "msg français");

  $dom = Int(-name => "PositiveInt", -min => 0);
  $msg = $dom->inspect("foobar");
  is($msg, "PositiveInt: nombre incorrect", "msg français");


  $dom = Int(-messages => "fix that number");
  $msg = $dom->inspect("foobar");
  is($msg, "Int: fix that number", "msg string");


  $dom = Int(-min => 4, 
             -max => 5,
             -messages => {TOO_SMALL => "too small", 
                           TOO_BIG => "too big (over %d)"}); 
  $msg = $dom->inspect(99);
  is($msg, "Int: too big (over 5)", "msg direct");

  $dom = Int(-min => 4, 
             -max => 5,
             -messages => sub {"got an error ($_[0])"});
  $msg = $dom->inspect(99);
  is($msg, "got an error (TOO_BIG)", "msg sub");

  Data::Domain->messages(sub {"validation error ($_[0])"});
  $dom = Int(-min => 0);
  $msg = $dom->inspect(-99);
  is($msg, "validation error (TOO_SMALL)", "msg global sub");

  Data::Domain->messages("english");
};


#----------------------------------------------------------------------
# examples from doc
#----------------------------------------------------------------------

subtest "doc" => sub {
  plan tests => 4;

  sub Phone   { String(-regex => qr/^\+?[0-9() ]+$/, @_) }
  sub Email   { String(-regex => qr/^[-.\w]+\@[\w.]+$/, @_) }
  sub Contact { Struct(-fields => [name   => String,
                                   phone  => Phone,
                                   mobile => Phone(-optional => 1),
                                   emails => List(-all => Email)], @_) }

  $msg = Contact->inspect({name => "Foo", 
                           phone => 12345,
                           emails => ['foo.bar@foo.com']});

  ok(!$msg, "contact OK");


  $dom = Struct( foo => 123,
                 bar => List(Int, 'buz', Int) );
  ok(!$dom->inspect({foo => 123, bar => [1, buz => 2]}), "constant subdomains");
  $msg = $dom->inspect({foo => "foo", bar => [buz => 1, 2]});
  ok($msg, "constant subdomains ERR1");
  note(explain($msg));

  $msg = $dom->inspect({foo => 111, bar => [1, zorglub => 3]});
  ok($msg, "constant subdomains ERR2");
  note(explain($msg));

};


#----------------------------------------------------------------------
# class for testing stringification
#----------------------------------------------------------------------
package FakeString;
use strict;
use warnings;

use overload '""' => sub {my $self = shift; join "", @$self};

sub new {
  my $class = shift;
  bless [@_], $class;
}
