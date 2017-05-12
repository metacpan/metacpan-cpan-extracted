
#BEGIN_HEADER

use CDMI;

our $entity_field_defs = {
    'AlignmentTree' => {
	id => 1,
		    'alignment_method' => 1,
		    'alignment_parameters' => 1,
		    'alignment_properties' => 1,
		    'tree_method' => 1,
		    'tree_parameters' => 1,
		    'tree_properties' => 1,
	
    },
    'Annotation' => {
	id => 1,
		    'annotator' => 1,
		    'comment' => 1,
		    'annotation_time' => 1,
	
    },
    'AtomicRegulon' => {
	id => 1,
	
    },
    'Attribute' => {
	id => 1,
		    'description' => 1,
	
    },
    'Biomass' => {
	id => 1,
		    'mod_date' => 1,
		    'name' => 1,
	
    },
    'BiomassCompound' => {
	id => 1,
		    'coefficient' => 1,
	
    },
    'Compartment' => {
	id => 1,
		    'abbr' => 1,
		    'mod_date' => 1,
		    'name' => 1,
	
    },
    'Complex' => {
	id => 1,
		    'name' => 1,
		    'msid' => 1,
		    'mod_date' => 1,
	
    },
    'Compound' => {
	id => 1,
		    'label' => 1,
		    'abbr' => 1,
		    'msid' => 1,
		    'ubiquitous' => 1,
		    'mod_date' => 1,
		    'uncharged_formula' => 1,
		    'formula' => 1,
		    'mass' => 1,
	
    },
    'Contig' => {
	id => 1,
		    'source_id' => 1,
	
    },
    'ContigChunk' => {
	id => 1,
		    'sequence' => 1,
	
    },
    'ContigSequence' => {
	id => 1,
		    'length' => 1,
	
    },
    'CoregulatedSet' => {
	id => 1,
		    'source_id' => 1,
	
    },
    'Diagram' => {
	id => 1,
		    'name' => 1,
		    'content' => 1,
	
    },
    'EcNumber' => {
	id => 1,
		    'obsolete' => 1,
		    'replacedby' => 1,
	
    },
    'Experiment' => {
	id => 1,
		    'source' => 1,
	
    },
    'Family' => {
	id => 1,
		    'type' => 1,
		    'family_function' => 1,
	
    },
    'Feature' => {
	id => 1,
		    'feature_type' => 1,
		    'source_id' => 1,
		    'sequence_length' => 1,
		    'function' => 1,
	
    },
    'Genome' => {
	id => 1,
		    'pegs' => 1,
		    'rnas' => 1,
		    'scientific_name' => 1,
		    'complete' => 1,
		    'prokaryotic' => 1,
		    'dna_size' => 1,
		    'contigs' => 1,
		    'domain' => 1,
		    'genetic_code' => 1,
		    'gc_content' => 1,
		    'phenotype' => 1,
		    'md5' => 1,
		    'source_id' => 1,
	
    },
    'Identifier' => {
	id => 1,
		    'source' => 1,
		    'natural_form' => 1,
	
    },
    'Media' => {
	id => 1,
		    'mod_date' => 1,
		    'name' => 1,
		    'type' => 1,
	
    },
    'Model' => {
	id => 1,
		    'mod_date' => 1,
		    'name' => 1,
		    'version' => 1,
		    'type' => 1,
		    'status' => 1,
		    'reaction_count' => 1,
		    'compound_count' => 1,
		    'annotation_count' => 1,
	
    },
    'ModelCompartment' => {
	id => 1,
		    'compartment_index' => 1,
		    'label' => 1,
		    'pH' => 1,
		    'potential' => 1,
	
    },
    'OTU' => {
	id => 1,
	
    },
    'PairSet' => {
	id => 1,
		    'score' => 1,
	
    },
    'Pairing' => {
	id => 1,
	
    },
    'ProbeSet' => {
	id => 1,
	
    },
    'ProteinSequence' => {
	id => 1,
		    'sequence' => 1,
	
    },
    'Publication' => {
	id => 1,
		    'citation' => 1,
	
    },
    'Reaction' => {
	id => 1,
		    'mod_date' => 1,
		    'name' => 1,
		    'msid' => 1,
		    'abbr' => 1,
		    'equation' => 1,
		    'reversibility' => 1,
	
    },
    'ReactionRule' => {
	id => 1,
		    'direction' => 1,
		    'transproton' => 1,
	
    },
    'Reagent' => {
	id => 1,
		    'stoichiometry' => 1,
		    'cofactor' => 1,
		    'compartment_index' => 1,
		    'transport_coefficient' => 1,
	
    },
    'Requirement' => {
	id => 1,
		    'direction' => 1,
		    'transproton' => 1,
		    'proton' => 1,
	
    },
    'Role' => {
	id => 1,
		    'hypothetical' => 1,
	
    },
    'SSCell' => {
	id => 1,
	
    },
    'SSRow' => {
	id => 1,
		    'curated' => 1,
		    'region' => 1,
	
    },
    'Scenario' => {
	id => 1,
		    'common_name' => 1,
	
    },
    'Source' => {
	id => 1,
	
    },
    'Subsystem' => {
	id => 1,
		    'version' => 1,
		    'curator' => 1,
		    'notes' => 1,
		    'description' => 1,
		    'usable' => 1,
		    'private' => 1,
		    'cluster_based' => 1,
		    'experimental' => 1,
	
    },
    'SubsystemClass' => {
	id => 1,
	
    },
    'TaxonomicGrouping' => {
	id => 1,
		    'domain' => 1,
		    'hidden' => 1,
		    'scientific_name' => 1,
		    'alias' => 1,
	
    },
    'Variant' => {
	id => 1,
		    'role_rule' => 1,
		    'code' => 1,
		    'type' => 1,
		    'comment' => 1,
	
    },
    'Variation' => {
	id => 1,
		    'notes' => 1,
	
    },

};

our $entity_field_rels = {
    'AlignmentTree' => {
    },
    'Annotation' => {
    },
    'AtomicRegulon' => {
    },
    'Attribute' => {
    },
    'Biomass' => {
	    'name' => 'BiomassName',
    },
    'BiomassCompound' => {
    },
    'Compartment' => {
    },
    'Complex' => {
	    'name' => 'ComplexName',
    },
    'Compound' => {
    },
    'Contig' => {
    },
    'ContigChunk' => {
    },
    'ContigSequence' => {
    },
    'CoregulatedSet' => {
    },
    'Diagram' => {
	    'content' => 'DiagramContent',
    },
    'EcNumber' => {
    },
    'Experiment' => {
    },
    'Family' => {
	    'family_function' => 'FamilyFunction',
    },
    'Feature' => {
    },
    'Genome' => {
	    'phenotype' => 'GenomeSequencePhenotype',
    },
    'Identifier' => {
    },
    'Media' => {
    },
    'Model' => {
    },
    'ModelCompartment' => {
	    'label' => 'ModelCompartmentLabel',
    },
    'OTU' => {
    },
    'PairSet' => {
    },
    'Pairing' => {
    },
    'ProbeSet' => {
    },
    'ProteinSequence' => {
    },
    'Publication' => {
    },
    'Reaction' => {
    },
    'ReactionRule' => {
    },
    'Reagent' => {
    },
    'Requirement' => {
    },
    'Role' => {
    },
    'SSCell' => {
    },
    'SSRow' => {
    },
    'Scenario' => {
    },
    'Source' => {
    },
    'Subsystem' => {
    },
    'SubsystemClass' => {
    },
    'TaxonomicGrouping' => {
	    'alias' => 'TaxonomicGroupingAlias',
    },
    'Variant' => {
	    'role_rule' => 'VariantRole',
    },
    'Variation' => {
	    'notes' => 'VariationNotes',
    },

};

our $relationship_field_defs = {
    'AffectsLevelOf' => {
	to_link => 1, from_link => 1,
		    'level' => 1,
	
    },
    'IsAffectedIn' => {
	to_link => 1, from_link => 1,
		    'level' => 1,
	
    },
    'Aligns' => {
	to_link => 1, from_link => 1,
		    'begin' => 1,
		    'end' => 1,
		    'len' => 1,
		    'sequence_id' => 1,
		    'properties' => 1,
	
    },
    'IsAlignedBy' => {
	to_link => 1, from_link => 1,
		    'begin' => 1,
		    'end' => 1,
		    'len' => 1,
		    'sequence_id' => 1,
		    'properties' => 1,
	
    },
    'Concerns' => {
	to_link => 1, from_link => 1,
	
    },
    'IsATopicOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Contains' => {
	to_link => 1, from_link => 1,
	
    },
    'IsContainedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'Controls' => {
	to_link => 1, from_link => 1,
	
    },
    'IsControlledUsing' => {
	to_link => 1, from_link => 1,
	
    },
    'Describes' => {
	to_link => 1, from_link => 1,
	
    },
    'IsDescribedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Displays' => {
	to_link => 1, from_link => 1,
		    'location' => 1,
	
    },
    'IsDisplayedOn' => {
	to_link => 1, from_link => 1,
		    'location' => 1,
	
    },
    'Encompasses' => {
	to_link => 1, from_link => 1,
	
    },
    'IsEncompassedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'Formulated' => {
	to_link => 1, from_link => 1,
	
    },
    'WasFormulatedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'GeneratedLevelsFor' => {
	to_link => 1, from_link => 1,
		    'level_vector' => 1,
	
    },
    'WasGeneratedFrom' => {
	to_link => 1, from_link => 1,
		    'level_vector' => 1,
	
    },
    'HasAssertionFrom' => {
	to_link => 1, from_link => 1,
		    'function' => 1,
		    'expert' => 1,
	
    },
    'Asserts' => {
	to_link => 1, from_link => 1,
		    'function' => 1,
		    'expert' => 1,
	
    },
    'HasCompoundAliasFrom' => {
	to_link => 1, from_link => 1,
		    'alias' => 1,
	
    },
    'UsesAliasForCompound' => {
	to_link => 1, from_link => 1,
		    'alias' => 1,
	
    },
    'HasIndicatedSignalFrom' => {
	to_link => 1, from_link => 1,
		    'rma_value' => 1,
		    'level' => 1,
	
    },
    'IndicatesSignalFor' => {
	to_link => 1, from_link => 1,
		    'rma_value' => 1,
		    'level' => 1,
	
    },
    'HasMember' => {
	to_link => 1, from_link => 1,
	
    },
    'IsMemberOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasParticipant' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'ParticipatesIn' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'HasPresenceOf' => {
	to_link => 1, from_link => 1,
		    'concentration' => 1,
		    'minimum_flux' => 1,
		    'maximum_flux' => 1,
	
    },
    'IsPresentIn' => {
	to_link => 1, from_link => 1,
		    'concentration' => 1,
		    'minimum_flux' => 1,
		    'maximum_flux' => 1,
	
    },
    'HasReactionAliasFrom' => {
	to_link => 1, from_link => 1,
		    'alias' => 1,
	
    },
    'UsesAliasForReaction' => {
	to_link => 1, from_link => 1,
		    'alias' => 1,
	
    },
    'HasRepresentativeOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRepresentedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'HasResultsIn' => {
	to_link => 1, from_link => 1,
		    'sequence' => 1,
	
    },
    'HasResultsFor' => {
	to_link => 1, from_link => 1,
		    'sequence' => 1,
	
    },
    'HasSection' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSectionOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasStep' => {
	to_link => 1, from_link => 1,
	
    },
    'IsStepOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasUsage' => {
	to_link => 1, from_link => 1,
	
    },
    'IsUsageOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasValueFor' => {
	to_link => 1, from_link => 1,
		    'value' => 1,
	
    },
    'HasValueIn' => {
	to_link => 1, from_link => 1,
		    'value' => 1,
	
    },
    'Imported' => {
	to_link => 1, from_link => 1,
	
    },
    'WasImportedFrom' => {
	to_link => 1, from_link => 1,
	
    },
    'Includes' => {
	to_link => 1, from_link => 1,
		    'sequence' => 1,
		    'abbreviation' => 1,
		    'auxiliary' => 1,
	
    },
    'IsIncludedIn' => {
	to_link => 1, from_link => 1,
		    'sequence' => 1,
		    'abbreviation' => 1,
		    'auxiliary' => 1,
	
    },
    'IndicatedLevelsFor' => {
	to_link => 1, from_link => 1,
		    'level_vector' => 1,
	
    },
    'HasLevelsFrom' => {
	to_link => 1, from_link => 1,
		    'level_vector' => 1,
	
    },
    'Involves' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInvolvedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsARequirementIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsARequirementOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsAlignedIn' => {
	to_link => 1, from_link => 1,
		    'start' => 1,
		    'len' => 1,
		    'dir' => 1,
	
    },
    'IsAlignmentFor' => {
	to_link => 1, from_link => 1,
		    'start' => 1,
		    'len' => 1,
		    'dir' => 1,
	
    },
    'IsAnnotatedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Annotates' => {
	to_link => 1, from_link => 1,
	
    },
    'IsBindingSiteFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsBoundBy' => {
	to_link => 1, from_link => 1,
	
    },
    'IsClassFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInClass' => {
	to_link => 1, from_link => 1,
	
    },
    'IsCollectionOf' => {
	to_link => 1, from_link => 1,
		    'representative' => 1,
	
    },
    'IsCollectedInto' => {
	to_link => 1, from_link => 1,
		    'representative' => 1,
	
    },
    'IsComposedOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsComponentOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsComprisedOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Comprises' => {
	to_link => 1, from_link => 1,
	
    },
    'IsConfiguredBy' => {
	to_link => 1, from_link => 1,
	
    },
    'ReflectsStateOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsConsistentWith' => {
	to_link => 1, from_link => 1,
	
    },
    'IsConsistentTo' => {
	to_link => 1, from_link => 1,
	
    },
    'IsCoregulatedWith' => {
	to_link => 1, from_link => 1,
		    'coefficient' => 1,
	
    },
    'HasCoregulationWith' => {
	to_link => 1, from_link => 1,
		    'coefficient' => 1,
	
    },
    'IsCoupledTo' => {
	to_link => 1, from_link => 1,
		    'co_occurrence_evidence' => 1,
		    'co_expression_evidence' => 1,
	
    },
    'IsCoupledWith' => {
	to_link => 1, from_link => 1,
		    'co_occurrence_evidence' => 1,
		    'co_expression_evidence' => 1,
	
    },
    'IsDefaultFor' => {
	to_link => 1, from_link => 1,
	
    },
    'RunsByDefaultIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsDefaultLocationOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasDefaultLocation' => {
	to_link => 1, from_link => 1,
	
    },
    'IsDeterminedBy' => {
	to_link => 1, from_link => 1,
		    'inverted' => 1,
	
    },
    'Determines' => {
	to_link => 1, from_link => 1,
		    'inverted' => 1,
	
    },
    'IsDividedInto' => {
	to_link => 1, from_link => 1,
	
    },
    'IsDivisionOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsExemplarOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasAsExemplar' => {
	to_link => 1, from_link => 1,
	
    },
    'IsFamilyFor' => {
	to_link => 1, from_link => 1,
	
    },
    'DeterminesFunctionOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsFormedOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsFormedInto' => {
	to_link => 1, from_link => 1,
	
    },
    'IsFunctionalIn' => {
	to_link => 1, from_link => 1,
	
    },
    'HasFunctional' => {
	to_link => 1, from_link => 1,
	
    },
    'IsGroupFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInGroup' => {
	to_link => 1, from_link => 1,
	
    },
    'IsImplementedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Implements' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInPair' => {
	to_link => 1, from_link => 1,
	
    },
    'IsPairOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInstantiatedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInstanceOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsLocatedIn' => {
	to_link => 1, from_link => 1,
		    'ordinal' => 1,
		    'begin' => 1,
		    'len' => 1,
		    'dir' => 1,
	
    },
    'IsLocusFor' => {
	to_link => 1, from_link => 1,
		    'ordinal' => 1,
		    'begin' => 1,
		    'len' => 1,
		    'dir' => 1,
	
    },
    'IsModeledBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Models' => {
	to_link => 1, from_link => 1,
	
    },
    'IsNamedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Names' => {
	to_link => 1, from_link => 1,
	
    },
    'IsOwnerOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsOwnedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'IsProposedLocationOf' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'HasProposedLocationIn' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'IsProteinFor' => {
	to_link => 1, from_link => 1,
	
    },
    'Produces' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRealLocationOf' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'HasRealLocationIn' => {
	to_link => 1, from_link => 1,
		    'type' => 1,
	
    },
    'IsRegulatedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRegulatedSetOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRelevantFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRelevantTo' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRequiredBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Requires' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRoleOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasRole' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRowOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsRoleFor' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSequenceOf' => {
	to_link => 1, from_link => 1,
	
    },
    'HasAsSequence' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSubInstanceOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Validates' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSuperclassOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsSubclassOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsTargetOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Targets' => {
	to_link => 1, from_link => 1,
	
    },
    'IsTaxonomyOf' => {
	to_link => 1, from_link => 1,
	
    },
    'IsInTaxa' => {
	to_link => 1, from_link => 1,
	
    },
    'IsTerminusFor' => {
	to_link => 1, from_link => 1,
		    'group_number' => 1,
	
    },
    'HasAsTerminus' => {
	to_link => 1, from_link => 1,
		    'group_number' => 1,
	
    },
    'IsTriggeredBy' => {
	to_link => 1, from_link => 1,
		    'optional' => 1,
		    'type' => 1,
	
    },
    'Triggers' => {
	to_link => 1, from_link => 1,
		    'optional' => 1,
		    'type' => 1,
	
    },
    'IsUsedAs' => {
	to_link => 1, from_link => 1,
	
    },
    'IsUseOf' => {
	to_link => 1, from_link => 1,
	
    },
    'Manages' => {
	to_link => 1, from_link => 1,
	
    },
    'IsManagedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'OperatesIn' => {
	to_link => 1, from_link => 1,
	
    },
    'IsUtilizedIn' => {
	to_link => 1, from_link => 1,
	
    },
    'Overlaps' => {
	to_link => 1, from_link => 1,
	
    },
    'IncludesPartOf' => {
	to_link => 1, from_link => 1,
	
    },
    'ParticipatesAs' => {
	to_link => 1, from_link => 1,
	
    },
    'IsParticipationOf' => {
	to_link => 1, from_link => 1,
	
    },
    'ProducedResultsFor' => {
	to_link => 1, from_link => 1,
	
    },
    'HadResultsProducedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'ProjectsOnto' => {
	to_link => 1, from_link => 1,
		    'gene_context' => 1,
		    'percent_identity' => 1,
		    'score' => 1,
	
    },
    'IsProjectedOnto' => {
	to_link => 1, from_link => 1,
		    'gene_context' => 1,
		    'percent_identity' => 1,
		    'score' => 1,
	
    },
    'Provided' => {
	to_link => 1, from_link => 1,
	
    },
    'WasProvidedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Shows' => {
	to_link => 1, from_link => 1,
		    'location' => 1,
	
    },
    'IsShownOn' => {
	to_link => 1, from_link => 1,
		    'location' => 1,
	
    },
    'Submitted' => {
	to_link => 1, from_link => 1,
	
    },
    'WasSubmittedBy' => {
	to_link => 1, from_link => 1,
	
    },
    'Uses' => {
	to_link => 1, from_link => 1,
	
    },
    'IsUsedBy' => {
	to_link => 1, from_link => 1,
	
    },

};

our $relationship_field_rels = {
    'AffectsLevelOf' => {
    },
    'IsAffectedIn' => {
    },
    'Aligns' => {
    },
    'IsAlignedBy' => {
    },
    'Concerns' => {
    },
    'IsATopicOf' => {
    },
    'Contains' => {
    },
    'IsContainedIn' => {
    },
    'Controls' => {
    },
    'IsControlledUsing' => {
    },
    'Describes' => {
    },
    'IsDescribedBy' => {
    },
    'Displays' => {
    },
    'IsDisplayedOn' => {
    },
    'Encompasses' => {
    },
    'IsEncompassedIn' => {
    },
    'Formulated' => {
    },
    'WasFormulatedBy' => {
    },
    'GeneratedLevelsFor' => {
    },
    'WasGeneratedFrom' => {
    },
    'HasAssertionFrom' => {
    },
    'Asserts' => {
    },
    'HasCompoundAliasFrom' => {
    },
    'UsesAliasForCompound' => {
    },
    'HasIndicatedSignalFrom' => {
    },
    'IndicatesSignalFor' => {
    },
    'HasMember' => {
    },
    'IsMemberOf' => {
    },
    'HasParticipant' => {
    },
    'ParticipatesIn' => {
    },
    'HasPresenceOf' => {
    },
    'IsPresentIn' => {
    },
    'HasReactionAliasFrom' => {
    },
    'UsesAliasForReaction' => {
    },
    'HasRepresentativeOf' => {
    },
    'IsRepresentedIn' => {
    },
    'HasResultsIn' => {
    },
    'HasResultsFor' => {
    },
    'HasSection' => {
    },
    'IsSectionOf' => {
    },
    'HasStep' => {
    },
    'IsStepOf' => {
    },
    'HasUsage' => {
    },
    'IsUsageOf' => {
    },
    'HasValueFor' => {
    },
    'HasValueIn' => {
    },
    'Imported' => {
    },
    'WasImportedFrom' => {
    },
    'Includes' => {
    },
    'IsIncludedIn' => {
    },
    'IndicatedLevelsFor' => {
    },
    'HasLevelsFrom' => {
    },
    'Involves' => {
    },
    'IsInvolvedIn' => {
    },
    'IsARequirementIn' => {
    },
    'IsARequirementOf' => {
    },
    'IsAlignedIn' => {
    },
    'IsAlignmentFor' => {
    },
    'IsAnnotatedBy' => {
    },
    'Annotates' => {
    },
    'IsBindingSiteFor' => {
    },
    'IsBoundBy' => {
    },
    'IsClassFor' => {
    },
    'IsInClass' => {
    },
    'IsCollectionOf' => {
    },
    'IsCollectedInto' => {
    },
    'IsComposedOf' => {
    },
    'IsComponentOf' => {
    },
    'IsComprisedOf' => {
    },
    'Comprises' => {
    },
    'IsConfiguredBy' => {
    },
    'ReflectsStateOf' => {
    },
    'IsConsistentWith' => {
    },
    'IsConsistentTo' => {
    },
    'IsCoregulatedWith' => {
    },
    'HasCoregulationWith' => {
    },
    'IsCoupledTo' => {
    },
    'IsCoupledWith' => {
    },
    'IsDefaultFor' => {
    },
    'RunsByDefaultIn' => {
    },
    'IsDefaultLocationOf' => {
    },
    'HasDefaultLocation' => {
    },
    'IsDeterminedBy' => {
    },
    'Determines' => {
    },
    'IsDividedInto' => {
    },
    'IsDivisionOf' => {
    },
    'IsExemplarOf' => {
    },
    'HasAsExemplar' => {
    },
    'IsFamilyFor' => {
    },
    'DeterminesFunctionOf' => {
    },
    'IsFormedOf' => {
    },
    'IsFormedInto' => {
    },
    'IsFunctionalIn' => {
    },
    'HasFunctional' => {
    },
    'IsGroupFor' => {
    },
    'IsInGroup' => {
    },
    'IsImplementedBy' => {
    },
    'Implements' => {
    },
    'IsInPair' => {
    },
    'IsPairOf' => {
    },
    'IsInstantiatedBy' => {
    },
    'IsInstanceOf' => {
    },
    'IsLocatedIn' => {
    },
    'IsLocusFor' => {
    },
    'IsModeledBy' => {
    },
    'Models' => {
    },
    'IsNamedBy' => {
    },
    'Names' => {
    },
    'IsOwnerOf' => {
    },
    'IsOwnedBy' => {
    },
    'IsProposedLocationOf' => {
    },
    'HasProposedLocationIn' => {
    },
    'IsProteinFor' => {
    },
    'Produces' => {
    },
    'IsRealLocationOf' => {
    },
    'HasRealLocationIn' => {
    },
    'IsRegulatedIn' => {
    },
    'IsRegulatedSetOf' => {
    },
    'IsRelevantFor' => {
    },
    'IsRelevantTo' => {
    },
    'IsRequiredBy' => {
    },
    'Requires' => {
    },
    'IsRoleOf' => {
    },
    'HasRole' => {
    },
    'IsRowOf' => {
    },
    'IsRoleFor' => {
    },
    'IsSequenceOf' => {
    },
    'HasAsSequence' => {
    },
    'IsSubInstanceOf' => {
    },
    'Validates' => {
    },
    'IsSuperclassOf' => {
    },
    'IsSubclassOf' => {
    },
    'IsTargetOf' => {
    },
    'Targets' => {
    },
    'IsTaxonomyOf' => {
    },
    'IsInTaxa' => {
    },
    'IsTerminusFor' => {
    },
    'HasAsTerminus' => {
    },
    'IsTriggeredBy' => {
    },
    'Triggers' => {
    },
    'IsUsedAs' => {
    },
    'IsUseOf' => {
    },
    'Manages' => {
    },
    'IsManagedBy' => {
    },
    'OperatesIn' => {
    },
    'IsUtilizedIn' => {
    },
    'Overlaps' => {
    },
    'IncludesPartOf' => {
    },
    'ParticipatesAs' => {
    },
    'IsParticipationOf' => {
    },
    'ProducedResultsFor' => {
    },
    'HadResultsProducedBy' => {
    },
    'ProjectsOnto' => {
    },
    'IsProjectedOnto' => {
    },
    'Provided' => {
    },
    'WasProvidedBy' => {
    },
    'Shows' => {
    },
    'IsShownOn' => {
    },
    'Submitted' => {
    },
    'WasSubmittedBy' => {
    },
    'Uses' => {
    },
    'IsUsedBy' => {
    },

};

our $relationship_entities = {
    'AffectsLevelOf' => [ 'Experiment', 'AtomicRegulon' ],
    'IsAffectedIn' => [ 'AtomicRegulon', 'Experiment' ],
    'Aligns' => [ 'AlignmentTree', 'ProteinSequence' ],
    'IsAlignedBy' => [ 'ProteinSequence', 'AlignmentTree' ],
    'Concerns' => [ 'Publication', 'ProteinSequence' ],
    'IsATopicOf' => [ 'ProteinSequence', 'Publication' ],
    'Contains' => [ 'SSCell', 'Feature' ],
    'IsContainedIn' => [ 'Feature', 'SSCell' ],
    'Controls' => [ 'Feature', 'CoregulatedSet' ],
    'IsControlledUsing' => [ 'CoregulatedSet', 'Feature' ],
    'Describes' => [ 'Subsystem', 'Variant' ],
    'IsDescribedBy' => [ 'Variant', 'Subsystem' ],
    'Displays' => [ 'Diagram', 'Reaction' ],
    'IsDisplayedOn' => [ 'Reaction', 'Diagram' ],
    'Encompasses' => [ 'Feature', 'Feature' ],
    'IsEncompassedIn' => [ 'Feature', 'Feature' ],
    'Formulated' => [ 'Source', 'CoregulatedSet' ],
    'WasFormulatedBy' => [ 'CoregulatedSet', 'Source' ],
    'GeneratedLevelsFor' => [ 'ProbeSet', 'AtomicRegulon' ],
    'WasGeneratedFrom' => [ 'AtomicRegulon', 'ProbeSet' ],
    'HasAssertionFrom' => [ 'Identifier', 'Source' ],
    'Asserts' => [ 'Source', 'Identifier' ],
    'HasCompoundAliasFrom' => [ 'Source', 'Compound' ],
    'UsesAliasForCompound' => [ 'Compound', 'Source' ],
    'HasIndicatedSignalFrom' => [ 'Feature', 'Experiment' ],
    'IndicatesSignalFor' => [ 'Experiment', 'Feature' ],
    'HasMember' => [ 'Family', 'Feature' ],
    'IsMemberOf' => [ 'Feature', 'Family' ],
    'HasParticipant' => [ 'Scenario', 'Reaction' ],
    'ParticipatesIn' => [ 'Reaction', 'Scenario' ],
    'HasPresenceOf' => [ 'Media', 'Compound' ],
    'IsPresentIn' => [ 'Compound', 'Media' ],
    'HasReactionAliasFrom' => [ 'Source', 'Reaction' ],
    'UsesAliasForReaction' => [ 'Reaction', 'Source' ],
    'HasRepresentativeOf' => [ 'Genome', 'Family' ],
    'IsRepresentedIn' => [ 'Family', 'Genome' ],
    'HasResultsIn' => [ 'ProbeSet', 'Experiment' ],
    'HasResultsFor' => [ 'Experiment', 'ProbeSet' ],
    'HasSection' => [ 'ContigSequence', 'ContigChunk' ],
    'IsSectionOf' => [ 'ContigChunk', 'ContigSequence' ],
    'HasStep' => [ 'Complex', 'ReactionRule' ],
    'IsStepOf' => [ 'ReactionRule', 'Complex' ],
    'HasUsage' => [ 'Compound', 'BiomassCompound' ],
    'IsUsageOf' => [ 'BiomassCompound', 'Compound' ],
    'HasValueFor' => [ 'Experiment', 'Attribute' ],
    'HasValueIn' => [ 'Attribute', 'Experiment' ],
    'Imported' => [ 'Source', 'Identifier' ],
    'WasImportedFrom' => [ 'Identifier', 'Source' ],
    'Includes' => [ 'Subsystem', 'Role' ],
    'IsIncludedIn' => [ 'Role', 'Subsystem' ],
    'IndicatedLevelsFor' => [ 'ProbeSet', 'Feature' ],
    'HasLevelsFrom' => [ 'Feature', 'ProbeSet' ],
    'Involves' => [ 'Reaction', 'Reagent' ],
    'IsInvolvedIn' => [ 'Reagent', 'Reaction' ],
    'IsARequirementIn' => [ 'Model', 'Requirement' ],
    'IsARequirementOf' => [ 'Requirement', 'Model' ],
    'IsAlignedIn' => [ 'Contig', 'Variation' ],
    'IsAlignmentFor' => [ 'Variation', 'Contig' ],
    'IsAnnotatedBy' => [ 'Feature', 'Annotation' ],
    'Annotates' => [ 'Annotation', 'Feature' ],
    'IsBindingSiteFor' => [ 'Feature', 'CoregulatedSet' ],
    'IsBoundBy' => [ 'CoregulatedSet', 'Feature' ],
    'IsClassFor' => [ 'SubsystemClass', 'Subsystem' ],
    'IsInClass' => [ 'Subsystem', 'SubsystemClass' ],
    'IsCollectionOf' => [ 'OTU', 'Genome' ],
    'IsCollectedInto' => [ 'Genome', 'OTU' ],
    'IsComposedOf' => [ 'Genome', 'Contig' ],
    'IsComponentOf' => [ 'Contig', 'Genome' ],
    'IsComprisedOf' => [ 'Biomass', 'BiomassCompound' ],
    'Comprises' => [ 'BiomassCompound', 'Biomass' ],
    'IsConfiguredBy' => [ 'Genome', 'AtomicRegulon' ],
    'ReflectsStateOf' => [ 'AtomicRegulon', 'Genome' ],
    'IsConsistentWith' => [ 'EcNumber', 'Role' ],
    'IsConsistentTo' => [ 'Role', 'EcNumber' ],
    'IsCoregulatedWith' => [ 'Feature', 'Feature' ],
    'HasCoregulationWith' => [ 'Feature', 'Feature' ],
    'IsCoupledTo' => [ 'Family', 'Family' ],
    'IsCoupledWith' => [ 'Family', 'Family' ],
    'IsDefaultFor' => [ 'Compartment', 'Reaction' ],
    'RunsByDefaultIn' => [ 'Reaction', 'Compartment' ],
    'IsDefaultLocationOf' => [ 'Compartment', 'Reagent' ],
    'HasDefaultLocation' => [ 'Reagent', 'Compartment' ],
    'IsDeterminedBy' => [ 'PairSet', 'Pairing' ],
    'Determines' => [ 'Pairing', 'PairSet' ],
    'IsDividedInto' => [ 'Model', 'ModelCompartment' ],
    'IsDivisionOf' => [ 'ModelCompartment', 'Model' ],
    'IsExemplarOf' => [ 'Feature', 'Role' ],
    'HasAsExemplar' => [ 'Role', 'Feature' ],
    'IsFamilyFor' => [ 'Family', 'Role' ],
    'DeterminesFunctionOf' => [ 'Role', 'Family' ],
    'IsFormedOf' => [ 'AtomicRegulon', 'Feature' ],
    'IsFormedInto' => [ 'Feature', 'AtomicRegulon' ],
    'IsFunctionalIn' => [ 'Role', 'Feature' ],
    'HasFunctional' => [ 'Feature', 'Role' ],
    'IsGroupFor' => [ 'TaxonomicGrouping', 'TaxonomicGrouping' ],
    'IsInGroup' => [ 'TaxonomicGrouping', 'TaxonomicGrouping' ],
    'IsImplementedBy' => [ 'Variant', 'SSRow' ],
    'Implements' => [ 'SSRow', 'Variant' ],
    'IsInPair' => [ 'Feature', 'Pairing' ],
    'IsPairOf' => [ 'Pairing', 'Feature' ],
    'IsInstantiatedBy' => [ 'Compartment', 'ModelCompartment' ],
    'IsInstanceOf' => [ 'ModelCompartment', 'Compartment' ],
    'IsLocatedIn' => [ 'Feature', 'Contig' ],
    'IsLocusFor' => [ 'Contig', 'Feature' ],
    'IsModeledBy' => [ 'Genome', 'Model' ],
    'Models' => [ 'Model', 'Genome' ],
    'IsNamedBy' => [ 'ProteinSequence', 'Identifier' ],
    'Names' => [ 'Identifier', 'ProteinSequence' ],
    'IsOwnerOf' => [ 'Genome', 'Feature' ],
    'IsOwnedBy' => [ 'Feature', 'Genome' ],
    'IsProposedLocationOf' => [ 'Compartment', 'ReactionRule' ],
    'HasProposedLocationIn' => [ 'ReactionRule', 'Compartment' ],
    'IsProteinFor' => [ 'ProteinSequence', 'Feature' ],
    'Produces' => [ 'Feature', 'ProteinSequence' ],
    'IsRealLocationOf' => [ 'ModelCompartment', 'Requirement' ],
    'HasRealLocationIn' => [ 'Requirement', 'ModelCompartment' ],
    'IsRegulatedIn' => [ 'Feature', 'CoregulatedSet' ],
    'IsRegulatedSetOf' => [ 'CoregulatedSet', 'Feature' ],
    'IsRelevantFor' => [ 'Diagram', 'Subsystem' ],
    'IsRelevantTo' => [ 'Subsystem', 'Diagram' ],
    'IsRequiredBy' => [ 'Reaction', 'Requirement' ],
    'Requires' => [ 'Requirement', 'Reaction' ],
    'IsRoleOf' => [ 'Role', 'SSCell' ],
    'HasRole' => [ 'SSCell', 'Role' ],
    'IsRowOf' => [ 'SSRow', 'SSCell' ],
    'IsRoleFor' => [ 'SSCell', 'SSRow' ],
    'IsSequenceOf' => [ 'ContigSequence', 'Contig' ],
    'HasAsSequence' => [ 'Contig', 'ContigSequence' ],
    'IsSubInstanceOf' => [ 'Subsystem', 'Scenario' ],
    'Validates' => [ 'Scenario', 'Subsystem' ],
    'IsSuperclassOf' => [ 'SubsystemClass', 'SubsystemClass' ],
    'IsSubclassOf' => [ 'SubsystemClass', 'SubsystemClass' ],
    'IsTargetOf' => [ 'ModelCompartment', 'BiomassCompound' ],
    'Targets' => [ 'BiomassCompound', 'ModelCompartment' ],
    'IsTaxonomyOf' => [ 'TaxonomicGrouping', 'Genome' ],
    'IsInTaxa' => [ 'Genome', 'TaxonomicGrouping' ],
    'IsTerminusFor' => [ 'Compound', 'Scenario' ],
    'HasAsTerminus' => [ 'Scenario', 'Compound' ],
    'IsTriggeredBy' => [ 'Complex', 'Role' ],
    'Triggers' => [ 'Role', 'Complex' ],
    'IsUsedAs' => [ 'Reaction', 'ReactionRule' ],
    'IsUseOf' => [ 'ReactionRule', 'Reaction' ],
    'Manages' => [ 'Model', 'Biomass' ],
    'IsManagedBy' => [ 'Biomass', 'Model' ],
    'OperatesIn' => [ 'Experiment', 'Media' ],
    'IsUtilizedIn' => [ 'Media', 'Experiment' ],
    'Overlaps' => [ 'Scenario', 'Diagram' ],
    'IncludesPartOf' => [ 'Diagram', 'Scenario' ],
    'ParticipatesAs' => [ 'Compound', 'Reagent' ],
    'IsParticipationOf' => [ 'Reagent', 'Compound' ],
    'ProducedResultsFor' => [ 'ProbeSet', 'Genome' ],
    'HadResultsProducedBy' => [ 'Genome', 'ProbeSet' ],
    'ProjectsOnto' => [ 'ProteinSequence', 'ProteinSequence' ],
    'IsProjectedOnto' => [ 'ProteinSequence', 'ProteinSequence' ],
    'Provided' => [ 'Source', 'Subsystem' ],
    'WasProvidedBy' => [ 'Subsystem', 'Source' ],
    'Shows' => [ 'Diagram', 'Compound' ],
    'IsShownOn' => [ 'Compound', 'Diagram' ],
    'Submitted' => [ 'Source', 'Genome' ],
    'WasSubmittedBy' => [ 'Genome', 'Source' ],
    'Uses' => [ 'Genome', 'SSRow' ],
    'IsUsedBy' => [ 'SSRow', 'Genome' ],

};

#sub _init_instance
#{
#    my($self) = @_;
#    $self->{db} = CDMI->new(dbhost => 'seed-db-read', sock => '', DBD => '/home/parrello/FIGdisk/dist/releases/current/WinBuild/KSaplingDBD.xml');
#}

sub _validate_fields_for_entity
{
    my($self, $tbl, $fields, $ensure_id) = @_;

    my $valid_fields = $entity_field_defs->{$tbl};

    my $have_id;

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my @rel_fields;
    my @qfields;
    my @sfields;
    my @bad_fields;
    for my $field (@$fields)
    {
	$field =~ s/-/_/g;
	if (!$valid_fields->{$field})
	{
	    push(@bad_fields, $field);
	    next;
	}
	if (my $rel = $entity_field_rels->{$tbl}->{$field})
	{
	    push(@rel_fields, [$field, $rel]);
	}
	else
	{
	    push(@sfields, $field);
	    my $qfield = $q . $field . $q;
	    $have_id = 1 if $field eq 'id';
	    push(@qfields, $qfield);
	}
    }

    if (@bad_fields)
    {
	die "The following fields are invalid in entity $tbl: @bad_fields";
    }

    if (!$have_id && ($ensure_id || @rel_fields))
    {
	unshift(@sfields, 'id');
	unshift(@qfields, $q . 'id' . $q);
    }

    return(\@sfields, \@qfields, \@rel_fields);
}

sub _validate_fields_for_relationship
{
    my($self, $tbl, $fields, $link_field) = @_;

    my $valid_fields = $relationship_field_defs->{$tbl};

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my $have_id = 0;
    my @qfields;
    my @sfields;
    my @bad_fields;
    for my $field (@$fields)
    {
	$field =~ s/-/_/g;
	if (!$valid_fields->{$field})
	{
	    push(@bad_fields, $field);
	    next;
	}

	$have_id = 1 if $field eq $link_field;
	push(@sfields, $field);
	my $qfield = $q . $field . $q;
	push(@qfields, $qfield);
    }

    if (!$have_id)
    {
	unshift(@sfields, $link_field);
	unshift(@qfields, $q . $link_field . $q);
    }

    if (@bad_fields)
    {
	die "The following fields are invalid in relationship $tbl: @bad_fields";
    }

    return(\@sfields, \@qfields);
}

sub _get_entity
{
    my($self, $ctx, $tbl, $ids, $fields) = @_;

    my($sfields, $qfields, $rel_fields) = $self->_validate_fields_for_entity($tbl, $fields, 1);
    
    my $filter = "id IN (" . join(", ", map { '?' } @$ids) . ")";

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my $qstr = join(", ", @$qfields);
    my $qry = "SELECT $qstr FROM $q$tbl$q WHERE $filter";

    my $attrs = {};
    my $dbk = $cdmi->{_dbh};
    if ($dbk->dbms eq 'mysql')
    {
	$attrs->{mysql_use_result} = 1;
    }

    my $sth = $dbk->{_dbh}->prepare($qry, $attrs);
    
    # print STDERR "$qry\n";
    $sth->execute(@$ids);
    my $out = $sth->fetchall_hashref('id');

    #
    # Now query for the fields that are in separate relations.
    #
    for my $ent (@$rel_fields)
    {
	my($field, $rel) = @$ent;
	my $sth = $dbk->{_dbh}->prepare(qq(SELECT id, $field FROM $rel WHERE $filter));
	$sth->execute(@$ids);
	while (my $row = $sth->fetchrow_arrayref())
	{
	    my($id, $val) = @$row;
	    push(@{$out->{$id}->{$field}}, $val);
	}
    }
    return $out;
}    

sub _get_relationship
{
    my($self, $ctx, $relationship, $table, $is_converse, $ids, $from_fields, $rel_fields, $to_fields) = @_;

    my($from_tbl, $to_tbl) = @{$relationship_entities->{$relationship}};
    if (!$from_tbl)
    {
	die "Unknown relationship $relationship";
    }

    my %link_name_map;
    my($from_link, $to_link);
    if ($is_converse)
    {
	($from_link, $to_link) = qw(to_link from_link);
	%link_name_map = ( from_link => 'to_link', to_link => 'from_link');
    }
    else
    {
	($from_link, $to_link) = qw(from_link to_link);
	%link_name_map = ( from_link => 'from_link', to_link => 'to_link');
    }
    for my $f (@$rel_fields)
    {
	if (!exists $link_name_map{$f})
	{
	    $link_name_map{$f} = $f;
	}
    }

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my($from_sfields, $from_qfields, $from_relfields) = $self->_validate_fields_for_entity($from_tbl, $from_fields, 0);
    my($to_sfields, $to_qfields, $to_relfields) = $self->_validate_fields_for_entity($to_tbl, $to_fields, 0);

    my @trans_rel_fields = map { $link_name_map{$_} } @$rel_fields;
    my($rel_sfields, $rel_qfields) = $self->_validate_fields_for_relationship($relationship, \@trans_rel_fields, $from_link);
    
    my $filter = "$from_link IN (" . join(", ", map { '?' } @$ids) . ")";

    my $from = "$q$table$q r ";
    if (@$from_qfields)
    {
	$from .= "JOIN $q$from_tbl$q f ON f.id = r.$from_link ";
    }
    if (@$to_qfields)
    {
	$from .= "JOIN $q$to_tbl$q t ON t.id = r.$to_link ";
    }

    my $qstr = join(", ",
		    (map { "f.$_" } @$from_qfields),
		    (map { "t.$_" }  @$to_qfields),
		    (map { "r.$_" } @$rel_qfields));

    my $qry = "SELECT $qstr FROM $from WHERE $filter";

    my $attrs = {};
    my $dbk = $cdmi->{_dbh};
    if ($dbk->dbms eq 'mysql')
    {
	$attrs->{mysql_use_result} = 1;
    }

    my $sth = $dbk->{_dbh}->prepare($qry, $attrs);
    
    # print STDERR "$qry\n";
    $sth->execute(@$ids);
    my $res = $sth->fetchall_arrayref();

    my $out = [];

    my(%from_keys_for_rel, %to_keys_for_rel);
    for my $ent (@$res)
    {
	my($fout, $rout, $tout) = ({}, {}, {});
	for my $fld (@$from_sfields)
	{
	    my $v = shift @$ent;
	    $fout->{$fld} = $v;
	}
	for my $fld (@$to_sfields)
	{
	    my $v = shift @$ent;
	    $tout->{$fld} = $v;
	}
	for my $fld (@$rel_sfields)
	{
	    my $v = shift @$ent;
	    $rout->{$link_name_map{$fld}} = $v;
	}
	my $row = [$fout, $rout, $tout];

	if (@$from_relfields)
	{
	    push(@{$from_keys_for_rel{$fout->{id}}}, $row);
	}

	if (@$to_relfields)
	{
	    push(@{$to_keys_for_rel{$tout->{id}}}, $row);
	}

	push(@$out, $row);
    }

    if (@$from_relfields)
    {
	my %ids = keys %from_keys_for_rel;
	my @ids = keys %ids;

	my $filter = "id IN (" . join(", ", map { '?' } @ids) . ")";

	for my $ent (@$from_relfields)
	{
	    my($field, $rel) = @$ent;
	    
	    my $sth = $dbk->{_dbh}->prepare(qq(SELECT id, $field FROM $rel WHERE $filter));
	    $sth->execute(@ids);
	    while (my $row = $sth->fetchrow_arrayref())
	    {
		my($id, $val) = @$row;

		for my $row (@{$from_keys_for_rel{$id}})
		{
		    push(@{$row->[0]->{$field}}, $val);
		}
	    }
	}
    }

    if (@$to_relfields)
    {
	my %ids = keys %to_keys_for_rel;
	my @ids = keys %ids;

	my $filter = "id IN (" . join(", ", map { '?' } @ids) . ")";

	for my $ent (@$to_relfields)
	{
	    my($field, $rel) = @$ent;
	    
	    my $sth = $dbk->{_dbh}->prepare(qq(SELECT id, $field FROM $rel WHERE $filter));
	    $sth->execute(@ids);
	    while (my $row = $sth->fetchrow_arrayref())
	    {
		my($id, $val) = @$row;

		for my $row (@{$to_keys_for_rel{$id}})
		{
		    push(@{$row->[2]->{$field}}, $val);
		}
	    }
	}
    }


    return $out;
}    

sub _all_entities
{
    my($self, $ctx, $tbl, $start, $count, $fields) = @_;

    my($sfields, $qfields, $rel_fields) = $self->_validate_fields_for_entity($tbl, $fields, 1);

    my $cdmi = $self->{db};
    my $q = $cdmi->{_dbh}->quote;

    my $qstr = join(", ", @$qfields);

    my $attrs = {};
    my $dbk = $cdmi->{_dbh};
    my $limit;
    
    if ($dbk->dbms eq 'mysql')
    {
	$attrs->{mysql_use_result} = 1;
	$limit = "LIMIT $start, $count";
    }
    elsif ($dbk->dbms eq 'Pg')
    {
	$limit = "ORDER BY id LIMIT $count OFFSET $start";
    }

    my $qry = "SELECT $qstr FROM $q$tbl$q $limit";

    my $sth = $dbk->{_dbh}->prepare($qry, $attrs);
    
    # print STDERR "$qry\n";
    $sth->execute();
    my $out = $sth->fetchall_hashref('id');

    #
    # Now query for the fields that are in separate relations.
    #
    my @ids = keys %$out;
    if (@ids)
    {
	my $filter = "id IN (" . join(", ", map { '?' } @ids) . ")";
	
	for my $ent (@$rel_fields)
	{
	    my($field, $rel) = @$ent;
	    
	    my $sth = $dbk->{_dbh}->prepare(qq(SELECT id, $field FROM $rel WHERE $filter));
	    $sth->execute(@ids);
	    while (my $row = $sth->fetchrow_arrayref())
	    {
		my($id, $val) = @$row;
		push(@{$out->{$id}->{$field}}, $val);
	    }
	}
    }

    return $out;
}    

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

    my($cdmi) = @args;
    if (! $cdmi) {
	$cdmi = CDMI->new();
    }
    $self->{db} = $cdmi;

    #END_CONSTRUCTOR
    
    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}



sub get_entity_AlignmentTree
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_AlignmentTree

    $return = $self->_get_entity($ctx, 'AlignmentTree', $ids, $fields);

    #END get_entity_AlignmentTree
    return $return;
}

sub all_entities_AlignmentTree
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_AlignmentTree

    $return = $self->_all_entities($ctx, 'AlignmentTree', $start, $count, $fields);

    #END all_entities_AlignmentTree
    return $return;
}


sub get_entity_Annotation
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Annotation

    $return = $self->_get_entity($ctx, 'Annotation', $ids, $fields);

    #END get_entity_Annotation
    return $return;
}

sub all_entities_Annotation
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Annotation

    $return = $self->_all_entities($ctx, 'Annotation', $start, $count, $fields);

    #END all_entities_Annotation
    return $return;
}


sub get_entity_AtomicRegulon
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_AtomicRegulon

    $return = $self->_get_entity($ctx, 'AtomicRegulon', $ids, $fields);

    #END get_entity_AtomicRegulon
    return $return;
}

sub all_entities_AtomicRegulon
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_AtomicRegulon

    $return = $self->_all_entities($ctx, 'AtomicRegulon', $start, $count, $fields);

    #END all_entities_AtomicRegulon
    return $return;
}


sub get_entity_Attribute
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Attribute

    $return = $self->_get_entity($ctx, 'Attribute', $ids, $fields);

    #END get_entity_Attribute
    return $return;
}

sub all_entities_Attribute
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Attribute

    $return = $self->_all_entities($ctx, 'Attribute', $start, $count, $fields);

    #END all_entities_Attribute
    return $return;
}


sub get_entity_Biomass
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Biomass

    $return = $self->_get_entity($ctx, 'Biomass', $ids, $fields);

    #END get_entity_Biomass
    return $return;
}

sub all_entities_Biomass
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Biomass

    $return = $self->_all_entities($ctx, 'Biomass', $start, $count, $fields);

    #END all_entities_Biomass
    return $return;
}


sub get_entity_BiomassCompound
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_BiomassCompound

    $return = $self->_get_entity($ctx, 'BiomassCompound', $ids, $fields);

    #END get_entity_BiomassCompound
    return $return;
}

sub all_entities_BiomassCompound
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_BiomassCompound

    $return = $self->_all_entities($ctx, 'BiomassCompound', $start, $count, $fields);

    #END all_entities_BiomassCompound
    return $return;
}


sub get_entity_Compartment
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Compartment

    $return = $self->_get_entity($ctx, 'Compartment', $ids, $fields);

    #END get_entity_Compartment
    return $return;
}

sub all_entities_Compartment
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Compartment

    $return = $self->_all_entities($ctx, 'Compartment', $start, $count, $fields);

    #END all_entities_Compartment
    return $return;
}


sub get_entity_Complex
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Complex

    $return = $self->_get_entity($ctx, 'Complex', $ids, $fields);

    #END get_entity_Complex
    return $return;
}

sub all_entities_Complex
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Complex

    $return = $self->_all_entities($ctx, 'Complex', $start, $count, $fields);

    #END all_entities_Complex
    return $return;
}


sub get_entity_Compound
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Compound

    $return = $self->_get_entity($ctx, 'Compound', $ids, $fields);

    #END get_entity_Compound
    return $return;
}

sub all_entities_Compound
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Compound

    $return = $self->_all_entities($ctx, 'Compound', $start, $count, $fields);

    #END all_entities_Compound
    return $return;
}


sub get_entity_Contig
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Contig

    $return = $self->_get_entity($ctx, 'Contig', $ids, $fields);

    #END get_entity_Contig
    return $return;
}

sub all_entities_Contig
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Contig

    $return = $self->_all_entities($ctx, 'Contig', $start, $count, $fields);

    #END all_entities_Contig
    return $return;
}


sub get_entity_ContigChunk
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_ContigChunk

    $return = $self->_get_entity($ctx, 'ContigChunk', $ids, $fields);

    #END get_entity_ContigChunk
    return $return;
}

sub all_entities_ContigChunk
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_ContigChunk

    $return = $self->_all_entities($ctx, 'ContigChunk', $start, $count, $fields);

    #END all_entities_ContigChunk
    return $return;
}


sub get_entity_ContigSequence
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_ContigSequence

    $return = $self->_get_entity($ctx, 'ContigSequence', $ids, $fields);

    #END get_entity_ContigSequence
    return $return;
}

sub all_entities_ContigSequence
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_ContigSequence

    $return = $self->_all_entities($ctx, 'ContigSequence', $start, $count, $fields);

    #END all_entities_ContigSequence
    return $return;
}


sub get_entity_CoregulatedSet
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_CoregulatedSet

    $return = $self->_get_entity($ctx, 'CoregulatedSet', $ids, $fields);

    #END get_entity_CoregulatedSet
    return $return;
}

sub all_entities_CoregulatedSet
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_CoregulatedSet

    $return = $self->_all_entities($ctx, 'CoregulatedSet', $start, $count, $fields);

    #END all_entities_CoregulatedSet
    return $return;
}


sub get_entity_Diagram
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Diagram

    $return = $self->_get_entity($ctx, 'Diagram', $ids, $fields);

    #END get_entity_Diagram
    return $return;
}

sub all_entities_Diagram
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Diagram

    $return = $self->_all_entities($ctx, 'Diagram', $start, $count, $fields);

    #END all_entities_Diagram
    return $return;
}


sub get_entity_EcNumber
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_EcNumber

    $return = $self->_get_entity($ctx, 'EcNumber', $ids, $fields);

    #END get_entity_EcNumber
    return $return;
}

sub all_entities_EcNumber
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_EcNumber

    $return = $self->_all_entities($ctx, 'EcNumber', $start, $count, $fields);

    #END all_entities_EcNumber
    return $return;
}


sub get_entity_Experiment
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Experiment

    $return = $self->_get_entity($ctx, 'Experiment', $ids, $fields);

    #END get_entity_Experiment
    return $return;
}

sub all_entities_Experiment
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Experiment

    $return = $self->_all_entities($ctx, 'Experiment', $start, $count, $fields);

    #END all_entities_Experiment
    return $return;
}


sub get_entity_Family
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Family

    $return = $self->_get_entity($ctx, 'Family', $ids, $fields);

    #END get_entity_Family
    return $return;
}

sub all_entities_Family
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Family

    $return = $self->_all_entities($ctx, 'Family', $start, $count, $fields);

    #END all_entities_Family
    return $return;
}


sub get_entity_Feature
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Feature

    $return = $self->_get_entity($ctx, 'Feature', $ids, $fields);

    #END get_entity_Feature
    return $return;
}

sub all_entities_Feature
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Feature

    $return = $self->_all_entities($ctx, 'Feature', $start, $count, $fields);

    #END all_entities_Feature
    return $return;
}


sub get_entity_Genome
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Genome

    $return = $self->_get_entity($ctx, 'Genome', $ids, $fields);

    #END get_entity_Genome
    return $return;
}

sub all_entities_Genome
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Genome

    $return = $self->_all_entities($ctx, 'Genome', $start, $count, $fields);

    #END all_entities_Genome
    return $return;
}


sub get_entity_Identifier
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Identifier

    $return = $self->_get_entity($ctx, 'Identifier', $ids, $fields);

    #END get_entity_Identifier
    return $return;
}

sub all_entities_Identifier
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Identifier

    $return = $self->_all_entities($ctx, 'Identifier', $start, $count, $fields);

    #END all_entities_Identifier
    return $return;
}


sub get_entity_Media
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Media

    $return = $self->_get_entity($ctx, 'Media', $ids, $fields);

    #END get_entity_Media
    return $return;
}

sub all_entities_Media
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Media

    $return = $self->_all_entities($ctx, 'Media', $start, $count, $fields);

    #END all_entities_Media
    return $return;
}


sub get_entity_Model
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Model

    $return = $self->_get_entity($ctx, 'Model', $ids, $fields);

    #END get_entity_Model
    return $return;
}

sub all_entities_Model
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Model

    $return = $self->_all_entities($ctx, 'Model', $start, $count, $fields);

    #END all_entities_Model
    return $return;
}


sub get_entity_ModelCompartment
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_ModelCompartment

    $return = $self->_get_entity($ctx, 'ModelCompartment', $ids, $fields);

    #END get_entity_ModelCompartment
    return $return;
}

sub all_entities_ModelCompartment
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_ModelCompartment

    $return = $self->_all_entities($ctx, 'ModelCompartment', $start, $count, $fields);

    #END all_entities_ModelCompartment
    return $return;
}


sub get_entity_OTU
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_OTU

    $return = $self->_get_entity($ctx, 'OTU', $ids, $fields);

    #END get_entity_OTU
    return $return;
}

sub all_entities_OTU
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_OTU

    $return = $self->_all_entities($ctx, 'OTU', $start, $count, $fields);

    #END all_entities_OTU
    return $return;
}


sub get_entity_PairSet
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_PairSet

    $return = $self->_get_entity($ctx, 'PairSet', $ids, $fields);

    #END get_entity_PairSet
    return $return;
}

sub all_entities_PairSet
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_PairSet

    $return = $self->_all_entities($ctx, 'PairSet', $start, $count, $fields);

    #END all_entities_PairSet
    return $return;
}


sub get_entity_Pairing
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Pairing

    $return = $self->_get_entity($ctx, 'Pairing', $ids, $fields);

    #END get_entity_Pairing
    return $return;
}

sub all_entities_Pairing
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Pairing

    $return = $self->_all_entities($ctx, 'Pairing', $start, $count, $fields);

    #END all_entities_Pairing
    return $return;
}


sub get_entity_ProbeSet
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_ProbeSet

    $return = $self->_get_entity($ctx, 'ProbeSet', $ids, $fields);

    #END get_entity_ProbeSet
    return $return;
}

sub all_entities_ProbeSet
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_ProbeSet

    $return = $self->_all_entities($ctx, 'ProbeSet', $start, $count, $fields);

    #END all_entities_ProbeSet
    return $return;
}


sub get_entity_ProteinSequence
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_ProteinSequence

    $return = $self->_get_entity($ctx, 'ProteinSequence', $ids, $fields);

    #END get_entity_ProteinSequence
    return $return;
}

sub all_entities_ProteinSequence
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_ProteinSequence

    $return = $self->_all_entities($ctx, 'ProteinSequence', $start, $count, $fields);

    #END all_entities_ProteinSequence
    return $return;
}


sub get_entity_Publication
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Publication

    $return = $self->_get_entity($ctx, 'Publication', $ids, $fields);

    #END get_entity_Publication
    return $return;
}

sub all_entities_Publication
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Publication

    $return = $self->_all_entities($ctx, 'Publication', $start, $count, $fields);

    #END all_entities_Publication
    return $return;
}


sub get_entity_Reaction
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Reaction

    $return = $self->_get_entity($ctx, 'Reaction', $ids, $fields);

    #END get_entity_Reaction
    return $return;
}

sub all_entities_Reaction
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Reaction

    $return = $self->_all_entities($ctx, 'Reaction', $start, $count, $fields);

    #END all_entities_Reaction
    return $return;
}


sub get_entity_ReactionRule
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_ReactionRule

    $return = $self->_get_entity($ctx, 'ReactionRule', $ids, $fields);

    #END get_entity_ReactionRule
    return $return;
}

sub all_entities_ReactionRule
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_ReactionRule

    $return = $self->_all_entities($ctx, 'ReactionRule', $start, $count, $fields);

    #END all_entities_ReactionRule
    return $return;
}


sub get_entity_Reagent
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Reagent

    $return = $self->_get_entity($ctx, 'Reagent', $ids, $fields);

    #END get_entity_Reagent
    return $return;
}

sub all_entities_Reagent
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Reagent

    $return = $self->_all_entities($ctx, 'Reagent', $start, $count, $fields);

    #END all_entities_Reagent
    return $return;
}


sub get_entity_Requirement
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Requirement

    $return = $self->_get_entity($ctx, 'Requirement', $ids, $fields);

    #END get_entity_Requirement
    return $return;
}

sub all_entities_Requirement
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Requirement

    $return = $self->_all_entities($ctx, 'Requirement', $start, $count, $fields);

    #END all_entities_Requirement
    return $return;
}


sub get_entity_Role
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Role

    $return = $self->_get_entity($ctx, 'Role', $ids, $fields);

    #END get_entity_Role
    return $return;
}

sub all_entities_Role
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Role

    $return = $self->_all_entities($ctx, 'Role', $start, $count, $fields);

    #END all_entities_Role
    return $return;
}


sub get_entity_SSCell
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_SSCell

    $return = $self->_get_entity($ctx, 'SSCell', $ids, $fields);

    #END get_entity_SSCell
    return $return;
}

sub all_entities_SSCell
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_SSCell

    $return = $self->_all_entities($ctx, 'SSCell', $start, $count, $fields);

    #END all_entities_SSCell
    return $return;
}


sub get_entity_SSRow
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_SSRow

    $return = $self->_get_entity($ctx, 'SSRow', $ids, $fields);

    #END get_entity_SSRow
    return $return;
}

sub all_entities_SSRow
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_SSRow

    $return = $self->_all_entities($ctx, 'SSRow', $start, $count, $fields);

    #END all_entities_SSRow
    return $return;
}


sub get_entity_Scenario
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Scenario

    $return = $self->_get_entity($ctx, 'Scenario', $ids, $fields);

    #END get_entity_Scenario
    return $return;
}

sub all_entities_Scenario
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Scenario

    $return = $self->_all_entities($ctx, 'Scenario', $start, $count, $fields);

    #END all_entities_Scenario
    return $return;
}


sub get_entity_Source
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Source

    $return = $self->_get_entity($ctx, 'Source', $ids, $fields);

    #END get_entity_Source
    return $return;
}

sub all_entities_Source
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Source

    $return = $self->_all_entities($ctx, 'Source', $start, $count, $fields);

    #END all_entities_Source
    return $return;
}


sub get_entity_Subsystem
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Subsystem

    $return = $self->_get_entity($ctx, 'Subsystem', $ids, $fields);

    #END get_entity_Subsystem
    return $return;
}

sub all_entities_Subsystem
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Subsystem

    $return = $self->_all_entities($ctx, 'Subsystem', $start, $count, $fields);

    #END all_entities_Subsystem
    return $return;
}


sub get_entity_SubsystemClass
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_SubsystemClass

    $return = $self->_get_entity($ctx, 'SubsystemClass', $ids, $fields);

    #END get_entity_SubsystemClass
    return $return;
}

sub all_entities_SubsystemClass
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_SubsystemClass

    $return = $self->_all_entities($ctx, 'SubsystemClass', $start, $count, $fields);

    #END all_entities_SubsystemClass
    return $return;
}


sub get_entity_TaxonomicGrouping
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_TaxonomicGrouping

    $return = $self->_get_entity($ctx, 'TaxonomicGrouping', $ids, $fields);

    #END get_entity_TaxonomicGrouping
    return $return;
}

sub all_entities_TaxonomicGrouping
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_TaxonomicGrouping

    $return = $self->_all_entities($ctx, 'TaxonomicGrouping', $start, $count, $fields);

    #END all_entities_TaxonomicGrouping
    return $return;
}


sub get_entity_Variant
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Variant

    $return = $self->_get_entity($ctx, 'Variant', $ids, $fields);

    #END get_entity_Variant
    return $return;
}

sub all_entities_Variant
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Variant

    $return = $self->_all_entities($ctx, 'Variant', $start, $count, $fields);

    #END all_entities_Variant
    return $return;
}


sub get_entity_Variation
{
    my($self, $ctx, $ids, $fields) = @_;

    my $return;
    #BEGIN get_entity_Variation

    $return = $self->_get_entity($ctx, 'Variation', $ids, $fields);

    #END get_entity_Variation
    return $return;
}

sub all_entities_Variation
{
    my($self, $ctx, $start, $count, $fields) = @_;

    my $return;
    #BEGIN all_entities_Variation

    $return = $self->_all_entities($ctx, 'Variation', $start, $count, $fields);

    #END all_entities_Variation
    return $return;
}




sub get_relationship_AffectsLevelOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_AffectsLevelOf

    $return = $self->_get_relationship($ctx, 'AffectsLevelOf', 'AffectsLevelOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_AffectsLevelOf
    return $return;
}



sub get_relationship_IsAffectedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsAffectedIn

    $return = $self->_get_relationship($ctx, 'IsAffectedIn', 'AffectsLevelOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAffectedIn
    return $return;
}



sub get_relationship_Aligns
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Aligns

    $return = $self->_get_relationship($ctx, 'Aligns', 'Aligns', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Aligns
    return $return;
}



sub get_relationship_IsAlignedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsAlignedBy

    $return = $self->_get_relationship($ctx, 'IsAlignedBy', 'Aligns', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAlignedBy
    return $return;
}



sub get_relationship_Concerns
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Concerns

    $return = $self->_get_relationship($ctx, 'Concerns', 'Concerns', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Concerns
    return $return;
}



sub get_relationship_IsATopicOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsATopicOf

    $return = $self->_get_relationship($ctx, 'IsATopicOf', 'Concerns', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsATopicOf
    return $return;
}



sub get_relationship_Contains
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Contains

    $return = $self->_get_relationship($ctx, 'Contains', 'Contains', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Contains
    return $return;
}



sub get_relationship_IsContainedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsContainedIn

    $return = $self->_get_relationship($ctx, 'IsContainedIn', 'Contains', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsContainedIn
    return $return;
}



sub get_relationship_Controls
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Controls

    $return = $self->_get_relationship($ctx, 'Controls', 'Controls', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Controls
    return $return;
}



sub get_relationship_IsControlledUsing
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsControlledUsing

    $return = $self->_get_relationship($ctx, 'IsControlledUsing', 'Controls', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsControlledUsing
    return $return;
}



sub get_relationship_Describes
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Describes

    $return = $self->_get_relationship($ctx, 'Describes', 'Describes', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Describes
    return $return;
}



sub get_relationship_IsDescribedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsDescribedBy

    $return = $self->_get_relationship($ctx, 'IsDescribedBy', 'Describes', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDescribedBy
    return $return;
}



sub get_relationship_Displays
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Displays

    $return = $self->_get_relationship($ctx, 'Displays', 'Displays', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Displays
    return $return;
}



sub get_relationship_IsDisplayedOn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsDisplayedOn

    $return = $self->_get_relationship($ctx, 'IsDisplayedOn', 'Displays', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDisplayedOn
    return $return;
}



sub get_relationship_Encompasses
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Encompasses

    $return = $self->_get_relationship($ctx, 'Encompasses', 'Encompasses', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Encompasses
    return $return;
}



sub get_relationship_IsEncompassedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsEncompassedIn

    $return = $self->_get_relationship($ctx, 'IsEncompassedIn', 'Encompasses', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsEncompassedIn
    return $return;
}



sub get_relationship_Formulated
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Formulated

    $return = $self->_get_relationship($ctx, 'Formulated', 'Formulated', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Formulated
    return $return;
}



sub get_relationship_WasFormulatedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_WasFormulatedBy

    $return = $self->_get_relationship($ctx, 'WasFormulatedBy', 'Formulated', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_WasFormulatedBy
    return $return;
}



sub get_relationship_GeneratedLevelsFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_GeneratedLevelsFor

    $return = $self->_get_relationship($ctx, 'GeneratedLevelsFor', 'GeneratedLevelsFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_GeneratedLevelsFor
    return $return;
}



sub get_relationship_WasGeneratedFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_WasGeneratedFrom

    $return = $self->_get_relationship($ctx, 'WasGeneratedFrom', 'GeneratedLevelsFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_WasGeneratedFrom
    return $return;
}



sub get_relationship_HasAssertionFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasAssertionFrom

    $return = $self->_get_relationship($ctx, 'HasAssertionFrom', 'HasAssertionFrom', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasAssertionFrom
    return $return;
}



sub get_relationship_Asserts
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Asserts

    $return = $self->_get_relationship($ctx, 'Asserts', 'HasAssertionFrom', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Asserts
    return $return;
}



sub get_relationship_HasCompoundAliasFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasCompoundAliasFrom

    $return = $self->_get_relationship($ctx, 'HasCompoundAliasFrom', 'HasCompoundAliasFrom', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasCompoundAliasFrom
    return $return;
}



sub get_relationship_UsesAliasForCompound
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_UsesAliasForCompound

    $return = $self->_get_relationship($ctx, 'UsesAliasForCompound', 'HasCompoundAliasFrom', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_UsesAliasForCompound
    return $return;
}



sub get_relationship_HasIndicatedSignalFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasIndicatedSignalFrom

    $return = $self->_get_relationship($ctx, 'HasIndicatedSignalFrom', 'HasIndicatedSignalFrom', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasIndicatedSignalFrom
    return $return;
}



sub get_relationship_IndicatesSignalFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IndicatesSignalFor

    $return = $self->_get_relationship($ctx, 'IndicatesSignalFor', 'HasIndicatedSignalFrom', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IndicatesSignalFor
    return $return;
}



sub get_relationship_HasMember
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasMember

    $return = $self->_get_relationship($ctx, 'HasMember', 'HasMember', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasMember
    return $return;
}



sub get_relationship_IsMemberOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsMemberOf

    $return = $self->_get_relationship($ctx, 'IsMemberOf', 'HasMember', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsMemberOf
    return $return;
}



sub get_relationship_HasParticipant
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasParticipant

    $return = $self->_get_relationship($ctx, 'HasParticipant', 'HasParticipant', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasParticipant
    return $return;
}



sub get_relationship_ParticipatesIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_ParticipatesIn

    $return = $self->_get_relationship($ctx, 'ParticipatesIn', 'HasParticipant', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ParticipatesIn
    return $return;
}



sub get_relationship_HasPresenceOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasPresenceOf

    $return = $self->_get_relationship($ctx, 'HasPresenceOf', 'HasPresenceOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasPresenceOf
    return $return;
}



sub get_relationship_IsPresentIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsPresentIn

    $return = $self->_get_relationship($ctx, 'IsPresentIn', 'HasPresenceOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsPresentIn
    return $return;
}



sub get_relationship_HasReactionAliasFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasReactionAliasFrom

    $return = $self->_get_relationship($ctx, 'HasReactionAliasFrom', 'HasReactionAliasFrom', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasReactionAliasFrom
    return $return;
}



sub get_relationship_UsesAliasForReaction
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_UsesAliasForReaction

    $return = $self->_get_relationship($ctx, 'UsesAliasForReaction', 'HasReactionAliasFrom', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_UsesAliasForReaction
    return $return;
}



sub get_relationship_HasRepresentativeOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasRepresentativeOf

    $return = $self->_get_relationship($ctx, 'HasRepresentativeOf', 'HasRepresentativeOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasRepresentativeOf
    return $return;
}



sub get_relationship_IsRepresentedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRepresentedIn

    $return = $self->_get_relationship($ctx, 'IsRepresentedIn', 'HasRepresentativeOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRepresentedIn
    return $return;
}



sub get_relationship_HasResultsIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasResultsIn

    $return = $self->_get_relationship($ctx, 'HasResultsIn', 'HasResultsIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasResultsIn
    return $return;
}



sub get_relationship_HasResultsFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasResultsFor

    $return = $self->_get_relationship($ctx, 'HasResultsFor', 'HasResultsIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasResultsFor
    return $return;
}



sub get_relationship_HasSection
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasSection

    $return = $self->_get_relationship($ctx, 'HasSection', 'HasSection', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasSection
    return $return;
}



sub get_relationship_IsSectionOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsSectionOf

    $return = $self->_get_relationship($ctx, 'IsSectionOf', 'HasSection', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSectionOf
    return $return;
}



sub get_relationship_HasStep
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasStep

    $return = $self->_get_relationship($ctx, 'HasStep', 'HasStep', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasStep
    return $return;
}



sub get_relationship_IsStepOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsStepOf

    $return = $self->_get_relationship($ctx, 'IsStepOf', 'HasStep', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsStepOf
    return $return;
}



sub get_relationship_HasUsage
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasUsage

    $return = $self->_get_relationship($ctx, 'HasUsage', 'HasUsage', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasUsage
    return $return;
}



sub get_relationship_IsUsageOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsUsageOf

    $return = $self->_get_relationship($ctx, 'IsUsageOf', 'HasUsage', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUsageOf
    return $return;
}



sub get_relationship_HasValueFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasValueFor

    $return = $self->_get_relationship($ctx, 'HasValueFor', 'HasValueFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasValueFor
    return $return;
}



sub get_relationship_HasValueIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasValueIn

    $return = $self->_get_relationship($ctx, 'HasValueIn', 'HasValueFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasValueIn
    return $return;
}



sub get_relationship_Imported
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Imported

    $return = $self->_get_relationship($ctx, 'Imported', 'Imported', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Imported
    return $return;
}



sub get_relationship_WasImportedFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_WasImportedFrom

    $return = $self->_get_relationship($ctx, 'WasImportedFrom', 'Imported', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_WasImportedFrom
    return $return;
}



sub get_relationship_Includes
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Includes

    $return = $self->_get_relationship($ctx, 'Includes', 'Includes', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Includes
    return $return;
}



sub get_relationship_IsIncludedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsIncludedIn

    $return = $self->_get_relationship($ctx, 'IsIncludedIn', 'Includes', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsIncludedIn
    return $return;
}



sub get_relationship_IndicatedLevelsFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IndicatedLevelsFor

    $return = $self->_get_relationship($ctx, 'IndicatedLevelsFor', 'IndicatedLevelsFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IndicatedLevelsFor
    return $return;
}



sub get_relationship_HasLevelsFrom
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasLevelsFrom

    $return = $self->_get_relationship($ctx, 'HasLevelsFrom', 'IndicatedLevelsFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasLevelsFrom
    return $return;
}



sub get_relationship_Involves
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Involves

    $return = $self->_get_relationship($ctx, 'Involves', 'Involves', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Involves
    return $return;
}



sub get_relationship_IsInvolvedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsInvolvedIn

    $return = $self->_get_relationship($ctx, 'IsInvolvedIn', 'Involves', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInvolvedIn
    return $return;
}



sub get_relationship_IsARequirementIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsARequirementIn

    $return = $self->_get_relationship($ctx, 'IsARequirementIn', 'IsARequirementIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsARequirementIn
    return $return;
}



sub get_relationship_IsARequirementOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsARequirementOf

    $return = $self->_get_relationship($ctx, 'IsARequirementOf', 'IsARequirementIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsARequirementOf
    return $return;
}



sub get_relationship_IsAlignedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsAlignedIn

    $return = $self->_get_relationship($ctx, 'IsAlignedIn', 'IsAlignedIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAlignedIn
    return $return;
}



sub get_relationship_IsAlignmentFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsAlignmentFor

    $return = $self->_get_relationship($ctx, 'IsAlignmentFor', 'IsAlignedIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAlignmentFor
    return $return;
}



sub get_relationship_IsAnnotatedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsAnnotatedBy

    $return = $self->_get_relationship($ctx, 'IsAnnotatedBy', 'IsAnnotatedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsAnnotatedBy
    return $return;
}



sub get_relationship_Annotates
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Annotates

    $return = $self->_get_relationship($ctx, 'Annotates', 'IsAnnotatedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Annotates
    return $return;
}



sub get_relationship_IsBindingSiteFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsBindingSiteFor

    $return = $self->_get_relationship($ctx, 'IsBindingSiteFor', 'IsBindingSiteFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsBindingSiteFor
    return $return;
}



sub get_relationship_IsBoundBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsBoundBy

    $return = $self->_get_relationship($ctx, 'IsBoundBy', 'IsBindingSiteFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsBoundBy
    return $return;
}



sub get_relationship_IsClassFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsClassFor

    $return = $self->_get_relationship($ctx, 'IsClassFor', 'IsClassFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsClassFor
    return $return;
}



sub get_relationship_IsInClass
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsInClass

    $return = $self->_get_relationship($ctx, 'IsInClass', 'IsClassFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInClass
    return $return;
}



sub get_relationship_IsCollectionOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsCollectionOf

    $return = $self->_get_relationship($ctx, 'IsCollectionOf', 'IsCollectionOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCollectionOf
    return $return;
}



sub get_relationship_IsCollectedInto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsCollectedInto

    $return = $self->_get_relationship($ctx, 'IsCollectedInto', 'IsCollectionOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCollectedInto
    return $return;
}



sub get_relationship_IsComposedOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsComposedOf

    $return = $self->_get_relationship($ctx, 'IsComposedOf', 'IsComposedOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsComposedOf
    return $return;
}



sub get_relationship_IsComponentOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsComponentOf

    $return = $self->_get_relationship($ctx, 'IsComponentOf', 'IsComposedOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsComponentOf
    return $return;
}



sub get_relationship_IsComprisedOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsComprisedOf

    $return = $self->_get_relationship($ctx, 'IsComprisedOf', 'IsComprisedOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsComprisedOf
    return $return;
}



sub get_relationship_Comprises
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Comprises

    $return = $self->_get_relationship($ctx, 'Comprises', 'IsComprisedOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Comprises
    return $return;
}



sub get_relationship_IsConfiguredBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsConfiguredBy

    $return = $self->_get_relationship($ctx, 'IsConfiguredBy', 'IsConfiguredBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsConfiguredBy
    return $return;
}



sub get_relationship_ReflectsStateOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_ReflectsStateOf

    $return = $self->_get_relationship($ctx, 'ReflectsStateOf', 'IsConfiguredBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ReflectsStateOf
    return $return;
}



sub get_relationship_IsConsistentWith
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsConsistentWith

    $return = $self->_get_relationship($ctx, 'IsConsistentWith', 'IsConsistentWith', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsConsistentWith
    return $return;
}



sub get_relationship_IsConsistentTo
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsConsistentTo

    $return = $self->_get_relationship($ctx, 'IsConsistentTo', 'IsConsistentWith', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsConsistentTo
    return $return;
}



sub get_relationship_IsCoregulatedWith
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsCoregulatedWith

    $return = $self->_get_relationship($ctx, 'IsCoregulatedWith', 'IsCoregulatedWith', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCoregulatedWith
    return $return;
}



sub get_relationship_HasCoregulationWith
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasCoregulationWith

    $return = $self->_get_relationship($ctx, 'HasCoregulationWith', 'IsCoregulatedWith', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasCoregulationWith
    return $return;
}



sub get_relationship_IsCoupledTo
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsCoupledTo

    $return = $self->_get_relationship($ctx, 'IsCoupledTo', 'IsCoupledTo', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCoupledTo
    return $return;
}



sub get_relationship_IsCoupledWith
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsCoupledWith

    $return = $self->_get_relationship($ctx, 'IsCoupledWith', 'IsCoupledTo', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsCoupledWith
    return $return;
}



sub get_relationship_IsDefaultFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsDefaultFor

    $return = $self->_get_relationship($ctx, 'IsDefaultFor', 'IsDefaultFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDefaultFor
    return $return;
}



sub get_relationship_RunsByDefaultIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_RunsByDefaultIn

    $return = $self->_get_relationship($ctx, 'RunsByDefaultIn', 'IsDefaultFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_RunsByDefaultIn
    return $return;
}



sub get_relationship_IsDefaultLocationOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsDefaultLocationOf

    $return = $self->_get_relationship($ctx, 'IsDefaultLocationOf', 'IsDefaultLocationOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDefaultLocationOf
    return $return;
}



sub get_relationship_HasDefaultLocation
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasDefaultLocation

    $return = $self->_get_relationship($ctx, 'HasDefaultLocation', 'IsDefaultLocationOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasDefaultLocation
    return $return;
}



sub get_relationship_IsDeterminedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsDeterminedBy

    $return = $self->_get_relationship($ctx, 'IsDeterminedBy', 'IsDeterminedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDeterminedBy
    return $return;
}



sub get_relationship_Determines
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Determines

    $return = $self->_get_relationship($ctx, 'Determines', 'IsDeterminedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Determines
    return $return;
}



sub get_relationship_IsDividedInto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsDividedInto

    $return = $self->_get_relationship($ctx, 'IsDividedInto', 'IsDividedInto', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDividedInto
    return $return;
}



sub get_relationship_IsDivisionOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsDivisionOf

    $return = $self->_get_relationship($ctx, 'IsDivisionOf', 'IsDividedInto', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsDivisionOf
    return $return;
}



sub get_relationship_IsExemplarOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsExemplarOf

    $return = $self->_get_relationship($ctx, 'IsExemplarOf', 'IsExemplarOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsExemplarOf
    return $return;
}



sub get_relationship_HasAsExemplar
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasAsExemplar

    $return = $self->_get_relationship($ctx, 'HasAsExemplar', 'IsExemplarOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasAsExemplar
    return $return;
}



sub get_relationship_IsFamilyFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsFamilyFor

    $return = $self->_get_relationship($ctx, 'IsFamilyFor', 'IsFamilyFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsFamilyFor
    return $return;
}



sub get_relationship_DeterminesFunctionOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_DeterminesFunctionOf

    $return = $self->_get_relationship($ctx, 'DeterminesFunctionOf', 'IsFamilyFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_DeterminesFunctionOf
    return $return;
}



sub get_relationship_IsFormedOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsFormedOf

    $return = $self->_get_relationship($ctx, 'IsFormedOf', 'IsFormedOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsFormedOf
    return $return;
}



sub get_relationship_IsFormedInto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsFormedInto

    $return = $self->_get_relationship($ctx, 'IsFormedInto', 'IsFormedOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsFormedInto
    return $return;
}



sub get_relationship_IsFunctionalIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsFunctionalIn

    $return = $self->_get_relationship($ctx, 'IsFunctionalIn', 'IsFunctionalIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsFunctionalIn
    return $return;
}



sub get_relationship_HasFunctional
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasFunctional

    $return = $self->_get_relationship($ctx, 'HasFunctional', 'IsFunctionalIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasFunctional
    return $return;
}



sub get_relationship_IsGroupFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsGroupFor

    $return = $self->_get_relationship($ctx, 'IsGroupFor', 'IsGroupFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsGroupFor
    return $return;
}



sub get_relationship_IsInGroup
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsInGroup

    $return = $self->_get_relationship($ctx, 'IsInGroup', 'IsGroupFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInGroup
    return $return;
}



sub get_relationship_IsImplementedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsImplementedBy

    $return = $self->_get_relationship($ctx, 'IsImplementedBy', 'IsImplementedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsImplementedBy
    return $return;
}



sub get_relationship_Implements
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Implements

    $return = $self->_get_relationship($ctx, 'Implements', 'IsImplementedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Implements
    return $return;
}



sub get_relationship_IsInPair
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsInPair

    $return = $self->_get_relationship($ctx, 'IsInPair', 'IsInPair', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInPair
    return $return;
}



sub get_relationship_IsPairOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsPairOf

    $return = $self->_get_relationship($ctx, 'IsPairOf', 'IsInPair', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsPairOf
    return $return;
}



sub get_relationship_IsInstantiatedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsInstantiatedBy

    $return = $self->_get_relationship($ctx, 'IsInstantiatedBy', 'IsInstantiatedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInstantiatedBy
    return $return;
}



sub get_relationship_IsInstanceOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsInstanceOf

    $return = $self->_get_relationship($ctx, 'IsInstanceOf', 'IsInstantiatedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInstanceOf
    return $return;
}



sub get_relationship_IsLocatedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsLocatedIn

    $return = $self->_get_relationship($ctx, 'IsLocatedIn', 'IsLocatedIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsLocatedIn
    return $return;
}



sub get_relationship_IsLocusFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsLocusFor

    $return = $self->_get_relationship($ctx, 'IsLocusFor', 'IsLocatedIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsLocusFor
    return $return;
}



sub get_relationship_IsModeledBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsModeledBy

    $return = $self->_get_relationship($ctx, 'IsModeledBy', 'IsModeledBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsModeledBy
    return $return;
}



sub get_relationship_Models
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Models

    $return = $self->_get_relationship($ctx, 'Models', 'IsModeledBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Models
    return $return;
}



sub get_relationship_IsNamedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsNamedBy

    $return = $self->_get_relationship($ctx, 'IsNamedBy', 'IsNamedBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsNamedBy
    return $return;
}



sub get_relationship_Names
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Names

    $return = $self->_get_relationship($ctx, 'Names', 'IsNamedBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Names
    return $return;
}



sub get_relationship_IsOwnerOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsOwnerOf

    $return = $self->_get_relationship($ctx, 'IsOwnerOf', 'IsOwnerOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsOwnerOf
    return $return;
}



sub get_relationship_IsOwnedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsOwnedBy

    $return = $self->_get_relationship($ctx, 'IsOwnedBy', 'IsOwnerOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsOwnedBy
    return $return;
}



sub get_relationship_IsProposedLocationOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsProposedLocationOf

    $return = $self->_get_relationship($ctx, 'IsProposedLocationOf', 'IsProposedLocationOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsProposedLocationOf
    return $return;
}



sub get_relationship_HasProposedLocationIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasProposedLocationIn

    $return = $self->_get_relationship($ctx, 'HasProposedLocationIn', 'IsProposedLocationOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasProposedLocationIn
    return $return;
}



sub get_relationship_IsProteinFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsProteinFor

    $return = $self->_get_relationship($ctx, 'IsProteinFor', 'IsProteinFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsProteinFor
    return $return;
}



sub get_relationship_Produces
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Produces

    $return = $self->_get_relationship($ctx, 'Produces', 'IsProteinFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Produces
    return $return;
}



sub get_relationship_IsRealLocationOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRealLocationOf

    $return = $self->_get_relationship($ctx, 'IsRealLocationOf', 'IsRealLocationOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRealLocationOf
    return $return;
}



sub get_relationship_HasRealLocationIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasRealLocationIn

    $return = $self->_get_relationship($ctx, 'HasRealLocationIn', 'IsRealLocationOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasRealLocationIn
    return $return;
}



sub get_relationship_IsRegulatedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRegulatedIn

    $return = $self->_get_relationship($ctx, 'IsRegulatedIn', 'IsRegulatedIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRegulatedIn
    return $return;
}



sub get_relationship_IsRegulatedSetOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRegulatedSetOf

    $return = $self->_get_relationship($ctx, 'IsRegulatedSetOf', 'IsRegulatedIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRegulatedSetOf
    return $return;
}



sub get_relationship_IsRelevantFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRelevantFor

    $return = $self->_get_relationship($ctx, 'IsRelevantFor', 'IsRelevantFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRelevantFor
    return $return;
}



sub get_relationship_IsRelevantTo
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRelevantTo

    $return = $self->_get_relationship($ctx, 'IsRelevantTo', 'IsRelevantFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRelevantTo
    return $return;
}



sub get_relationship_IsRequiredBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRequiredBy

    $return = $self->_get_relationship($ctx, 'IsRequiredBy', 'IsRequiredBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRequiredBy
    return $return;
}



sub get_relationship_Requires
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Requires

    $return = $self->_get_relationship($ctx, 'Requires', 'IsRequiredBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Requires
    return $return;
}



sub get_relationship_IsRoleOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRoleOf

    $return = $self->_get_relationship($ctx, 'IsRoleOf', 'IsRoleOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRoleOf
    return $return;
}



sub get_relationship_HasRole
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasRole

    $return = $self->_get_relationship($ctx, 'HasRole', 'IsRoleOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasRole
    return $return;
}



sub get_relationship_IsRowOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRowOf

    $return = $self->_get_relationship($ctx, 'IsRowOf', 'IsRowOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRowOf
    return $return;
}



sub get_relationship_IsRoleFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsRoleFor

    $return = $self->_get_relationship($ctx, 'IsRoleFor', 'IsRowOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsRoleFor
    return $return;
}



sub get_relationship_IsSequenceOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsSequenceOf

    $return = $self->_get_relationship($ctx, 'IsSequenceOf', 'IsSequenceOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSequenceOf
    return $return;
}



sub get_relationship_HasAsSequence
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasAsSequence

    $return = $self->_get_relationship($ctx, 'HasAsSequence', 'IsSequenceOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasAsSequence
    return $return;
}



sub get_relationship_IsSubInstanceOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsSubInstanceOf

    $return = $self->_get_relationship($ctx, 'IsSubInstanceOf', 'IsSubInstanceOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSubInstanceOf
    return $return;
}



sub get_relationship_Validates
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Validates

    $return = $self->_get_relationship($ctx, 'Validates', 'IsSubInstanceOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Validates
    return $return;
}



sub get_relationship_IsSuperclassOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsSuperclassOf

    $return = $self->_get_relationship($ctx, 'IsSuperclassOf', 'IsSuperclassOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSuperclassOf
    return $return;
}



sub get_relationship_IsSubclassOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsSubclassOf

    $return = $self->_get_relationship($ctx, 'IsSubclassOf', 'IsSuperclassOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsSubclassOf
    return $return;
}



sub get_relationship_IsTargetOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsTargetOf

    $return = $self->_get_relationship($ctx, 'IsTargetOf', 'IsTargetOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsTargetOf
    return $return;
}



sub get_relationship_Targets
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Targets

    $return = $self->_get_relationship($ctx, 'Targets', 'IsTargetOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Targets
    return $return;
}



sub get_relationship_IsTaxonomyOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsTaxonomyOf

    $return = $self->_get_relationship($ctx, 'IsTaxonomyOf', 'IsTaxonomyOf', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsTaxonomyOf
    return $return;
}



sub get_relationship_IsInTaxa
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsInTaxa

    $return = $self->_get_relationship($ctx, 'IsInTaxa', 'IsTaxonomyOf', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsInTaxa
    return $return;
}



sub get_relationship_IsTerminusFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsTerminusFor

    $return = $self->_get_relationship($ctx, 'IsTerminusFor', 'IsTerminusFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsTerminusFor
    return $return;
}



sub get_relationship_HasAsTerminus
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HasAsTerminus

    $return = $self->_get_relationship($ctx, 'HasAsTerminus', 'IsTerminusFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HasAsTerminus
    return $return;
}



sub get_relationship_IsTriggeredBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsTriggeredBy

    $return = $self->_get_relationship($ctx, 'IsTriggeredBy', 'IsTriggeredBy', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsTriggeredBy
    return $return;
}



sub get_relationship_Triggers
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Triggers

    $return = $self->_get_relationship($ctx, 'Triggers', 'IsTriggeredBy', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Triggers
    return $return;
}



sub get_relationship_IsUsedAs
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsUsedAs

    $return = $self->_get_relationship($ctx, 'IsUsedAs', 'IsUsedAs', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUsedAs
    return $return;
}



sub get_relationship_IsUseOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsUseOf

    $return = $self->_get_relationship($ctx, 'IsUseOf', 'IsUsedAs', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUseOf
    return $return;
}



sub get_relationship_Manages
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Manages

    $return = $self->_get_relationship($ctx, 'Manages', 'Manages', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Manages
    return $return;
}



sub get_relationship_IsManagedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsManagedBy

    $return = $self->_get_relationship($ctx, 'IsManagedBy', 'Manages', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsManagedBy
    return $return;
}



sub get_relationship_OperatesIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_OperatesIn

    $return = $self->_get_relationship($ctx, 'OperatesIn', 'OperatesIn', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_OperatesIn
    return $return;
}



sub get_relationship_IsUtilizedIn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsUtilizedIn

    $return = $self->_get_relationship($ctx, 'IsUtilizedIn', 'OperatesIn', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUtilizedIn
    return $return;
}



sub get_relationship_Overlaps
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Overlaps

    $return = $self->_get_relationship($ctx, 'Overlaps', 'Overlaps', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Overlaps
    return $return;
}



sub get_relationship_IncludesPartOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IncludesPartOf

    $return = $self->_get_relationship($ctx, 'IncludesPartOf', 'Overlaps', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IncludesPartOf
    return $return;
}



sub get_relationship_ParticipatesAs
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_ParticipatesAs

    $return = $self->_get_relationship($ctx, 'ParticipatesAs', 'ParticipatesAs', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ParticipatesAs
    return $return;
}



sub get_relationship_IsParticipationOf
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsParticipationOf

    $return = $self->_get_relationship($ctx, 'IsParticipationOf', 'ParticipatesAs', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsParticipationOf
    return $return;
}



sub get_relationship_ProducedResultsFor
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_ProducedResultsFor

    $return = $self->_get_relationship($ctx, 'ProducedResultsFor', 'ProducedResultsFor', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ProducedResultsFor
    return $return;
}



sub get_relationship_HadResultsProducedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_HadResultsProducedBy

    $return = $self->_get_relationship($ctx, 'HadResultsProducedBy', 'ProducedResultsFor', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_HadResultsProducedBy
    return $return;
}



sub get_relationship_ProjectsOnto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_ProjectsOnto

    $return = $self->_get_relationship($ctx, 'ProjectsOnto', 'ProjectsOnto', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_ProjectsOnto
    return $return;
}



sub get_relationship_IsProjectedOnto
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsProjectedOnto

    $return = $self->_get_relationship($ctx, 'IsProjectedOnto', 'ProjectsOnto', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsProjectedOnto
    return $return;
}



sub get_relationship_Provided
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Provided

    $return = $self->_get_relationship($ctx, 'Provided', 'Provided', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Provided
    return $return;
}



sub get_relationship_WasProvidedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_WasProvidedBy

    $return = $self->_get_relationship($ctx, 'WasProvidedBy', 'Provided', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_WasProvidedBy
    return $return;
}



sub get_relationship_Shows
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Shows

    $return = $self->_get_relationship($ctx, 'Shows', 'Shows', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Shows
    return $return;
}



sub get_relationship_IsShownOn
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsShownOn

    $return = $self->_get_relationship($ctx, 'IsShownOn', 'Shows', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsShownOn
    return $return;
}



sub get_relationship_Submitted
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Submitted

    $return = $self->_get_relationship($ctx, 'Submitted', 'Submitted', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Submitted
    return $return;
}



sub get_relationship_WasSubmittedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_WasSubmittedBy

    $return = $self->_get_relationship($ctx, 'WasSubmittedBy', 'Submitted', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_WasSubmittedBy
    return $return;
}



sub get_relationship_Uses
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_Uses

    $return = $self->_get_relationship($ctx, 'Uses', 'Uses', 0, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_Uses
    return $return;
}



sub get_relationship_IsUsedBy
{
    my($self, $ids, $from_fields, $rel_fields, $to_fields) = @_;
    my $ctx = $CDMI_EntityAPIServer::CallContext;
    my($return);

    #BEGIN get_relationship_IsUsedBy

    $return = $self->_get_relationship($ctx, 'IsUsedBy', 'Uses', 1, $ids, $from_fields, $rel_fields, $to_fields);
	
    #END get_relationship_IsUsedBy
    return $return;
}


