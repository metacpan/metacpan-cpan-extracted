use ExtUtils::MakeMaker;

sub check_swifty_version {
    my $req_ver = shift;
    open my $fh, '-|', 'swifty --version'
	or die <<EOT;
Could not find swifty.

Please download and install swifty from
http://labs.cybozu.co.jp/blog/kazuhoatwork/my_projects/swifty/

EOT
;
    my $ver_line = <$fh>;
    close $fh;
    if ($ver_line !~ /\s([0-9\.])+/ || $1 < $req_ver) {
	die <<"EOT";
Please upgrade swifty.
This version of Cache::Swifty requires swifty > $req_ver.
EOT
;
    }
}

check_swifty_version('0.06');

WriteMakefile(
    NAME          => 'Cache::Swifty',
    VERSION_FROM  => 'lib/Cache/Swifty.pm',
    PREREQ_PM     => {
        'File::Remove'        => 0,
        'Test::Pod::Coverage' => 1.04,
    },
    ABSTRACT_FROM => 'lib/Cache/Swifty.pm',
    AUTHOR        => 'Kazuho Oku',
    LIBS          => [ '-lswifty' ],
    DEFINE        => '',
    INC           => '-I.',
    # Un-comment this if you add C files to link with later:
    # OBJECT      => '$(O_FILES)', # link all the C files too
);
