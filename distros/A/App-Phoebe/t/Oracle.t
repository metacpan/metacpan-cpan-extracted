# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use File::Slurper qw(read_binary write_binary);
use Mojo::JSON qw(decode_json encode_json);
use List::Util qw(first);
use Modern::Perl;
use Test::More;
use utf8;

our @use = qw(Oracle);

require './t/test.pl';

# variables set by test.pl
our $base;
our $host;
our $port;
our $dir;

my $page = query_gemini("$base/oracle");
like($page, qr/^# Oracle/m, "Title");
like($page, qr/^=> \/oracle\/ask Ask a question/m, "Link to ask a question");

$page = query_gemini("$base/oracle/ask", undef, 0);
like($page, qr/^60/, "Client certificate required");

$page = query_gemini("$base/oracle/ask");
like($page, qr/^10/, "Ask a question");

$page = query_gemini("$base/oracle/ask?2+%2b+2%20%E2%89%9F");
like($page, qr/^# The oracle accepts/m, "Oracle accepts the question");
$page =~ /^=> \/oracle\/question\/(\d+) Show question/m;
my $n = $1;
ok($n > 0, "Question number");

$page = query_gemini("$base/oracle/log");
like($page, qr/^=> \/oracle\/question\/(\d+) \d\d\d\d-\d\d-\d\d Question #$n: 2 \+ 2 ≟$/m, "Log");

$page = query_gemini("$base/oracle/question/$n");
like($page, qr/^# Question #$n/m, "Question title");
like($page, qr/^2 \+ 2 ≟/m, "Question text");
like($page, qr/^=> \/oracle\/question\/$n\/delete Delete this question/m, "Link to delete this question");
unlike($page, qr/publish/, "Cannot publish a question without answer");
unlike($page, qr/answer/, "Question asker does not get to answer");

$page = query_gemini("$base/oracle/question/$n", undef, 0);
unlike($page, qr/delete/, "Unidentified visitor does not get to delete the question");
unlike($page, qr/answer/, "Unidentified visitor does not get to answer the question");

$page = query_gemini("$base/oracle/question/$n", undef, 2);
unlike($page, qr/delete/, "Somebody else does not get to delete the question");
like($page, qr/^=> \/oracle\/question\/$n\/answer/m, "Somebody else may answer");

$page = query_gemini("$base/oracle/question/$n/answer", undef, 0);
like($page, qr/^60/, "Unidentified visitor does not get a prompt for an answer");
$page = query_gemini("$base/oracle/question/$n/answer");
like($page, qr/^40/, "Question asker does not get to answer");
$page = query_gemini("$base/oracle/question/$n/answer", undef, 2);
like($page, qr/^10/, "Prompt for an answer");
$page = query_gemini("$base/oracle/question/" . ($n+1) . "/answer", undef, 2);
like($page, qr/deleted/, "Attempt to answer an unknown question");

$page = query_gemini("$base/oracle/question/$n/answer?4%E2%80%BC", undef, 2);
like($page, qr/^30 $base\/oracle\/question\/$n\r$/m, "Answer given");

$page = query_gemini("$base/oracle/question/$n");
like($page, qr/^## Answer #1/m, "Answer title");
like($page, qr/^4‼/m, "Answer text");
like($page, qr/^=> \/oracle\/question\/$n\/publish Publish this question/m, "Link to publish this question");
like($page, qr/^=> \/oracle\/question\/$n\/delete Delete this question/m, "Link to delete this question");
like($page, qr/^=> \/oracle\/question\/$n\/1\/delete Delete this answer/m, "Link to delete this answer");

$page = query_gemini("$base/oracle/question/$n", undef, 0);
unlike($page, qr/^4/, "Unidentified visitor does not get to see the answer");

$page = query_gemini("$base/oracle/question/$n", undef, 2);
like($page, qr/^## Your answer/m, "Your answer title");
like($page, qr/^4/m, "Your answer text");
like($page, qr/^=> \/oracle\/question\/$n\/1\/delete Delete this answer/m, "Link to delete your answer");
unlike($page, qr/^=> \/oracle\/question\/$n\/answer/m, "You no longer may answer");

$page = query_gemini("$base/oracle/question/$n/answer?4", undef, 2);
like($page, qr/already answered/, "Do not answer twice");

$page = query_gemini("$base/oracle/question/$n/2/delete", undef, 0);
unlike($page, qr/^40/, "Unidentified visitor does not get to delete an answer");

$page = query_gemini("$base/oracle/question/$n/2/delete");
unlike($page, qr/^30/, "Question owner gets to delete an answer");

# delete the answers we have
my $data = decode_json read_binary("$dir/oracle/oracle.json");
my $question = first { $_->{number} eq $n } @$data;
ok($question, "Found question in the JSON file");
$question->{answers} = [];
write_binary("$dir/oracle/oracle.json", encode_json $data);

$page = query_gemini("$base/oracle/question/$n/answer?4", undef, 2);
like($page, qr/^30/, "Answer given, again");

$page = query_gemini("$base/oracle/question/$n/2/delete", undef, 2);
unlike($page, qr/^30/, "Answer owner also gets to delete an answer");

# assume two answers exist so that adding the third answer marks the question as
# answered
$question->{answers} = [
  {fingerprint => "x", text => "3"},
  {fingerprint => "y", text => "5"}, ];
write_binary("$dir/oracle/oracle.json", encode_json $data);

$page = query_gemini("$base/oracle/question/$n/answer?4", undef, 2);
like($page, qr/^30 $base\/oracle\/\r$/m, "Answer given, setting the question to answered");

$page = query_gemini("$base/oracle/", undef, 2);
unlike($page, qr/$n/, "Question is answered and thus invisible for the question asker");

$page = query_gemini("$base/oracle/", undef, 0);
unlike($page, qr/$n/, "Question is answered and thus invisible for unidentified visitors");

$page = query_gemini("$base/oracle/");
like($page, qr/$n/, "Question is visible for the question asker");

$page = query_gemini("$base/oracle/question/$n");
like($page, qr/publish/m, "Question asker may publish");

$page = query_gemini("$base/oracle/question/$n/publish");
like($page, qr/^30/m, "Published");

$page = query_gemini("$base/oracle/");
like($page, qr/$n/m, "Question is visible for the question asker, obviously");

$page = query_gemini("$base/oracle/", undef, 0);
like($page, qr/$n/m, "Question is visible for unidentified visitors, too");

$page = query_gemini("$base/oracle/", undef, 2);
like($page, qr/$n/m, "Question is visible for other people, too");

$page = query_gemini("$base/oracle/ask");
like($page, qr/^10/, "With the question published, you can ask another");

$page = query_gemini("$base/oracle/question/$n/delete", undef, 0);
like($page, qr/^60/m, "Unidentified visitors may not delete a question");

$page = query_gemini("$base/oracle/question/$n/delete", undef, 2);
like($page, qr/switch identity/i, "Other people may not delete a question");

$page = query_gemini("$base/oracle/question/$n/delete");
like($page, qr/^30/m, "Deleted");

$page = query_gemini("$base/oracle/");
unlike($page, qr/$n/, "Question is gone");

done_testing;
