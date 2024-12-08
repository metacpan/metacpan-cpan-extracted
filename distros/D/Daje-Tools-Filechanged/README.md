[![Actions Status](https://github.com/janeskil1525/Daje-Tools-Filechanged/actions/workflows/test.yml/badge.svg)](https://github.com/janeskil1525/Daje-Tools-Filechanged/actions)
# NAME

Daje::Tools::Filechanged

# SYNOPSIS

    use Daje::Tools::Filechanged;

    my $changes = Daje::Tools::Filechanged->new(

    )->is_file_changed(

        $file_path_name, $old_hash
    ):

# DESCRIPTION

Daje::Tools::Filechanged - It's new $module

Daje::Tools::Filechanged is a tool to check if two hashes are equal

# REQUIRES

[Mojo::File](https://metacpan.org/pod/Mojo%3A%3AFile) 

[Digest::SHA](https://metacpan.org/pod/Digest%3A%3ASHA) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

    my $changed = $self->is_file_changed($file_path_name, $old_hash);

Is the hashes different ?

# AUTHOR

janeskil1525 janeskil1525@gmail.com

# LICENSE

Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
