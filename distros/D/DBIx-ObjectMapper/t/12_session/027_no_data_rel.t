use strict;
use warnings;
use Test::More;

use FindBin;
use File::Spec::Functions qw(catfile);
use lib catfile($FindBin::Bin, 'lib');
use MyTest11;

MyTest11->mapping_with_foreign_key;
my $mapper = MyTest11->mapper;
$mapper->metadata->t('artist')->insert(name => 'test')->execute;

{
    my $session = $mapper->begin_session;
    ok my $artist = $session->get( 'MyTest11::Artist' => 1 );

    is_deeply $artist->cds, [];
    is_deeply $artist->cds, [];

    is $session->uow->{query_cnt}, 2;
};

done_testing;
