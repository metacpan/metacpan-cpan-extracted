use Test::More tests => 7;

BEGIN { use_ok('Audio::TagLib::ID3v2::RelativeVolumeFrame') };

my @methods = qw(new DESTROY toString channels channelType
                 setChannelType volumeAdjustmentIndex setVolumeAdjustmentIndex
                 volumeAdjustment setVolumeAdjustment peakVolume setPeakVolume);
can_ok("Audio::TagLib::ID3v2::RelativeVolumeFrame", @methods) 				or 
	diag("can_ok failed");

isa_ok(Audio::TagLib::ID3v2::RelativeVolumeFrame->new(), 
	"Audio::TagLib::ID3v2::RelativeVolumeFrame") 							or 
	diag("method new() failed");
my $i = Audio::TagLib::ID3v2::RelativeVolumeFrame->new(
	Audio::TagLib::ByteVector->new("XXXX\0\0\0\0\0\0", 10))                 or
	diag("method new(data) failed");
# This is deprecated. Call has no effect
$i->setChannelType("BackCentre");
# This proves that setChannelType() is deprecated. type is hard-coded
is($i->channelType(), "MasterVolume") 								        or 
	diag("method setChannelType(t) and channelType() failed");
$i->setVolumeAdjustmentIndex(20, "MasterVolume");
cmp_ok($i->volumeAdjustmentIndex("MasterVolume"), "==", 20) 		        or 
	diag("method setVolumeAdjustmentIndex(index) and".
		" volumeAdjustmentIndex(MasterVolume) failed");
# Set float 20.20 that's a float, not a comma
$i->setVolumeAdjustment(20.20, "MasterVolume");
cmp_ok($i->volumeAdjustment("MasterVolume"), "==", 20.19921875) 			or 
	diag("method setVolumeAdjustment(adj) and".
		" valumeAdjustment(MasterVolume) failed");
my $peak = Audio::TagLib::ID3v2::RelativeVolumeFrame::PeakVolume->new();
# So, 20 bits represent Peak. This is a local function that sets a PeakVolume structure menber 
$peak->setBitsRepresentingPeak(20);
# setPeakVolume() sets the PeakVolume structure to this ByteVector, which is a series
# of 20 bits (see above) that represents the PeakVolume. What we have here is obviously
# just an arbitrary piece of data
$peak->setPeakVolume(Audio::TagLib::ByteVector->new("blah blah"));
$i->setPeakVolume($peak, "MasterVolume");
isa_ok($i->peakVolume("MasterVolume"), 
	"Audio::TagLib::ID3v2::RelativeVolumeFrame::PeakVolume") 				or 
	diag("method setPeakVolume(peak) and peakVolume() failed");
