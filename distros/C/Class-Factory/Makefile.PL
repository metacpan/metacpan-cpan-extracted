use ExtUtils::MakeMaker;

my %opts = (
    'NAME'         => 'Class::Factory',
    'VERSION_FROM' => 'lib/Class/Factory.pm',
);

if ( $ExtUtils::MakeMaker::VERSION >= 5.43 ) {
    $opts{AUTHOR}   = 'Chris Winters <chris@cwinters.com';
    $opts{ABSTRACT} = 'Useful base class for factory classes',
}

WriteMakefile( %opts );

sub MY::test {

    my $test = shift->MM::test(@_);

	eval { require Test::More } && ($Test::More::VERSION >= 0.62) 
or return <<EOF;
test::
\t\@echo sorry, cannot run tests without Test::More 0.62
EOF

    if ( eval { require Devel::Cover } ) {
        $test .= <<EOF;
testcover ::
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover make test
	cover
EOF
    }

    return $test;
}
