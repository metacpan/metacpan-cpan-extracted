#!perl
use strict;
use warnings;
use Test::More tests => 55;
use Test::Expect;

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/12-env.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/\b2\b/, 'in the REPL');

expect_send(':e');
expect_like(qr/\$Env = \{\};/);

expect_send(':u');
expect_like(qr{\bNow at t/scripts/12-env\.pl:42 \(frame 1\)\.});

expect_send(':e');
expect_like(qr/\$Env = \{(?!\};)/);
expect_like(qr/"\\\$alpha" => \\do \{ my \$v = 1 \}/);
expect_like(qr/"%args"   => \{/);
expect_like(qr/Be => 4/);
expect_like(qr/H  => 1/);
expect_like(qr/He => 2/);
expect_like(qr/Li => 3/);
expect_like(qr/"\\\$beta"  => \\do \{ my \$v = 2 \}/);
expect_like(qr/"\\\$delta" => \\do \{ my \$v = 4 \}/);
expect_like(qr/"\\\$gamma" => \\do \{ my \$v = 3 \}/);

expect_send(':u');
expect_like(qr{\bNow at t/scripts/12-env\.pl:44 \(frame 2\)\.});

expect_send(':e');
expect_like(qr/\$Env = \{(?!\};)/);
expect_like(qr/"%args"     => \{/);
expect_like(qr/Be => 4/);
expect_like(qr/H  => 1/);
expect_like(qr/He => 2/);
expect_like(qr/Li => 3/);
expect_like(qr/\+.*\+.*\+/);

expect_send(':u');
expect_like(qr{\bNow at t/scripts/12-env\.pl:28 \(frame 3\)\.});

expect_send(':e');
expect_like(qr/\$Env = \{(?!\};)/);
expect_like(qr/"\\\$dos"  => \\do \{ my \$v = 'is' \}/);
expect_like(qr/"\\\$tres" => \\do \{ my \$v = 'I' \}/);
expect_like(qr/"\\\$uno"  => \\do \{ my \$v = 'I' \}/);

expect_send(':u');
expect_like(qr{\bNow at t/scripts/12-env\.pl:19 \(frame 4\)\.});

expect_send(':e');
expect_like(qr/\$Env = \{(?!\};)/);
expect_like(qr/"\\\$a" => \\do \{ my \$v = 'I' \}/);
expect_like(qr/"\\\$b" => \\do \{ my \$v = 'I' \}/);

expect_send(':u');
expect_like(qr{\b\QNow at t/scripts/12-env.pl:13 (frame 5).\E});

expect_send(':e');
expect_like(qr/\$Env = \{ "\\\$num" => \\do \{ my \$v = 'I' \} \};/);

expect_send(':u');
expect_like(qr{\b\QNow at t/scripts/12-env.pl:7 (frame 6).\E});

expect_send(':e');
expect_like(qr/\$Env = \{\};/);

expect_send(':u');
expect_like(qr{\b\QNow at t/scripts/12-env.pl:52 (frame 7).\E});

expect_send(':e');
expect_like(qr/\$Env = \{\};/);

expect_send(':u');
expect_like(qr{You're already at the top frame\.});

