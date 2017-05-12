package BackPAN::Index::Types;

use Mouse;
use Mouse::Util::TypeConstraints;

# Predeclare class types.  Otherwise if the class isn't loaded Mouse might
# quietly and confusingly think its a non-class type.
class_type('App::Cache');
class_type('BackPAN::Index');
class_type('BackPAN::Index::Database');
class_type('BackPAN::Index::IndexFile');
class_type('DBI::db');
class_type('DBIx::Class::Schema');

coerce class_type("URI") =>
  from 'Str',
  via {
      require URI;
      URI->new($_)
  };

coerce class_type("Path::Class::File") =>
  from 'Str',
  via {
      require Path::Class::File;
      Path::Class::File->new($_)
  };

coerce class_type("Path::Class::Dir") =>
  from 'Str',
  via {
      require Path::Class::Dir;
      Path::Class::Dir->new($_)
  };

1;
