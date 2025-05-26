# t/letter.t
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Business::LetterWriter;
use Test::More tests => 1;
Business::LetterWriter::get_one_answer_from_new_llm("hello");
ok(1, 'Basic test passes');

