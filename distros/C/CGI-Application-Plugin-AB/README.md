NAME
----

CGI::Application::Plugin::AB - A/B Testing for CGI::Application-based applications.



SYNOPSIS
--------
      use CGI::Application::Plugin::AB;


      # Your application
      sub run_mode {
        my ($self) = ( @_);

        my $version = $self->a_or_b();
      }

DESCRIPTION
------------
This module divides all visitors into an "A" group, or a "B" group, and
allows you to determine which set they are a member of.


MOTIVATION
----------
To test the effectiveness of marketing text, or similar, it is sometimes
useful to display two different versions of a web-page to visitors:

* One version will show features and a price of $5.00

* One version will show features and a price of $10.00

To do this you must pick 50% of your visitors at random and show half
one template, and the other half the other.

Once the user signs up you can record which version of the page was
displayed, allowing you to incrementally improve your signup-rate.

This module helps you achieve this goal by automatically assigning all
visitors membership of the A-group, or the B-group.

You're expected to handle the logic of showing different templates and
recording the version the user viewed.

AUTHOR
------
Steve Kemp <steve@steve.org.uk>

COPYRIGHT AND LICENSE
---------------------
Copyright (C) 2014 Steve Kemp <steve@steve.org.uk>.

This library is free software. You can modify and or distribute it under
the same terms as Perl itself.

