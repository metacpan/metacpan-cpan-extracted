use strict;
use warnings;

use Test::More tests => 1;

subtest 'pod' => sub {
    eval "use Test::Pod 1.00";
    plan skip_all => "Test::Pod v1.00 or later required for testing coverage"
      if $@;

    all_pod_files_ok();
};

done_testing();

exit;

__END__
