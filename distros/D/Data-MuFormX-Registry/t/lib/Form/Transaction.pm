package Form::Transaction;

use Moo;
use Data::MuForm::Meta;

extends 'Data::MuForm';

has_field 'sender_address' => (
  type => 'Text',
  required => 1 );

has_field 'recipient_address' => (
  type => 'Text',
  required => 1 );

has_field 'signature' => (
  type => 'Text',
  required => 1 );

has_field 'amount' => (
  type => 'Text',
  required => 1 );

1;
