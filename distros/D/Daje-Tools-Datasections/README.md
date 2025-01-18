# NAME

Daje::Tools::Datasections

# DESCRIPTION

Daje::Tools::Datasections - Load and store data sections in memory from a named \*.pm

# REQUIRES

[Mojo::Loader](https://metacpan.org/pod/Mojo%3A%3ALoader) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

Get one section of loaded data

    my $c1 = $data->get_data_section('c1');

Add a section of data

    $data->set_data_section('new_section', 'section data');

Set a new source

    $data->set_source('New::Source');

Add a new section to load

    $data->add_data_section('test');

# Synopsis

    use GenerateSQL::Tools::Datasections

    my $data = GenerateSQL::Tools::Datasections->new(

         data_sections => ['c1','c2','c3'],

         source => 'Class::Containing::Datasections

     )->load_data_sections();

# Abstract

Get and store data sections from perl classes

# AUTHOR

Jan Eskilsson

# COPYRIGHT

Copyright (C) 2024 Jan Eskilsson.

# LICENSE

Generate::Tools::Datasections  (the distribution) is licensed under the same terms as Perl.
