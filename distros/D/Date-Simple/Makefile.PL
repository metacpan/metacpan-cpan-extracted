use ExtUtils::MakeMaker;

$xs = 1;
@noxs = ();
if (@ARGV && $ARGV[0] eq 'noxs') {
    shift (@ARGV);
    print "Disabling XS code.\n";
    # Attempt to disable the C code in three ways, since MakeMaker
    # documentation is unclear.  Set 'XS' to an empty hash.  Set 'C'
    # to an empty array.  As a last resort, strip Simple.* from
    # the constants section.
    # XXX Maybe it would be more robust to simply delete or disguise
    # Simple.xs.  But normally packages don't modify their own files.
    $xs = 0;
    @noxs = ('XS' => {}, 'C' => []);
}
else {
    print "Enabling XS code.\n";
    print "If you get errors, run `make distclean'\n";
    print "and try again using `perl Makefile.PL noxs'.\n";
}

WriteMakefile(
    'NAME'		=> 'Date::Simple',
    'VERSION_FROM'	=> 'lib/Date/Simple.pm',
    'PREREQ_PM'		=> {
                            'Test::More'   => undef,
                            'Scalar::Util' => undef,
                           },
    @noxs,
);

package MY;

sub constants {
    my ($self) = @_;
    my $ret = $self->SUPER::constants;
    unless ($::xs) {
    	$ret =~ s/Simple.(pm|pod)/SimpleFoo.$1/g;
    	$ret =~ s/Simple\.\S+//gs;
    	$ret =~ s/SimpleFoo/Simple/g;
    }
    return $ret;
}
