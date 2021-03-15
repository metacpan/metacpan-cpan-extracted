package App::PerlNitpick::PCPWrap;
use strict;
use warnings;
use Object::Method;

sub new {
    my ($class, $pcp_class, $on_violate_cb) = @_;

    my $o = $pcp_class->new;

    method(
        $o,
        violation => sub {
            my ($self, $msg, $expl, $elem) = @_;
            return [$msg, $expl, $elem];
        }
    );

    return $o;
}

1;
