# Bio-RetrieveAssemblies
Download WGS assemblies or annotation from [GenBank](http://www.ncbi.nlm.nih.gov/Traces/wgs/?term=embl). 
All accessions are screened against [RefWeak](https://github.com/refweak/refweak).


## Installation
	cpanm Bio::RetrieveAssemblies
	
## Usage
	# Download all assemblies for Salmonella 
	retrieve_assemblies Salmonella
	
	# Download all assemblies for Typhi 
	retrieve_assemblies Typhi
	
	# Download all assemblies in a BioProject
	retrieve_assemblies PRJEB8877

	# Set the output directory
	retrieve_assemblies -o my_salmonella Salmonella
	
	# Get GFF3 files instead of GenBank files
	retrieve_assemblies -f gff Salmonella

	# Get annotated GFF3 files instead of GenBank files (compatible with Roary)
	retrieve_assemblies -a -f gff Salmonella
    
	# Get FASTA files instead of GenBank files
	retrieve_assemblies -f fasta Salmonella
    
	# Search for a different category, VRT/INV/PLN/MAM/PRI/ENV (default is BCT)
	retrieve_assemblies -p MAM Canis 
	
	# This message 
  	retrieve_assemblies -h 
