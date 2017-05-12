#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

# Autoflush ON
local $| = 1;

####################
# LOAD DIST MODULES
####################
use Config::Properties::Commons;

# use Data::Printer;

####################
# RUN TESTS
####################

# Init object
my $cpc = Config::Properties::Commons->new();

# Test option aliases
my $got_options = $cpc->_set_options(
    delimiter      => ';',
    include        => 'my_include',
    basepath       => '/foo',
    includes_allow => 1,
    cache          => 1,
    interpolate    => 0,
    force_arrayref => 1,
    validate       => sub { },
    filename       => 'props',
    single_line    => 0,
    wrap           => 0,
    columns        => 72,
    separator      => ':',
    header         => '# My Header',
    footer         => '# My Footer',
);

# p $got_options;

# Remove values that are 'known' subroutine references
foreach (qw(callback save_sorter)) {
  next unless exists $got_options->{$_};
    if ( ref $got_options->{$_} eq 'CODE' ) {
        delete $got_options->{$_};
    }
} ## end foreach (qw(callback save_sorter))

my $expected_options = {
    cache_files          => 1,
    defaults             => {},
    force_value_arrayref => 1,
    include_keyword      => "my_include",
    includes_basepath    => '/foo',
    interpolation        => 0,
    load_file            => 'props',
    process_includes     => 1,
    save_combine_tokens  => 0,
    save_footer          => "# My Footer",
    save_header          => "# My Header",
    save_separator       => ":",
    save_wrapped         => 0,
    save_wrapped_len     => 72,
    token_delimiter      => ";"
};

cmp_deeply( $got_options, $expected_options, 'Option Aliasing' );

####################
# DONE
####################
done_testing();
exit 0;
