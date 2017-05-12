use ExtUtils::MakeMaker;

my @CLEAN_FILES = ();
my $mp_version = mod_perl_version();

#test_configure();


my %makeconf = (
		NAME	  			=> "Apache::Upload::Slurp",
	  VERSION_FROM 	=> "Slurp.pm",
	 	PREREQ_PM     => {
	 	                   'Apache' 			=> 0,
											 'Test::More'		=> 0,
                     },
	      ($] >= 5.005 ?
	       (
		ABSTRACT   => "Component to slurp all uploaded file via Apache",
		AUTHOR	   => "Emiliano Bruni <info\@ebruni.it>") : ()),
		clean      => {
											FILES => "@CLEAN_FILES"
									},
);

if ($mp_version == 2) {
    # 1.9922 is 2.0.0 RC5. mod_perl package renames happend at this release.
    $makeconf{PREREQ_PM}{mod_perl2} = '1.9922';
    $makeconf{PREREQ_PM}{CGI} = '3.12';
}

WriteMakefile(%makeconf);

# inspired by Apache::Peek 1.01
sub test_configure {
    if (eval { require Apache::TestMM }) {
        # enable "make test"
        Apache::TestMM->import(qw(test clean));

        # accept configs from command line.
        Apache::TestMM::filter_args();

        Apache::TestMM::generate_script('t/TEST');

        push @CLEAN_FILES, 't/TEST';
    }
    else {
        # overload test rule with a no-op
        warn "***: You should install Apache::Test to do real testing\n";
        *MY::test = sub {
            return <<'EOF';
test : pure_all
	@echo \*** This test suite requires Apache::Test available from CPAN
EOF
        }
    }
}

sub mod_perl_version {
    eval {
        require mod_perl
    };
    unless ($@) {
        if ($mod_perl::VERSION >= 1.99) {
            # mod_perl 2 prior to RC5 (1.99_21 or earlier)
            die "mod_perl 2.0.0 RC5 or later is required for this module";
        }

        return 1;
    }

    eval {
        require mod_perl2;
    };
    unless ($@) {
				# mod_perl2 not supported
    		die "mod_perl version $mod_perl::VERSION is not supported\n";
        #return 2;
    }

    die "mod_perl version $mod_perl::VERSION is not supported\n";
}
