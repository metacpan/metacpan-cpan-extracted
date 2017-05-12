#!perl
use Test::Most;

use lib qw(t/lib);
use ZapziTestDatabase;

use App::Zapzi;
use App::Zapzi::Folders qw(get_folder add_folder delete_folder folders_summary);

test_can();

my ($test_dir, $app) = ZapziTestDatabase::get_test_app();

test_get();
test_add();
test_delete();
test_summary();

done_testing();

sub test_can
{
    can_ok( 'App::Zapzi::Folders', qw(get_folder add_folder delete_folder) );
}

sub test_get
{
    my $inbox = get_folder("Inbox");
    ok( $inbox, 'Can read Inbox folder' );
    is( $inbox->id, 100, 'Inbox ID is 100' );

    my $false_folder = get_folder('This folder does not exist');
    ok( ! $false_folder, 'Can detect folders that do not exist' );
}

sub test_add
{
    add_folder("Foo");
    my $foo = get_folder("Foo");
    ok( $foo, 'Can add folders' );

    eval { add_folder('Foo') };
    like( $@, qr/Could not add/, 'Detect adding existing folder' );

    eval { add_folder() };
    like( $@, qr/not provided/, 'Detect adding empty folder' );
}

sub test_delete
{
    ok( delete_folder("Nonesuch"), 'Will ignore non-existing folders' );

    ok( delete_folder("Foo"), 'Can delete folder'  );
    my $foo = get_folder("Foo");
    ok( ! $foo, 'Deletion works' );
}

sub test_summary
{
    my $summary = folders_summary();
    ok( $summary, 'Can get folder summary' );
    is( $summary->{Inbox}, 1, 'Inbox contains one article' );
}
