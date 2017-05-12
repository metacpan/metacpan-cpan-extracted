package t::PersonEDM;
use strict;
use warnings;

use Ambrosia::Meta;
class
{
    extends => [qw/Ambrosia::EntityDataModel/],
    public  => [qw/PersonId FirstName LastName Age/],
};

sub source_name
{
    return 'Client';
}

sub table
{
    return 'tPerson';
}

sub primary_key
{
    return 'PersonId';
}

1;
