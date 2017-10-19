#ifndef TYPES_H
#define TYPES_H

// Bio::Phylo object type constants
#define _NONE_ 1
#define _NODE_ 2
#define _TREE_ 3
#define _FOREST_ 4
#define _TAXON_ 5
#define _TAXA_ 6
#define _DATUM_ 7
#define _MATRIX_ 8
#define _MATRICES_ 9
#define _SEQUENCE_ 10
#define _ALIGNMENT_ 11
#define _CHAR_ 12
#define _PROJECT_ 9
#define _CHARSTATE_ 13
#define _CHARSTATESEQ_ 14
#define _MATRIXROW_ 15
#define _ANNOTATION_ 16
#define _DICTIONARY_ 17
#define _DOMCREATOR_ 18
#define _META_ 19
#define _DESCRIPTION_ 20
#define _RESOURCE_ 21
#define _DOCUMENT_ 22
#define _ELEMENT_ 23
#define _CHARACTERS_ 24
#define _CHARACTER_ 25
#define _SET_ 26
#define _MODEL_ 27
#define _OPERATION_ 28
#define _DATATYPE_ 29

// tag/package indices
#define _NODE_IDX_ 0
#define _TREE_IDX_ 1
#define _FOREST_IDX_ 2
#define _TAXON_IDX_ 3
#define _TAXA_IDX_ 4
#define _DATUM_IDX_ 5
#define _MATRIX_IDX_ 6
#define _CHARACTER_IDX_ 7
#define _CHARACTERS_IDX_ 8
#define _META_IDX_ 9
#define _PROJECT_IDX_ 10
#define _SET_IDX_ 11
#define _DATATYPE_IDX_ 12
#define _TAXAMEDIATOR_IDX_ 13

/*
Allocate memory with Newx if it's
available - if it's an older perl
that doesn't have Newx then we
resort to using New.
*/
#ifndef Newx
#  define Newx(v,n,t) New(0,v,n,t)
#endif

#endif
