package # Hide from pause
     TestSchema::Sakila3::Result::FooBar;
   
use base 'DBIx::Class::Core';
    
__PACKAGE__->table("foobar");
__PACKAGE__->add_columns(
  "id"    => { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name"  => { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");




1;
