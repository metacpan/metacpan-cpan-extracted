table refseqGenes
"Describes the refseqGenes"
(
string chrom;    "Reference sequence chromosome or scaffold"
uint chromStart; "Start position in chromosome"
uint chromEnd;   "End position in chromosome"
string name;     "RefSeq Gene"
uint score;      "Prediction quality"
char strand;     "Strand"
uint fatStart;   "transcript start"
uint fatEnd;     "transcript end"
string itemRGB;  "RGB value for item"
uint blockCount; "Number of exons"
string blockSizes; "Exon sizes, comma delimited"
string blockStarts; "Exon starts, comma delimited"
)
