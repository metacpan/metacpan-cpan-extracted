use Test::More;
use Test::Exception;

use App::Kit::Util::RW;    # must be loaded before App::Kit is use()d
use App::Kit;

my $app = App::Kit->new;

my @roles = (
    [ 'Locale' => { isa => 'Locale::Maketext::Utils::Mock::en' } ],
    [ 'HTTP'   => { isa => 'HTTP::Tiny' } ],
    [ 'NS'     => { isa => 'App::Kit::Obj::NS' } ],
    [ 'FS'     => { isa => 'App::Kit::Obj::FS' } ],
    [ 'Str'    => { isa => 'App::Kit::Obj::Str' } ],
    [ 'CType'  => { isa => 'App::Kit::Obj::CType' } ],
    [ 'Detect' => { isa => 'App::Kit::Obj::Detect' } ],
    [ 'DB'     => { isa => 'App::Kit::Obj::DB' } ],
    [ 'Log'    => { isa => 'Log::Dispatch' } ],
);

for my $role_ar (@roles) {
    my $role    = $role_ar->[0];
    my $role_hr = $role_ar->[1];

    my $has = lc($role);
    ok( !exists $app->{$has}, "Devel-Kit_RW '$has' does not exist before it is called" );
    is( ref $app->$has(), $role_hr->{'isa'}, "Devel-Kit_RW '$has' returns the expected object" );
    ok( exists $app->{$has}, "Devel-Kit_RW '$has' exists after it is called" );

    my $org = $app->$has();
    is( ref $app->$has( bless {}, 'Foo' ), 'Foo', "Devel-Kit_RW '$has' can be set, returns new obj" );
    is( ref $app->$has(), 'Foo', "Devel-Kit_RW '$has' subsequently returns the new object" );
    $app->$has($org);
}

done_testing;
