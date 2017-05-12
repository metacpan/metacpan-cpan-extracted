use strict;
use warnings;
use Test::More;

use_ok( 'Data::MuForm' );
use_ok( 'Data::MuForm::Field' );
use_ok( 'Data::MuForm::Fields' );
use_ok( 'Data::MuForm::Field::Text' );
use_ok( 'Data::MuForm::Field::Submit' );
use_ok( 'Data::MuForm::Field::Checkbox' );
use_ok( 'Data::MuForm::Field::Select' );
use_ok( 'Data::MuForm::Field::Compound' );
use_ok( 'Data::MuForm::Field::Integer' );
use_ok( 'Data::MuForm::Field::PrimaryKey' );
use_ok( 'Data::MuForm::Field::Repeatable' );

done_testing;
