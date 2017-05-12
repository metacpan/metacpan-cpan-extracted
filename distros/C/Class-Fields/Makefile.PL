#!/usr/bin/perl

use ExtUtils::MakeMaker;

require 5.005;

$PACKAGE = 'Class::Fields';
($PACKAGE_FILE) = $PACKAGE =~ /::([^:]+)/;
$LAST_API_CHANGE = 0;

eval "require $PACKAGE";

unless ($@) { # Make sure we did find the module.
    print <<"CHANGE_WARN" if ${$PACKAGE.'::VERSION'} < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

CHANGE_WARN
}

{
    package MY;
    sub test_via_harness {
        my($self, $orig_perl, $tests) = @_;

        my @perls = ($orig_perl);
        push @perls, qw(perl5.8.0 bleadperl) 
          if $ENV{PERL_TEST_ALL};

        my $out;
        foreach my $perl (@perls) {
            $out .= $self->SUPER::test_via_harness($perl, $tests);
        }

        return $out;
    }
}


my $mm_ver = $ExtUtils::MakeMaker::VERSION;
WriteMakefile(
    NAME                => $PACKAGE,

    VERSION_FROM        => 'lib/Class/Fields.pm',
    ABSTRACT_FROM       => "lib/Class/Fields.pm",
    AUTHOR              => 'Michael G Schwern <schwern@pobox.com>',

    PREREQ_PM           => { Carp               => 0,
                             constant           => 0,
                             'Carp::Assert'     => 0,
                             base               => 2.0,
                             'Test::More'       => 0.47,
                           },
    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),
);
