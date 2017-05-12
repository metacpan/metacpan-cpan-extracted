use strict;

use ExtUtils::MakeMaker;
{
    no strict 'refs';

    my $libscan = \&{"ExtUtils::MM_Any::libscan"};
    *{"ExtUtils::MM_Any::libscan"} = sub {
        return '' unless $libscan->(@_);
        return '' if $_[1] =~ /\.swp$/;
        return $_[1];
    };
}

WriteMakefile(
    NAME         => 'Class::LazyLoad',
    VERSION_FROM => 'lib/Class/LazyLoad.pm', 
    PREREQ_PM    => {
        'Test::More' => 0.47,
        'overload'   => 0.01,
    }
);
