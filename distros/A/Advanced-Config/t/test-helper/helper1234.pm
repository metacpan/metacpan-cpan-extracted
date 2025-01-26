##
## Stub module to do common methods used between test cases ...
## So that the t/*.t programs don't get cluttered with these common functions!
##

package helper1234;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Test::More;
use Fred::Fish::DBUG 2.09 qw / on /;
use File::Spec;
use File::Basename;

$VERSION = "1.10";
@ISA = qw( Exporter );

@EXPORT = qw(
              turn_fish_on_off_for_advanced_config 
              print_opts_hash
            );

@EXPORT_OK = qw( );

BEGIN
{
}

END
{
}

# Uses 2 ENV vars so that the meaning of undefined %ENV var can be easily
# changed for deciding what to do with the real %ENV var ...
sub turn_fish_on_off_for_advanced_config
{
   DBUG_ENTER_FUNC(@_);

   # Get the name of the fish file to return ...
   my $fish = $0;
   $fish =~ s/[.]t$//;
   $fish =~ s/[.]pl$//;
   $fish .= ".fish.txt";

   # So default is to use fish if environment variable isn't set!
   my $on = ( $ENV{FISH_OFF_FLAG} ) ? 0 : 1;

   # %ENV var that controls whether this module uses fish or not ...
   my $fish_tag = 'ADVANCED_CONFIG_FISH';

   my $msg;
   if ( $on ) {
      $ENV{$fish_tag} = 1;
      $msg = "Fish has been turned on for Advanced::Config ...";
      $fish = File::Spec->catfile (dirname ($fish), "log_details", basename ($fish));

   } else {
      delete ( $ENV{$fish_tag} );
      $msg = "Fish has been disabled for Advanced::Config ...";
      $fish = File::Spec->catfile (dirname ($fish), "log_summary", basename ($fish));
   }

   DBUG_PRINT ("INFO", "\n%s\n ", $msg);

   DBUG_RETURN ( $fish );
}

# Returns the hash if not empty or undef.
sub print_opts_hash
{
   DBUG_ENTER_FUNC(@_);
   my $lbl  = shift;
   my $opts = shift;

   my $cnt = 0;
   foreach ( sort keys %{$opts} ) {
      DBUG_PRINT ("OPTS", "%s ==> %s", $_, $opts->{$_});
      ++$cnt;
   }

   DBUG_RETURN ( $cnt ? $opts : undef );
}

# ============================================================
#required if module is included w/ require command;
1;

