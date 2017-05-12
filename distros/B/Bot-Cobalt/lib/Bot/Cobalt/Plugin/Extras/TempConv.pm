package Bot::Cobalt::Plugin::Extras::TempConv;
$Bot::Cobalt::Plugin::Extras::TempConv::VERSION = '0.021003';
## RECEIVES AND EATS:
##  _public_cmd_tempconv  ( !tempconv )
##  _public_cmd_temp      ( !temp )

use strictures 2;

use Object::Pluggable::Constants qw/ :ALL /;
use Bot::Cobalt::Utils qw/ color /;

use constant MAX_TEMP => 100_000_000_000;

sub new { bless [], shift }

sub Cobalt_register {
  my ($self, $core) = splice @_, 0, 2;
  $core->plugin_register( $self, 'SERVER',
    qw/
      public_cmd_temp
      public_cmd_tempconv
    /,
  );

  $core->log->info("Registered, cmds: temp tempconv");

  return PLUGIN_EAT_NONE
}

sub Cobalt_unregister {
  my ($self, $core) = splice @_, 0, 2;

  $core->log->info("Unregistering");

  return PLUGIN_EAT_NONE
}

## !temp(conv):
sub Bot_public_cmd_tempconv { Bot_public_cmd_temp(@_) }
sub Bot_public_cmd_temp {
  my ($self, $core) = splice @_, 0, 2;
  my $msg     = ${ $_[0] };
  my $context = $msg->context;

  my $str = $msg->message_array->[0] || '';
  my ($temp, $type) = $str =~ /(-?\d+\.?\d*)?(\w)?/;

  $temp = 0   unless $temp;
  $temp = MAX_TEMP if $temp > MAX_TEMP;
  $type = 'F' unless $type and grep { $_ eq uc($type) } qw/F C K/;

  my ($f, $k, $c);
  for my $upper (uc $type) {
    ( ($f, $k, $c) = ( $temp, _f2k($temp), _f2c($temp) ) and last )
      if $upper eq 'F';

    ( ($f, $k, $c) = ( _c2f($temp), _c2k($temp), $temp ) and last )
      if $upper eq 'C';

    ( ($f, $k, $c) = ( _k2f($temp), $temp, _k2c($temp) ) and last )
      if $upper eq 'K';
  }

  $_ = sprintf("%.2f", $_) for ($f, $k, $c);

  my $resp = color( 'bold', "(${f}F)" )
             . " == " .
             color( 'bold', "(${c}C)" )
             . " == " .
             color( 'bold', "(${k}K)" );

  my $channel = $msg->channel;

  $core->send_event( 'message', $context, $channel, $resp );

  return PLUGIN_EAT_ALL
}

## Conversion functions:
sub _f2c {  (shift(@_) - 32    ) * (5/9)  }
sub _f2k {  (shift(@_) + 459.67) * (5/9)  }

sub _c2f {  shift(@_) * (9/5) + 32  }
sub _c2k {  shift(@_) + 273.15      }

sub _k2f {  shift(@_) * (9/5) - 459.67  }
sub _k2c {  shift(@_) - 273.15          }

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::Extras::TempConv - Temperature conversion

=head1 SYNOPSIS

  !tempconv 27F
  !temp 27F
  !temp 3C
  !temp 270K

=head1 DESCRIPTION

Simple temperature conversion plugin for Cobalt.

Speaks Fahrenheit, Celsius, and Kelvin.
A converted temperature is returned in all three formats:

  <avenj> !temp 27f
  <cobalt> (27.00F) == (-2.78C) == (270.37K)

(B<!tempconv> is also an alias for B<!temp>)

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
