#!/usr/bin/env perl

use strict;
use warnings;

use constant DEBUG => $ENV{AB_DEBUG} || 0;

#########################################################################
# minimum version of A::B required
my $ab = 0.07;
eval { require Apache::Bootstrap };
do { $! = 255; die "Please install Apache::Bootstrap $ab"; } if $@;

if ($Apache::Bootstrap::VERSION < $ab) {
    $! = 255;
    die "Apache::Bootstrap $ab required, found " . $Apache::Bootstrap::VERSION;
}

my $bs = eval { Apache::Bootstrap->new({ mod_perl2 => 1.99022 }) };

do { $! = 255; die($@); } if $@;
##########################################################################


# try mp2 first, but allow builds with mod_perl one
# when MOD_PERL_1_BUILD ENV is set (for maintainers mostly)
my $mp_gen = $bs->satisfy_mp_generation(2);
if (! $mp_gen) {

    $! = 255;
    die "mod_perl2 needed to build Apache2::Connection::SkipDummy";
}

# check for Apache::Test, $HAS_APACHE_TEST contains version or is undefined
my $HAS_APACHE_TEST = $bs->check_for_apache_test();

my %maker_opts = (
    PREREQ_PM     => $bs->mp_prereqs,
    clean         => { FILES => 't/TEST' },
    NAME          => "Apache2::Connection::SkipDummy",
    VERSION_FROM  => 'lib/Apache2/Connection/SkipDummy.pm',
    ABSTRACT_FROM => 'lib/Apache2/Connection/SkipDummy.pm',
);

$bs->WriteMakefile( %maker_opts );

package MY;

sub test {
    my $self = shift;

    eval { require Test::More } or return <<EOF;
test::
\t\@echo sorry, cannot run tests without Test::More
EOF

    unless ($HAS_APACHE_TEST) {

        return <<EOF
test::
\t\@echo
\t\@echo sorry, cannot run tests without a properly
\t\@echo configured Apache-Test environment
\t\@echo
EOF
    }

    return $self->Apache::TestMM::test(@_);
}

sub clean {
    my $self = shift;

    return $self->Apache::TestMM::clean(@_) if $HAS_APACHE_TEST;

    return $self->SUPER::clean(@_);
}

1;
