# <? read_starfish_conf(); &generate_header; !>
#+
# file: Makefile.PL
# CGI::AuthRegister - Simple CGI Authentication and Registration in Perl
# (c) 2012-14 Vlado Keselj http://web.cs.dal.ca/~vlado
# $Date: $
# $Id: $
#-
use ExtUtils::MakeMaker;

WriteMakefile(
    # <? &generate_WriteMakefile_part !>
    #+
    'NAME'		=> 'CGI::AuthRegister',
    'ABSTRACT'          => 'Simple CGI Authentication and Registration in Perl',
    'VERSION_FROM'	=> 'AuthRegister.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    (5.014004 >= 5.005 ?    ## Add these new keywords supported since 5.005
       ( AUTHOR     => 'Vlado Keselj http://web.cs.dal.ca/~vlado') : ()),
    #-
    'dist'  => {'COMPRESS'=>'gzip', 'SUFFIX' => 'gz'},
    'clean' => {FILES => "tmp* *~"},
    EXE_FILES => [], # eg:[ 'bin/some_program' ],
    PMLIBDIRS => [], #eg:[ 'Package/samples', 'Package/samples/1' ],
);

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
