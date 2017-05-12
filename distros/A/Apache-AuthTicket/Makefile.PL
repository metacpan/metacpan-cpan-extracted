use ExtUtils::MakeMaker;
use lib qw(t/lib);
use My::Util qw(mod_perl_version);

require 5.6.0;

my @CLEAN_FILES = ();
my $mp_version = mod_perl_version();
test_configure();

my %conf = (
    NAME          => 'Apache::AuthTicket',
    VERSION_FROM  => 'lib/Apache/AuthTicket.pm',
    PREREQ_PM     => {
        'Apache::Test'          => 1.35,
        'CGI'                   => 3.12,
        'Class::Accessor::Fast' => 0,
        'DBI'                   => 0,
        'Digest::MD5'           => 0,
        'MIME::Base64'          => 0,
        'ModPerl::VersionUtil'  => 0,
        'MRO::Compat'           => 0,
        'SQL::Abstract'         => 0,
        'Storable'              => 0,
        'Test::More'            => 0
    },
    clean         => {
        FILES => \@CLEAN_FILES
    }
);

if ($mp_version == 2) {
    # MP2 deps
    $conf{PREREQ_PM}{'mod_perl2'} = '1.9922';  # 2.0 RC5 (Apache -> Apache2)
    $conf{PREREQ_PM}{'Apache2::AuthCookie'} = '3.0';
}
else {
    # MP1 deps
    $conf{PREREQ_PM}{'mod_perl'} = '1.27';
    $conf{PREREQ_PM}{'Apache::AuthCookie'} = '3.0';
}

if (MM->can('signature_target')) {
    $conf{SIGN} = 1;
}

if ($ExtUtils::MakeMaker::VERSION >= 6.48) {
    $conf{META_MERGE} = {
        no_index => { directory => [qw(t)] },
    };
}

WriteMakefile(%conf);

sub test_configure {
    if (eval { require Apache::TestMM }) {
        # enable make test
        Apache::TestMM->import(qw(test clean));

        Apache::TestMM::filter_args;

        Apache::TestMM::generate_script('t/TEST');

        push @CLEAN_FILES, 't/TEST';
    }
    else {
        # overload test rule with a no-op
        warn "***: You should install Apache::Test to do real testing\n";
        *MY::test = \&skip_no_apache_test;
    }

    unless (eval { require DBD::SQLite }) {
        warn "***: You should install DBD::SQLite to do real testing\n";
    }
}

sub skip_no_apache_test {
    return <<'EOF';
test::
	@echo \*** This test suite requires Apache::Test available from CPAN
EOF
}

# :vim set ts=4 sw=4 ai et
