package Daje::Plugin::Authorities::Helpers;
use Mojo::Base -base, -signatures;
use v5.42;

# NAME
# ====
#
# Daje::Plugin::Authorities::Helpers - Model class
#
# SYNOPSIS
# ========
#
#       use Daje::Plugin::Authorities::Helpers;
#
#       my $class = Daje::Plugin::Authorities::Helpers->new();
#       $app->helper(
#           v_authorities_function_plugin_role_permission => sub {
#               state  $v_authorities_function_plugin_role_permission = Daje::Database::Model::vAuthoritiesFunctionPluginRolePermission->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_license => sub {
#               state  $v_authorities_license = Daje::Database::Model::vAuthoritiesLicense->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_plugin => sub {
#               state  $v_authorities_plugin = Daje::Database::Model::vAuthoritiesPlugin->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_function => sub {
#               state  $v_authorities_function = Daje::Database::Model::vAuthoritiesFunction->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_permissions => sub {
#               state  $v_authorities_permissions = Daje::Database::Model::vAuthoritiesPermissions->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_function_permissions => sub {
#               state  $v_authorities_function_permissions = Daje::Database::Model::vAuthoritiesFunctionPermissions->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_license_plugin => sub {
#               state  $v_authorities_license_plugin = Daje::Database::Model::vAuthoritiesLicensePlugin->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_license_function => sub {
#               state  $v_authorities_license_function = Daje::Database::Model::vAuthoritiesLicenseFunction->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_role => sub {
#               state  $v_authorities_role = Daje::Database::Model::vAuthoritiesRole->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_plugin_role => sub {
#               state  $v_authorities_plugin_role = Daje::Database::Model::vAuthoritiesPluginRole->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_function_plugin_role => sub {
#               state  $v_authorities_function_plugin_role = Daje::Database::Model::vAuthoritiesFunctionPluginRole->new(db => shift->pg->db)
#        });#
#       $app->helper(
#           v_authorities_function_plugin_role_permission_list => sub {
#               state  $v_authorities_function_plugin_role_permission_list = Daje::Database::Model::vAuthoritiesFunctionPluginRolePermissionList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_license_list => sub {
#               state  $v_authorities_license_list = Daje::Database::Model::vAuthoritiesLicenseList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_plugin_list => sub {
#               state  $v_authorities_plugin_list = Daje::Database::Model::vAuthoritiesPluginList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_function_list => sub {
#               state  $v_authorities_function_list = Daje::Database::Model::vAuthoritiesFunctionList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_permissions_list => sub {
#               state  $v_authorities_permissions_list = Daje::Database::Model::vAuthoritiesPermissionsList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_function_permissions_list => sub {
#               state  $v_authorities_function_permissions_list = Daje::Database::Model::vAuthoritiesFunctionPermissionsList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_license_plugin_list => sub {
#               state  $v_authorities_license_plugin_list = Daje::Database::Model::vAuthoritiesLicensePluginList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_license_function_list => sub {
#               state  $v_authorities_license_function_list = Daje::Database::Model::vAuthoritiesLicenseFunctionList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_role_list => sub {
#               state  $v_authorities_role_list = Daje::Database::Model::vAuthoritiesRoleList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_plugin_role_list => sub {
#               state  $v_authorities_plugin_role_list = Daje::Database::Model::vAuthoritiesPluginRoleList->new(db => shift->pg->db)
#        });
#       $app->helper(
#           v_authorities_function_plugin_role_list => sub {
#               state  $v_authorities_function_plugin_role_list = Daje::Database::Model::vAuthoritiesFunctionPluginRoleList->new(db => shift->pg->db)
#        });#
# DESCRIPTION
# ===========
#
# Daje::Plugin::Authorities::Helpers is the standard routes
#
# METHODS
# =======
#
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.com
#

# This file is generated automatically by Daje Tools 2026-03-01 05:33:53.
# It will be re-generated by Daje Tools again.
# <!-- Autogenerated file 2026-03-01 05:33:53 -->

use Daje::Database::View::vAuthoritiesFunctionPluginRolePermission;
use Daje::Database::View::vAuthoritiesLicense;
use Daje::Database::View::vAuthoritiesPlugin;
use Daje::Database::View::vAuthoritiesFunction;
use Daje::Database::View::vAuthoritiesPermissions;
use Daje::Database::View::vAuthoritiesFunctionPermissions;
use Daje::Database::View::vAuthoritiesLicensePlugin;
use Daje::Database::View::vAuthoritiesLicenseFunction;
use Daje::Database::View::vAuthoritiesRole;
use Daje::Database::View::vAuthoritiesPluginRole;
use Daje::Database::View::vAuthoritiesFunctionPluginRole;# Lists
use Daje::Database::View::vAuthoritiesFunctionPluginRolePermissionList;
use Daje::Database::View::vAuthoritiesLicenseList;
use Daje::Database::View::vAuthoritiesPluginList;
use Daje::Database::View::vAuthoritiesFunctionList;
use Daje::Database::View::vAuthoritiesPermissionsList;
use Daje::Database::View::vAuthoritiesFunctionPermissionsList;
use Daje::Database::View::vAuthoritiesLicensePluginList;
use Daje::Database::View::vAuthoritiesLicenseFunctionList;
use Daje::Database::View::vAuthoritiesRoleList;
use Daje::Database::View::vAuthoritiesPluginRoleList;
use Daje::Database::View::vAuthoritiesFunctionPluginRoleList;

our $VERSION = '0.01';

sub helpers($self, $app, $config) {

    $app->helper(
        v_authorities_function_plugin_role_permission => sub {
            state  $v_authorities_function_plugin_role_permission = Daje::Database::View::vAuthoritiesFunctionPluginRolePermission->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_license => sub {
            state  $v_authorities_license = Daje::Database::View::vAuthoritiesLicense->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_plugin => sub {
            state  $v_authorities_plugin = Daje::Database::View::vAuthoritiesPlugin->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_function => sub {
            state  $v_authorities_function = Daje::Database::View::vAuthoritiesFunction->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_permissions => sub {
            state  $v_authorities_permissions = Daje::Database::View::vAuthoritiesPermissions->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_function_permissions => sub {
            state  $v_authorities_function_permissions = Daje::Database::View::vAuthoritiesFunctionPermissions->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_license_plugin => sub {
            state  $v_authorities_license_plugin = Daje::Database::View::vAuthoritiesLicensePlugin->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_license_function => sub {
            state  $v_authorities_license_function = Daje::Database::View::vAuthoritiesLicenseFunction->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_role => sub {
            state  $v_authorities_role = Daje::Database::View::vAuthoritiesRole->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_plugin_role => sub {
            state  $v_authorities_plugin_role = Daje::Database::View::vAuthoritiesPluginRole->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_function_plugin_role => sub {
            state  $v_authorities_function_plugin_role = Daje::Database::View::vAuthoritiesFunctionPluginRole->new(db => shift->pg->db)
        });    # Lists
    $app->helper(
        v_authorities_function_plugin_role_permission_list => sub {
            state  $v_authorities_function_plugin_role_permission_list = Daje::Database::View::vAuthoritiesFunctionPluginRolePermissionList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_license_list => sub {
            state  $v_authorities_license_list = Daje::Database::View::vAuthoritiesLicenseList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_plugin_list => sub {
            state  $v_authorities_plugin_list = Daje::Database::View::vAuthoritiesPluginList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_function_list => sub {
            state  $v_authorities_function_list = Daje::Database::View::vAuthoritiesFunctionList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_permissions_list => sub {
            state  $v_authorities_permissions_list = Daje::Database::View::vAuthoritiesPermissionsList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_function_permissions_list => sub {
            state  $v_authorities_function_permissions_list = Daje::Database::View::vAuthoritiesFunctionPermissionsList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_license_plugin_list => sub {
            state  $v_authorities_license_plugin_list = Daje::Database::View::vAuthoritiesLicensePluginList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_license_function_list => sub {
            state  $v_authorities_license_function_list = Daje::Database::View::vAuthoritiesLicenseFunctionList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_role_list => sub {
            state  $v_authorities_role_list = Daje::Database::View::vAuthoritiesRoleList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_plugin_role_list => sub {
            state  $v_authorities_plugin_role_list = Daje::Database::View::vAuthoritiesPluginRoleList->new(db => shift->pg->db)
        });
    $app->helper(
        v_authorities_function_plugin_role_list => sub {
            state  $v_authorities_function_plugin_role_list = Daje::Database::View::vAuthoritiesFunctionPluginRoleList->new(db => shift->pg->db)
        });}

1;



