# file: Makefile.PL
# CGI::AuthRegister - AuthRegister Module for Simple CGI Authentication and
#   Registration in Perl
# (c) 2012-20 Vlado Keselj (cpan:vlado vlado.ca http://vlado.ca)
use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'         => 'CGI::AuthRegister',
  'ABSTRACT'     => 'AuthRegister Module for Simple CGI Authentication'.
                    ' and Registration in Perl',
  'VERSION_FROM' => 'AuthRegister.pm', # finds $VERSION
  'PREREQ_PM'    => {
    'CGI' => 0,                     # some dependence on CGI
    'HTTP::Request::Common' => '0', # required if used with CAS functionality
  }, 
  (5.020003 >= 5.005 ?    ## Add these new keywords supported since 5.005
    ( AUTHOR => 'Vlado Keselj (cpan:vlado vlado.ca http://vlado.ca)') : ()),
    'dist'  => {'COMPRESS'=>'gzip', 'SUFFIX' => 'gz'},
  'clean' => {FILES => "tmp* *~"},
  EXE_FILES => [], #eg:[ 'bin/some_program' ],
  PMLIBDIRS => [], #eg:[ 'Package/samples', 'Package/samples/1' ],
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => { repository => {
      type => 'git',
      url => 'https://github.com/vkeselj/CGI-AuthRegister.git',
      web => 'https://github.com/vkeselj/CGI-AuthRegister',
}}}) : () ));

# private parts of Makefile
open(M, ">>Makefile") or die;
if ( -f 'priv.make' ) { print M getfile('priv.make') }
close(M);

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}
