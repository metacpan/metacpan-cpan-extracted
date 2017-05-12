use 5.006;

# Selftests on cpantesters.org consistently fail on Windows. I don't have
# access to Windows, and don't really care enough to pursue this.
die "OS unsupported"            if $^O =~ /mswin/i;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'CGI::Alert',
    'AUTHOR'            => 'Eduardo Santiago <esm@cpan.org>',
    'VERSION_FROM'      => 'lib/CGI/Alert.pm', # finds $VERSION
    'ABSTRACT_FROM'     => 'lib/CGI/Alert.pm', # retrieve abstract from module
    'LICENSE'           => 'perl',

    'PREREQ_PM'         => {
        'Test::More' => 0,
        'Test::Differences' => 0,
    },
    # (only for use by Ed): README is generated from README.in, so I don't
    # have to maintain the version in two places.  Make sure README is
    # up-to-date before we ship it.
    depend              => { distdir => 'README' },
);

sub MY::postamble {
    return <<'-';
README:	README.in Makefile
	sed -e "s/__VERSION__/$(VERSION)/" -e "s/<YYYY>/$(shell date +%Y)/" <$< >$@.tmp.$$ && mv -f $@.tmp.$$ $@

-
}
