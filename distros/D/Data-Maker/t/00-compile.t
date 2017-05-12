#!perl -w
use strict;
use warnings; 

use Test::More tests => 21;

# just attempt to load every module in the distribution

use_ok("Data::Maker");
use_ok("Data::Maker::Field");
use_ok("Data::Maker::Field::Code");
use_ok("Data::Maker::Field::DateTime");
use_ok("Data::Maker::Field::File");
use_ok("Data::Maker::Field::Format");
use_ok("Data::Maker::Field::IP");
use_ok("Data::Maker::Field::Initials");
use_ok("Data::Maker::Field::Lorem");
use_ok("Data::Maker::Field::MultiSet");
use_ok("Data::Maker::Field::Number");
use_ok("Data::Maker::Field::Password");
use_ok("Data::Maker::Field::Person");
use_ok("Data::Maker::Field::Person::FirstName");
use_ok("Data::Maker::Field::Person::Gender");
use_ok("Data::Maker::Field::Person::LastName");
use_ok("Data::Maker::Field::Person::MiddleName");
use_ok("Data::Maker::Field::Person::SSN");
use_ok("Data::Maker::Field::Set");
use_ok("Data::Maker::Record");
use_ok("Data::Maker::Value");
