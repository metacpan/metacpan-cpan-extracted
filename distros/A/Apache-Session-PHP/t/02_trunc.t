use strict;
use Test::More tests => 1;

use Apache::Session::PHP;
use FileHandle;

my %session;
tie %session, 'Apache::Session::PHP', undef, {
    SavePath => 't',
};

$session{foo} = "bar" x 20;

my $sid = $session{_session_id};
untie %session;

# reload

tie %session, 'Apache::Session::PHP', $sid, {
    SavePath => 't',
};

$session{foo} = "a";
untie %session;

# now correctly cleared?
my $handle = FileHandle->new("t/sess_$sid");
my $content = do { local $/; <$handle> };
unlike $content, qr/bar/, "foo key correctly cleared";


tie %session, 'Apache::Session::PHP', $sid, {
    SavePath => 't',
};
tied(%session)->delete;
untie %session;
