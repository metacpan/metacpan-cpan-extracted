
# $Name:  $
use vars qw($VERSION); $VERSION = sprintf("%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/);

use ExtUtils::MakeMaker;

{   package MM;
sub new {
    my $self = shift;
    $self->SUPER::new(@_);
}
}
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $prereq_pm = { 'Devel::Peek' => 1.01
                 ,'Devel::Size' => 0.58
                 ,'Time::HiRes' => 1.59
                 ,'XML::Quote'  => 1.02
                };
if ( $^O eq 'MSWin32' ) {
    $prereq_pm->{'Win32::Process::Info'} = 1.002;
    $prereq_pm->{'Win32::OLE'} = 0.1403;
} else { # assume Linux and *nix
    $prereq_pm->{'Proc::ProcessTable'} = 0.39;
}

WriteMakefile(
    'NAME'	=> 'Benchmark::Harness',
    'VERSION' => '1.12',
    'PREREQ_PM' => $prereq_pm,
    ($] ge '5.005') ? (
                     'AUTHOR' => 'Glenn Wood http://search.cpan.org/~glennwood/',
                     'ABSTRACT' => 'Test/Profile harness for general purpose peeking',
                    ) : (),
);

