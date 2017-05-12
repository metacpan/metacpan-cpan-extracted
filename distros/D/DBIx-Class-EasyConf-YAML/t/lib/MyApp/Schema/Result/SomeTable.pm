package MyApp::Schema::Result::SomeTable;

use parent qw[ DBIx::Class::Core ];
__PACKAGE__->load_components(qw[ EasyConf::YAML ]);
our $DDL ||= __PACKAGE__->configure;



1;

__DATA__
--->
=head1 NAME

MyAPP::Schema::Result::SomeTable - Random Schema File

=head1 DESCRIPTION
---
  table: some_table
  primary_key: id
  columns:
    id:
      type: int
      nullable: 0
      is_auto_increment: 1
    name:
      type: VARCHAR
      size: 16
      nullable: 0
    description:
      type: VARCHAR
      size: 128
      nullable: 1
  relationships:
    - other_relation: 
        - belongs_to
        - MyApp::Schema::Result::SomeOtherTable
        - id
  unique:
    name_uniq: id
    desc_uniq: 
      - name
      - description
      

# EndOfYAML

