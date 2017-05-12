use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Test::More;
use Test::Output;

use Amon2::CLI 'MyApp';

{
    stdout_like {
        MyApp->bootstrap->show_usage(-exitval => 'NOEXIT');
    } qr/print "usage";/, "show usage";
}

done_testing;

__END__

=head1 SYNOPSIS

    print "usage";

=cut

