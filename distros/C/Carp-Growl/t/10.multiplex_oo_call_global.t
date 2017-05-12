package main;
our %LINES;

package Foo;
use lib 't/testlib';    # Load fake 'Growl::Any'

use Carp::Growl qw/global/;

sub new {
    my $class = shift;
    bless {}, $class;
}

$main::LINES{Foo} = [ map { __LINE__ + $_ } 1 .. 2 ];
sub _warn  { shift; warn @_; }
sub _die   { shift; die @_; }
sub _carp  { shift; carp @_; }
sub _croak { shift; croak @_; }

package Bar;    # subclass of 'Foo'

use base 'Foo';

$main::LINES{Bar} = $main::LINES{Foo};

package Baz;    # stand alone

sub new {
    my $class = shift;
    bless {}, $class;
}

$main::LINES{Baz}
    = [ @{ $main::LINES{Foo} }[ 0, 1 ], __LINE__ + 3, __LINE__ + 4 ];
sub _warn  { shift; Foo::_warn 0,  @_; }
sub _die   { shift; Foo::_die 0,   @_; }
sub _carp  { shift; Foo::_carp 0,  @_; }
sub _croak { shift; Foo::_croak 0, @_; }

package main;
use Test::More;

my @funcs = qw/_warn _die _carp _croak/;
my @packs = qw/Foo Bar Baz/;
Test::More->import( tests => ( @funcs * @packs ) * 2 );

my $CAPTURED_WARN;
local $SIG{__WARN__} = local $SIG{__DIE__} = sub { $CAPTURED_WARN = shift; };

for my $pkg (@packs) {
    my @lines = @{ $main::LINES{$pkg} } or die explain %main::LINES;
    my $LINE = shift(@lines);
    diag 'call &' . $pkg . '::<func> from main';
    my $obj = $pkg->new();
    for my $func (@funcs) {
        my $warn_message = 'call &' . $pkg . '::' . $func . '()';
        my $warn_message_complete
            = $warn_message . ' at ' . __FILE__ . ' line ';
        my $expected = $warn_message_complete;
        $expected .= $LINE ? $LINE : ( __LINE__ + 1 );
        eval { $obj->$func($warn_message) };
        like( $Growl::Any::SUB_NOTIFY_ARGS->[2],
            qr/^\Q$expected\E\.?$/, $warn_message . " - GROWL" );
        like( $CAPTURED_WARN, qr/^\Q$expected\E\.?$/,
            $warn_message . " - $func" );
        $CAPTURED_WARN                = undef;           #reset
        @$Growl::Any::SUB_NOTIFY_ARGS = ();              #reset
        $LINE                         = shift(@lines);
    }
}
