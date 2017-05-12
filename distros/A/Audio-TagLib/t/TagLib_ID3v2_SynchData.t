use Test::More tests => 4;

BEGIN { use_ok('Audio::TagLib::ID3v2::SynchData') };

# In the ID3v2.4 standard most integer values are encoded as "synch safe"
# integers which are encoded in such a way that they will not give false
# MPEG syncs and confuse MPEG decoders.  

my @methods = qw(toUInt fromUInt);
can_ok("Audio::TagLib::ID3v2::SynchData", @methods) 					                       or 
	diag("can_ok failed");

cmp_ok(Audio::TagLib::ID3v2::SynchData->toUInt(Audio::TagLib::ByteVector->new("a")), "==", 97) or
        diag("method toUInt(data) failed");
my $data = Audio::TagLib::ID3v2::SynchData->fromUInt(97)->data();
cmp_ok(length($data), "==", 4) 									                               or 
	diag("method fromUInt(value) failed");
