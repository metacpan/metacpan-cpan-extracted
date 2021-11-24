use ExtUtils::MakeMaker;
use 5.010;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'          => 'CAD::Mesh3D',
    'AUTHOR'        => 'Peter C. Jones <petercj AT cpan.org>',
    'VERSION_FROM'  => 'lib/CAD/Mesh3D.pm',
    'ABSTRACT_FROM' => 'lib/CAD/Mesh3D.pm',
    'PREREQ_PM'     => {
        'Math::Vector::Real'    => 0.18,
        'Exporter'              => 5.57,    # needed for `use Exporter qw(import);` notation
        'warnings'              => 0,
        'strict'                => 0,
        'Carp'                  => 0,
        'CAD::Format::STL'      => v0.2.1,
    },
    'realclean'     => {
        FILES => 'cover_db LICENSE.pod README.pod MYMETA.json.lock lib/CAD/Format',
    },
    'META_MERGE'    => {            # EUMM 6.46
        'meta-spec' => {
            version => '2',
            url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        },
        resources => {
            bugtracker => {
                mailto  => 'bug-CAD-Mesh3D@rt.cpan.org',
                web     => 'https://github.com/pryrt/CAD-Mesh3D/issues',
            },
            repository => {
                url     => 'https://github.com/pryrt/CAD-Mesh3D.git',
                web     => 'https://github.com/pryrt/CAD-Mesh3D',
                type    => 'git',
            },
        },
        keywords => [ '3D', 'CAD', 'STL'],
        no_index => {
            directory   => [ 'patch' ], # don't include packages in patch/ in the indexer report
        },
        provides => {
            'CAD::Mesh3D' => { file => 'lib/CAD/Mesh3D.pm' },
            'CAD::Mesh3D::STL' => { file => 'lib/CAD/Mesh3D/STL.pm' },
        },
    },
    'LICENSE' => 'perl_5',          # EUMM 6.31
    'MIN_PERL_VERSION' => '5.10.0', # EUMM 6.48
    'CONFIGURE_REQUIRES' => {       # EUMM 6.52
        'ExtUtils::MakeMaker' => 0,
        'warnings' => 0,
        'strict' => 0,
        'Test::More' => 0.86,
        'Test::Exception' => 0,
        'constant' => 0,
        'Config' => 0,
    },
    'TEST_REQUIRES' => {            # EUMM 6.64
        'warnings' => 0,
        'strict' => 0,
        'Test::More' => 0.86,
        'Test::Exception' => 0,
        'constant' => 0,
        'Config' => 0,
    },
);

{
    # in most cases, delete from %mm_args rather than adding to the hash like I used to do
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION < '6.46' ) {
        delete $mm_args{META_MERGE};
    } else {
        # automatically determine the versions for 'provides'; MM->parse_version exists as of MM v6.31, so not a problem with >= 6.46
        my $v = ''.MM->parse_version( $mm_args{VERSION_FROM} );
        for my $k ( keys %{ $mm_args{META_MERGE}{provides} }) {
            $mm_args{META_MERGE}{provides}{$k}{version} = $v;
        };
    }

    # simple deletions
    if( $ExtUtils::MakeMaker::VERSION < '6.31' ) {
        delete $mm_args{LICENSE};
    }
    if( $ExtUtils::MakeMaker::VERSION < '6.48' ) {
        delete $mm_args{MIN_PERL_VERSION};
    }

    # merge TEST_REQUIRES into CONFIGURE_REQUIRES, or both into PREREQ_PM
    if( $ExtUtils::MakeMaker::VERSION < '6.52' ) {
        $mm_args{PREREQ_PM} = {
            $mm_args{TEST_REQUIRES},
            $mm_args{CONFIGURE_REQUIRES},
            $mm_args{PREREQ_PM},
        };            # merge TEST and CONFIG into PREREQ
        delete $mm_args{CONFIGURE_REQUIRES};
        delete $mm_args{TEST_REQUIRES};
    } elsif( $ExtUtils::MakeMaker::VERSION < '6.64' ) {
        $mm_args{CONFIGURE_REQUIRES} = {
            $mm_args{TEST_REQUIRES},
            $mm_args{CONFIGURE_REQUIRES},
        } if exists $mm_args{CONFIGURE_REQUIRES};   # merge TEST into CONFIG
        delete $mm_args{TEST_REQUIRES};
    }

    # sign distro if able
    if( $ExtUtils::MakeMaker::VERSION >= '6.18' ) {
        $mm_args{SIGN} = 1 if MM->can('signature_target') && $ENV{MM_SIGN_DIST};
    }
}

sub MY::postamble {
    my (undef,%h) = @_;
    return <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

MY_COPYRIGHT = Copyright (C) 2017,2018,2019,2020,2021 Peter C. Jones

testcover :: lib/CAD/Mesh3D.pm
	$(NOECHO) cover -test -report html

windebug ::
	$(NOECHO) for %f in ( t\*.t ) do $(NOECHO) (echo %f & perl %f & echo ----------)

# run author-tests on the original
authtest ::
	$(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# run author-tests on the distribution
distauthtest :: disttest
	cd $(DISTVNAME) && $(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

#coverclean :: realclean
# moved "realclean ::" into the realclean=> element of the %mm_args hash
#realclean ::
#	$(NOECHO) ( $(TEST_D) cover_db && $(RM_RF) cover_db ) || $(ECHO) realclean:: skip "rm -rf cover_db"
#	$(NOECHO) ( $(TEST_F) MYMETA.json.lock && $(RM_RF) MYMETA.json.lock ) || $(ECHO) realclean:: skip "rm -rf MYMETA.json.lock"
#	$(NOECHO) ( $(TEST_D) lib/CAD/Format && $(RM_RF) lib/CAD/Format ) || $(ECHO) realclean:: skip "rm -rf lib/CAD/Format"

# auto-populate the VERSION in the submodules from $(VERSION), which comes from main module
populateversion :: lib/CAD/Mesh3D.pm
	$(NOECHO) $(ECHO) want to auto-populate VERSION in all sub-modules: $(VERSION)
	$(PERL) -pi -e "s/^(\s*our\s+.VERSION\s*=).*?;.*?$$/\1 '$(VERSION)'; # auto-populated from CAD::Mesh3D/" lib/CAD/Mesh3D/STL.pm

# auto-populate COPYRIGHT line
populatecopyright ::
	$(NOECHO) $(ECHO) want to auto-populate COPYRIGHT
	$(PERL) -pi -e "s/^\QCopyright (C)\E.*$$/$(MY_COPYRIGHT)/" lib/CAD/Mesh3D.pm lib/CAD/Mesh3D/STL.pm lib/CAD/Mesh3D/ProvideNewFormat.pod

# auto-generate the README from the lib/CAD/Mesh3D.pm
README.md :: lib/CAD/Mesh3D.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(README.pod));$$p->select({head1 => [qq(NAME),qq(SYNOPSIS),qq(DESCRIPTION),qq(TODO),qq(AUTHOR),qq(COPYRIGHT),qq(LICENSE)]});$$p->parse_file(qq(lib/CAD/Mesh3D.pm));'
	pod2markdown README.pod README.md
	$(RM_F) README.pod

# auto-generate the LICENSE file from the lib/Math/PRBS.pm
LICENSE :: lib/CAD/Mesh3D.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(LICENSE.pod));$$p->select({head1 => [qw/AUTHOR COPYRIGHT LICENSE/]});$$p->parse_file(qq(lib/CAD/Mesh3D.pm));'
	pod2text LICENSE.pod LICENSE
	$(RM_F) LICENSE.pod

docs :: manifest populateversion populatecopyright README.md LICENSE

POSTAMBLE
}

WriteMakefile( %mm_args )
