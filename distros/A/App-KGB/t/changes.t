use Test::More;
eval 'use Test::CPAN::Changes; 1'
    or do { diag($@); plan skip_all => 'Test::CPAN::Changes not available'; };

use App::KGB;
changes_file_ok( 'Changes', { version => $App::KGB::VERSION } );

done_testing;
