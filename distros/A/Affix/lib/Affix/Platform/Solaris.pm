package Affix::Platform::Solaris v1.2.5 {
    use v5.40;
    use parent 'Affix::Platform::Unix';
    use parent 'Exporter';
    our @EXPORT_OK   = qw[find_library];
    our %EXPORT_TAGS = ( all => \@EXPORT_OK );
};
1;
