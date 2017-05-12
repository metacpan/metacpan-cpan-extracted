use Test::More tests => 3;
use strict; use warnings;

BEGIN { 
  use_ok( 'Bot::Cobalt::Frontend::Utils', qw/:all/ )
}
subtest 'yesno' => sub {
  plan tests => 4;

  open my $stdin, '<', \"y\n" or die "open stdin: $!";
  local *STDIN = $stdin;

  ok( 
    ask_yesno(
      prompt  => "Default no, answer yes?",
      default => 'n'
    ), 'Yes, default no'
  );

  open $stdin, '<', \"y\n" or die "open stdin: $!";
  local *STDIN = $stdin;

  ok(
    ask_yesno(
      prompt  => "Default yes, answer yes?",
      default => 'y'
    ), 'Yes, default yes'
  );

  open $stdin, '<', \"n\n" or die "open stdin: $!";
  local *STDIN = $stdin;
  
  ok(
    ! ask_yesno(
      prompt  => "Default no, answer no?",
      default => 'n',
    ), 'No, default no'
  );

  open $stdin, '<', \"n\n" or die "open stdin: $!";
  local *STDIN = $stdin;

  ok(
    ! ask_yesno(
      prompt  => "Default yes, answer no?",
      default => 'y',
    ), 'No, default yes'
  );
};


subtest 'question' => sub {
  plan tests => 1;

  open my $stdin, '<', \"A string\n" or die "open stdin: $!";
  local *STDIN = $stdin;

  ok(
    ask_question(
      prompt   => "A question",
      die_if_invalid => 1,
      validate => sub {
        $_[0] =~ /\w+/ ? undef : "Not a string"
      },
    ), 'ask_question and validate'
  );
};
