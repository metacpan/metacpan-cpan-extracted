package MyApp::Schema::Result::SomeOtherTable;

use parent qw[ DBIx::Class::Core ];
__PACKAGE__->load_components(qw[ EasyConf::YAML ]);
our $DDL ||= __PACKAGE__->configure;



1;

__DATA__
--->
=head1 NAME

MyAPP::Schema::Result::SomeOtherTable - Random Schema File

=head1 DESCRIPTION
---
  table: some_other_table
  primary_key: id
  columns:
    id:
      type: int
      nullable: 0
      is_auto_increment: 1
    this_name:
      type: VARCHAR
      size: 16
      nullable: 0
    desc:
      type: VARCHAR
      size: 128
      nullable: 1
  relationships:
    - foreign_relation:
        - has_one
        - MyApp::Schema::Result::SomeTable
        - id

       

# EndOfYAML

