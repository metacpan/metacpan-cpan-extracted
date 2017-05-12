
use Config::ApacheFormat;

BEGIN {
    eval {
        require Scalar::Util;
        import  Scalar::Util qw(weaken);
    };
    if ($@) {
        my $mesg = $@;  # $@ cleared on require/import
        require Test::More;
		import  Test::More skip_all => $mesg;
		exit;
	}
}

use Test::More qw(no_plan);

# run this with the call to weaken() in ApacheFormat.pm commented out
# and watch the amazing leaking code in top!  You might need to add
# more iterations if it's buzzing by too fast.
for(0 .. 100) {
    my $config = Config::ApacheFormat->new();
    $config->read("t/block.conf");
    ok(1);
}
