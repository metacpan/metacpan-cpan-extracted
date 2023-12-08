#!/usr/bin/env perl

use strict;
use warnings;

use App::Run::Command::ToFail;
use File::Temp qw(tempfile);
use IO::Barf qw(barf);

my (undef, $tmp_file) = tempfile();
barf($tmp_file, <<'END');
use strict;
use warnings;

print ".";
END

# Arguments.
@ARGV = (
        '-n 10',
        $tmp_file,
);

# Run.
exit App::Run::Command::ToFail->new->run;

# Output like:
# ..........Everything is ok.