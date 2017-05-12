use Test::More no_plan => 1;

use strict;
use warnings;

use Data::Plist::BinaryReader;
use Data::Plist::BinaryWriter;
use Data::Plist::Foundation::NSObject;
use YAML;

my $ret;
my $read = Data::Plist::BinaryReader->new;
my $p    = $read->open_file("t/data/todo.plist");
my $o    = $p->object; # Should return a Data::Plist::Foundation::LibraryTodo,
                       # which isa Data::Plist::Foundation::NSObject
isa_ok( $o, "Data::Plist::Foundation::NSObject" );
my $s = Data::Plist::BinaryWriter->write($o);    # Returns a binary plist
ok( $s, "Write successful." );
my $r = $read->open_string($s);
ok( $r, "Second read successful" );
isa_ok( $r, "Data::Plist" );
