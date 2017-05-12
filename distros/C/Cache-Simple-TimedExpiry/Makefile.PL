           use inc::Module::Install;

           name            ('Cache-Simple-TimedExpiry');
           abstract        ('A lightweight cache with timed expiration');
           author          ('Robert Spier <rspier@pobox.com>, Jesse Vincent <jesse@bestpractical.com>');
           version_from    ('lib/Cache/Simple/TimedExpiry.pm');
           license         ('perl');

           requires        ('perl' => 5.005);

&WriteAll;
