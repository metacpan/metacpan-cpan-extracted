use strict;
use warnings;
use Test::More;

use lib qw( ../lib );

my @modules = qw(
  AproJo
  AproJo::Admin
  AproJo::Form
  AproJo::Front
  AproJo::User

  AproJo::DB::Schema

  AproJo::DB::Schema::Result::Address
  AproJo::DB::Schema::Result::Article
  AproJo::DB::Schema::Result::Configuration
  AproJo::DB::Schema::Result::Contact
  AproJo::DB::Schema::Result::Group
  AproJo::DB::Schema::Result::Order
  AproJo::DB::Schema::Result::Orderitem
  AproJo::DB::Schema::Result::Party
  AproJo::DB::Schema::Result::Preference
  AproJo::DB::Schema::Result::Role
  AproJo::DB::Schema::Result::Status
  AproJo::DB::Schema::Result::TimeEntry
  AproJo::DB::Schema::Result::Unit
  AproJo::DB::Schema::Result::User
  AproJo::DB::Schema::Result::UserGroup
  AproJo::DB::Schema::Result::UserRole
  AproJo::DB::Schema::Result::Usertime

  AproJo::Form::Address
  AproJo::Form::Article
  AproJo::Form::Configuration
  AproJo::Form::Contact
  AproJo::Form::Group
  AproJo::Form::Order
  AproJo::Form::Orderitem
  AproJo::Form::Party
  AproJo::Form::Preference
  AproJo::Form::Role
  AproJo::Form::Status
  AproJo::Form::TimeEntry
  AproJo::Form::Unit
  AproJo::Form::User

  AproJo::I18N::de
  AproJo::I18N::en

);

eval "package AproJo::I18N; use base 'Locale::Maketext'; 1;";

for my $module (@modules) {
  use_ok($module);
}

done_testing;
