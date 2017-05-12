use ExtUtils::MakeMaker;

our $VERSION="0.5";

open ABSTRACT, "<", "ABSTRACT";
our $ABSTRACT=<ABSTRACT>;
chomp $ABSTRACT;
close ABSTRACT;

WriteMakefile(
    NAME         => 'Apache::ForwardedFor',
    VERSION      => $VERSION,
    AUTHOR       => 'Jay J. Lawrence',
    ABSTRACT     => $ABSTRACT,
    PREREQ_PM    => {
            mod_perl => undef,
    },

);

open VERSION, ">", "VERSION";
print VERSION "$VERSION";
close VERSION;

