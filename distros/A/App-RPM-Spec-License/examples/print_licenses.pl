#!/usr/bin/env perl

use strict;
use warnings;

use App::RPM::Spec::License;
use File::Temp;
use File::Spec::Functions qw(catfile);
use IO::Barf qw(barf);

# Temp dir.
my $temp_dir = File::Temp->newdir;

barf(catfile($temp_dir, 'ex1.spec'), <<'END');
License: BSD
END
barf(catfile($temp_dir, 'ex2.spec'), <<'END');
License: MIT
END
barf(catfile($temp_dir, 'ex3.spec'), <<'END');
License: MIT
END

# Arguments.
@ARGV = (
        $temp_dir,
);

# Run.
exit App::RPM::Spec::License->new->run;

# Output:
# BSD
# MIT
# MIT