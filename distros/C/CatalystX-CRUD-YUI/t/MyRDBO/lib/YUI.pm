package YUI;
use strict;
use base qw(
    Rose::DB::Object
    Rose::DB::Object::Helpers
    Rose::DBx::Object::MoreHelpers
);
use Carp;
use YUI::DB;
use YUI::Metadata;

sub meta_class {'YUI::Metadata'}

sub init_db {
    YUI::DB->new_or_cached();
}

sub schema_class_prefix {'YUI'}    # TODO instead __PACKAGE__ ?

1;
