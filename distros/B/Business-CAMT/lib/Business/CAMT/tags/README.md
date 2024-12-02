# Abbreviation table

The abbreviations.pdf files is loaded from
https://www.iso20022.org/sites/default/files/media/file/XML_Tags.pdf
This file was converted into lib/Business/CAMT/xsd/abbreviations.csv via
cut-n-paste from the evince PDF reader.

Only 3 abbreviations are missing from that list, at the moment (for the
may 2024 release of the CAMT set).  Please help me solve the last tags.
Search for /,$/ in file index.csv.

To interpret the names, https://www.mx-message.com is a great help
(even with its older and very limited number of messages)

Some short versions have stayed. Those made some names increadably long, without
adding much clarity:
* Id for Identification (abstract code)  This is not in the database 'id' sense, which is 'code' in these schemes
* Ind for Indicator (flags existence)
* NAV for Net Asset Value

## Extraction process

This distribution contains a bin/make-templates script, which is run when there
are changes in the schemas and index.csv file.  It is lazy: will not update them
where there is no need.  It also checks that all abbreviated tags are included
in the index.csv.
