use Test::More tests => 45;

use strict;
use warnings;

use Data::Plist::XMLWriter;

my $out;

# Dict
one_way(
    { "kitteh" => "Angleton" }, '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
        <dict>
                <key>kitteh</key>
                <string>Angleton</string>
        </dict>
</plist>
'
);

# Array
one_way(
    [ "Cthulhu", 42, "a" ], '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
        <array>
                <string>Cthulhu</string>
                <integer>42</integer>
                <string>a</string>
        </array>
</plist>
'
);

# UID
preserialize(
    [ UID => 1 ], '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
        <dict>
                <key>CF$UID</key>
                <integer>1</integer>
        </dict>
</plist>
'
);

# Miscs
preserialize(
    [ false => 0 ], '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
        <false />
</plist>
'
);
preserialize(
    [ true => 1 ], '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
        <true />
</plist>
'
);
preserialize(
    [ fill => 15 ], '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
        <fill />
</plist>
'
);
preserialize(
    [ null => 0 ], '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
        <null />
</plist>
'
);

# Data
preserialize(
    [ data => "stu\x00ff" ], '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
        <data>c3R1AGZm
</data>
</plist>
'
);

# Not one of the prescribes structures
preserialize(
    [ random => 17 ], '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">

<plist version="1.0">
        <!-- random -->
</plist>
'
);

sub one_way {
    my $write = Data::Plist::XMLWriter->new( serialize => 1 );
    test( $write, @_ );
}

sub preserialize {
    my $write = Data::Plist::XMLWriter->new( serialize => 0 );
    test( $write, @_ );
}

sub test {
    my ( $write, $input, $output ) = @_;
    ok( $write, "Created XML writer." );
    isa_ok( $write, "Data::Plist::XMLWriter" );
    $out = $write->write($input);
    ok( $out, "Created xml." );
    is( "$@", '' );
    is( $out, $output, "XML output is correct." );
}
