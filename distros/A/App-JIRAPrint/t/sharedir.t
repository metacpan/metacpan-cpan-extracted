#! perl -w

use Test::More;

use App::JIRAPrint;

{
    my $j = App::JIRAPrint->new({ config_files => [ 't/config1.conf' ,  't/config2.conf' ] });
    ok( -d $j->shared_directory() );
    ok( -e $j->template_file() );
}


done_testing();

