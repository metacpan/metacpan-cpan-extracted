#!/usr/bin/env perl

use Test2::V0;
use Config::AWS;

is [ sort keys %Config::AWS:: ], [qw(
    BEGIN
    EXPORT
    EXPORT_OK
    EXPORT_TAGS
    ISA
    VERSION
    __ANON__
    _exporter_permitted_regexp
    _exporter_validate_opts
    config_file
    credentials_file
    default_profile
    import
    list_profiles
    read
    read_all
    read_file
    read_handle
    read_string
)] => 'No unexpected methods in namespace';

done_testing;
