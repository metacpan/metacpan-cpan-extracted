use Test::More;

use App::Kit;

diag("Testing ns() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();
ok( !exists $INC{'Module/Want.pm'}, 'lazy under pinning not loaded before' );
isa_ok( $app->ns(), 'App::Kit::Obj::NS' );
ok( exists $INC{'Module/Want.pm'}, 'lazy under pinning loaded after' );

########################
#### non-Module::Want ##
########################

# base()
my $class = App::Kit::Obj::NS->new( { base => 'Test::CLASS' } );
is( $class->base, 'Test::CLASS', 'class based is class' );
isa_ok( $app->ns->base, ref $app, 'obj based is object' );

# employ()
{
    no warnings 'redefine';
    my $args_obj;
    my $args_pkg;
    *Role::Tiny::apply_roles_to_object  = sub { $args_obj = \@_ };
    *Role::Tiny::apply_roles_to_package = sub { $args_pkg = \@_ };

    $app->ns->employ( "Foo", "Bar" );
    is_deeply( $args_obj, [ 'Role::Tiny', $app, qw(Foo Bar) ], 'employ() on obj calls apply_roles_to_object()' );

    $class->employ( "Baz", "Wop" );
    is_deeply( $args_pkg, [qw(Role::Tiny Test::CLASS Baz Wop)], 'employ() on clss calls apply_roles_to_package()' );
}

# absorb()
SKIP: {
    eval 'require MIME::Base64';
    skip "Need Mime::Base64 for these tests", 3 if $@;
    $app->ns->absorb('MIME::Base64::encode_base64');
    ok( $app->can('encode_base64'), 'absorb() obj ok' );
    is( $app->encode_base64("foo"), MIME::Base64::encode_base64("foo"), "new method works like its function" );

    $class->absorb('MIME::Base64::decode_base64');
    ok( $class->base->can('decode_base64'), 'absorb() class ok' );
    is( $class->base->decode_base64("Zm9v"), MIME::Base64::decode_base64("Zm9v"), "new method works like its function" );
}

# impose()
# {
#
#     package Foo;
#
#     # do these no()'s to ensure they are off before testing
#     no strict;      ## no critic
#     no warnings;    ## no critic
#
#     $app->ns->impose();
#
#     $@ = undef;     # just in case
#     eval 'print $x;';
#     Test::More::ok( $@, 'impose() no args obj: strict' );
#
#     my $warn = '';
#     local $SIG{__WARN__} = sub {
#         $warn = join( '', @_ );
#     };
#     eval 'print @X[0]';
#     Test::More::ok( $warn, 'impose() no args obj: warnings' );
#
#     Test::More::ok( defined &try,  'impose() no args obj: Try::Tiny' );
#     Test::More::ok( defined &carp, 'impose() no args obj: Carp' );
#
#     package main;
# }

# {
#
#     package Bar;
#
#     # do these no()'s to ensure they are off before testing
#     no strict;      ## no critic
#     no warnings;    ## no critic
#
#     $class->impose();
#
#     $@ = undef;     # just in case
#     eval 'print $x;';
#     Test::More::ok( $@, 'impose() no args class: strict' );
#
#     my $warn = '';
#     local $SIG{__WARN__} = sub {
#         $warn = join( '', @_ );
#     };
#     eval 'print @X[0]';
#     Test::More::ok( $warn, 'impose() no args class: warnings' );
#
#     Test::More::ok( defined &try,  'impose() no args class: Try::Tiny' );
#     Test::More::ok( defined &carp, 'impose() no args class: Carp' );
#
#     package main;
# }
#
# {
#     $app->ns->impose( 'integer', [qw(File::Slurp write_file)] );
#     is( 10 / 3, 3, 'impose() obj: pragma imposed on caller' );
#     ok( defined &write_file, 'impose() obj: module w/ args imposed on caller' );
# }
#
# {
#     $class->impose( 'integer', [qw(File::Slurp read_file)] );
#     is( 10 / 3, 3, 'impose() class: pragma imposed on caller' );
#     ok( defined &read_file, 'impose() class: module w/ args imposed on caller' );
# }

# enable()
ok( !defined &cwd, 'enabled() before not defined' );
$app->ns->enable('Cwd::cwd');
ok( defined &cwd, 'enabled() after is defined' );
is( \&cwd, \&Cwd::cwd, 'enabled correct function' );

ok( !defined &copy, 'enabled() class before not defined' );
$class->enable('File::Copy::copy');
ok( defined &copy, 'enabled() class after is defined' );
is( \&copy, \&File::Copy::copy, 'enabled() class correct function' );

############################
#### Module::Want related ##
############################

ok( $app->ns->is_ns("Foo"),         "is_ns() correctly true" );
ok( !$app->ns->is_ns("Howdy What"), "is_ns() correctly false" );

is_deeply(
    [ $app->ns->normalize_ns(q{Foo::Bar'Baz}) ],
    [ Module::Want::normalize_ns('Foo::Bar::Baz') ],
    'normalize_ns() returns the same as its lazy under pinning'
);

is_deeply(
    [ $app->ns->have_mod('CGI') ],        # Perl::DependList-NO_DEP(CGI)
    [ Module::Want::have_mod('CGI') ],    # Perl::DependList-NO_DEP(CGI)
    'normalize_ns() returns the same as its lazy under pinning'
);

is_deeply(
    [ $app->ns->ns2distname('Foo::Bar::Baz') ],
    [ Module::Want::ns2distname('Foo::Bar::Baz') ],
    'normalize_ns() returns the same as its lazy under pinning'
);

is_deeply(
    [ $app->ns->distname2ns('Foo-Bar-Baz') ],
    [ Module::Want::distname2ns('Foo-Bar-Baz') ],
    'normalize_ns() returns the same as its lazy under pinning'
);

######################
#### File::ShareDir ##
######################

# $app->ns->sharedir
SKIP: {
    skip "That is weird: fake module Foo::Bar exists, skipping non-existent module check", 6 if $app->ns->have_mod('Foo::Bar');

    ok( !exists $INC{'File/ShareDir.pm'}, 'Sanity: File::ShareDir not loaded before sharedir()' );
    is $app->ns->sharedir("Foo-Bar"), undef, 'sharedir() bad dist = undef';
    like $@, qr/Failed to find share dir for dist 'Foo-Bar'/, 'sharedir() bad dist - $@';
    ok( exists $INC{'File/ShareDir.pm'}, 'File::ShareDir lazy loaded on initial sharedir()' );
    is $app->ns->sharedir("Foo::Bar"), undef, 'sharedir() unloaded module = undef';
    like $@, qr/Failed to find share dir for dist 'Foo-Bar'/, 'sharedir() unloaded module - $@';
}

# TODO test dist that does have share dir,  unloaded and loaded
# TODO test module that does have share dir, unloaded and loaded

done_testing;
