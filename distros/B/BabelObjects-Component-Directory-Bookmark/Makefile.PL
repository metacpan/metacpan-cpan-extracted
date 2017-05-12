use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$PACKAGE = 'BabelObjects::Component::Directory::Bookmark';
($PACKAGE_FILE = $PACKAGE) =~ s|::|/|g;
$LAST_API_CHANGE = 0;

eval "require $PACKAGE";

unless ($@) { # Make sure we did find the module.
    print <<"CHANGE_WARN" if ${$PACKAGE.'::VERSION'} < $LAST_API_CHANGE;

NOTE: There have been API changes between this version and any older
than version $LAST_API_CHANGE!  Please read the Changes file if you
are upgrading from a version older than $LAST_API_CHANGE.

CHANGE_WARN
}


WriteMakefile(
    NAME            => $PACKAGE,
    VERSION_FROM    => "lib/$PACKAGE_FILE.pm", # finds $VERSION
    AUTHOR          => 'Jean-Christophe Kermagoret <jck@BabelObjects.Org>',
    dist            => { 'COMPRESS' => 'gzip -9f',
                          'SUFFIX'   => 'gz'
                       },
    PREREQ_PM       => { XML::DOM => 0,
                        URI::Bookmarks => 0
                       }
);
