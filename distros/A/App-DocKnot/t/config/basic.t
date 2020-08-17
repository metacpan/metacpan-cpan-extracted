#!/usr/bin/perl
#
# Tests for the App::DocKnot::Config module API.
#
# Copyright 2019-2020 Russ Allbery <rra@cpan.org>
#
# SPDX-License-Identifier: MIT

use 5.024;
use autodie;
use warnings;

use File::ShareDir qw(module_file);
use File::Spec;
use JSON::MaybeXS qw(JSON);
use Perl6::Slurp;

use Test::More tests => 7;

# Load the modules.
BEGIN { use_ok('App::DocKnot::Config') }

# Root of the test data.
my $dataroot = File::Spec->catfile('t', 'data', 'generate');

# Load a test configuration and check a few inobvious pieces of it.
my $metadata_path = File::Spec->catfile($dataroot, 'ansicolor', 'metadata');
my $config        = App::DocKnot::Config->new({ metadata => $metadata_path });
isa_ok($config, 'App::DocKnot::Config');
my $data_ref = $config->config();
is($data_ref->{build}{install}, 1, 'build/install defaults to 1');
my $blurb_path = File::Spec->catfile($metadata_path, 'blurb');
is($data_ref->{blurb}, slurp($blurb_path), 'blurb contains file contents');
my $notices_path = File::Spec->catfile($metadata_path, 'notices');
is($data_ref->{license}{notices},
    slurp($notices_path), 'license/notices loaded');
my $quote_path = File::Spec->catfile($metadata_path, 'quote');
is($data_ref->{quote}{text}, slurp($quote_path), 'quote/text loaded');

# Check that the license data is expanded correctly.
my $json = JSON->new;
$json->relaxed;
my $license_path      = module_file('App::DocKnot', 'licenses.json');
my $license_data      = $json->decode(scalar(slurp($license_path)));
my $perl_license_data = $license_data->{Perl};
my $full_license_path
  = module_file('App::DocKnot', File::Spec->catfile('licenses', 'Perl'));
$perl_license_data->{full} = slurp($full_license_path);
delete($data_ref->{license}{notices});
is_deeply($data_ref->{license}, $perl_license_data,
    'license data loaded properly');
