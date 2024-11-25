Download the newest versions from https://www.iso20022.org/iso-20022-message-definitions "camt Cash Management"

Also keep older versions: best definition match wins.

# Abbreviate table

The abbreviations.pdf files is loaded from
https://www.iso20022.org/sites/default/files/media/file/XML_Tags.pdf
This file was converted into lib/Business/CAMT/xsd/abbreviations.csv via
cut-n-paste from the evince PDF reader.

Remove all lines where no abbreviation takes place for speed.
```
:g/^\\(.*\\),\\1$/d
```
This removes about 480 lines.

