
use strict;
use warnings;

use Test::More;
use Term::ANSIColor qw( colorstrip );

{
    package    # Hide from indexers
      KENTNL::Example;

    use Acme::Beamerang::Logger;

    sub do_work {
        log_warn { "This is a warning" };
        log_trace { "This is a trace" };
    }
}

my $capture = '';
{
    my %old = %ENV;
    delete $old{$_} for grep /BEAMERANG/, keys %old;
    local (%ENV) = (%old);
    local $SIG{__WARN__} = sub { $capture .= colorstrip($_[0]) };
    KENTNL::Example->do_work;
}
like( $capture, qr/\[warn\s+KENT/, "warn level emitted by default" );
unlike( $capture, qr/\[trace\s+KENT/, "trace level not emitted by default" );

$capture = '';
{
    my %old = %ENV;
    delete $old{$_} for grep /BEAMERANG/, keys %old;
    local (%ENV) = (%old);
    $ENV{BEAMERANG_UPTO} = 'fatal';
    local $SIG{__WARN__} = sub { $capture .= colorstrip($_[0]) };
    KENTNL::Example->do_work;
}
unlike( $capture, qr/\[warn\s+KENT/, "warn level not emitted with UPTO=fatal" );
unlike( $capture, qr/\[trace\s+KENT/, "trace level not emitted with UPTO=fatal" );

$capture = '';
{
    my %old = %ENV;
    delete $old{$_} for grep /BEAMERANG/, keys %old;
    local (%ENV) = (%old);
    $ENV{BEAMERANG_UPTO} = 'trace';
    local $SIG{__WARN__} = sub { $capture .= colorstrip($_[0]) };
    KENTNL::Example->do_work;
}
like( $capture, qr/\[warn\s+KENT/, "warn level emitted with UPTO=trace" );
like( $capture, qr/\[trace\s+KENT/, "trace level emitted with UPTO=trace" );


done_testing;
