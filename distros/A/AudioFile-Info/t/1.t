use Test::More tests => 4;
BEGIN { use_ok('AudioFile::Info') }

# Hard to test anything really as we don't have any plugins installed
# at this point
#
# Hmm... ok, let's try and test some stuff that shouldn't work :)

eval { AudioFile::Info->new };
ok($@);

eval { AudioFile::Info->new('file_with_no_ext') };
ok($@);

eval { AudioFile::Info->new('file_with_bad_ext.foo') };
ok($@);

