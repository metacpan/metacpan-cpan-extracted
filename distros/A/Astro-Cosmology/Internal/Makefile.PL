# -*- perl -*-
#

# we do nothing if PDL does not exist
eval "use PDL::Core::Dev;";
return 1 if $@;

use ExtUtils::MakeMaker;
use Cwd;

$package = [ 'internal.pd', Internal, Astro::Cosmology::Internal ];

%hash = pdlpp_stdargs( $package );

# note we take the version number from the top-level package
$hash{VERSION_FROM} = '../Cosmology.pm';

# what code do we want compiled and linked in?
$hash{OBJECT} .= join( "", map { " $_\$(OBJ_EXT)"; } qw( romberg utils ) );
#
#@wanted = qw( romberg utils );
#for $file ( @wanted ) {
#    $hash{OBJECT} .= " $file\$(OBJ_EXT)";
#}

push @{ $hash{LIBS} }, "-lm";

WriteMakefile( %hash );

sub MY::postamble {
    pdlpp_postamble($package);
}
