package Header;
use Data::Section -setup => { header_re => qr/^\@\@\s*(\S+)/ };

1;
__DATA__

@@ a
1
@@ b
2
