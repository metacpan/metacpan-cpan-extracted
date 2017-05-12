#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
require Catmandu::Fix;

lives_ok(sub{

    my $markdown = <<EOF;
ILL or 'Interlibrary loan' enables patrons to get articles or books from any library, both in Belgium or abroad.

Books are usually available in print, journal articles and book chapters are usually delivered as pdf attachment to an email.
Some supplying libraries have restrictions, e.g. the items supplied can only be viewed in the requesting library and may not be borrowed.
ILL requests are not for free, please check the price list first.

The document delivery service also provides books and articles available in a UGent library at a remote faculty. ILL requests met by UGent libraries are free for UGent students and staff.
Requests for items that are available in electronic form or available in the faculty of the requester will be cancelled.


This service is only available to registered patrons.
Filing a request?

* start [web request](http://rolland.ugent.be/requests/new "Request document delivery")
* via SFX document request (e.g. when the full-text is not accessible)


Current pricing for interlibrary requests:

|                                                        | document available at any UGent location     | document delivered from outside      |
|----------------------------------------------------    |------------------------------------------    |----------------------------------    |
| UGent students                                         | 0,00 €                                       | 5,00 €                               |
| UGent staff                                            | 0,00 €                                       | 10,00 €                              |
| students at HoGent, Artevelde hogeschool or HoWest     | 5,00 €                                       | 5,00 €                               |
| staff of HoGent, Artevelde hogeschool or HoWest        | 5,00 €                                       | 10,00 €                              |
| Library card holders                                   | 5,00 €                                       | 10,00 €                              |
| All other requesters                                   | 25,00 €                                      | not available                        |


Payment:

* Requesters have to pay the amount due in the library upon pickup of the book. Articles and chapters are available in digital form, payment is due in the library, within one month after delivery.
* UGent staff requests are invoiced regularly to their departments. No payment needed at pickup.
* Libraries requesting on behalf of their patrons receive an invoice or can pay with IFLA vouchers.

Requests from external libraries can only be processed if the document is readily available at a UGent library.
At UGent, items like reference works, old and precious books, manuscripts, maps, dissertations are excluded from ILL. They can be consulted at the library only.
Please contact the interlibrary service (docu\@mail.lib.ugent.be) with your re
EOF

    my $fixer = Catmandu::Fix->new(fixes => ["markdown_to_html('markdown')"]);
    my $record = { markdown => $markdown };
    $fixer->fix($record);

});

done_testing 1;
