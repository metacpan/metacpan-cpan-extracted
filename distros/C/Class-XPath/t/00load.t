use Test::More qw(no_plan);
BEGIN { use_ok('Class::XPath', 
               get_name => 'name',
               get_parent => 'parent',
               get_root   => 'root',
               get_children => 'kids',               
               get_attr_names => 'param',
               get_attr_value => 'param',
               get_content    => 'data',
              ); }

