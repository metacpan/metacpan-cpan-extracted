use Test::Most;

warning_is { eval { require Color::Library } } "";

done_testing;
