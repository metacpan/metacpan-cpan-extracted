[![Actions Status](https://github.com/janeskil1525/Daje-Workflow-Savefile-Activity/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Workflow-Savefile-Activity/actions)
# NAME

Daje::Workflow::Savefile::Activity - It's tool to save a n array of files

# SYNOPSIS

    use Daje::Workflow::Savefile::Activity;

     "activity_data": {
              "file" : {
                "target_dir_tag": "sql_target_dir",
                "filetype": ".sql",
                "file_list_tag": "sql"
              }

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
