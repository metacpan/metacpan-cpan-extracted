use Test::More qw/no_plan/;
BEGIN { use_ok('Algorithm::NGram') };

my $ng = Algorithm::NGram->new(ngram_width => 3);
$ng->add_text('yesterday my best dog went to the deli');
$ng->add_text('yesterday my best friend went to the market');

like($ng->generate_text, qr/yesterday my best (friend|dog) went to the (deli|market)/, "Text trigram");

my $ser = $ng->serialize;

my $ng2 = Algorithm::NGram->deserialize($ser);
is_deeply($ng2->token_table, $ng->token_table, 'Serialize/deserialize');
