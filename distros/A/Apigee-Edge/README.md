[![Build Status](https://travis-ci.org/binary-com/perl-Apigee-Edge.svg?branch=master)](https://travis-ci.org/binary-com/perl-Apigee-Edge)
[![codecov](https://codecov.io/gh/binary-com/perl-Apigee-Edge/branch/master/graph/badge.svg)](https://codecov.io/gh/binary-com/perl-Apigee-Edge)
[![Gitter chat](https://badges.gitter.im/binary-com/perl-Apigee-Edge.png)](https://gitter.im/binary-com/perl-Apigee-Edge)

# NAME

Apigee::Edge - Apigee.com 'Edge' management API.

# SYNOPSIS

    use Apigee::Edge;

    my $apigee = Apigee::Edge->new(
      org => 'apigee_org',
      usr => 'your_email',
      pwd => 'your_password'
    );

# DESCRIPTION

Apigee::Edge is an object-oriented interface to facilitate management of Developers and Apps using the Apigee.com 'Edge' management API. see [http://apigee.com/docs/api-services/content/api-reference-getting-started](http://apigee.com/docs/api-services/content/api-reference-getting-started)

The API is incompleted. welcome to fork the repos on github [https://github.com/binary-com/perl-Apigee-Edge](https://github.com/binary-com/perl-Apigee-Edge) and send us pull-requests.

# METHODS

## new

- org

    required. organization name.

- usr

    required. login email

- pwd

    required. login password

- endpoint

    optional. default to https://api.enterprise.apigee.com/v1

## Apps

[http://apigee.com/docs/api/apps-0](http://apigee.com/docs/api/apps-0)

### get\_app

    my $app = $apigee->get_app($app_id);

### get\_apps

    my $app_ids = $apigee->get_apps();
    my $apps = $apigee->get_apps(expand => 'true', includeCred => 'true');

### get\_apps\_by\_family

    my $app_ids = $apigee->get_apps_by_family($family);

### get\_apps\_by\_keystatus

    my $app_ids = $apigee->get_apps_by_keystatus($keystatus);

### get\_apps\_by\_type

    my $app_ids = $apigee->get_apps_by_type($type);

## Developers

[http://apigee.com/docs/api/developers-0](http://apigee.com/docs/api/developers-0)

### get\_developers

    my $developers = $apigee->get_developers();

### get\_app\_developers

    my $developers = $apigee->get_app_developers($app_name);

### get\_developer

    my $developer = $apigee->get_developer('fayland@binary.com') or die $apigee->errstr;

### create\_developer

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

### update\_developer

    my $developer = $apigee->update_developer(
        $developer_email,
        {
            "firstName" => "Fayland",
            "lastName" => "Lam",
        }
    );

### delete\_developer

    my $developer = $apigee->delete_developer('fayland@binary.com') or die $apigee->errstr;

### set\_developer\_status

    my $status = $apigee->set_developer_status($email, $status);

## Apps: Developer

[http://apigee.com/docs/api/apps-developer](http://apigee.com/docs/api/apps-developer)

### change\_app\_status

    my $app = $apigee->change_app_status($developer_email, $app_name);

### create\_developer\_app

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

### delete\_developer\_app

    my $app = $apigee->delete_developer_app($developer_email, $app_name);

### get\_developer\_app

    my $app = $apigee->get_developer_app($developer_email, $app_name);

### get\_developer\_apps

    my $apps = $apigee->get_developer_apps($developer_email);
    my $apps = $apigee->get_developer_apps($developer_email, { expand => 'true' });

### update\_developer\_app

    my $app = $apigee->update_developer_app($developer_email, $app_name, {
        # update part
    });

### regenerate\_developer\_app\_key

    my $app = $apigee->regenerate_developer_app_key($developer_email, $app_name, {
        # update part
    });

### get\_count\_of\_developer\_app\_resource

    my $count = $apigee->get_count_of_developer_app_resource($developer_email, $app_name, $entity_name);

## API Products

[http://apigee.com/docs/api/api-products-1](http://apigee.com/docs/api/api-products-1)

### get\_api\_products

    my $products = $apigee->get_api_products();
    my $products = $apigee->get_api_products(expand => 'true');

### search\_api\_products

    my $products = $apigee->search_api_products('attributename' => 'access', 'attributevalue' => 'public');
    my $products = $apigee->search_api_products('attributename' => 'access', 'attributevalue' => 'private', expand => 'true');

### get\_api\_product

    my $product = $apigee->get_api_product($product_name);

### get\_api\_product\_details

    my $apps = $apigee->get_api_product_details(
        $product_name,
        query => 'list', entity => 'apps' # or query => 'count', entity => 'keys, apps, developers, or companies'
    );

### delete\_api\_product

    my $product = $apigee->delete_api_product($product_name);

### create\_api\_product

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

### update\_api\_product

    my $product = $apigee->update_api_product(
        "test-product-name",
        {
            "approvalType" => "auto",
            "displayName" => "ANOTHER TEST PRODUCT NAME",
        }
    );

## request

The underlaying method to call Apigee when you see something is missing.

    $self->request('GET', "/o/$org_name/apps/$app_id");
    $self->request('DELETE', "/o/$org_name/developers/" . uri_escape($email));
    $self->request('POST', "/o/$org_name/developers", %args);
    $self->request('PUT', "/o/$org_name/developers/" . uri_escape($email), %args);

# GITHUB

[https://github.com/binary-com/perl-Apigee-Edge](https://github.com/binary-com/perl-Apigee-Edge)

# AUTHOR

Binary.com <fayland@binary.com>

# COPYRIGHT

Copyright 2014- Binary.com

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
