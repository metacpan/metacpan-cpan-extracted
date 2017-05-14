use Test::More qw(no_plan);

BEGIN {
    use_ok ('Acme::Time::Asparagus');
    warn ("\n\nYou'll get warnings here about redefined methods. That's OK.\n\n");
    use_ok ('Acme::Time::Aubergine');
    warn ("\n\nAnd that should be the end of the warnings.\n\n");
    use_ok ('Acme::Time::DimSum');
}

