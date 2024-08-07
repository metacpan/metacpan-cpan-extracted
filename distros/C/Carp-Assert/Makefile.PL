use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my @REQUIRES = (
    'strict'    => 0,
    'warnings'  => 0,
    'Exporter'  => 0,
    'vars'      => 0,
    'Carp'      => 0,
);

my @TEST_REQUIRES = (
    'Test::More'    => 0.88,
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

warn "Carp::Assert likes to have B::Deparse but can't find it.\n" unless 
  eval { require B::Deparse };

WriteMakefile(
    NAME        => 'Carp::Assert',
    VERSION_FROM => 'lib/Carp/Assert.pm', # finds $VERSION
    PREREQ_PM   => { @REQUIRES },
    'dist'      => {COMPRESS => 'gzip -9',
                    SUFFIX   => '.gz',
                    DIST_DEFAULT => 'all tardist',
                   },

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
        : ()
    ),

    ($mm_ver >= 6.31 ? (LICENSE => 'perl') : ()),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver <= 6.45 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                web  => 'https://github.com/demerphq/Carp-Assert',
                url  => 'git://github.com/demerphq/Carp-Assert.git',
            },
        },
    })),

);

{
    package MY;
    sub top_targets {
        my($self) = @_;

        return $self->SUPER::top_targets(@_) unless
          eval { require Pod::Tests; 1 };

        my $out = "POD2TEST_EXE = pod2test\n";

        $out .= $self->SUPER::top_targets(@_);
        $out =~ s/^(pure_all\b.*)/$1 testifypods/m;

        foreach my $pod (keys %{$self->{MAN1PODS}},
                         keys %{$self->{MAN3PODS}})
        {
            (my $test = $pod) =~ s/\.(pm|pod)$//;
            $test =~ s/^lib\W//;
            $test =~ s/\W/-/;
            $test = "t/embedded-$test.t";
            
            $pod2test{$pod} = $test;
        }

        $out .= <<"END_OF_MAKE";

testifypods : @{[ join " ", values %pod2test ]}
\t\$(NOECHO) \$(NOOP)

END_OF_MAKE
        
        for my $pod (keys %pod2test) {
            my $test = $pod2test{$pod};
            
            $out .= <<"END_OF_MAKE";
$test : $pod
\t\$(NOECHO) \$(ECHO) Testifying $pod to $test
\t\$(NOECHO) \$(POD2TEST_EXE) $pod $test

END_OF_MAKE
        }

        return $out;
    }


    sub test_via_harness {
        my($self, $orig_perl, $tests) = @_;

        my @perls = ($orig_perl);
        if ($ENV{PERL_TEST_ALL} and $ENV{HOME}) {
            chomp(my @list = `perlbrew list 2>&1`);
            my %candidate;
            foreach my $name (@list) {
                $name=~s/^\s+//;
                $name=~s/\s+\z//;
                next unless $name =~ /^(perl-\d+\.\d+)\.(\d+)\z/
                         or $name =~ /^(latest_blead)\z/;
                my $major = $1;
                my $minor = $2 // 0;
                my $path = "$ENV{HOME}/perl5/perlbrew/perls/$name/bin/perl";
                if (-e $path) {
                    $candidate{$major} = [$minor, $path]
                        if !$candidate{$major} or $candidate{$major}[0] < $minor;
                }
            }
            push @perls, sort map { $_->[-1] } values %candidate;
        }
        my $out;
        foreach my $perl (@perls) {
            $out .= $self->SUPER::test_via_harness($perl, $tests);
        }

        return $out;
    }
}
