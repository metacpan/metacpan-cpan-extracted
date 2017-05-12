#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_embgroup		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from embgroup.c: automatically generated

EmbPGroupTop
embGrpMakeNewGnode (name)
       const AjPStr name
    OUTPUT:
       RETVAL

EmbPGroupProg
embGrpMakeNewPnode (name, doc, keywords, package)
       const AjPStr name
       const AjPStr doc
       const AjPStr keywords
       const AjPStr package
    OUTPUT:
       RETVAL

void
embGrpSortGroupsList (groupslist)
       AjPList groupslist

void
embGrpSortProgsList (progslist)
       AjPList progslist

ajint
embGrpCompareTwoGnodes (a, b)
       const char* a
       const char* b
    OUTPUT:
       RETVAL

ajint
embGrpCompareTwoPnodes (a, b)
       const char* a
       const char* b
    OUTPUT:
       RETVAL

void
embGrpOutputGroupsList (outfile, groupslist, showprogs, html, showkey, package)
       AjPFile outfile
       const AjPList groupslist
       AjBool showprogs
       AjBool html
       AjBool showkey
       const AjPStr package

void
embGrpOutputProgsList (outfile, progslist, html, showkey, package)
       AjPFile outfile
       const AjPList progslist
       AjBool html
       AjBool showkey
       const AjPStr package

void
embGrpGroupsListDel (groupslist)
       AjPList& groupslist
    OUTPUT:
       groupslist

void
embGrpProgsListDel (progslist)
       AjPList& progslist
    OUTPUT:
       progslist

void
embGrpKeySearchProgs (newlist, glist, key, all)
       AjPList newlist
       const AjPList glist
       const AjPStr key
       AjBool all
    OUTPUT:
       newlist

void
embGrpKeySearchSeeAlso (newlist, appgroups, package, alpha, glist, key)
       AjPList newlist
       AjPList & appgroups
       AjPStr & package
       const AjPList alpha
       const AjPList glist
       const AjPStr key
    OUTPUT:
       appgroups
       package

void
embGrpProgsMakeUnique (list)
       AjPList list

void
embGrpGroupMakeUnique (list)
       AjPList list

void
embGrpExit ()

