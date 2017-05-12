# NAME

DBIx::Class::InflateColumn::Serializer::Hstore - Hstore Inflator

# SYNOPSIS
 

     package MySchema::Table;
       use base 'DBIx::Class';
    

       __PACKAGE__->load_components('InflateColumn::Serializer', 'Core');
       __PACKAGE__->add_columns(
           'data_column' => {
               'data_type' => 'VARCHAR',
               'size'      => 255,
               'serializer_class' => 'Hstore',
           }
        );
    

        Then in your code...
    

        my $struct = { 'I' => { 'am' => 'a struct' };
        $obj->data_column($struct);
        $obj->update;
    

        And you can recover your data structure with:
    

        my $obj = ...->find(...);
        my $struct = $obj->data_column;
    

The data structures you assign to "data\_column" will be saved in the database in Hstore format.
 

- get\_freezer
 

    Called by DBIx::Class::InflateColumn::Serializer to get the routine that serializes
    the data passed to it. Returns a coderef.
     

- get\_unfreezer
 

    Called by DBIx::Class::InflateColumn::Serializer to get the routine that deserializes
    the data stored in the column. Returns a coderef.
     

# AUTHOR
 

Jeen Lee
 

# SEE ALSO

[DBIx::Class::InflateColumn::Serializer](http://search.cpan.org/perldoc?DBIx::Class::InflateColumn::Serializer)

[Pg::hstore](http://search.cpan.org/perldoc?Pg::hstore)

# LICENSE
 

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
 
