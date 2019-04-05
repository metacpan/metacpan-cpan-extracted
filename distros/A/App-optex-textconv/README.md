# NAME

textconv - module to replace document file by its text contents

# VERSION

Version 0.01

# SYNOPSIS

optex command -Mtextconv

# DESCRIPTION

This module replaces several sort of filenames by node representing
its text information.  File itself is not altered.

For example, you can check the text difference between MS word files
like this:

    $ optex diff -Mtextconv OLD.docx NEW.docx

If you have symbolic link named **diff** to **optex**, and following
setting in your `~/.optex.d/diff.rc`:

    option default --textconv
    option --textconv -Mtextconv $<move>

Next command simply produces the same result.

    $ diff OLD.docx NEW.docx

# SEE ALSO

[https://github.com/kaz-utashiro/optex-textconv](https://github.com/kaz-utashiro/optex-textconv)

# LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro
