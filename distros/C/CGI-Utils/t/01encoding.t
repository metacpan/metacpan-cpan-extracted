#!/usr/bin/env perl -w

# Creation date: 2003-08-13 21:01:33
# Authors: Don
# Change log:
# $Id: 01encoding.t,v 1.2 2003/09/21 17:40:02 don Exp $

use strict;
use Carp;

# main
{
    local($SIG{__DIE__}) = sub { &Carp::cluck(); exit 0 };

    use Test;
    BEGIN { plan tests => 5 }

    use CGI::Utils;

    ok(my $utils = CGI::Utils->new);

    my $plain_str = '01 23%45&67;_89';
    my $encoded_str = '01%2023%2545%2667%3b_89';
    ok($utils->urlEncode($plain_str) eq $encoded_str);
    ok($utils->urlDecode($encoded_str) eq $plain_str);

    ok(&test_decode_vars($utils));
    ok(&test_encode_vars($utils));

    
}

exit 0;

###############################################################################
# Subroutines

sub test_encode_vars {
    my ($utils) = @_;
    my $vars = { field1 => 'val1',
                 field2 => [ 'val2', 'val2_3' ],
                 field3 => 'val3',
               };
    my $str = $utils->urlEncodeVars($vars);
    return &test_decode_vars($utils, $str);
}

sub test_decode_vars {
    my ($utils, $query) = @_;
    $query = 'field1=val1;field2=val2;field2=val2_3;field3=val3' unless defined $query;
    my $var_hash = $utils->urlDecodeVars($query);

    my @keys = keys %$var_hash;
    return undef unless scalar(@keys) == 3;

    return undef unless exists($$var_hash{field1}) and exists($$var_hash{field2})
        and exists($$var_hash{field3});

    my $field2 = $$var_hash{field2};
    return undef unless ref($field2) eq 'ARRAY';
    return undef unless $$field2[0] eq 'val2' and $$field2[1] eq 'val2_3';

    return undef unless $$var_hash{field1} eq 'val1';
    return undef unless $$var_hash{field3} eq 'val3';
    
    return 1;
}
