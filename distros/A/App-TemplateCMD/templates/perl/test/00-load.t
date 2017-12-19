[% IF not module %][% module = 'module'   %][% END -%]
#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( '[% module %]' );
}

diag( "Testing [% module %] $[% module %]::VERSION, Perl $], $^X" );
done_testing();
