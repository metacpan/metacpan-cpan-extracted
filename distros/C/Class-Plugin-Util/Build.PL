# $Id: Build.PL,v 1.1.1.1 2007/05/23 22:07:09 ask Exp $
# $Source: /opt/CVS/classpluginutil/Build.PL,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.1.1.1 $
# $Date: 2007/05/23 22:07:09 $
use strict;
use warnings;
use Module::Build;

# ##########################################################

# Configuration for this script is done in the config.ph file.
our $BUILD_CONFIGFILE = 'config.ph';

# ##########################################################



sub YES { 1 };
sub NO  { 0 };

$ENV{DEVEL_COVER_OPTIONS} = '-ignore,blib/Class/InsideOut/Policy/Modwheel.pm';

my $configfile = slurp_file($BUILD_CONFIGFILE);

my %BUILD_CONFIG = eval $configfile;

my $builder = Module::Build->new(%BUILD_CONFIG)->create_build_script( );

sub slurp_file {
    my ($filepath) = @_;
    open my $fh, '<', $filepath
        or die "Couldn't open $filepath for reading: $!\n";
    my $contents = do { local $/; <$fh> };
    close $fh
        or die "Couldn't close $filepath after reading: $!\n";
    return $contents;
}

