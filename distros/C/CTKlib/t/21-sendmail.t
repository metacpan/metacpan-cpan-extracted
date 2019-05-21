#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 21-sendmail.t 260 2019-05-16 19:18:32Z minus $
#
#########################################################################
use strict;
use warnings;
use utf8;
use Test::More;
plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
plan tests => 1;

use CTK::Util qw/sendmail/;

use constant {
        TO      => 'to@example.com',
        FROM    => 'from@example.com',
        SMTP    => '192.168.0.1',
    };

my $message = <<'MESSAGE';
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent sit amet mi vel
tellus accumsan ultricies. Aenean non purus convallis, suscipit nibh ac, maximus
nibh. Aliquam sed mattis odio, id blandit quam. Donec tempor sagittis pretium. Donec
quis convallis nisi, et consequat dolor. Nulla posuere consectetur placerat. Maecenas
rhoncus ullamcorper odio eu consectetur. Aenean facilisis lectus nisi, ac posuere magna
cursus placerat. Integer nec cursus justo. Quisque vestibulum id turpis sed elementum.
Maecenas sed orci sed arcu accumsan facilisis. Maecenas iaculis aliquet tempus.
Nam tempus risus eu consectetur varius. Etiam varius nulla lorem, sit amet maximus
felis vestibulum vel.

Cras placerat enim at eleifend pharetra. Sed vehicula massa ac consequat facilisis.
Duis et faucibus dolor, euismod laoreet tortor. Pellentesque euismod lorem massa.
Donec orci quam, commodo nec nulla vel, finibus efficitur elit. Phasellus vitae sem
sed arcu faucibus fermentum in in felis. Nunc ac nunc eu augue auctor laoreet eget ac
orci. Nam vehicula, lectus in tincidunt tristique, augue urna eleifend sapien, vitae
facilisis neque ex vitae erat.

Sed at ante tristique, consequat dui eget, eleifend elit. Quisque pellentesque nunc id
orci ultricies, id porta diam placerat. Etiam laoreet leo non turpis ultrices tempus.
Ut at sem nisi. Pellentesque habitant morbi tristique senectus et netus et malesuada
fames ac turpis egestas. Curabitur consequat ipsum nisl. Ut eu euismod massa. Fusce
pretium felis quis lorem congue maximus. Cras id posuere enim. Suspendisse volutpat
ipsum eu ullamcorper tristique. Pellentesque iaculis in augue quis mollis. Quisque
ultrices risus ac tellus commodo blandit. Lorem ipsum dolor sit amet, consectetur
adipiscing elit.

Ut eu mi a erat pharetra condimentum et sit amet quam. Sed varius justo augue, vitae
porttitor tortor pretium quis. Curabitur justo enim, scelerisque eget tincidunt sit
amet, imperdiet et turpis. Nam elementum justo et erat rutrum, eget consectetur neque
commodo. Integer ornare a odio vel dapibus. Sed in lobortis nibh, vitae imperdiet
mauris. Pellentesque mollis ullamcorper justo quis interdum. Nulla dapibus augue quis
ligula scelerisque, lacinia faucibus orci dapibus. Vivamus consectetur tortor at cursus
porttitor. Vivamus sed lectus id ligula semper rutrum. Phasellus volutpat in nisl vel
congue. Nulla vel feugiat diam. Maecenas ullamcorper rutrum eros vel suscipit. Integer
a ligula nec risus imperdiet commodo. Nunc sed ex ac est pellentesque cursus.

Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae;
Ut mollis vehicula leo a vulputate. Donec orci nulla, tempor sed risus id, tempor
dignissim mi. Maecenas imperdiet lorem vitae imperdiet scelerisque. Sed commodo nunc
nec finibus dignissim. Nunc tincidunt odio a sapien vehicula, sit amet sodales mauris
convallis. Maecenas id luctus augue, et molestie tellus. Donec nisi erat, molestie sed
imperdiet at, facilisis et est. Maecenas tincidunt ligula est, non semper lectus
consequat quis. Nullam id dapibus lectus, eget finibus velit. Duis tempor consectetur
elit, quis suscipit odio tempor a. Duis tempor arcu eu dolor pulvinar, a tincidunt
lectus accumsan. Aenean imperdiet, quam eu posuere imperdiet, odio purus posuere
tortor, nec aliquam mauris nibh quis purus. Vivamus a sollicitudin urna. Nullam
varius ornare lectus, mattis molestie arcu volutpat id.
MESSAGE

if (TO =~ "example.com") {
    pass("SMTP sending");
} else {
    ok(sendmail(
        -smtp       => SMTP,
        -to         => TO,
        -from       => FROM,
        -subject    => "Test message",
        -message    => $message,
    ), "SMTP sending");
}

__END__

