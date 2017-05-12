#!/usr/bin/env perl

use strict;
use warnings;
use Data::Transpose::Validator;
use Data::Dumper;

use Test::More tests => 2;


# failing test which should illustrate the usage

my $dirty = {
             email => "i'm\@broken",
             password => "1234",
             country => "  ",
             custom => "hello",
             email2 => "hello",
             country2 => "ciao",
            };

# set the options
my $form = Data::Transpose::Validator->new(stripwhite => 1);

my %sc = (
          email => {
                    validator => {
                                  class => 'EmailValid',
                                  options => {
                                              a => 1,
                                              b => 2,
                                             },
                                 },
                    required => 1,
                    options => {
                                stripwhite => 0, # override the global
                               },
                   },
          password => {
                       validator => {
                                     class => 'PasswordPolicy',
                                     options => {
                                                 minlength => 10,
                                                 maxlength => 50,
                                                 patternlength => 4,
                                                 mindiffchars => 5,
                                                 disabled => {
                                                              digits => 1,
                                                              mixed => 1,
                                                              username => 1,
                                                             }
                                                }
                                    },
                       required => 0,
                      }
         );

$form->prepare(%sc);

# add more, if you want, as an arrayref (will keep the sorting);

my $customvalidator = sub {
    my $field = shift;
    return ($field, undef) if $field =~ m/\w/;
    return (undef, "My error");
};

$form->prepare([
                { name => "country" ,
                  required => 1,
                  validator => $customvalidator,
                },
                { name => "custom",
                  required => 1,
                  validator => $customvalidator,
                },
                {
                 name => "country2",
                 validator => 'String'},
                {
                 name => "email2",
                 validator => "EmailValid"
                },
               ]
              );


# here $clean is meant to be fully validated, or nothing
my $clean = $form->transpose($dirty);

if ($clean) {
    print Dumper($clean);
} else {
    print Dumper($form->errors);
}
# print Dumper($form);

ok($form->errors);
ok(defined $form->success && $form->success == 0);

# print Dumper($form->field);
# print join("\n", $form->faulty_fields);
# 
# print Dumper($form->errors_as_hashref_for_humans);
# print "\n";
# 
# print Dumper($form->errors_as_hashref);
# 
# print "\n";
# 
print join("\n", $form->packed_errors), "\n";
