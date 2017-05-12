use Test::More tests => 2;

BEGIN { use_ok('Audio::TagLib::FileRef::FileTypeResolver') };

my @methods = qw(createFile);
can_ok("Audio::TagLib::FileRef::FileTypeResolver", @methods) 			or 
	diag("can_ok failed");

# A class for pluggable file type resolution.
# This class is used to add extend TagLib's very basic file name based file type resolution.
# So therefore there's not much to do, other than to verify the class presence.
