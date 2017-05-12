#
#===============================================================================
#
#         FILE:  05-backend-mailcap.t
#
#  DESCRIPTION:  Tests App::Open::Backend::MailCap
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  06/06/2008 04:30:37 AM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use constant CLASS => 'App::Open::Backend::MailCap';

BEGIN {
    require Test::More;

    if (eval { require Mail::Cap; require MIME::Types }) {
        Test::More->import('no_plan');
        use_ok(CLASS);
    } else {
        Test::More->import('skip_all' => 'Mail::Cap or MIME::Types is not installed');
    }
};

use Test::Exception;

my $tmp;
my $mailcap_file = "t/resource/backends/mailcap/mailcap";

can_ok( CLASS, "new" );
can_ok( CLASS, "lookup_file" );
can_ok( CLASS, "lookup_url" );

lives_ok { $tmp = CLASS->new(); };

lives_ok { $tmp = CLASS->new([]); };
lives_ok { $tmp = CLASS->new(undef); };
lives_ok { $tmp = CLASS->new(""); };

throws_ok { $tmp = CLASS->new("foo"); } qr/BACKEND_CONFIG_ERROR/;
throws_ok { $tmp = CLASS->new({ }); } qr/BACKEND_CONFIG_ERROR/;

lives_ok { $tmp = CLASS->new(); };

ok(!$tmp->mailcap_file);
is($tmp->mailcap_take, "ALL");

lives_ok { $tmp = CLASS->new([$mailcap_file]); };

is($tmp->mailcap_file, $mailcap_file);
is($tmp->mailcap_take, "FIRST");

# XXX mailcap does not support urls
ok(!$tmp->lookup_url("http"));

is( $tmp->lookup_file("gz"), 'gunzip %s' );
is( $tmp->lookup_file(".gz"), 'gunzip %s' );
ok( !$tmp->lookup_file(".foo") );
