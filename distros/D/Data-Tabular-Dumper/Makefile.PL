use ExtUtils::MakeMaker;


my %prereq = (
    Text::CSV_XS => 0.2,
    Spreadsheet::WriteExcel => 0.26
);
foreach my $m ( keys %prereq ) {
    eval qq{use $m;};
    next if $@;
    delete $prereq{$m};
}

if( %prereq ) {
    warn <<WARN; 
The following modules are not installed.  While not strictly necessary to
use Data::Tabular::Dumper, it will greatly enhance your experience. 

WARN

    foreach my $m ( sort keys %prereq ) {
        my $ret = prompt( qq(Require $m?), "n" );
        next if $ret =~ /^Y$/i;
        delete $prereq{$m};
    }
}

WriteMakefile(
    AUTHOR         => 'Philip Gwyn',
    NAME           => 'Data::Tabular::Dumper',
    VERSION_FROM    => 'Dumper.pm', # finds $VERSION
    dist=>{COMPRESS =>'gzip -9f', EXT=>'gz'},
    LICENSE         => 'perl',
    'PREREQ_PM'     => {
            %prereq
    }
);
