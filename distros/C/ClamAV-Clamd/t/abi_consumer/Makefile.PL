use strict;
use warnings;
use ExtUtils::MakeMaker;

# A consumer resolves the provider through ExtUtils::Depends when it is
# installed, and falls back to sibling -I paths when it is not - which is
# the case inside the provider's own test suite.
my %args = (
    NAME      => 'TestConsumer',
    VERSION   => '0.01',
    OBJECT    => 'Consumer$(OBJ_EXT)',
);

my $wired = 0;
if (eval { require ExtUtils::Depends; 1 }) {
    my $pkg = eval { ExtUtils::Depends->new('TestConsumer', 'ClamAV::Clamd') };
    if ($pkg && !$@) {
        my %dep = $pkg->get_makefile_vars;
        delete $dep{LIBS};
        delete $dep{LDFROM};
        %args = (%args, %dep);
        $wired = 1;
    }
}
$args{INC} = join ' ', ($args{INC} || ''), '-I../../include';

WriteMakefile(%args);
