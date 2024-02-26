#!/usr/bin/env perl

use strict;
use warnings;

use App::ISBN::Check;
use File::Temp;
use IO::Barf qw(barf);

# ISBNs for test.
my $isbns = <<'END';
978-80-253-4336-4
9788025343363
9788025343364
978802534336
9656123456
END

# Temporary file.
my $temp_file = File::Temp->new->filename;

# Barf out.
barf($temp_file, $isbns);

# Arguments.
@ARGV = (
        $temp_file,
);

# Run.
exit App::ISBN::Check->new->run;

# Output:
# 9788025343363: Different after format (978-80-253-4336-4).
# 9788025343364: Different after format (978-80-253-4336-4).
# 978802534336: Cannot parse.
# 9656123456: Not valid.