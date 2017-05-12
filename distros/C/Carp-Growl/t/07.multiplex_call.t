package main;
our %LINES;

package Foo;
use lib 't/testlib';    # Load fake 'Growl::Any'
use Carp::Growl;

$main::LINES{ __PACKAGE__ . '' }
    = [ map { __LINE__ + $_ } 1 .. 4 ];
sub _warn  { warn @_; }
sub _die   { die @_; }
sub _carp  { carp @_; }
sub _croak { croak @_; }

package Bar;            # subclass of 'Foo'
use lib 't/testlib';    # Load fake 'Growl::Any'
use Carp::Growl;

$main::LINES{ __PACKAGE__ . '' }
    = [ @{ $main::LINES{Foo} }[ 0, 1 ], undef, __LINE__ + 4 ];
sub _warn  { Foo::_warn(@_); }
sub _die   { Foo::_die(@_); }
sub _carp  { carp(@_); }          #remarkable
sub _croak { Foo::_croak(@_); }

package Baz;                      # stand alone

$main::LINES{ __PACKAGE__ . '' }
    = [ @{ $main::LINES{Bar} } ];
${ $main::LINES{ __PACKAGE__ . '' } }[2] = __LINE__ + 3;
sub _warn  { Bar::_warn(@_); }
sub _die   { Bar::_die(@_); }
sub _carp  { Bar::_carp(@_); }
sub _croak { Bar::_croak(@_); }

package main;
use Test::More;

my @funcs = qw/_warn _die _carp _croak/;
my @packs = qw/Foo Bar Baz/;
Test::More->import( tests => ( @funcs * @packs ) * 2 );

my $CAPTURED_WARN;
local $SIG{__WARN__} = local $SIG{__DIE__} = sub { $CAPTURED_WARN = shift; };
@{ $main::LINES{Foo} }[ 2, 3 ] = ();
for my $pkg (@packs) {
    my @lines = @{ $main::LINES{$pkg} } or die explain %main::LINES;
    my $LINE = shift(@lines);
    diag 'call &' . $pkg . '::<func> from main';
    for my $func (@funcs) {
        my $warn_message = 'call &' . $pkg . '::' . $func . '()';
        my $warn_message_complete
            = $warn_message . ' at ' . __FILE__ . ' line ';
        my $expected = $warn_message_complete;
        $expected .= $LINE ? $LINE : ( __LINE__ + 1 );
        eval { &{ $pkg . '::' . $func }($warn_message) };
        like( $Growl::Any::SUB_NOTIFY_ARGS->[2],
            qr/^\Q$expected\E\.?$/, $warn_message . " - GROWL" );
        like( $CAPTURED_WARN, qr/^\Q$expected\E\.?$/,
            $warn_message . " - $func" );
        $CAPTURED_WARN                = undef;           #reset
        @$Growl::Any::SUB_NOTIFY_ARGS = ();              #reset
        $LINE                         = shift(@lines);
    }
}
