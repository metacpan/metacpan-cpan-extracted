use strict;

BEGIN { chdir 't' if -d 't' }
### add ../lib to the path
BEGIN { use File::Spec;
        use lib 'inc';
        use lib File::Spec->catdir(qw[.. lib]);
}        
BEGIN { require 'conf.pl' }

my $map = {
    MM      => [qw|xs noxs|],
    Build   => [qw|xs noxs|],
};    

### run only one particular combination
if( @ARGV ) {
    my @parts = split '/', $ARGV[0];
    $map = {};
    $map->{ $parts[0] } = [ $parts[1] ];
}    

### create a debian dist using EU::MM and no XS files
{   for my $type ( keys %$map ) {
        for my $dir ( @{ $map->{$type} } ) {

            diag("Taking care of $type / $dir");

            my $mod     = $FAKEMOD->clone;
            my $name    = $mod->module;
            my $distdir = File::Spec->rel2abs(
                            File::Spec->catdir( 'src', $type, $dir )
                          );
            
            ### point it to your dummy dir
            $mod->status->extract( File::Spec->catdir(  $distdir,
                                                        $mod->package_name ) );
            
            ### to avoid refetching
            $mod->status->fetch( File::Spec->catfile(   $distdir,
                                                        $mod->package ) );
           
            ### skip tests to avoid testcounter mismatch warnings
            my $rv = $mod->install( format      => $CLASS,
                                    target      => 'create',
                                    skiptest    => 1 );
                    
            ok( $rv,                        "$CLASS package created" );
            
            my $dist = $mod->status->dist;
            ok( $dist,                      "Dist object retrieved" );
            isa_ok( $dist,                  $CLASS );
           
            ### check out the file
            my $par = $dist->status->dist;
            ok( $par,                       "   PAR written to '$par'" );
            ok( -e $par,                    "       File exists " );
            ok( -s $par,                    "       File has size" );
            like( $par, '/'. $mod->package_name .'/',
                                            "       Conatains package name" );
            like( $par, '/'. $mod->package_version .'/',
                                            "       Contains package version" );

            1 while unlink $par;
            
            ok( ! -e $par,                  "   File Removed" );
        }            
    }
}
