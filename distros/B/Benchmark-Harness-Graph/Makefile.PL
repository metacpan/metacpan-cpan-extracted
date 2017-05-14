
# $Name:  $
use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

use ExtUtils::MakeMaker;

{   package MM;
sub new {
    my $self = shift;
    $self->SUPER::new(@_);
}
}
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $prereq_pm = { 'Benchmark::Harness' => 1.08
                 ,'GD' => 2.12
                 ,'GD::Graph::lines' => 1.15
                };

WriteMakefile(
    'NAME'	=> 'Benchmark::Harness::Graph',
    'VERSION_FROM' => 'Graph.pm', # finds $VERSION
    # test.pl uses this hash, also, to poll all modules we depend on
    'PREREQ_PM' => $prereq_pm,
    ($] ge '5.005') ? (
                     'AUTHOR' => 'Glenn Wood http://search.cpan.org/search?mode=author&query=GLENNWOOD',
                     'ABSTRACT' => 'Graph and profile utilities for Benchmark::Harness',
                    ) : (),
);

