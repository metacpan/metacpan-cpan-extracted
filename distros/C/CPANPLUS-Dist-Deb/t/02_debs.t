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
            my $deb = $dist->status->dist;
            ok( $deb,                       "   Deb written to '$deb'" );
            ok( -e $deb,                    "       File exists " );
            ok( -s $deb,                    "       File has size" );
           
            ### check the --info on the file
            {   my $out = join '', `$DPKG --info $deb`;
                ok( $out,                   "   Deb --info retrieved" );
                like( $out, qr/Package: $CPANDEB/,
                                            "       Package: ok" );   
                like( $out, qr/Section: perl/,
                                            "       Section: ok" );
                like( $out, qr/Provides: $DEBMOD/,
                                            "       Provides: ok" );
                unlike( $out, qr/Replaces: $DEBMOD/,
                                            "       Replaces: not mentioned" );
                like( $out, qr/Description: $name/,
                                            "       Description: ok" );
                like( $out, qr/Maintainer: \S+/,
                                            "       Maintainer: ok" );
            }
            
            ### check out the --contents on the file
            {   my $out = join '', `$DPKG --contents $deb`;
                my ($need,$omit) = @{$CONTENTS->{$dir}};
                
                ok( $out,                   "   Deb --contents retrieved" );

                for my $entry ( @$need ) {
                    my $re = qr/.$entry$/m;
                    like( $out, $re,        "       Contains $entry" );
                }
                for my $entry ( @$omit ) {
                    my $re = qr/$entry$/m;
                    unlike( $out, $re,      "       Doesn't contain $entry" );
                }
            }
           
            ### install tests
            SKIP: {
                my ($need) = @{$CONTENTS->{$dir}};
                my $to_skip = 3 + 2 * scalar @$need;
                
                skip "Can not (un)install -- no superuser privileges", 
                    $to_skip if ($> and not 
                                 $CB->configure_object->get_program('sudo')); 
            
                ok( $dist->install,         "   Dist installed" );
            
                my $out = join '', `$DPKG -L $CPANDEB`;
                ok( $out,                   "       Deb files retrieved" );
            
                ### check out if all got installed ok
                for my $entry ( @$need ) {
                    ok( -e $entry,          "       File $entry installed" );                
                }

                ok( $dist->uninstall,       "   Dist uninstalled" );
                
                ### check out if all got removed ok
                for my $entry ( @$need ) {
                    ok( !-e $entry,         "       File $entry uninstalled");                
                }
                
            }
           
            {   my $files = $dist->status->files;
                ok( $files,                 "   Files for this package" );
                is( scalar(@$files), 5,     "       All Files found" );
                
                for ( @$files ) {
                    ok( -e $_,              "       File '$_' exists" );
                    1 while unlink $_;
                    ok( !-e $_,             "       File '$_' removed" );
                }
            }
            
            ### check out the naming
            like( $deb, qr/$DEBMOD/,        "   Deb is called '$DEBMOD'" );
            
            if( $dir eq 'xs' ) {
                my $arch = DEB_ARCHITECTURE->()->();
                like( $deb, qr/$arch/,      "       Arch dependant ($arch)" );
            } else {     
                like( $deb, qr/all/,        "       Is platform independant");
            }

            ### checking some constants that require dist objects and the like 
            {   ### output path 
                my $path = DEB_DISTDIR->()->( $dist, 'x-' );
                is( $path, 'main/pool/x-lib/f/cpan-libfoo-bar-perl',
                                            "Output path constructed OK" );
            }

            ### see if we can write some package files
            {   if ( $DO_META ) {
                    ok( $DO_META,           "Testing meta files" );
            
                    for my $type (qw[sources packages]) {
                        my $loc = $dist->write_meta_files( type => $type );
            
                        ok( $loc,           "File '$loc' written" );
                        ok( -e $loc,        "   File exists" );
                        ok( -s $loc,        "   File has size" );
                        
                        ### st00pit vms
                        1 while unlink $loc;
                        
                        ok( !-e $loc,       "   File got deleted" );  
                    }
                }
            }
        }    
    }
}
