use 5.018001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'Crypt::U2F::Server',
    VERSION_FROM  => 'lib/Crypt/U2F/Server.pm',    # finds $VERSION
    TEST_REQUIRES => {
        'Test::More'          => 0,
        'JSON::XS'            => 0,
        'Authen::U2F::Tester' => 0.02,
    },
    PREREQ_PM => { "DynaLoader" => 0, },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/Crypt/U2F/Server.pm',    # retrieve abstract from module
            AUTHOR => 'Rene Schickbauer <rene.schickbauer@magnapowertrain.com>'
          )
        : ()
    ),
    LIBS   => ['-lu2f-server'],             # e.g., '-lm'
    DEFINE => '',                           # e.g., '-DHAVE_SOMETHING'
    INC    => '-I.',                        # e.g., '-I. -I/usr/include/other'
    OBJECT => '$(O_FILES)',                 # link all the C files too
);
if ( eval { require ExtUtils::Constant; 1 } ) {

    # If you edit these definitions to change the constants used by this module,
    # you will need to use the generated const-c.inc and const-xs.inc
    # files to replace their "fallback" counterparts before distributing your
    # changes.
    my @names = (qw());
    ExtUtils::Constant::WriteConstants(
        NAME         => 'Crypt::U2F::Server',
        NAMES        => \@names,
        DEFAULT_TYPE => 'IV',
        C_FILE       => 'const-c.inc',
        XS_FILE      => 'const-xs.inc',
    );

}
else {
    use File::Copy;
    use File::Spec;
    foreach my $file ( 'const-c.inc', 'const-xs.inc' ) {
        my $fallback = File::Spec->catfile( 'fallback', $file );
        copy( $fallback, $file ) or die "Can't copy $fallback to $file: $!";
    }
}
