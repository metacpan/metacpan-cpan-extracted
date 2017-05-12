# Bio::BLAST - low-level routines for working with BLAST tools and formats

Currently, this CPAN module only contains Bio::BLAST::Database.

Each object of Bio::BLAST::Database class represents an NCBI-formatted sequence
database on disk, which is a set of files, the exact structure of which varies
a bit with the type and size of the sequence set.

This is mostly an object-oriented wrapper for using *fastacmd* and
*formatdb* to index sequence files and such.
