package t::lib::Support::does_not_have_method;
my $engine;
sub setup_engine { $engine = $_[1] }
sub run { $engine }

1;
