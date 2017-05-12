use Test;
use Chart::Sequence;
use Chart::Sequence::Renderer::Imager;
use strict;

my $has_imager = eval "require Imager";
my $skip = $has_imager ? 0 : "no Imager.pm";

my $r;
my $s;

my @tests = (
sub {
    return skip $skip, 1 if $skip;
    $r = Chart::Sequence::Renderer::Imager->new;
    ok $r->isa( "Chart::Sequence::Renderer::Imager" );
},
sub {
    return skip $skip, 1 if $skip;
    $s = Chart::Sequence->new(
        Name => "Sequence 1",
        Messages => [
            [ Foo => "Bar", "Message 1" ],
            [ Bar => "Baz", "Message 2" ],
            Chart::Sequence::Message->new(
                From        => 'Baz',
                To          => 'Bat',
                Name        => 'Message 3',
                Color       => '#000040',
            ),
        ],
    );
    ok $s;
},
#sub {
#    return skip $skip, 1 if $skip;
#    $r->lay_out( $s );
#    ok 1;
#},

sub {
    return skip $skip, 1 if $skip;
    my $f = "sequence_chart_via_Imager.png";
    $r->render_to_file( $s, $f );
#    system "ee $f";
    my $ok = -e $f;
    ok $ok, 1, "$f existance";
    warn "\nCreated Image: $f via Imager.pm\n";
}

);

plan tests => 0+@tests;

$_->() for @tests;
