use Test::LocalFunctions;
use Test::More;
all_local_functions_ok({ignore_functions => [qr(_execute)]});
done_testing;
