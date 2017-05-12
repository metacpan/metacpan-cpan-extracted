use Test::More tests => 31;

BEGIN { use_ok('Audio::TagLib::ID3v2::FrameList') };

my @methods = qw(new DESTROY begin end insert sortedInsert append
                 prepend clear size isEmpty find contains erase front back
                 setAutoDelete getItem copy equals);
can_ok("Audio::TagLib::ID3v2::FrameList", @methods) 					    or 
	diag("can_ok failed");

my $i = Audio::TagLib::ID3v2::FrameList->new();
isa_ok($i, "Audio::TagLib::ID3v2::FrameList")							    or 
	diag("method new() failed");
isa_ok(Audio::TagLib::ID3v2::FrameList->new($i), 
	"Audio::TagLib::ID3v2::FrameList") 								        or 
	diag("method new(framelist) failed");

isa_ok($i->begin(), "Audio::TagLib::ID3v2::FrameList::Iterator") 		    or 
	diag("method begin() failed");
isa_ok($i->end(), "Audio::TagLib::ID3v2::FrameList::Iterator") 		        or 
	diag("method end() failed");
my $tag = Audio::TagLib::ID3v2::Tag->new();
$tag->setTitle(Audio::TagLib::String->new("title"));
$tag->setArtist(Audio::TagLib::String->new("artist"));
$tag->setAlbum(Audio::TagLib::String->new("album"));
$tag->setComment(Audio::TagLib::String->new("comment"));
$tag->setGenre(Audio::TagLib::String->new("genre"));
$tag->setYear(1981);
$tag->setTrack(3);

# Caution: changes list order
sub pit {
    my ($tag, $it) = @_;
    my $i = $it->begin();
    my $s = $it->size();
    print STDERR "\nDump $tag\n";
    return if $s == 0;
    my $n = 0;
    do {
        print STDERR $$i->render()->data(), "\n";
        $n ++;
        return if $n == $s;
        $i++;
    } while 1;
}
my $j = $tag->frameList();
# $j is  List of Frames of Audio::TagLib::ID3v2::Tag and inherits from TagLib::Tag
# framelist returns the FrameList, frames in the order that they were inserted
# i.e., not sorted; see above.

# $i is  Audio::TagLib::ID3v2::FrameList
# Framelist is a List of type Frame (List<Frame>)
# insert, begin and end are all methods of type List<T>
# This uses the end() iterator to insert the front item from the framelist $j.
# which (I'm guessing here) is the Title, etc from above.
$i->insert($i->end(), $j->front());

# So, we get the front item from $i, and verify that its the title
# thus verifying that its what was inserted first
like($i->front()->render()->data(), qr/^TIT2.*?title$/) 		            or 
	diag("method insert(it, item) & front() failed");

# This verifies that in $i back() is the same as fromt()
# i.e., $i is a FrameList with one member
like($i->back()->render()->data(), qr/^TIT2.*?title$/) 			            or 
	diag("method back() failed");

# Note getItem is local to id3v2tagframelist.xs. it implements []
$i->sortedInsert($j->getItem(1));
like(($i->getItem(1))->render()->data(), qr/^TIT2.*?title$/) 	            or 
	diag("method sortedInsert(item) and getItem(1) failed");
$i->append($j->getItem(2));
like($i->back()->render()->data(), qr/^TALB.*?album$/) 			            or 
	diag("method append(item) failed");
$i->prepend($j->getItem(3));
like($i->front()->render()->data(), qr/COMM.*?comment$/) 		            or 
	diag("method prepend(item) failed");
$i->clear();
cmp_ok($i->size(), "==", 0) 									            or 
	diag("method clear() and size() failed");
ok($i->isEmpty()) 												            or 
	diag("method isEmpty() failed");
$i->sortedInsert($j->front());
like($i->find($j->front())->data()->render()->data(), qr/^TIT2.*?title$/)   or
    diag("method find(key) failed");
ok($i->contains($j->front())) 									            or 
	diag("method contains(key) failed");
$i->erase($i->find($j->front()));
ok(not $i->contains($j->front())) 								            or 
	diag("method erase(key) failed");
ok(not $i->equals($j)) 											            or 
	diag("method equals(obj) failed");
################################################################
# NOW START TO TEST TIE MAGIC
################################################################
tie my @i, ref($i), $i;
isa_ok(tied @i, "Audio::TagLib::ID3v2::FrameList") 					        or 
	diag("method TIEARRAY failed");
$i[0] = $j->front();
like($i[0]->render()->data(), qr/^TIT2.*?title$/) 				            or 
	diag("method FETCH and STORE failed");
cmp_ok($#i+1, "==", $i->size()) 								            or 
	diag("method FETCHSIZE failed");
SKIP: {
skip "skip STORESIZE & EXTEND", 0 if 1;
}
ok(exists($i[0])) 												            or 
	diag("method EXISTS failed");
ok(not exists($i[10])) 											            or 
	diag("method not EXISTS failed");
delete($i[0]);
ok(not exists($i[0])) 											            or 
	diag("method DELETE failed");
$i[0] = $j->front();
@i = ();
cmp_ok(scalar(@i), "==", 0) 									            or 
	diag("method CLEAR failed");
push(@i, $j->front());
like($i[0]->render()->data(), qr/^TIT2.*?title$/) 				            or 
	diag("method PUSH failed");
like((pop @i)->render()->data(), qr/^TIT2.*?title$/) 			            or 
	diag("method POP failed");
unshift @i, $j->front();
like($i[0]->render()->data(), qr/^TIT2.*?title$/) 				            or 
	diag("method UNSHIFT failed");
like((shift @i)->render()->data(), qr/^TIT2.*?title$/) 			            or 
	diag("method SHIFT failed");
splice @i, 0, 0, $j->front(), $j->back();
cmp_ok(scalar(@i), "==", 2) 									            or 
	diag("method SPLICE failed");
my ($first, $second) = splice @i, 0, 2;
like($first->render()->data(), qr/^TIT2.*?title$/) 				            or 
	diag("method SPLICE failed");
like($second->render()->data(), qr/^TRCK.*?3$/) 				            or 
	diag("method SPLICE failed");
