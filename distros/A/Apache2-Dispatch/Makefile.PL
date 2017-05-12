package Apache::Dispatch;

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

# make sure we have at least one minimum version of mod_perl
my $bs = eval { Apache::Bootstrap->new({ mod_perl2 => 1.99022,
                                         mod_perl  => 1.30 }) };
do { $! = 255; die($@); } if $@;
##########################################################################


# try mp2 first, but allow builds with mod_perl one
# when MOD_PERL_1_BUILD ENV is set (for maintainers mostly)
my $mp_gen = $bs->satisfy_mp_generation(2);
if (! $ENV{MOD_PERL_1_BUILD} && $mp_gen) {

	warn("building for mp2 since MOD_PERL_1_BUILD not set") if DEBUG;
    push @ARGV, "-apxs $ENV{MP_APXS}" if exists $ENV{MP_APXS};

} elsif ( $mp_gen = $bs->satisfy_mp_generation(1)) {

	warn("building for mp1") if DEBUG;
} else {
	die "no mp generation could be satisfied\n";
}

# check for Apache::Test, $HAS_APACHE_TEST contains version or is undefined
my $HAS_APACHE_TEST = $bs->check_for_apache_test();

# calculate common makefile version vars

my $apache = $bs->apache_major_version;
my $base_lib = "lib/$apache/Dispatch.pm";

# common makefile build options
my %maker_opts = (
    PREREQ_PM     => $bs->mp_prereqs,
    clean         => { FILES => 't/TEST, *.xs*' },
    NAME          => "$apache\::Dispatch",
    VERSION_FROM  => 'lib/Apache/Dispatch/Util.pm',
    ABSTRACT_FROM => $base_lib,
);


if ( $mp_gen == 1 ) {

    # Build directives using xs or PerlSetVar
    my %makefile_params = ();

    eval {
        require Apache::ExtUtils;
        require Apache::src;
    };

    if ( $@ || $ENV{DISPATCH_PUREPERL} ) {
        print
"Building without Custom Apache Directives, use 'PerlSetVar' for configuration.\n\n";
        $makefile_params{'PL_FILES'} = { 'set_pureperl.PL' => '1' };
        $makefile_params{'C'} = [];

    }
    else {
        print "Building with Custom Apache Directives ('DispatchPrefix'). You 
will need a C compiler and Apache/mod_perl sources.\n\n";

        $makefile_params{'PL_FILES'} = { 'set_pureperl.PL' => '0' };

        import Apache::ExtUtils qw(command_table);
        use lib 'lib';
        require Apache::Dispatch::Util;
        my @directives = Apache::Dispatch::Util->directives();
        command_table( \@directives );

        my $inc = Apache::src->new->inc;
        die "Can't find mod_perl header files installed" unless $inc;
        $makefile_params{'INC'} = $inc;
    }

    %maker_opts = ( %maker_opts, %makefile_params );

}

$bs->WriteMakefile( %maker_opts );

pop @ARGV if $ENV{MOD_PERL_1_BUILD};

package MY;

sub postamble {
    my $self = shift;

    my $string = $self->SUPER::postamble;

    $string .= <<'EOF';
tag :
	svn copy https://apache-dispatch.svn.sourceforge.net/svnroot/apache-dispatch/trunk https://apache-dispatch.svn.sourceforge.net/svnroot/apache-dispatch/tags/$(VERSION_SYM)
	@echo update lib/Apache/Dispatch.pm VERSION now
EOF

    return $string;
}

sub test {
    my $self = shift;

    eval { require Test::More } or return <<EOF;
test::
\t\@echo sorry, cannot run tests without Test::More
EOF

    return $self->Apache::TestMM::test(@_) if $HAS_APACHE_TEST;

    return <<EOF
test::
\t\@echo
\t\@echo sorry, cannot run tests without a properly
\t\@echo configured Apache-Test environment
\t\@echo
EOF
}

sub clean {
    my $self = shift;

    return $self->Apache::TestMM::clean(@_) if $HAS_APACHE_TEST;

    return $self->SUPER::clean(@_);
}
