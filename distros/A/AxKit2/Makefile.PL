#!/usr/bin/perl -w

use ExtUtils::MakeMaker;

use strict;
use warnings;

BEGIN {

my @optionals;
push @optionals, 'Cache::Cache' unless eval { require Cache::Cache };
push @optionals, 'Pod::SAX' unless eval { require Pod::SAX };
push @optionals, 'File::MMagic' unless eval { require File::MMagic };
push @optionals, 'RDF::Core' unless eval { require RDF::Core };
push @optionals, 'XML::XPathScript' unless eval { require XML::XPathScript };

if (@optionals) {
    print <<EOT;
The following optional modules are not available. They are required to make some
of the demos works so you may wish to install them:

EOT
    print "$_\n" for @optionals;
    print "\n";
}

}

WriteMakefile(
    NAME           => 'AxKit2',
    VERSION_FROM   => 'lib/AxKit2.pm',
    PREREQ_PM      => {
        'Danga::Socket' => 1.52,
        'XML::LibXML'   => 1.59,
        'XML::LibXSLT'  => 1.59,
        'XML::LibXML::XPathContext' => 0.07,
        'LWP::UserAgent' => 0,
        'Test::Builder::Module' => 0.03,
    },
    ABSTRACT_FROM  => 'lib/AxKit2.pm',
    AUTHOR         => 'Apache Software Foundation <axkit-users@axkit.org>',
    EXE_FILES      => [qw(axkit)],
);

sub MY::libscan {
    my $path = $_[1];
    return '' if $path =~ /\B\.svn\b/;
    return $path;
}

sub MY::install {
    package MY;
    my $script = shift->SUPER::install(@_);

    $script =~ s/^install :: (.*)$/install :: fail_install/m;
    $script .= <<EOT;
fail_install :
\t\@\$(PERL) -e "die qq(Do not run _make install_. See README for details.\\n)"

EOT

    return $script;
}
