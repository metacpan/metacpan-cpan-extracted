
use strict;
use ExtUtils::MakeMaker;
my $min_perl_version = 5.005;

if($] < $min_perl_version) 
{
    print STDERR "This module will not work with perl version $]. It requires perl version $min_perl_version or higher\n";
    exit 1;
}

eval('use Apache::Admin::Config');
if(!$@ && $Apache::Admin::Config::VERSION < 0.10)
{
    $|++;
    print
    (   STDERR
        qq(Your actual version of Apache::Admin::Config ($Apache::Admin::Config::VERSION) use the old API.\n),
        qq(Changes in new API may dont work correctly with your programs, so you _have_ to read\n),
        qq(the documentation and the "UPDATE-0.10" file before installing this version.\n\n),
        qq(Would you like to install it anyway ? (Y/n):)
    );

    my $answer = <STDIN>;
    if($answer =~ /n/i)
    {
        print STDERR "Installation aborted.\n";
        exit 1;
    }
}

WriteMakefile
(
    NAME            => 'Apache::Admin::Config',
    DISTNAME        => 'Apache-Admin-Config',
    VERSION_FROM    => 'lib/Apache/Admin/Config.pm', # finds $VERSION
    PREREQ_PM       => {FileHandle => 2.00},
    PMLIBDIRS       => ['lib'],
    ABSTRACT_FROM   => 'lib/Apache/Admin/Config.pm', # retrieve abstract from module
    AUTHOR          => 'Olivier Poitrey <rs@rhapsodyk.net>',
);
