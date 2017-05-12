#!/usr/bin/perl

use warnings;
use strict;
use Test::More;

sub make_inc_hook
{
    return sub {
        my (undef, $modfile) = @_;

        return 0 unless ( $modfile =~ m{\ATemplate} );

        my $done;
        $modfile =~ s{.pm\z}{};
        $modfile =~ s{/}{::}g;

        return sub {
            return 0 if $done;
            $_ = qq{package $modfile; 0;};
            return $done = 1;
        }
    };
}

BEGIN {
    unshift @INC, make_inc_hook();

    # The ::Test class is under out test directory.
    use lib qw(t/lib);
    use_ok( 'CPANPLUS::Dist::Arch::Test' );
}

my $cda_obj = CPANPLUS::Dist::Arch::Test->new( name => 'CDA-Template', version => '0.01' );

# Test our builtin template engine.  Make sure [%- and -%] works...
is $cda_obj->get_tt_module, 0,
    'We are using our internal template engine.';

sub istt
{
    my ($templ, $txt, $test) = @_;
    $cda_obj->set_pkgbuild_templ($templ);
    is $cda_obj->get_pkgbuild, $txt, $test;
}

istt '[%- pkgname -%]', 'perl-cda-template',
    q{[%-'s and -%]'s work with our internal template engine};

istt '[% pkgname %]', 'perl-cda-template',
    q{[%'s and %]'s work with our internal template engine};

istt 'A[% foobar %]Z', 'AZ',
    q{undefined template vars expand to empty strings};

# TEST WHITESPACE
##############################################################################

my @ws_tests;
push @ws_tests, <<'END_TEMPL', "GOOD\n\n";
[% IF pkgname -%]
GOOD[% END %]

END_TEMPL

push @ws_tests, <<'END_TEMPL', "GOOD";
[% IF pkgname -%]
GOOD[% END -%]

END_TEMPL

push @ws_tests, <<'END_TEMPL', "GOOD\n\n";
[% IF pkgname -%]GOOD
[% END %]
END_TEMPL

my $count = 1;
while( my ($templ, $result) = splice @ws_tests, 0, 2 ) {
    $cda_obj->set_pkgbuild_templ( $templ );
    is $cda_obj->get_pkgbuild(), $result;
}

# TEST IF BLOCKS

istt '[% IF undefined_var %]foobar[% END %]', q{},
    'Undefined vars evaluate to false in if tests';

done_testing;
