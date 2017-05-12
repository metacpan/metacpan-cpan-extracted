#############################################################################
## Name:        MakeMaker.pm
## Purpose:     MakeMaker class for HPLOO classes.
## Author:      Graciliano M. P.
## Modified by:
## Created:     30/10/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Class::HPLOO::MakeMaker ;

use 5.006 ;
use strict qw(vars) ;

use vars qw($VERSION $SYNTAX @ISA) ;

$VERSION = '0.1';

############
# EXPORTER #
############

require Exporter;
@ISA = qw(Exporter UNIVERSAL) ;
our @EXPORT = qw(WriteMakefile) ;
our @EXPORT_OK = @EXPORT ;

###########
# REQUIRE #
###########

  use Class::HPLOO::Build ;

  use ExtUtils::MakeMaker () ;

  eval(' use Inline::MakeMaker () ;') ;
  my $USE_INLINE = $@ ? 0 : 1 ;

#################
# WRITEMAKEFILE #
#################

sub WriteMakefile {

  if ( $USE_INLINE ) {
    my ( %args ) = @_ ;
    
    my $ver = -s $args{VERSION_FROM} ? ExtUtils::MM_Unix::parse_version('MM' , $args{VERSION_FROM} ) : undef ;
    
    Class::HPLOO::Build::build([$ver],"-r") ;
    
    $args{clean} ||= { FILES=>q[_Inline *.inl] } ;

    Inline::MakeMaker::WriteMakefile(%args) ;
  
    if ( $args{VERSION_FROM} =~ /(.*?)(\w+)\.pm$/ ) {
      my ($path,$name) = ($1,$2) ;
      open (MKFL,"Makefile") ;
      my $data = join '' , <MKFL> ;
      close (MKFL) ;
  
      $data =~ s/(\npure_all :: )$name(.inl)/${1}$path$name$2/si ;
    
      open (MKFL,">Makefile") ;
      print MKFL $data ;
      close (MKFL) ;
    }
  }
  else {
    Class::HPLOO::Build::build("-r") ;
    ExtUtils::MakeMaker::WriteMakefile(@_) ;
  }

}

#######
# END #
#######

1;


