use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'BFD',
    VERSION_FROM  => 'lib/BFD.pm',
    PREREQ_PM => {
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
