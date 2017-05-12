package SchemaLkpDetection::Result::StudyType;

use strict;
use warnings;
use base qw/DBIx::Class::Core/;



__PACKAGE__->table("studyType");

__PACKAGE__->add_columns(
      "study_type_id",	{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
      "name",		{ data_type => "varchar2", is_nullable => 0, size => 45 },
      "user_id",	{ data_type => "integer", is_nullable => 0 }
    
);

__PACKAGE__->set_primary_key("study_type_id");

__PACKAGE__->belongs_to( "user" => "SchemaLkpDetection::Result::User", {"foreign.user_id" => "self.user_id"} );

	


1;