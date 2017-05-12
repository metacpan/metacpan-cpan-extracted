#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "src/feature_selection.h"

MODULE = Algorithm::TrunkClassifier::FeatureSelection			PACKAGE = Algorithm::TrunkClassifier::FeatureSelection

int
indTTest(expData, numFeatures, numSamples, sampleNames, normal, malign)
	double ** 	expData
	int 		numFeatures
	int 		numSamples
	char ** 	sampleNames
	char * 		normal
	char * 		malign
	
	OUTPUT:
		RETVAL
	
	CLEANUP:
		int i = 0;
		while(expData[i] != NULL){
			free(expData[i]);
			i++;
		}
		free(expData);
		free(sampleNames);
