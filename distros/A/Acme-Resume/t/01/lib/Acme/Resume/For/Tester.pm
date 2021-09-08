use Acme::Resume;
use strict;
use warnings;

# PODCLASSNAME

resume Tester {

    name 'The Tester';

    email 'the.tester@example.com';

    address ['A street 2', 'Inatown', 'USA'];

    phone '+1 (555) 123 4321';

    education {
        school => 'Central West Junior High',
        location => 'Capital City',
        program => 'Junior high',
        started => 'August 25, 1981',
        left => 'June 3, 1984',
        description => 'Junior high.',
    };

    education {
        school => 'Owen Patterson High',
        location => 'Capital City',
        program => 'High School',
        started => 'August 24, 1984',
        left => 'June 4, 1987',
        description => qs{Had glasses.

            Good at math.
        },
    };

    education {
        school => 'Capital City Institute of Technology',
        url => 'http://www.ccit.org/',
        location => 'Capital City',
        program => 'Computer Science',
        started => 'September 2, 1987',
        left => 'May 22, 1990',
        description => 'Top of the class.',
    };

    job {
        company => 'Capital City Institute of Technology Cleaners',
        location => 'Capital City',
        role => 'Cleaner',
        started => 'March 15, 1988',
        left => 'May 22, 1990',
        description => 'Making ends meet.',
    };

    job {
        company => 'Omni Consumer Products',
        location => 'Capital City',
        role => 'Software developer',
        started => 'May 25, 1990',
        left => 'March 31, 1999',
        description => 'Cubicle warrior.',
    };

}

1;
