# NAME

**App::PDFLibrarian** - Manage a library of academic papers in PDF format with embedded BibTeX metadata.

# INSTALLATION

Requires the following packages:

- Debian, Ubuntu:

    ```
    apt install cpanminus ghostscript libwx-perl libxml2-dev libxslt1-dev perl-base poppler-utils xdg-utils zlib1g-dev
    ```

Then install from CPAN:

```
cpanm App::PDFLibrarian
```

# APPLICATIONS

## **pdf-lbr-import-pdf** - Import PDF files into the PDF library.

### SYNOPSIS

**pdf-lbr-import-pdf** **--version**
**pdf-lbr-import-pdf** **--help**|**-h**

**pdf-lbr-import-pdf** \[ **--no-pdf-bib** \] \[ **--manual-entry**|**-e** _type_ **--manual-field**|**-f** _field_=_value_ ... \] _files_|_directories_ ...

... _files_|_directories_ ... **|** **pdf-lbr-import-pdf** ...

### DESCRIPTION

**pdf-lbr-import-pdf** imports PDF _files_ and/or any PDF files in _directories_ into the PDF library. If **--no-pdf-bib** is specified, any BibTeX metadata embedded in the PDF files will be ignored. If _files_|_directories_ are not given on the command line, they are read from standard input, one per line.

The user will be asked to select an online query database and supply a query value which uniquely identifies the paper(s), in order for App::PDFLibrarian to retrieve a BibTeX record for the paper(s). By default App::PDFLibrarian tries to extract a Digital Object Identifier from the PDF paper(s) for use in the query. If the query is successful, the user will have an opportunity to edit the BibTeX record(s) before the PDF _files_ are added to the library.

The user may also enter the BibTeX record manually. The _type_ of the manual BibTeX entry defaults to _article_, unless the **--manual-entry** option specifies a different _type_. Additional manual BibTeX _field_s may be set using the **--manual-field** option.

Note that the editor will open the BibTeX entries of all PDF files passed to the command line, even if they are already in the library. In this way, the user may call up relevant existing BibTeX entries as a guide to filling out a new BibTeX entry; for example: entries of the same type (e.g. book, techreport), entries that appear in the same journal/conference series, etc.

## **pdf-lbr-edit-bib** - Edit BibTeX bibliographic metadata in PDF files.

### SYNOPSIS

**pdf-lbr-edit-bib** **--version**
**pdf-lbr-edit-bib** **--help**|**-h**

**pdf-lbr-edit-bib** _links_|_link-directories_ ...

... _links_|_link-directories_ ... **|** **pdf-lbr-edit-bib** ...

### DESCRIPTION

**pdf-lbr-edit-bib** reads BibTeX bibliographic metadata embedded in PDF files given by _links_ and/or within _link-directories_ in the PDF links directory. If _links_|_link-directories_ are not given on the command line, they are read from standard input, one per line.

The BibTeX metadata is written to a temporary file, which is then opened in an editing program, given either by the **$VISUAL** or **$EDITOR** environment variables, or else the program **editor**. The **macros** section of the configuration file is parsed for custom BibTeX macros to define.

Any modifications are then written back to the PDF files given by the _file_ field in each BibTeX entry, and the PDF library links rebuilt as needed.

## **pdf-lbr-output-bib** - Output BibTeX bibliographic metadata from PDF files.

### SYNOPSIS

**pdf-lbr-output-bib** **--version**
**pdf-lbr-output-bib** **--help**|**-h**

**pdf-lbr-output-bib** \[ **--clipboard**|**-c** \] \[ **--max-authors**|**-m** _count_ \[ **--only-first-author**|**-f** \] \] \[ **--filter**|**-F** \[_type_**:**\]_field_\[**?**_iffield_|**!**_ifnotfield_...\]**=**_spec_ ... \] \[ **--no-default-filter**|**-N** \] \[ **--abbreviate**|**-a** _scheme_ ... \] \[ **--output-text-format**|**-o** _type_=&lt;format> ... | **--output-text**|**-O** | **--pdf-file-comment**|**-P** \] _files_|_directories_ ...

... _files_|_directories_ ... **|** **pdf-lbr-output-bib** ...

### DESCRIPTION

**pdf-lbr-output-bib** reads BibTeX bibliographic metadata embedded in PDF _files_ and/or any PDF files in _directories_. If _files_|_directories_ are not given on the command line, they are read from standard input, one per line.

The BibTeX metadata is then printed to standard output; if **--clipboard** is given, it is instead copied to the clipboard.

### OPTIONS

- **--max-authors**|**-m** _count_ \[ **--only-first-author**|**-f** \]

    If the number of authors is greater than _count_, and

    - If **--only-first-author** is given, output only the first author, followed by "and others".
    - Otherwise, output the first _count_ authors, followed by "and others".

- **--filter**|**-F** \[_type_**:**\]_field_\[**?**_iffield_|**!**_ifnotfield_...\]**=**_spec_ ... \[ **--no-default-filter**|**-N** \]

    Apply the filter _spec_ to the BibTeX _field_. If given, _type_ applies filter only to BibTeX entries of that type, _iffield_ applies filter only to BibTeX entries where &lt;iffield> is defined, and _ifnotfield_ applies filter only to BibTeX entries where &lt;ifnotfield> is not defined. Possible _spec_ are:

    - **d**

        Exclude _field_ from output.

    - **=**_value_

        Set _field_ to _value_ in output.

    - **s****/**_pattern_**/**_replacement_\[**/**_pattern_**/**_replacement_...\]**/**

        Replace each regular expression _pattern_ with _replacement_ in output.

    If no **--filter** arguments are given, default filters given in the configuration file are applied (unless **--no-default-filter** is given).

- **--abbreviate**|**-a** _scheme_ ...

    Abbreviate journal/series titles according to the given _scheme_, applied in the order given on the command line. Available _scheme_s:

    - _aas_

        AAS macros for astronomy journals, used by the NASA Astrophysics Data System.

    - _iso4_

        ISO4 abbreviations using the ISSN List of Title Word Abbreviations.

    - _iso4~_

        Same as _iso4_ but separate words with tildes instead of spaces.

- **--pdf-file-comment**|**-P**

    If true, output the PDF filename as a comment before each BibTeX entry. Default is false. (The PDF filename is never included in the BibTeX entry itself.)

- **--output-text-format**|**-o** _type_=&lt;format>

    Instead of outputting a BibTeX entry, output plain text, formatting entries of type _type_ with format _format_. BibTeX _field_s may be substituted into _format_ with the syntax _%field_.

    The _author_ and _editor_ fields must include one of the suffixes _:fvlj_ or _:vljf_ to indicate the citation style: _author:fvlj_ cites authors with initials then last name; _author:vljf_ cites authors with last name then initials.

    Format text surrounded by curly braces is removed if it contains a _%_ from an unexpanded _field_. Curly braces may be nested to define alternatives for missing fields, e.g. _{DOI:%doi{URL:%url}}_ provides a URL only if the DOI field is missing.

- **--output-text**|**-O**

    Instead of outputting a BibTeX entry, output plain text, formatting entries with formats given in the configuration file.

## **pdf-lbr-output-key** - Output BibTeX bibliographic keys from PDF files.

### SYNOPSIS

**pdf-lbr-output-key** **--version**
**pdf-lbr-output-key** **--help**|**-h**

**pdf-lbr-output-key** \[ **--clipboard**|**-c** \] _files_|_directories_ ...

... _files_|_directories_ ... **|** **pdf-lbr-output-key** ...

### DESCRIPTION

**pdf-lbr-output-key** reads BibTeX bibliographic keys for PDF _files_ and/or any PDF files in _directories_. If _files_|_directories_ are not given on the command line, they are read from standard input, one per line.

The BibTeX keys are then printed to standard output, separated by commas; if **--clipboard** is given, they are instead copied to the clipboard.

## **pdf-lbr-replace-pdf** - Replace a PDF file in the PDF library with a new PDF file.

### SYNOPSIS

**pdf-lbr-replace-pdf** **--version**
**pdf-lbr-replace-pdf** **--help**|**-h**

**pdf-lbr-replace-pdf** \[**-o** _output-directory_\] _old-link_ _new-file_

### DESCRIPTION

**pdf-lbr-replace-pdf** replaces a PDF file, given by a _old-link_ in the PDF links directory, with a new PDF _file_.

The replaced PDF file is moved to the directory _output-directory_, or else to the user's home directory.

## **pdf-lbr-remove-pdf** - Remove a PDF file from the PDF library.

### SYNOPSIS

**pdf-lbr-remove-pdf** **--version**
**pdf-lbr-remove-pdf** **--help**|**-h**

**pdf-lbr-remove-pdf** \[**-o** _output-directory_\] _link_

### DESCRIPTION

**pdf-lbr-remove-pdf** removes a PDF file, given by a _link_ in the PDF links directory, from the PDF library.

The PDF file is moved to the directory _output-directory_, or else to the user's home directory.

## **pdf-lbr-rebuild-links** - Rebuild the PDF links directory.

### SYNOPSIS

**pdf-lbr-rebuild-links** **--version**
**pdf-lbr-rebuild-links** **--help**|**-h**

**pdf-lbr-rebuild-links** \[**-o** _output-directory_\]

### DESCRIPTION

**pdf-lbr-rebuild-links** rebuilds the PDF links directory.

All BibTeX metadata is written to a temporary file, which is then opened in an editing program to check for errors. The editing program is given either by the **$VISUAL** or **$EDITOR** environment variables, or else the program **editor**.

PDF files for any BibTeX entries removing during editing are moved to the directory _output-directory_, or else to the user's home directory.

## **pdf-lbr-iso4-abbr** - Output ISO4 abbreviations.

### SYNOPSIS

**pdf-lbr-iso4-abbr** **--version**
**pdf-lbr-iso4-abbr** **--help**|**-h**

**pdf-lbr-iso4-abbr** \[ **--separator**|**-s** \] _words_ ...

### DESCRIPTION

**pdf-lbr-iso4-abbr** outputs the ISO4 abbreviation of _words_ using the ISSN List of Title Word Abbreviations. The abbreviation is also copied to the clipboard.

### OPTIONS

- **--separator**|**-s**

    Separate the abbreviated words with the given character. Default is space.

# COPYRIGHT AND LICENSE

Copyright (C) 2016--2026 Karl Wette. Licensed under the GNU General Public License, version 3 or later.
