BEGIN { chdir 't' if -d 't' }

### add ../lib to the path
BEGIN { use File::Spec;
        use lib 'inc';
        use lib File::Spec->catdir(qw[.. lib]);
}

BEGIN { require 'conf.pl' }

use strict;


### load the appropriate modules
use_ok( $DIST );
use_ok( $CLASS );
use_ok( $CONST );

### check if all it's functions got imported ok
{   for my $sub ( sort @CPANPLUS::Dist::Deb::Constants::EXPORT ) {
        can_ok( $CONST, $sub );
    }
}

### simple constants
{   my @list = qw[  DEB_LICENSE_GPL
                    DEB_LICENSE_ARTISTIC
                    DEB_URGENCY
                    DEB_DEBHELPER
                    DEB_PERL_DEPENDS
                    DEB_STANDARDS_VERSION
                    DEB_STANDARD_COPYRIGHT_PERL
                    DEB_REPLACE_PERL_CORE
                ];

    for my $name (@list) {
        my $sub = __PACKAGE__->can( $name );
        ok( $sub,                   "Found sub '$name'" );

        my $rv = $sub->();
        like( $rv, qr/\w+/,     "   RV holds data expected" );
    }
}

### file names + locations ###
{   my $map = {
        'DEB_DEBIAN_DIR'    => qr/debian/,
        'DEB_CHANGELOG'     => qr/changelog/,
        'DEB_COMPAT'        => qr/compat/,
        'DEB_CONTROL'       => qr/control/,
        'DEB_RULES'         => qr/rules/,
        'DEB_COPYRIGHT'     => qr/copyright/,
    };

    while( my($name,$re) = each %$map ) {
        my $sub = __PACKAGE__->can( $name );
        ok( $sub,                   "Found sub '$name'" );

        {   my $rv = $sub->()->();
            like( $rv, $re,         "   RV as expected ($rv)" );
        }

        {   my $dir = 'foo';
            my $rv  = $sub->()->($dir);
            like( $rv, $re,         "   RV as expected ($rv)" );
            like( $rv, qr/^$dir/,   "   RV contains '$dir'" );
        }
    }
}

### should return some sort of string
{   my @list = qw[  DEB_RULES_ARCH
                    DEB_ARCHITECTURE
                ];

    for my $name (@list) {
        my $sub = __PACKAGE__->can( $name );
        ok( $sub,                   "Found sub '$name'" );

        my $rv = $sub->();
        like( $rv, qr/.+/,     "   RV holds data expected" );
    }
}

### external programs
{   my @list = qw[  DEB_BIN_BUILDPACKAGE
                ];

    for my $name (@list) {
        my $sub = __PACKAGE__->can( $name );
        ok( $sub,                   "Found sub '$name'" );

        my $rv = $sub->()->();
        ok( -e $rv,                 "   Program '$rv' exists" );
        ok( -x $rv,                 "   Program '$rv' is executable" );
    }
}

### constants that operate on cpanplus module object
{   my $mod     = $FAKEMOD;
    my $debmod  = $DEBMOD;

    ok( $mod,                       "Module object created" );

    ### test debnaming
    {   my $debname = DEB_PACKAGE_NAME->()->( $mod );
        ok( $debname,               "   Module got debname '$debname'" );
        is( $debname, $debmod,      "       Module properly named" );
    }

    ### test versioning
    {   my $version = DEB_VERSION->()->( $mod );
        ok( $version,               "   Module has version '$version'" );
        like( $version, qr/\d+-1/,  "       Proper version found" );
    }

    ### package filename
    {   my $dir     = 'foo';
        my $file    = DEB_DEB_FILE_NAME->()->( $mod, $dir );
        ok( $file,                  "   File name '$file'" );
        like( $file, qr/$debmod/,   "       Contains '$debmod'" );
        like( $file, qr/^$dir/,     "       Contains '$dir'" );
        like( $file, qr/deb$/,      "       Contains 'deb'" );
    }

    ### get the rules content
    SKIP: {   
        skip "Rules Content requires real mod & dist objects", 2;
        
        $mod->status->installer_type( '' );     # quell warnings

        my $rv = DEB_GET_RULES_CONTENT->()->($mod);
        ok( $rv,                    "   Rules content retrieved" );
        like( $rv, qr/\w+/,         "       Has some content" );
    }
}
