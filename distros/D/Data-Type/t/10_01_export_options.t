use Test::More qw(no_plan);

use_ok( 'Data::Type', qw(<t::> +DB +Bio +Perl +Perl6) );

ok( t::STD::BOOL, 't::STD::BOOL exported');

ok( t::DB::VARCHAR, 't::DB::VARCHAR exported');

ok( t::BIO::DNA, 't::STD::DNA exported');
