#
# This file is part of Dancer-Plugin-FormValidator
#
# This software is copyright (c) 2013 by Natal Ngétal.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::TestApp;

use Dancer;
use Dancer::Plugin::FormValidator;

get '/' => sub {
    return 'Hello world';
};

post '/contact' => sub {
    if ( my $results = dfv('profile_contact') ) {
        return 'The form is validate';
    }
    else {
        return $results;
    }
};

post '/other_contact' => sub {
    my $results = form_validator_error('profile_contact');

    if ( ! $results ) {
        return 'The form is validate';
    }
    else {
        return $results;
    }
};

1;
