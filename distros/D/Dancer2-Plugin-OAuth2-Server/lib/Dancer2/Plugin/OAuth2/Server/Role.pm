package Dancer2::Plugin::OAuth2::Server::Role;
use Moo::Role;

requires 'login_resource_owner';
requires 'confirm_by_resource_owner';
requires 'verify_client';
requires 'store_auth_code';
requires 'generate_token';
requires 'verify_auth_code';
requires 'store_access_token';
requires 'verify_access_token';

1;
