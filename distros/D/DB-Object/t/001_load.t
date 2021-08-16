# -*- perl -*-
BEGIN
{
    use strict;
    use lib './lib';
    use Test::More qw( no_plan );
#     use File::Find;
#     our @modules;
#     File::Find::find(sub
#     {
#         next unless( /\.pm$/ );
#         print( "Checking file '$_' ($File::Find::name)\n" );
#         $_ = $File::Find::name;
#         s,^./lib/,,;
#         s,\.pm$,,;
#         s,/,::,g;
#         push( @modules, $_ );
#     }, qw( ./lib ) );
};

BEGIN
{
#     for( @modules )
#     {
#         diag( "Checking module $_" );
#         use_ok( $_ );
#     }
    use_ok( "DB::Object" );
    use_ok( "DB::Object::Cache::Tables" );
    use_ok( "DB::Object::Fields" );
    use_ok( "DB::Object::Fields::Field" );
    use_ok( "DB::Object::Query" );
    use_ok( "DB::Object::Statement" );
    use_ok( "DB::Object::Tables" );
};

done_testing();

