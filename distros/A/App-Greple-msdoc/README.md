# NAME

msdoc - Greple module for access MS office docx/pptx/xlsx documents

# VERSION

Version 1.02

# SYNOPSIS

greple -Mmsdoc

# DESCRIPTION

This module makes it possible to search string in Microsoft
docx/pptx/xlsx file.

Microsoft document consists of multiple files archived in zip format.
String information is stored in "word/document.xml",
"ppt/slides/\*.xml" or "xl/sharedStrings.xml".  This module extracts
these data and replaces the search target.

By default, text part from XML data is extracted.  This process is
done by very simple method and may include redundant information.

Strings are simply connected into paragrap for _.docx_ and _.pptx_
document.  For _.xlsx_ document, single space is inserted between
them.  Use **--separator** option to change this behavior.

After every paragraph, single newline is inserted for _.pptx_ and
_.xlsx_ file, and double newlines for _.docx_ file.  Use
**--space** option to change.

# OPTIONS

- **--dump**

    Simply print all converted data.  Additional pattern can be specified,
    and they will be highlighted inside whole text.

        $ greple -Mmsdoc --dump -e foo -e bar buz.docx

- **--space**=_n_

    Specify number of newlines inserted after every paragraph.  Any
    non-negative integer is allowed including zero.

- **--separator**=_string_

    Specify the separator string placed between each component strings.

- **--indent**

    Extract indented XML document, not a plain text.

- **--indent-mark**=_string_

    Set indentation string.  Default is `| `.

# INSTALL

cpanm App::Greple::msdoc

# LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[https://github.com/kaz-utashiro/greple-msdoc](https://github.com/kaz-utashiro/greple-msdoc)

# AUTHOR

Kazumasa Utashiro
