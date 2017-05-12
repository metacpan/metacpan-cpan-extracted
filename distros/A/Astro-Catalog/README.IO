
This lib/Astro/Catalog/IO directory contains the "plugins" for catalogue I/O.

Currently supported formats are:

 Astrom     - Starlink's ASTROM input file format, see SUN/5.
 Cluster    - Cluster Collaboration format
 FINDOFF    - Starlink's FINDOFF input/output file format, see SUN/139.
 GaiaPick   - Gaia/SkyCat Pick Object format. The output from a "Pick Object"
              in GAIA
 FITSTable  - Binary FITS tables.
 JCMT       - JCMT source catalogue
 SExtractor - ASCII_HEAD output from SExtractor.
 STL        - Starlink's Small Text List format, see SUN/190 and SSN/75
 Simple     - Simple ID, RA, Dec format
 TST        - Tab Separated Table see SSN/75 for more information.
 UKIRTBS    - UKIRT Bright Standard catalogue.
 VOTable    - The new standard for Virtual Observatory interoperability,
              see http://www.ivoa.net/ for more information

Other catalogue formats that we are considering:

 OASIS      - Text format from oasis.
               http://irsa.ipac.caltech.edu/applications/Oasis/svc/index.html
