#!/usr/local/bin/perl
use Test::More tests=>1;
use Test::Differences;

$ENV{HARNESS_PERL_SWITCHES} = "" unless defined $ENV{HARNESS_PERL_SWITCHES};

@output = `$^X $ENV{HARNESS_PERL_SWITCHES} -Iblib/lib bin/simple_scan -gen -define release=beta <examples/cross_product.in`;
@expected = map {"$_\n"} split /\n/,<<EOF;
use Test::More tests=>6;
use Test::WWW::Simple;
use strict;

mech->agent_alias('Windows IE 6');
page_like "http://able.beta.server.yahoo.com",
          qr/Copyright &copy; 2006/,
          qq(Will cross-product able [http://able.beta.server.yahoo.com] [/Copyright &copy; 2006/ should match]);
page_like "http://dog.beta.server.yahoo.com",
          qr/Copyright &copy; 2006/,
          qq(Will cross-product dog [http://dog.beta.server.yahoo.com] [/Copyright &copy; 2006/ should match]);
page_like "http://fox.beta.server.yahoo.com",
          qr/Copyright &copy; 2006/,
          qq(Will cross-product fox [http://fox.beta.server.yahoo.com] [/Copyright &copy; 2006/ should match]);
page_like "http://able.beta.server.yahoo.com",
          qr/Copyright &copy; 2006/,
          qq(Won't cross-product able [http://able.beta.server.yahoo.com] [/Copyright &copy; 2006/ should match]);
page_like "http://dog.beta.server.yahoo.com",
          qr/Copyright &copy; 2006/,
          qq(Won't cross-product dog [http://dog.beta.server.yahoo.com] [/Copyright &copy; 2006/ should match]);
page_like "http://fox.beta.server.yahoo.com",
          qr/Copyright &copy; 2006/,
          qq(Won't cross-product fox [http://fox.beta.server.yahoo.com] [/Copyright &copy; 2006/ should match]);
EOF
push @expected, "\n";
eq_or_diff(\@output, \@expected, "working output as expected");
