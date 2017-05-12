
package dev::encoding::hello;

use strict;
use warnings 'all';
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;
use MIME::Base64;
use Encode;
use utf8;

# TODO: Encoding tests to make sure we get round-trip encoding integrity.
sub run
{
  my ($s, $context) = @_;
  
  my $hellos = {
    arabic  => {
      original  => 'مرحبا ، العالم!',
      encoded => 'JiMxNjA1OyYjMTU4NTsmIzE1ODE7JiMxNTc2OyYjMTU3NTsgJiMxNTQ4OyAmIzE1NzU7JiMxNjA0
OyYjMTU5MzsmIzE1NzU7JiMxNjA0OyYjMTYwNTsh'
    },
    armenian  => {
      original  => 'Բարեւ, աշխարհի.',
      encoded   => 'JiMxMzMwOyYjMTM3NzsmIzE0MDg7JiMxMzgxOyYjMTQxMDssICYjMTM3NzsmIzEzOTk7JiMxMzg5
OyYjMTM3NzsmIzE0MDg7JiMxMzkyOyYjMTM4Nzsu',
    },
    russian   => {
      original  => 'Здравствуй, мир!',
      encoded   => 'JiMxMDQ3OyYjMTA3NjsmIzEwODg7JiMxMDcyOyYjMTA3NDsmIzEwODk7JiMxMDkwOyYjMTA3NDsm
IzEwOTE7JiMxMDgxOywgJiMxMDg0OyYjMTA4MDsmIzEwODg7IQ=='
    },
    chinese_simplified  => {
      original  => '你好，世界！',
      encoded   => 'JiMyMDMyMDsmIzIyOTA5OyYjNjUyOTI7JiMxOTk5MDsmIzMwMDI4OyYjNjUyODE7',
    },
    foo => {
      original  => 'Bjòrknù',
    }
  };
  
  my $lang = $Form->{lang}
    or return;
  $Response->ContentType("text/plain; charset=utf-8");
  $Response->Write(
    encode_utf8(
      $hellos->{$lang}->{original}
    )
  );
}# end run()

1;# return true:

