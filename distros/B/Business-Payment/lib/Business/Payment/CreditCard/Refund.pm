package Business::Payment::CreditCard::Refund;
use Moose::Role;

has '+number' => ( required => 1 );

no Moose::Role;
1;