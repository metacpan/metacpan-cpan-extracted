package Role::Deploy;

=head1 NAME

Role::Deploy

=cut

BEGIN {
    use Cwd;
    $ENV{DANCER_APPDIR} = Cwd::abs_path('t');
}

use Test::Exception;
use Test::More;
use Test::WWW::Mechanize::PSGI;

use Dancer qw/load_app set setting/;

use Test::Roo::Role;

=head1 ATTRIBUTES

=head2 mech

An instance of L<Test::WWW::Mechanize::PSGI> connected to the C<TestApp>.

=cut

has mech => (
    is      => 'ro',
    default => sub {
        Test::WWW::Mechanize::PSGI->new(
            app => sub {
                my $env = shift;
                load_app 'TestApp';
                my $request = Dancer::Request->new( env => $env );
                Dancer->dance($request);
            }
        );
    },
);

=head2 trap

defaults to C<< Dancer::Logger::Capture->trap >>

=cut

has trap => (
    is => 'ro',
    default =>
      sub { require Dancer::Logger::Capture; Dancer::Logger::Capture->trap },
);

test 'deploy tests' => sub {
    my $self = shift;

    diag "Role::Deploy";

    setting('plugins')->{DBIC} = {
        default => {
            schema_class => $self->schema_class,
            connect_info => [ $self->connect_info ],
        },
        shop2 => {
            schema_class => $self->schema_class,
            connect_info => [ $self->connect_info ],
        }
    };
    my $schema = $self->ic6s_schema;

    set session => 'DBIC';
    set session_options => { schema => $schema, };

    # deploy magically happens in here:
    lives_ok { $self->load_all_fixtures } "load all fixtures";

    cmp_ok( $self->attributes->count, '>=', 4, "at least 4 attributes" );
    cmp_ok( $self->countries->count, '>=', 250, "at least 250 countries" );
    cmp_ok( $self->price_modifiers->count,
        '>=', 15, "at least 15 price_modifiers" );
    cmp_ok( $self->roles->count, '>=', 5, "at least 5 roles" );
    cmp_ok( $self->states->count, '>=', 64, "at least 64 states" );
    cmp_ok( $self->taxes->count, '>=', 37, "at least 37 Tax rates" );
    cmp_ok( $self->users->count, '>=', 5, "at least 5 users" );
    cmp_ok( $self->zones->count, '>=', 317, "at least 317 zones" );

};

1;
