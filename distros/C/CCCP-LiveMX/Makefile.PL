use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'CCCP::LiveMX',
    VERSION_FROM      => 'lib/CCCP/LiveMX.pm',
    PREREQ_PM         => {
        'Mail::CheckUser' => 0,
        'Net::DNS'        => 0,
        'Net::Ping'       => 2.24
    },
    ($] >= 5.005 ? (AUTHOR => 'mr.Rico') : ()),
);
