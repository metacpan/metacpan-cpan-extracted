package App1::DoBill;

=head1 NAME

App1::DoBill - handle this step of the App1 app

=cut

use strict;
use warnings;
use base qw(App1);
use CGI::Ex::Dump qw(debug);

sub run_step {
    my $self = shift;

    my $r = $self->cgix->apache_request;
    local $| = 1 if ! $r;

    $self->cgix->print_content_type;

    print "<div id=fake_progress>\n";
    print "At this point I would do something useful with the form data<br>\n";
    print "I would probably add the customer and lineitems and bill the order<br>\n";
    debug $self->form;
    print "But for now I will just pretend I'm doing something for 10 seconds<br>\n";

    my $max = 10;
    for my $i (1 .. $max) {
        $r->rflush if $r;
        sleep 1;
        print "Sleep $i/$max<br>\n";
    }

    print "</div>\n";
    # this little progress effect would be better off with something like yui
    print "<script>
        var el = document.getElementById('fake_progress');
        if (el) el.style.display='none';
        document.scrollTop = '0px';
        </script>\n";

    return 0;
}

1;

