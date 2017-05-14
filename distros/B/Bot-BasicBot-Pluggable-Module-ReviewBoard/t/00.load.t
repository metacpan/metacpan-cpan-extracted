use Test::More tests => 1;

BEGIN {
    use_ok "Bot::BasicBot::Pluggable::Module::ReviewBoard" || BAIL_OUT "ReviewBoard module not loaded";
}
