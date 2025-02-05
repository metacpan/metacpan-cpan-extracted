[![Actions Status](https://github.com/janeskil1525/Daje-Workflow-Savefile-Activity/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Workflow-Savefile-Activity/actions)
# NAME

Daje::Workflow::Savefile::Activity - It's a tool to save an array of files

# SYNOPSIS

    use Daje::Workflow::Savefile::Activity;

     "activity_data": {
              "file" : {
                "target_dir_tag": "sql_target_dir",
                "filetype": ".sql",
                "file_list_tag": "sql"
              }

     Mandatory meta data

- file contains file name or name an path

- data content to write to disk

     Possible meta data

- path if set to 1 the file tag contains full path

- new\_only if set to 1 dont replace existing file

# DESCRIPTION

Daje::Workflow::Savefile::Activity is a file saver

# REQUIRES

[Mojo::File](https://metacpan.org/pod/Mojo%3A%3AFile) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

## save($self)

    save($self)();

# AUTHOR

janeskil1525 <janeskil1525@gmail.com>

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
