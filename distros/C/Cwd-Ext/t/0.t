use Test::Simple 'no_plan';
use strict;
use lib './lib';


use warnings;
use Cwd::Ext ':all'; #qw(abs_path_nd abs_path_is_in abs_path_is_in_nd);
use Cwd;
#$Cwd::Ext::DEBUG = 1;
use constant DEBUG => 1;

print STDERR " - $0 started\n" if DEBUG;

ok(1);

#ok( cwd(),'cwd is imported'); how do i get this to work


for( 
 cwd().'/t/a',
 cwd().'/t/a/b',
 cwd().'/t/a/b/c', 
){

   mkdir $_;

   ok(-d $_);

}


ok( abs_path_is_in( './t/a', './t' ));
ok( abs_path_is_in( './t/a/b', './t/a' ));
ok( abs_path_is_in( './t/a/b/c', './t/a/b' ));

ok( abs_path_is_in( './t/a/b/c', './t' ));
ok( abs_path_is_in( './t/a/b', './t' ));

ok( ! abs_path_is_in( './t', './t/a' ));
ok( ! abs_path_is_in( './t/a', './t/a/b' ));
ok( ! abs_path_is_in( './t/a/b', './t/a/b/c' ));




mkdir cwd().'/t/Clients';
mkdir cwd().'/t/Clients/The Heights School';
mkdir cwd().'/t/Clients/The Heights School/Vendors';

ok ( abs_path_nd('./t/Clients/The Heights School/Vendors'), 'normalized funnypath') or die("cant normalize funyn path");


# 

ok( abs_path_matches_into('/home/myself/childthing','/home/myself') );


if( symlinks_supported() ){

   symlink( cwd().'/t/a', cwd().'/t/_a');

   ok( -l cwd().'/t/_a') or die('bad symlink?');

   open(FI,'>',cwd().'/t/_a/junk.txt') or die($!);
   print FI 'content' or die($!);
   close FI or die($!);

   my $nd = abs_path_nd('./t/a/../_a/junk.txt');
   ok( 
      $nd
         eq cwd().'/t/_a/junk.txt', "nd[$nd] eq cwd/t/_a/junk.txt"
   );

   ok( 
      Cwd::abs_path( cwd().'/t/_a/b' ) eq cwd().'/t/a/b'  
   ); 

   ok( 
      abs_path_nd( cwd().'/t/_a/b' ) eq cwd().'/t/_a/b'  
   );
    
   ok(abs_path_nd( cwd().'/t/a/../_a/b' ) eq cwd().'/t/_a/b');  
        

}

else {
   warn('symlinks not supported, skipping some tests');
}






print STDERR " - $0 ended\n" if DEBUG;




