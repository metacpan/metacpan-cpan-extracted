#!perl -w

use Config;

if($^O =~ /vms/i) {
    # $^X isn't VMS-friendly.  I'm disinclined to add a dependency on
    # Probe::Perl just for testing this corner-case
    print "1..0 # skip - can't reliably taint-test on VMS\n";
# } elsif($ENV{PERL5LIB}) {
#     print "1..0 # skip - can't reliably taint-test with PERL5LIB set\n";
# } else {
#     exec("$^X -Tw -Iblib/lib t/realtainttest");
# }
} else {
    my $perl5lib = $ENV{PERL5LIB} || '';
    $ENV{PERL5LIB} = '';
    exec(
        join(' ',
            $Config{perlpath},
            '-Tw',
            (
		# map { "-I$_" }
                map { qq{-I"$_"} }
                grep { -d $_ } # bleh, code-refs getting stringified
                split(/$Config{path_sep}/, $perl5lib)
            ),
            't/realtainttest'
        )
    );
}
