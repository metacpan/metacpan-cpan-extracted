use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $modules = {
  'DBIx/Frame.pm'       => '$(INST_LIBDIR)/Frame.pm',
  'DBIx/Frame/CGI.pm'   => '$(INST_LIBDIR)/Frame/CGI.pm',
};

my $man3 = { 
  'DBIx/Frame.pm'       => '$(INST_MAN3DIR)/DBIx::Frame.3',
  'DBIx/Frame/CGI.pm'   => '$(INST_MAN3DIR)/DBIx::Frame::CGI.3',
};

WriteMakefile(
    'NAME'      => 'DBIx::Frame',
    'DISTNAME'  => 'DBIx-Frame',
    'MAN3PODS'  => $man3,
    'VERSION_FROM' => 'Version.pm', # finds $VERSION
    'PREREQ_PM'    => { 'DBI' => 1.14, 'HTML::FormRemove' => 0.1 },
    'PM' 	=> $modules,
    'EXE_FILES' => [ 'dbixframe.cgi', 'dbixframe_create.pl' ],
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'AUTHOR'    => 'tskirvin@ks.uiuc.edu (Tim Skirvin)',
    'ABSTRACT_FROM'  => 'DBIx/Frame.pm',
);
