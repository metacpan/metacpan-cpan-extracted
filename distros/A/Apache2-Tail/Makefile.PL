use ExtUtils::MakeMaker;
use strict;

#Apache::Test ?
if (eval " use Apache::Test; 1;") {
    require Apache::TestMM;
    Apache::TestMM->import(qw(test clean));    
    require Apache::TestRunPerl;

    Apache::TestMM::filter_args();
    Apache::TestRunPerl->generate_script();
}

WriteMakefile(
              NAME          => 'Apache2::Tail',
              VERSION_FROM  => 'lib/Apache2/Tail.pm',
              ABSTRACT_FROM  => 'lib/Apache2/Tail.pm',
              AUTHOR         => 'Philippe M. Chiasson <gozer@cpan.org>',
              SIGN              => 1,
              LICENSE           => 'perl',
              PREREQ_PM => {
                            'mod_perl2' => 0,
                            'CGI'       => 0,
                            'File::Tail' => 0,
			    'Test::More' => 0,
                           },
             );


sub MY::distdir {
    my $orig = shift->MM::distdir;
    
    $orig =~ s/^(distdir\s+:)/$1 README/m;
    
    return  $orig . <<"EOF";

README: lib/Apache2/Tail.pm
\t\@\$(PERL) -MPod::Text -e'Pod::Text->new->parse_from_file("\$<","\$@")'

EOF

}

