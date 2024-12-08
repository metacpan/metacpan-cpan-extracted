# NAME

Daje::Tools::Datasections

# DESCRIPTION

Daje::Tools::Datasections - Load and store data sections in memory from a named \*.pm

# REQUIRES

[Mojo::Loader](https://metacpan.org/pod/Mojo%3A%3ALoader) 

[v5.40](https://metacpan.org/pod/v5.40) 

[Mojo::Base](https://metacpan.org/pod/Mojo%3A%3ABase) 

# METHODS

Get one section of loaded data

my $c1 = $data->get\_data\_section('c1');

Add a section of data

$data->set\_data\_section('new\_section', 'section data');

Set a new source

$data->set\_source('New::Source');

Add a new section to load

$data->add\_data\_section('test');

# Abstract

Get and store data sections from perl classes

# Synopsis

use GenerateSQL::Tools::Datasections

my $data = GenerateSQL::Tools::Datasections->new(

        data_sections => ['c1','c2','c3'],

        source => 'Class::Containing::Datasections

    )->load_data_sections();

# AUTHOR

Jan Eskilsson

# COPYRIGHT

Copyright (C) 2024 Jan Eskilsson.

# LICENSE

Generate::Tools::Datasections  (the distribution) is licensed under the same terms as Perl.
