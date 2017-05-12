#!perl

use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;
use Test::More tests => 1;

my $dtv = Data::Transpose::Validator->new;
$dtv->prepare([
               { name => 'year',
                 validator => {
                               class => 'NumericRange',
                               options => {
                                           min => 1900,
                                           max => 2050,
                                           integer => 1,
                                          }
                              }
               },
               {
                name => 'mail',
                validator => 'EmailValid',
                required => 1,
               }
              ]);

$dtv->transpose({ year => 'blabla' });

is_deeply($dtv->errors_hash,
          {
           year => [
                    {
                     value => 'Not a number',
                     name => 'notanumber',
                    },
                    {
                     name => 'notinteger',
                     value => 'Not an integer',
                    }
                   ],
           mail => [
                    {
                     value => 'Missing required field mail',
                     name => 'required',
                    }
                   ],
          }, "Errors hash as expected");
