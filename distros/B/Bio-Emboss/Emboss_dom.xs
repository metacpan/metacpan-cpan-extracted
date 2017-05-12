#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "emboss_perl.h"
#include "bio_emboss_config.h"

MODULE = Bio::Emboss_dom		PACKAGE = Bio::Emboss		

PROTOTYPES: ENABLE

 # code from ajdom.c: automatically generated

AjPDomNodeEntry
ajDomNodeListAppend (list, child)
       AjPDomNodeList list
       AjPDomNode child
    OUTPUT:
       RETVAL
       list

AjPDomNode
ajDomNodeAppendChild (node, extrachild)
       AjPDomNode node
       AjPDomNode extrachild
    OUTPUT:
       RETVAL
       node

AjPDomNode
ajDomRemoveChild (node, child)
       AjPDomNode node
       AjPDomNode child
    OUTPUT:
       RETVAL
       node

AjBool
ajDomNodeListExists (list, child)
       AjPDomNodeList list
       const AjPDomNode child
    OUTPUT:
       RETVAL

AjPDomNodeEntry
ajDomNodeListRemove (list, child)
       AjPDomNodeList list
       AjPDomNode child
    OUTPUT:
       RETVAL
       list

void
ajDomDocumentDestroyNode (doc, node)
       AjPDomDocument doc
       AjPDomNode node
    OUTPUT:
       doc
       node

void
ajDomDocumentDestroyNodeList (doc, list, donodes)
       AjPDomDocument doc
       AjPDomNodeList list
       AjBool donodes
    OUTPUT:
       doc
       list

AjPDomNodeList
ajDomCreateNodeList (doc)
       AjPDomDocument doc
    OUTPUT:
       RETVAL

AjPDomNode
ajDomDocumentCreateNode (doc, nodetype)
       AjPDomDocument doc
       ajuint nodetype
    OUTPUT:
       RETVAL

AjPDomDocumentType
ajDomImplementationCreateDocumentType (qualname, publicid, systemid)
       const AjPStr qualname
       const AjPStr publicid
       const AjPStr systemid
    OUTPUT:
       RETVAL

AjPDomDocumentType
ajDomImplementationCreateDocumentTypeC (qualname, publicid, systemid)
       const char * qualname
       const char * publicid
       const char * systemid
    OUTPUT:
       RETVAL

AjPDomDocument
ajDomImplementationCreateDocument (uri, qualname, doctype)
       const AjPStr uri
       const AjPStr qualname
       AjPDomDocumentType doctype
    OUTPUT:
       RETVAL

AjPDomDocument
ajDomImplementationCreateDocumentC (uri, qualname, doctype)
       const char * uri
       const char * qualname
       AjPDomDocumentType doctype
    OUTPUT:
       RETVAL

AjPDomNode
ajDomNodeMapGetItem (map, name)
       const AjPDomNodeMap map
       const AjPStr name
    OUTPUT:
       RETVAL

AjPDomNode
ajDomNodeMapGetItemC (map, name)
       const AjPDomNodeMap map
       const char * name
    OUTPUT:
       RETVAL

AjPStr
ajDomElementGetAttribute (element, name)
       const AjPDomElement element
       const AjPStr name
    OUTPUT:
       RETVAL

AjPStr
ajDomElementGetAttributeC (element, name)
       const AjPDomElement element
       const char * name
    OUTPUT:
       RETVAL

AjPDomNode
ajDomNodeMapSetItem (map, arg)
       AjPDomNodeMap map
       AjPDomNode arg
    OUTPUT:
       RETVAL

AjPDomNode
ajDomNodeMapRemoveItem (map, name)
       AjPDomNodeMap map
       const AjPStr name
    OUTPUT:
       RETVAL

AjPDomNode
ajDomNodeMapRemoveItemC (map, name)
       AjPDomNodeMap map
       const char * name
    OUTPUT:
       RETVAL
       map

AjPDomNode
ajDomNodeMapItem (map, indexnum)
       const AjPDomNodeMap map
       ajint indexnum
    OUTPUT:
       RETVAL

AjPDomNode
ajDomNodeListItem (list, indexnum)
       const AjPDomNodeList list
       ajint indexnum
    OUTPUT:
       RETVAL

void
ajDomElementSetAttribute (element, name, value)
       const AjPDomElement element
       const AjPStr name
       const AjPStr value

void
ajDomElementSetAttributeC (element, name, value)
       const AjPDomElement element
       const char * name
       const char * value

void
ajDomElementRemoveAttribute (element, name)
       AjPDomElement element
       const AjPStr name

void
ajDomElementRemoveAttributeC (element, name)
       AjPDomElement element
       const char * name

AjPDomNode
ajDomElementGetAttributeNode (element, name)
       const AjPDomElement element
       const AjPStr name
    OUTPUT:
       RETVAL

AjPDomNode
ajDomElementGetAttributeNodeC (element, name)
       const AjPDomElement element
       const char * name
    OUTPUT:
       RETVAL

AjPDomNode
ajDomElementSetAttributeNode (element, newattr)
       AjPDomElement element
       AjPDomNode newattr
    OUTPUT:
       RETVAL

AjPDomNode
ajDomElementRemoveAttributeNode (element, oldattr)
       AjPDomElement element
       AjPDomNode oldattr
    OUTPUT:
       RETVAL
       element

AjPDomNodeList
ajDomElementGetElementsByTagName (element, name)
       AjPDomElement element
       const AjPStr name
    OUTPUT:
       RETVAL

AjPDomNodeList
ajDomElementGetElementsByTagNameC (element, name)
       AjPDomElement element
       const char * name
    OUTPUT:
       RETVAL

void
ajDomElementNormalise (element)
       AjPDomElement element
    OUTPUT:
       element

AjPStr
ajDomCharacterDataSubstringData (data, offset, count)
       const AjPDomCharacterData data
       ajint offset
       ajint count
    OUTPUT:
       RETVAL

void
ajDomCharacterDataAppendData (data, arg)
       AjPDomCharacterData data
       const AjPStr arg
    OUTPUT:
       data

void
ajDomCharacterDataAppendDataC (data, arg)
       AjPDomCharacterData data
       const char * arg
    OUTPUT:
       data

void
ajDomCharacterDataInsertData (data, offset, arg)
       AjPDomCharacterData data
       ajint offset
       const AjPStr arg
    OUTPUT:
       data

void
ajDomCharacterDataInsertDataC (data, offset, arg)
       AjPDomCharacterData data
       ajint offset
       const char * arg
    OUTPUT:
       data

void
ajDomCharacterDataDeleteData (data, offset, count)
       AjPDomCharacterData data
       ajint offset
       ajint count
    OUTPUT:
       data

void
ajDomCharacterDataReplaceData (data, offset, count, arg)
       AjPDomCharacterData data
       ajint offset
       ajint count
       const AjPStr arg
    OUTPUT:
       data

void
ajDomCharacterDataReplaceDataC (data, offset, count, arg)
       AjPDomCharacterData data
       ajint offset
       ajint count
       const char * arg
    OUTPUT:
       data

ajint
ajDomCharacterDataGetLength (data)
       const AjPDomCharacterData data
    OUTPUT:
       RETVAL

AjPDomText
ajDomTextSplitText (text, offset)
       AjPDomText text
       ajint offset
    OUTPUT:
       RETVAL
       text

AjPDomElement
ajDomDocumentCreateElement (doc, tagname)
       AjPDomDocument doc
       const AjPStr tagname
    OUTPUT:
       RETVAL
       doc

AjPDomElement
ajDomDocumentCreateElementC (doc, tagname)
       AjPDomDocument doc
       const char * tagname
    OUTPUT:
       RETVAL
       doc

AjPDomDocumentFragment
ajDomDocumentCreateDocumentFragment (doc)
       AjPDomDocument doc
    OUTPUT:
       RETVAL
       doc

AjPDomText
ajDomDocumentCreateTextNode (doc, data)
       AjPDomDocument doc
       const AjPStr data
    OUTPUT:
       RETVAL
       doc

AjPDomText
ajDomDocumentCreateTextNodeC (doc, data)
       AjPDomDocument doc
       const char * data
    OUTPUT:
       RETVAL
       doc

AjPDomComment
ajDomDocumentCreateComment (doc, data)
       AjPDomDocument doc
       const AjPStr data
    OUTPUT:
       RETVAL
       doc

AjPDomComment
ajDomDocumentCreateCommentC (doc, data)
       AjPDomDocument doc
       const char * data
    OUTPUT:
       RETVAL
       doc

AjPDomCDATASection
ajDomDocumentCreateCDATASection (doc, data)
       AjPDomDocument doc
       const AjPStr data
    OUTPUT:
       RETVAL
       doc

AjPDomCDATASection
ajDomDocumentCreateCDATASectionC (doc, data)
       AjPDomDocument doc
       const char * data
    OUTPUT:
       RETVAL
       doc

AjPDomAttr
ajDomDocumentCreateAttribute (doc, name)
       AjPDomDocument doc
       const AjPStr name
    OUTPUT:
       RETVAL
       doc

AjPDomAttr
ajDomDocumentCreateAttributeC (doc, name)
       AjPDomDocument doc
       const char * name
    OUTPUT:
       RETVAL
       doc

AjPDomEntityReference
ajDomDocumentCreateEntityReference (doc, name)
       AjPDomDocument doc
       const AjPStr name
    OUTPUT:
       RETVAL
       doc

AjPDomEntityReference
ajDomDocumentCreateEntityReferenceC (doc, name)
       AjPDomDocument doc
       const char * name
    OUTPUT:
       RETVAL
       doc

AjPDomPi
ajDomDocumentCreateProcessingInstruction (doc, target, data)
       AjPDomDocument doc
       const AjPStr target
       const AjPStr data
    OUTPUT:
       RETVAL
       doc

AjPDomPi
ajDomDocumentCreateProcessingInstructionC (doc, target, data)
       AjPDomDocument doc
       const char * target
       const char * data
    OUTPUT:
       RETVAL
       doc

AjPDomNodeList
ajDomDocumentGetElementsByTagName (doc, name)
       AjPDomDocument doc
       const AjPStr name
    OUTPUT:
       RETVAL

AjPDomNodeList
ajDomDocumentGetElementsByTagNameC (doc, name)
       AjPDomDocument doc
       const char * name
    OUTPUT:
       RETVAL

AjPDomDocumentType
ajDomDocumentGetDoctype (doc)
       const AjPDomDocument doc
    OUTPUT:
       RETVAL

AjPDomElement
ajDomDocumentGetDocumentElement (doc)
       const AjPDomDocument doc
    OUTPUT:
       RETVAL

void
ajDomPrintNode (node, indent)
       const AjPDomNode node
       ajint indent

void
ajDomPrintNode2 (node)
       const AjPDomNode node

void
ajDomNodePrintNode (node)
       const AjPDomNode node

AjPDomNode
ajDomNodeInsertBefore (node, newchild, refchild)
       AjPDomNode node
       AjPDomNode newchild
       AjPDomNode refchild
    OUTPUT:
       RETVAL
       node

AjPDomNode
ajDomNodeReplaceChild (node, newchild, oldchild)
       AjPDomNode node
       AjPDomNode newchild
       AjPDomNode oldchild
    OUTPUT:
       RETVAL

AjPDomNodeEntry
ajDomNodeListReplace (list, newchild, oldchild)
       AjPDomNodeList list
       AjPDomNode newchild
       AjPDomNode oldchild
    OUTPUT:
       RETVAL

AjPDomNode
ajDomNodeCloneNode (node, deep)
       AjPDomNode node
       AjBool deep
    OUTPUT:
       RETVAL

AjBool
ajDomNodeHasChildNodes (node)
       const AjPDomNode node
    OUTPUT:
       RETVAL

ajint
ajDomWrite (node, outf)
       const AjPDomDocument node
       AjPFile outf
    OUTPUT:
       RETVAL

AjPDomNodeEntry
ajDomNodeListInsert (list, newchild, refchild)
       AjPDomNodeList list
       AjPDomNode newchild
       AjPDomNode refchild
    OUTPUT:
       RETVAL

ajint
ajDomWriteIndent (node, outf, indent)
       const AjPDomDocument node
       AjPFile outf
       ajint indent
    OUTPUT:
       RETVAL

