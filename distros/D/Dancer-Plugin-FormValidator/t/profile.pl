#
# This file is part of Dancer-Plugin-FormValidator
#
# This software is copyright (c) 2013 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
{
     profile_contact => {
         'required' => [ qw(
             name subject body
          )],
          msgs => {
            missing => 'Not here',
          }
     },
}
