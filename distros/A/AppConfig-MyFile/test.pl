#========================================================================
#
# test.pl
#
# AppConfig::MyFile test file.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use vars qw($loaded);
$^W = 1;

BEGIN { 
    $| = 1; 
    print "1..3\n"; 
}

END {
    ok(0) unless $loaded;
}

my $ok_count = 1;
sub ok {
    shift or print "not ";
    print "ok $ok_count\n";
    ++$ok_count;
}

use AppConfig;
use AppConfig::MyFile;
$loaded = 1;
ok(1);


#------------------------------------------------------------------------

# create new AppConfig object
my $appconfig = AppConfig->new();
ok( $appconfig );

# call myfile to create AppConfig::MyFile and call parse()
ok( $appconfig->myfile(\*DATA) );


__DATA__
This is a test
