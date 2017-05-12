use strict;
use warnings;
use App::loggrep;

use Test::More;
use File::Temp qw(tempfile);
use Capture::Tiny qw(capture_stdout);

{

   package Opty;

   sub AUTOLOAD {
      ( my $name = our $AUTOLOAD ) =~ s/.*:://;
      no strict 'refs';
      *$AUTOLOAD = sub { shift->{$name} };
      goto &$AUTOLOAD;
   }
}

my ( undef, $filename ) = tempfile();
END { unlink $filename }

my %basic = (
   start => '9:12:01',
   end   => '9:12:01',
   date  => '^(\d++(?::\d++)*+)',
   log   => $filename
);

data(<<'END');
a
b
c
d
9:12:00
e
f
9:12:01
9:12:10
9:12:20
9:12:30
9:12:40
9:12:45
9:12:50
g
h
END

my $grepped = lgrep();
is $grepped, '9:12:01', "single line exact times";
$grepped = lgrep( before => 1 );
like $grepped, qr/^f/, "single line exact times; --before 1";
$grepped = lgrep( before => 2 );
like $grepped, qr/^e/, "single line exact times; --before 2";
$grepped = lgrep( after => 1 );
like $grepped, qr/10$/, "single line exact times; --after 1";
$grepped = lgrep( start => '9:12:00', end => '9:12:00', context => 2 );
like $grepped, qr/^c/,
  "single line exact times; context gives correct first line";
like $grepped, qr/f$/,
  "single line exact times; context gives correct last line";
$grepped = lgrep( start => '9:12:15', end => '9:12:35' );
my @lines = lines($grepped);
is scalar @lines, 2, 'correct number of lines with inexact ends';
is $lines[0], '9:12:20', 'correct first line';
is $lines[1], '9:12:30', 'correct second line';
$grepped = lgrep( start => '9:11:50', end => '9:13:00', context => 1 );
@lines = lines($grepped);
is scalar @lines, 12,
  'correct number of lines with inexact time and --context 2';
is $lines[0],  'd', 'correct first line';
is $lines[-1], 'g', 'correct last line';
$grepped = lgrep( start => '9:11:50', end => '9:13:00', blank => 1 );
@lines = lines($grepped);
is scalar @lines, 9, 'correct number of lines with inexact time and --blank';
is $lines[0],  '9:12:00', 'correct first line';
is $lines[-1], '9:12:50', 'correct last line';

data(<<'END');
cat
CAT
END
delete @basic{qw(start end)};

$grepped = lgrep( include => ['cat'] );
@lines = lines($grepped);
is scalar @lines, 1, 'correct number of lines with case-sensitive include';
like $grepped, qr/cat/, 'correct line with case-sensitive include';
$grepped = lgrep( include => ['cat'], case_insensitive => 1 );
@lines = lines($grepped);
is scalar @lines, 2, 'correct number of lines with case-insensitive include';
like $grepped, qr/cat.*CAT/s, 'correct lines with case-insensitive include';
$grepped = lgrep( exclude => ['cat'] );
@lines = lines($grepped);
is scalar @lines, 1, 'correct number of lines with case-sensitive exclude';
like $grepped, qr/CAT/, 'correct lines with case-sensitive exclude';
$grepped = lgrep( case_insensitive => 1, exclude => ['cat'] );
@lines = lines($grepped);
is scalar @lines, 0, 'correct number of lines with case-insensitive exclude';

done_testing();

sub lines {
   my $text = shift;
   return () unless length $text;
   my @lines = $text =~ /^.*$/mg;
   return @lines;
}

sub count_lines { scalar lines(shift) }

sub lgrep {
   my %opts = ( %basic, @_ );
   my $opts = bless \%opts, 'Opty';
   my $grepper = App::loggrep->new( $filename, $opts );
   $grepper->init;
   my $stdout = capture_stdout { $grepper->grep };
   $stdout =~ s/^\s+|\s+$//g;
   return $stdout;
}

sub data {
   my $data = shift;
   open my $fh, '>', $filename;
   print $fh $data;
   close $fh;
}
