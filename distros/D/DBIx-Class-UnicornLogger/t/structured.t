use strict;
use warnings;

use Test::More;

use DBIx::Class::UnicornLogger;

{
   my $cap;
   open my $fh, '>', \$cap;

   my $pp = DBIx::Class::UnicornLogger->new({
      squash_repeats => 1,
      tree => {
         profile => 'console_monochrome',
         fill_in_placeholders => 1,
         placeholder_surround => ['', ''],
      },
      multiline_format => " -- %m",
      format => "[%d] %m",
      show_progress => 0,
   });

   $pp->debugfh($fh);

   $pp->query_start('SELECT * FROM frew WHERE id = ?', q('1'));

   my @lines = split /\n/, $cap;

   like $lines[0], qr/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] SELECT \* /;
   like $lines[1], qr/ --   FROM frew /;
   like $lines[2], qr/ -- WHERE id = '1'/;
}

{
   my $cap;
   open my $fh, '>', \$cap;

   my $pp = DBIx::Class::UnicornLogger->new({
      squash_repeats => 1,
      tree => {
         profile => 'console_monochrome',
         fill_in_placeholders => 1,
         placeholder_surround => ['', ''],
      },
      format => "[%d] %m",
      multiline_format => undef,
      show_progress => 0,
   });

   $pp->debugfh($fh);

   $pp->query_start('SELECT * FROM frew WHERE id = ?', q('1'));
   # should do nothing
   $pp->query_end('SELECT * FROM frew WHERE id = ?', q('1'));

   my @lines = split /\n/, $cap;

   like $lines[0], qr/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] SELECT \* /;
   like $lines[1], qr/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\]   FROM frew /;
   like $lines[2], qr/\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] WHERE id = '1'/;
}

{
   my $cap;
   open my $fh, '>', \$cap;

   my $pp = DBIx::Class::UnicornLogger->new({
      squash_repeats => 1,
      tree => {
         profile => 'console_monochrome',
         fill_in_placeholders => 1,
         placeholder_surround => ['', ''],
      },
      format => "%T%n%m",
      multiline_format => '%m',
      show_progress => 0,
   });

   $pp->debugfh($fh);

   $pp->query_start('SELECT * FROM frew WHERE id = ?', q('1'));
   # should do nothing
   $pp->query_end('SELECT * FROM frew WHERE id = ?', q('1'));

   my @lines = split /\n/, $cap;

   like $lines[-4], qr/structured\.t/;
   like $lines[-3], qr/SELECT \* /;
   like $lines[-2], qr/  FROM frew /;
   like $lines[-1], qr/WHERE id = '1'/;
}

done_testing();
