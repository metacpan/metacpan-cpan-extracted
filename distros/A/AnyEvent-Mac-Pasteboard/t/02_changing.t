use strict;
use warnings;
use lib qw(lib);
use utf8;

use constant TEST_COUNT => 4;

use Test::More tests => TEST_COUNT;

use AnyEvent;
use AnyEvent::Mac::Pasteboard ();
use Encode;
use File::Temp;
use Time::HiRes;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $cv = AE::cv;

my @dictionary = (qw(FINE ☀ ☁ CLOUD RAIN ☂ ☃ ☆ ★ ♬ ♪ ♫));

diag("This test rewrite your current pasteboard. And do not edit pasteboard on running this test.");

### stash pasteboard content.
my $tmp_file = File::Temp->new( SUFFIX => '.pb' );
my $tmp_filename = $tmp_file->filename;
print {$tmp_file} `pbpaste`;

my $onchange_call_count = 0;
my $previous_content = '';
my $paste_tick = AnyEvent::Mac::Pasteboard->new(
    multibyte => 1,
    interval  => 2,
    on_change => sub {
        $onchange_call_count++;
        my $current_content = shift;
        isnt($current_content, $previous_content, "Catch changing pasteboard status");
        $cv->send() if $onchange_call_count == TEST_COUNT;
        $previous_content = $current_content;
    },
    on_unchange => sub {
        my $current_content = shift;
        fail("changing test is not ok. prev=$previous_content cur=$current_content");
        $cv->send("Error");
    },
);

my $dictionary_idx = 0;
my $system_pbcopy_cb = sub {
    my $word = encode('utf-8', $dictionary[ $dictionary_idx++ % @dictionary ]);
    system(qq{printf "$word" | pbcopy});
};
$system_pbcopy_cb->(); # initialize at first.

sleep 1;

my $pbpaste_system_tick = AE::timer 0, 0.3, $system_pbcopy_cb;

my $error = $cv->recv();

if ( $error ) {
    fail($error);
}

### revert pasteboard content.
if ( open my $fh, '<', $tmp_filename ) {
    my $pb_content = do { local $/; <$fh>; };
    close $fh;
    if ( open my $pipe, '|-', 'pbcopy' ) {
        print {$pipe} $pb_content;
        close $pipe;
    }
}
