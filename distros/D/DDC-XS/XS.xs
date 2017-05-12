/*-*- Mode: C -*- */
#include "ddcxs.h"

MODULE = DDC::XS		PACKAGE = DDC::XS

##=====================================================================
## bootstrap
##=====================================================================
BOOT:
 {
 } 

##=====================================================================
## DDC::XS::Constants
INCLUDE: Constants.xs

##=====================================================================
## DDC::XS::Object
INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- --typemap=typemap.xsp Object.xsp

##=====================================================================
## DDC::XS::CQueryCompiler
INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- --typemap=typemap.xsp QueryCompiler.xsp

##=====================================================================
## DDC::XS::CQuery
INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- --typemap=typemap.xsp Query.xsp

##=====================================================================
## DDC::XS::CQCount
INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- --typemap=typemap.xsp QCount.xsp

##=====================================================================
## DDC::XS::CQFilter
INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- --typemap=typemap.xsp QueryFilter.xsp

##=====================================================================
## DDC::XS::CQueryOptions
INCLUDE_COMMAND: $^X -MExtUtils::XSpp::Cmd -e xspp -- --typemap=typemap.xsp QueryOptions.xsp

##=====================================================================
## dummy
#INCLUDE: dummy.xs
