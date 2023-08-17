use Test::LocalFunctions;
use Test::More;
all_local_functions_ok({ignore_functions => [qr(_execute|_run|_handle)]});
done_testing;
