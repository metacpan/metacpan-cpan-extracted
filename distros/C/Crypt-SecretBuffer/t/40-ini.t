use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw( secret HEX );
use Crypt::SecretBuffer::INI;

sub span_equal_to {
   my $str= shift;
   object {
      call length => length($str);
      call sub { shift->starts_with($str) }, T;
   }
}
sub secret_equal_to {
   my $str= shift;
   object {
      call length => length($str);
      call sub { shift->index($str) }, 0;
   }
}

subtest defaults => sub {
   my $s= secret(<<END)->span;
[test]
a=1
b=2
this is an error
#\tcomment about stuff \t\t\r
c = 3 \r
 some setting= 4
END
   my $ini= Crypt::SecretBuffer::INI->new;
   is $ini->parse_next($s),
      { section => span_equal_to('test') },
      'line 1 section header';
   is $ini->parse_next($s),
      { key => span_equal_to('a'), value => span_equal_to('1') },
      'line 2 "a=1"';
   is $ini->parse_next($s),
      { key => span_equal_to('b'), value => span_equal_to('2') },
      'line 3 "b=2"';
   is $ini->parse_next($s),
      { error => match(qr/lacks delimiter/), context => T },
      'syntax error';
   is $ini->parse_next($s),
      { comment => span_equal_to("comment about stuff") },
      'comment';
   is $ini->parse_next($s),
      { key => span_equal_to('c'), value => span_equal_to('3') },
      'trim \r from value';
   is $ini->parse_next($s),
      { key => span_equal_to('some setting'), value => span_equal_to('4') },
      'leading ws on key';
};

subtest inline_comments => sub {
   my $s= secret(<<END)->span;
#! /bin/sh
[ test ] ; a header
a=1    # setting "a"
b=2 
END
   my $ini= Crypt::SecretBuffer::INI->new(inline_comments => 1);
   is $ini->parse_next($s),
      { comment => span_equal_to('! /bin/sh') },
      'comment';
   is $ini->parse_next($s),
      { section => span_equal_to('test'), comment => span_equal_to('a header') },
      'line 2 section header';
   is $ini->parse_next($s),
      { key => span_equal_to('a'), value => span_equal_to('1'), comment => span_equal_to('setting "a"') },
      'line 3 "a=1"';
   is $ini->parse_next($s),
      { key => span_equal_to('b'), value => span_equal_to('2') },
      'line 4 "b=2"';
};

subtest parse_env_file => sub {
   my $s= secret(<<END)->span;
EXAMPLE_1=value
EXAMPLE_2=some other value
DB_USER=myapp
DB_PASSWORD=iuvyzlxvuxzkcjvlskd
AES_KEY=001122334455
END
   my $ini= Crypt::SecretBuffer::INI->new(field_config => [
      qr/password/i => { secret => 1 },
      AES_KEY => { secret => 1, encoding => HEX },
   ]);
   is $ini->parse($s),
      [ '' => {
         EXAMPLE_1   => 'value',
         EXAMPLE_2   => 'some other value',
         DB_USER     => 'myapp',
         DB_PASSWORD => secret_equal_to('iuvyzlxvuxzkcjvlskd'),
         AES_KEY     => secret_equal_to("\x00\x11\x22\x33\x44\x55"),
      }],
      'mixed secrets and nonsecrets';
};

subtest parse_flat_sections => sub {
   my $s= secret(<<END)->span;
a=1
[B]
b=2
[C]
1=1
%=&
END
   my $ini= Crypt::SecretBuffer::INI->new;
   is $ini->parse($s),
      [ '' => { a => 1 },
        'B' => { b => 2 },
        'C' => { 1 => 1, '%' => '&' },
      ],
      'list of sections and hashrefs';
};

subtest parse_section_tree => sub {
   my $s= secret(<<END)->span;
x = 1
[Foo]
x = 2
[Foo::Bar]
a = 1
c = 9
[Foo::Bar::Baz]
two words = some text ; test
[ Qwerty ]
[ Foo::Qwerty ]
 123 =456
END
   my $ini= Crypt::SecretBuffer::INI->new(
      section_delim => '::',
      field_config => [
         'Foo::Bar' => [
            c => { secret => 1 },
            qr/two words/ => { secret => 1 },
         ],
      ]
   );
   is $ini->parse($s),
      {  x => 1,
         Foo => {
            x => 2,
            Bar => {
               a => 1,
               c => secret_equal_to(9),
               Baz => {
                  'two words' => secret_equal_to('some text ; test'),
               }
            },
            Qwerty => { '123' => '456' },
         },
         Qwerty => {},
      },
      'tree of sections';
};

# The example from the module SYNOPSIS
subtest synopsis => sub {
   my $input= secret(<<END);
[database]
user=myapp
password=hunter2
[database.encryption]
aes_key=0123456789ABCDEF
[email]
smtp_auth=sldkdsjfldsjklfadsjkf
END

   my $ini= Crypt::SecretBuffer::INI->new(
      section_delim => '.',
      field_config => [
         password  => { secret => 1 },
         smtp_auth => { secret => 1 },
         aes_key   => { secret => 1, encoding => HEX },
      ]
   );
   my $config= $ini->parse($input);
   use Data::Dumper;
   is 'Data::Dumper'->new([$config])->Terse(1)->Indent(1)->Sortkeys(1)->Dump, <<END, 'test Dumper output';
{
  'database' => {
    'encryption' => {
      'aes_key' => bless( {}, 'Crypt::SecretBuffer' )
    },
    'password' => bless( {}, 'Crypt::SecretBuffer' ),
    'user' => 'myapp'
  },
  'email' => {
    'smtp_auth' => bless( {}, 'Crypt::SecretBuffer' )
  }
}
END
};

done_testing;
