use ExtUtils::MakeMaker;

my $prereq = {};

if ( $^O =~ /win32/i ) {
    $prereq = {
        'Win32'          => 0,
        'Win32::Console' => 0,
        'Win32API::File' => 0,
        'Win32::Job'     => 0,
        'Win32::API'     => 0,
        'Win32::Process' => 0,
    };
}

$prereq->{AnyEvent} = '4.85';

WriteMakefile(
    NAME              => 'AnyEvent::Run',
    VERSION_FROM      => 'lib/AnyEvent/Run.pm',
    PREREQ_PM         => $prereq,
    ABSTRACT_FROM     => 'lib/AnyEvent/Run.pm',
    AUTHOR            => 'Andy Grundman <andy@hybridized.org>',
);
