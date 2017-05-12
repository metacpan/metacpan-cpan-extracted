use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Chart::Sequence',
    VERSION_FROM  => 'lib/Chart/Sequence.pm',
    EXE_FILES     => [],
    PREREQ_PM => {
        XML::SAX::PurePerl => 1,          # For testing
        XML::Filter::Dispatcher => 0.42,  # For XML parsing
        Imager => 0,                      # For rendering .pngs, etc.
    },
);


sub MY::libscan {
    package MY;
    my $self = shift;
    my ( $path ) = @_;
    return '' if /\.sw[a-z]$/;
    return '' unless length $self->SUPER::libscan( $path );
    return $path;
}
