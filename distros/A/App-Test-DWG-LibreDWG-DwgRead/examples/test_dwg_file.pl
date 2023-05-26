#!/usr/bin/env perl

use strict;
use warnings;

use App::Test::DWG::LibreDWG::DwgRead;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use IO::Barf qw(barf);
use MIME::Base64;

# Bad DWG data in base64.
my $bad_dwg_data = <<'END';
QUMxMDAyAAAAAAAAAAAAAAAK
END

# Prepare file in temp dir.
my $temp_dir = tempdir(CLEANUP => 1);

# Save data to file.
my $temp_file = catfile($temp_dir, 'bad.dwg');
barf($temp_file, decode_base64($bad_dwg_data));

# Arguments.
@ARGV = (
        $temp_dir,
);

# Run.
exit App::Test::DWG::LibreDWG::DwgRead->new->run;

# Output like:
# Cannot dwgread '/tmp/__TMP_DIR__/bad.dwg'.
#         Command 'dwgread -v1 /tmp/__TMP_DIR__/1.dwg' exit with 256.