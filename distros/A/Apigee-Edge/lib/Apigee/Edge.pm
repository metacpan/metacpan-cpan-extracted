package Apigee::Edge;

use strict;
use warnings;
our $VERSION = '0.08';

use Carp;
use Mojo::UserAgent;
use Mojo::URL;
use Mojo::Util qw(b64_encode);
use URI::Escape qw/uri_escape/;

use vars qw/$errstr/;
sub errstr { return $errstr }

sub new {    ## no critic (ArgUnpacking)
    my $class = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;

    for (qw/org usr pwd/) {
        $args{$_} || croak "Param $_ is required.";
    }

    $args{endpoint} ||= 'https://api.enterprise.apigee.com/v1';
    $args{timeout}  ||= 60;                                       # for ua timeout

    return bless \%args, $class;
}

sub __ua {
    my $self = shift;

    return $self->{ua} if exists $self->{ua};

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(3);
    $ua->inactivity_timeout($self->{timeout});
    $ua->proxy->detect;    # env proxy
    $ua->cookie_jar(0);
    $ua->max_connections(100);
    $self->{ua} = $ua;

    return $ua;
}

## Apps http://apigee.com/docs/api/apps-0
sub get_app {
    my ($self, $app_id) = @_;
    return $self->request('GET', "/o/" . $self->{org} . "/apps/$app_id");
}

sub get_apps_by_family {
    my ($self, $family) = @_;
    return $self->request('GET', "/o/" . $self->{org} . "/apps?appfamily=" . uri_escape($family));
}

sub get_apps_by_keystatus {
    my ($self, $keystatus) = @_;
    return $self->request('GET', "/o/" . $self->{org} . "/apps?keyStatus=" . uri_escape($keystatus));
}

sub get_apps_by_type {
    my ($self, $type) = @_;
    return $self->request('GET', "/o/" . $self->{org} . "/apps?apptype=" . uri_escape($type));
}

sub get_apps {    ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    my $url  = Mojo::URL->new("/o/" . $self->{org} . "/apps");
    $url->query(\%args) if %args;
    return $self->request('GET', $url->to_string);
}

## Developers http://apigee.com/docs/api/developers-0
sub create_developer {
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    return $self->request('POST', "/o/" . $self->{org} . "/developers", %args);
}

sub get_developer {
    my $self = shift;
    my ($email) = @_;
    return $self->request('GET', "/o/" . $self->{org} . "/developers/" . uri_escape($email));
}

sub delete_developer {
    my $self = shift;
    my ($email) = @_;
    return $self->request('DELETE', "/o/" . $self->{org} . "/developers/" . uri_escape($email));
}

sub get_app_developers {
    my $self = shift;
    my ($app) = @_;
    return $self->request('GET', "/o/" . $self->{org} . "/developers?app=" . uri_escape($app));
}

sub get_developers {
    my $self = shift;
    return $self->request('GET', "/o/" . $self->{org} . "/developers");
}

sub set_developer_status {
    my ($self, $email, $status);
    return $self->request('GET', "/o/" . $self->{org} . "/developers/" . uri_escape($email) . "?action=" . uri_escape($status));
}

sub update_developer {    ## no critic (ArgUnpacking)
    my $self  = shift;
    my $email = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;
    $email or croak "email is required.";
    return $self->request('PUT', "/o/" . $self->{org} . "/developers/" . uri_escape($email), %args);
}

## Apps: Developer http://apigee.com/docs/api/apps-developer
sub change_app_status {
    my ($self, $email, $app) = @_;
    return $self->request('GET', "/o/" . $self->{org} . "/developers/" . uri_escape($email) . "/apps/" . uri_escape($app));
}

sub create_developer_app {    ## no critic (ArgUnpacking)
    my $self  = shift;
    my $email = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;
    return $self->request('POST', "/o/" . $self->{org} . "/developers/" . uri_escape($email) . "/apps", %args);
}

sub delete_developer_app {
    my ($self, $email, $app) = @_;
    return $self->request('DELETE', "/o/" . $self->{org} . "/developers/" . uri_escape($email) . "/apps/" . uri_escape($app));
}

sub get_developer_app {
    my ($self, $email, $app) = @_;
    return $self->request('GET', "/o/" . $self->{org} . "/developers/" . uri_escape($email) . "/apps/" . uri_escape($app));
}

sub get_developer_apps {    ## no critic (ArgUnpacking)
    my $self  = shift;
    my $email = shift;
    $email or croak "email is required.";

    my %args = @_ % 2 ? %{$_[0]} : @_;
    my $url = Mojo::URL->new("/o/" . $self->{org} . "/developers/" . uri_escape($email) . "/apps");
    $url->query(\%args) if %args;
    return $self->request('GET', $url->to_string);
}

sub update_developer_app {    ## no critic (ArgUnpacking)
    my $self  = shift;
    my $email = shift;
    my $app   = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;
    $email or croak "email is required.";
    $app   or croak "app is required.";
    return $self->request('PUT', "/o/" . $self->{org} . "/developers/" . uri_escape($email) . "/apps/" . uri_escape($app), %args);
}

sub get_count_of_developer_app_resource {
    my ($self, $email, $app, $entity) = @_;
    return $self->request('GET',
              "/o/"
            . $self->{org}
            . "/developers/"
            . uri_escape($email)
            . "/apps/"
            . uri_escape($app)
            . qq~?"query=count&entity=~
            . uri_escape($entity)
            . qq~"~);
}

sub regenerate_developer_app_key {    ## no critic (ArgUnpacking)
    my $self  = shift;
    my $email = shift;
    my $app   = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;
    $email or croak "email is required.";
    $app   or croak "app is required.";
    return $self->request('POST', "/o/" . $self->{org} . "/developers/" . uri_escape($email) . "/apps/" . uri_escape($app), %args);
}

## API Products http://apigee.com/docs/api/api-products-1
sub create_api_product {              ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    return $self->request('POST', "/o/" . $self->{org} . "/apiproducts", %args);
}

sub update_api_product {              ## no critic (ArgUnpacking)
    my $self    = shift;
    my $product = shift;
    my %args    = @_ % 2 ? %{$_[0]} : @_;
    $product or croak "product is required.";
    return $self->request('PUT', "/o/" . $self->{org} . "/apiproducts/" . uri_escape($product), %args);
}

sub delete_api_product {
    my ($self, $product) = @_;
    return $self->request('DELETE', "/o/" . $self->{org} . "/apiproducts/" . uri_escape($product));
}

sub get_api_product {
    my ($self, $product) = @_;
    return $self->request('GET', "/o/" . $self->{org} . "/apiproducts/" . uri_escape($product));
}

sub get_api_products {    ## no critic (ArgUnpacking)
    my $self = shift;
    my %args = @_ % 2 ? %{$_[0]} : @_;
    my $url  = Mojo::URL->new("/o/" . $self->{org} . "/apiproducts");
    $url->query(\%args) if %args;
    return $self->request('GET', $url->to_string);
}

sub search_api_products {
    return (shift)->get_api_products(@_);
}

sub get_api_product_details {    ## no critic (ArgUnpacking)
    my $self    = shift;
    my $product = shift;
    my %args    = @_ % 2 ? %{$_[0]} : @_;
    my $url     = Mojo::URL->new("/o/" . $self->{org} . "/apiproducts/" . uri_escape($product));
    $url->query(\%args) if %args;
    return $self->request('GET', $url->to_string);
}

sub request {
    my ($self, $method, $url, %params) = @_;

    $errstr = '';                # reset

    my $ua = $self->__ua;
    my $header = {Authorization => 'Basic ' . b64_encode($self->{usr} . ':' . $self->{pwd}, '')};
    $header->{'Content-Type'} = 'application/json' if %params;
    my @extra = %params ? (json => \%params) : ();
    my $tx = $ua->build_tx($method => $self->{endpoint} . $url => $header => @extra);
    $tx->req->headers->accept('application/json');

    $tx = $ua->start($tx);
    if ($tx->res->headers->content_type and $tx->res->headers->content_type =~ 'application/json') {
        return $tx->res->json;
    }
    if (!$tx->success) {
        $errstr = "Failed to fetch $url: " . $tx->error->{message};
        return;
    }

    $errstr = "Unknown Response.";
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

Apigee::Edge - Apigee.com 'Edge' management API.

=head1 SYNOPSIS

  use Apigee::Edge;

  my $apigee = Apigee::Edge->new(
    org => 'apigee_org',
    usr => 'your_email',
    pwd => 'your_password'
  );

=head1 DESCRIPTION

Apigee::Edge is an object-oriented interface to facilitate management of Developers and Apps using the Apigee.com 'Edge' management API. see L<http://apigee.com/docs/api-services/content/api-reference-getting-started>

The API is incompleted. welcome to fork the repos on github L<https://github.com/binary-com/perl-Apigee-Edge> and send us pull-requests.

=head1 METHODS

=head2 new

=over 4

=item * org

required. organization name.

=item * usr

required. login email

=item * pwd

required. login password

=item * endpoint

optional. default to https://api.enterprise.apigee.com/v1

=back

=head2 Apps

L<http://apigee.com/docs/api/apps-0>

=head3 get_app

    my $app = $apigee->get_app($app_id);

=head3 get_apps

    my $app_ids = $apigee->get_apps();
    my $apps = $apigee->get_apps(expand => 'true', includeCred => 'true');

=head3 get_apps_by_family

    my $app_ids = $apigee->get_apps_by_family($family);

=head3 get_apps_by_keystatus

    my $app_ids = $apigee->get_apps_by_keystatus($keystatus);

=head3 get_apps_by_type

    my $app_ids = $apigee->get_apps_by_type($type);

=head2 Developers

L<http://apigee.com/docs/api/developers-0>

=head3 get_developers

    my $developers = $apigee->get_developers();

=head3 get_app_developers

    my $developers = $apigee->get_app_developers($app_name);

=head3 get_developer

    my $developer = $apigee->get_developer('fayland@binary.com') or die $apigee->errstr;

=head3 create_developer

    my $developer = $apigee->create_developer(
        "email" => 'fayland@binary.com',
        "firstName" => "Fayland",
        "lastName" => "Lam",
        "userName" => "fayland.binary",
        "attributes" => [
            {
                "name" => "Attr1",
                "value" => "V1"
            },
            {
                "name" => "A2",
                "value" => "V2.v2"
            }
        ]
    );

=head3 update_developer

    my $developer = $apigee->update_developer(
        $developer_email,
        {
            "firstName" => "Fayland",
            "lastName" => "Lam",
        }
    );

=head3 delete_developer

    my $developer = $apigee->delete_developer('fayland@binary.com') or die $apigee->errstr;

=head3 set_developer_status

    my $status = $apigee->set_developer_status($email, $status);

=head2 Apps: Developer

L<http://apigee.com/docs/api/apps-developer>

=head3 change_app_status

    my $app = $apigee->change_app_status($developer_email, $app_name);

=head3 create_developer_app

    my $app = $apigee->create_developer_app(
        $developer_email,
        {
            "name" => "Test App",
            "apiProducts" => [ "{apiproduct1}", "{apiproduct2}", ...],
            "keyExpiresIn" => "{milliseconds}",
            "attributes" => [
                {
                    "name" => "DisplayName",
                    "value" => "{display_name_value}"
                },
                {
                    "name" => "Notes",
                    "value" => "{notes_for_developer_app}"
                },
                {
                    "name" => "{custom_attribute_name}",
                    "value" => "{custom_attribute_value}"
                }
            ],
            "callbackUrl" => "{url}",
        }
    );

=head3 delete_developer_app

    my $app = $apigee->delete_developer_app($developer_email, $app_name);

=head3 get_developer_app

    my $app = $apigee->get_developer_app($developer_email, $app_name);

=head3 get_developer_apps

    my $apps = $apigee->get_developer_apps($developer_email);
    my $apps = $apigee->get_developer_apps($developer_email, { expand => 'true' });

=head3 update_developer_app

    my $app = $apigee->update_developer_app($developer_email, $app_name, {
        # update part
    });

=head3 regenerate_developer_app_key

    my $app = $apigee->regenerate_developer_app_key($developer_email, $app_name, {
        # update part
    });

=head3 get_count_of_developer_app_resource

    my $count = $apigee->get_count_of_developer_app_resource($developer_email, $app_name, $entity_name);

=head2 API Products

L<http://apigee.com/docs/api/api-products-1>

=head3 get_api_products

    my $products = $apigee->get_api_products();
    my $products = $apigee->get_api_products(expand => 'true');

=head3 search_api_products

    my $products = $apigee->search_api_products('attributename' => 'access', 'attributevalue' => 'public');
    my $products = $apigee->search_api_products('attributename' => 'access', 'attributevalue' => 'private', expand => 'true');

=head3 get_api_product

    my $product = $apigee->get_api_product($product_name);

=head3 get_api_product_details

    my $apps = $apigee->get_api_product_details(
        $product_name,
        query => 'list', entity => 'apps' # or query => 'count', entity => 'keys, apps, developers, or companies'
    );

=head3 delete_api_product

    my $product = $apigee->delete_api_product($product_name);

=head3 create_api_product

    my $product = $apigee->create_api_product(
        "approvalType" => "manual",
        "attributes" => [
            {
              "name" => "access",
              "value" => "private"
            },
            {
              "name" => "ATTR2",
              "value" => "V2"
            }
        ],
        "description" => "DESC",
        "displayName" => "TEST PRODUCT NAME",
        "name"  => "test-product-name",
        "apiResources" => [ "/resource1", "/resource2"],
        "environments" => [ "test", "prod"],
        # "proxies" => ["{proxy1}", "{proxy2}", ...],
        # "quota" => "{quota}",
        # "quotaInterval" => "{quota_interval}",
        # "quotaTimeUnit" => "{quota_unit}",
        "scopes" => ["user", "repos"]
    );

=head3 update_api_product

    my $product = $apigee->update_api_product(
        "test-product-name",
        {
            "approvalType" => "auto",
            "displayName" => "ANOTHER TEST PRODUCT NAME",
        }
    );

=head2 request

The underlaying method to call Apigee when you see something is missing.

    $self->request('GET', "/o/$org_name/apps/$app_id");
    $self->request('DELETE', "/o/$org_name/developers/" . uri_escape($email));
    $self->request('POST', "/o/$org_name/developers", %args);
    $self->request('PUT', "/o/$org_name/developers/" . uri_escape($email), %args);

=head2 errstr

=head1 GITHUB

L<https://github.com/binary-com/perl-Apigee-Edge>

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Binary.com

=head1 SEE ALSO

=cut
