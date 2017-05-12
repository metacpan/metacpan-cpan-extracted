use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Apache::AuthenMT',
    'VERSION_FROM'  => 'AuthenMT.pm',
    'ABSTRACT_FROM' => 'AuthenMT.pm',
    'PREREQ_PM'     => {
        'Apache' => 0,
    },
);

sub MY::libscan {
    my $self = shift;
    $_       = shift;

    # $self appears to be a blessed hashref that contains
    # all the attributes/value pairs passed to WriteMakeFile()
    # plus some other MakeMaker-related info.

    return 0 if /\.sw.$/ || /~$/;
    return $_;
}

sub MY::postamble {
'
';
}

# vim:syntax=perl
# $Id: Makefile.PL,v 1.2 2003/01/23 22:25:26 beppu Exp $
