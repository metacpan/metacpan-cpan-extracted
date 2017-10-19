#ifndef IDENTIFIABLE_H
#define IDENTIFIABLE_H

// gets incremented for each object
int idpool = 1;

// lookup table for type mapping,
// indices come from _*_IDX_ in types.h
static const char *package[] = {
	"Bio::PhyloXS::Forest::Node",
	"Bio::PhyloXS::Forest::Tree",
	"Bio::PhyloXS::Forest",
	"Bio::PhyloXS::Taxa::Taxon",
	"Bio::PhyloXS::Taxa",
	"Bio::PhyloXS::Matrices::Datum",
	"Bio::PhyloXS::Matrices::Matrix",
	"Bio::PhyloXS::Matrices::Character",
	"Bio::PhyloXS::Matrices::Characters",
	"Bio::PhyloXS::NeXML::Meta",
	"Bio::PhyloXS::Project",
	"Bio::PhyloXS::Set",
	"Bio::PhyloXS::Matrices::Datatype",
	"Bio::PhyloXS::Mediators::TaxaMediator"
};

typedef struct {
    int id; // from idpool
    int _type; // from defines
    int _container; // from defines
	int _index; // from defines
} Identifiable;

void initialize_identifiable(Identifiable* self);
void destroy_identifiable(Identifiable* self);

#endif
