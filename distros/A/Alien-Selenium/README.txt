Alien::Selenium automatically installs the Selenium
web testing framework.

Copyright (c) 2005, 2006 Mattia Barbon and Dominique Quatravaux.
This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Please notice that Selenium and JsUnit come with their own license.

To install:

    perl Build.PL                    # But see below
    ./Build test
    ./Build install

Starting from version 0.02 Alien::Selenium bundles a Selenium
distribution. To download and install a different Selenium version,
either modify the $SELENIUM_VERSION variable in lib/Alien/Selenium.pm,
or pass a --selenium-version option to Build.PL, eg

    perl Build.PL --selenium-version=0.6.0

If fetching the Selenium distribution fails for any reason,
putting the manually-downloaded archive inside the build
directory should suffice to proceed.
