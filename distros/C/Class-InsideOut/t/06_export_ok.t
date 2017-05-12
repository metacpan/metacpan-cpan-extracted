use strict;
use lib ".";
use Test::More;

my @export_std = qw(
        id
        private
        public
        register
    );
    
my @export_rest = qw(
        options
        property
    );
    
my @additional = qw(
      DESTROY
      STORABLE_freeze
      STORABLE_thaw
    );
    
my @all_methods = ( @export_std, @export_rest, @additional );

plan tests =>   3 + @all_methods                # export_ok tests
            +   3 + @export_std + @additional   # :std tests
            +   3 + @all_methods                # :all tests
            ;

$|++; # keep stdout and stderr in order on Win32

#--------------------------------------------------------------------------#

package export_ok_test;
use Test::More;

pass( "setting package to 'export_ok_test'" );

require_ok( 'Class::InsideOut' );

Class::InsideOut->import( @export_std, @export_rest );

pass( "Importing all \@EXPORT_OK functions" );

can_ok( 'export_ok_test', $_ ) for (@export_std, @export_rest, @additional);

#--------------------------------------------------------------------------#

package export_tags_std_test;
use Test::More;

pass( "setting package to 'export_tags_std_test'" );

require_ok( 'Class::InsideOut' );

Class::InsideOut->import( ":std" );

pass( "Importing ':std' tag" );

can_ok( 'export_tags_std_test', $_ ) for (@export_std, @additional);


#--------------------------------------------------------------------------#

package export_tags_all_test;
use Test::More;

pass( "setting package to 'export_tags_all_test'" );

require_ok( 'Class::InsideOut' );

Class::InsideOut->import( ":all" );

pass( "Importing ':all' tag" );

can_ok( 'export_tags_all_test', $_ ) for (@all_methods);

