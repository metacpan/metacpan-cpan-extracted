package Curio::Role::GitLab::API::v4;
our $VERSION = '0.01';

use GitLab::API::v4;
use Types::Common::String qw( NonEmptySimpleStr );
use Types::Standard qw( InstanceOf );

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Curio::Role';
with 'MooX::BuildArgs';

after initialize => sub{
    my ($class) = @_;

    my $factory = $class->factory();

    $factory->does_caching( 1 );
    $factory->key_argument( 'connection_key' );

    return;
};

has connection_key => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    required => 1,
);

has api => (
    is  => 'lazy',
    isa => InstanceOf[ 'GitLab::API::v4' ],
);

sub _build_api {
    my ($self) = @_;

    my $args = {};

    if ($self->can('access_token')) {
        my $token = $self->access_token();
        $args->{access_token} = $token if defined $token;
    }

    if ($self->can('private_token')) {
        my $token = $self->private_token();
        $args->{private_token} = $token if defined $token;
    }

    %$args = (
        %$args,
        %{ $self->build_args() },
    );

    $self->clear_build_args();

    delete $args->{connection_key};

    my $api = GitLab::API::v4->new( $args );

    return $api;
}

1;
__END__

=encoding utf8

=head1 NAME

Curio::Role::GitLab::API::v4 - Build Curio classes around GitLab::API::v4.

=head1 SYNOPSIS

Create your Curio class:

    package MyApp::Service::GitLab;
    
    use Curio role => '::GitLab::API::v4';
    use strictures 2;
    
    use Exporter qw( import );
    our @EXPORT = qw( myapp_gitlab );
    
    add_key 'anonymous';
    add_key 'bot-wiki-updater';
    add_key 'bot-user-manager';
    
    default_key 'anonymous';
    
    default_arguments (
        url => 'https://git.example.com/api/v4',
    );
    
    sub private_token {
        my ($self) = @_;
        return undef if $self->connection_key() eq 'anonymous';
        return get_secret_somehow(
            'gitlab-token-' . $self->connection_key(),
        );
    }
    
    sub myapp_gitlab {
        return __PACKAGE__->fetch( @_ )->api();
    }
    
    1;

Then use your new Curio class elsewhere:

    use MyApp::Service::GitLab;
    
    my $api = myapp_gitlab('bot-user-manager');

=head1 DESCRIPTION

This role provides all the basics for building a Curio class
which wraps around L<GitLab::API::v4>.

=head1 ATTRIBUTES

=head2 connection_key

    my $key = MyApp::Service::GitLab
              ->fetch('bot-user-manager')
              ->connection_key();

The C<connection_key> holds the Curio key.  So, in the example above
it would return C<bot-user-manager>.  This attribute's primary purpose
is to facilitate the writing of token methods as shown in L</TOKENS>.

=head2 api

    my $api = MyApp::Service::GitLab
              ->fetch('bot-user-manager')
              ->api();

Holds the L<GitLab::API::v4> object.

=head1 TOKENS

In your Curio class you may create two methods, C<access_token> and
C<private_token>.  If either/both of these methods exist and return a
defined value then they will be used when constructing the L</api>
object.

In the L</SYNOPSIS> a sample C<private_token> method is shown:

    sub private_token {
        my ($self) = @_;
        return undef if $self->connection_key() eq 'anonymous';
        return get_secret_somehow(
            'gitlab-token-' . $self->connection_key(),
        );
    }

The C<get_secret_somehow> call is expected to be the place where
you use whatever tool you use to hold your GitLab tokens and likely
all passwords and other credentials (secrets) that your application
needs.

Some common tools that people use to manage their secrets are
Kubernetes' secrets objects, AWS's Secret Manager, HashiCorp's Vault,
or just an inescure configuration file; to name a few.

So, the way you write your token methods is going to be unique to
your setup.

=head1 CACHING

This role sets the L<Curio::Factory/does_caching> feature.

You can of course disable this.

    does_caching 0;

=head1 SUPPORT

Please submit bugs and feature requests to the
Curio-Role-GitLab-API-v4 GitHub issue tracker:

L<https://github.com/bluefeet/Curio-Role-GitLab-API-v4/issues>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 AUTHORS

    Aran Clary Deltac <aran@bluefeet.dev>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 Aran Clary Deltac

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut

