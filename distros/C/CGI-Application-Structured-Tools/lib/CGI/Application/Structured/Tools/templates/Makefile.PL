
=head1 NAME

Template Makefile.PL for CGI::Application::Structured apps.

=cut 


use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => '<tmpl_var main_module>',
    AUTHOR              => '<tmpl_var author> <<tmpl_var email>>',
    VERSION_FROM        => '<tmpl_var main_pm_file>',
    ABSTRACT_FROM       => '<tmpl_var main_pm_file>',
    PL_FILES            => {},
    PREREQ_PM => {
        'CGI::Application'              => 4.04,
        'File::Find'                    => 0,
        'HTML::Template'                => 0,
        'Pod::Coverage'                 => 0.18,
        'Pod::Usage'                    => 0,
        'Test::More'                    => 0,
        'Test::Pod'                     => 1.22,
        'Test::Pod::Coverage'           => 1.08,
        'Test::WWW::Mechanize::CGIApp'  => 0,
    },
    SIGN => 1,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => '<tmpl_var distro>-*' },
);
