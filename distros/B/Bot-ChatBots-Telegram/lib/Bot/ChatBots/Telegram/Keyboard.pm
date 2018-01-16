package Bot::ChatBots::Telegram::Keyboard;
use strict;
use warnings;
{ our $VERSION = '0.010'; }

use Ouch;
use Log::Any qw< $log >;
use Data::Dumper;

use Moo;
use namespace::clean;

use Exporter qw< import >;
our @EXPORT_OK = qw< keyboard >;

has displayable => (
   is       => 'ro',
   required => 1,
);

has id => (
   is      => 'ro',
   default => sub { return 0 },
   isa     => sub {
      my $n         = shift;
      my $complaint = 'keyboard_id MUST be an unsigned 32 bits integer';
      ouch 500, $complaint unless $n =~ m{\A(?: 0 | [1-9]\d* )\z}mxs;
      my $r = unpack 'N', pack 'N', $n;
      ouch 500, $complaint unless $n eq $r;
      return;
   },
);

has _value_for => (
   is       => 'ro',
   required => 1,
);

{
   my ($ONE, $ZERO, $BOUNDARY);

   BEGIN {
      $ONE      = "\x{200B}";
      $ZERO     = "\x{200C}";
      $BOUNDARY = "\x{200D}";
   } ## end BEGIN

   sub __encode_uint32 {
      my $x = shift;
      (my $b = unpack 'B32', pack 'N', $x) =~ s/^0+//mxs;
      $b = '0' unless length $b;
      return join '', map { $_ ? $ONE : $ZERO } split //, $b;
   } ## end sub __encode_uint32

   sub __decode_uint32 {
      my $x = shift;
      my $b = join '', map { $_ eq $ONE ? '1' : '0' } split //, $x;
      $b = substr(('0' x 32) . $b, -32, 32);
      return unpack 'N', pack 'B32', $b;
   } ## end sub __decode_uint32

   sub __encode {
      my ($label, $keyboard_id, $code) = @_;
      return join '', $label,
        $BOUNDARY, __encode_uint32($keyboard_id),
        $BOUNDARY, __encode_uint32($code),
        $BOUNDARY;
   } ## end sub __encode

   sub __decode {
      return unless defined $_[0];
      my ($label, $kid, $code) = $_[0] =~ m{
         \A
                      (.*)
            $BOUNDARY ((?:$ZERO|$ONE)+)
            $BOUNDARY ((?:$ZERO|$ONE)+)
            $BOUNDARY
         \z
      }mxs;
      return unless defined $code;
      return ($label, __decode_uint32($kid), __decode_uint32($code));
   } ## end sub __decode
}

sub BUILDARGS {
   my ($class, %args) = @_;
   ouch 500, 'no input keyboard' unless exists $args{keyboard};
   my $id = $args{id} //= 0;
   @args{qw<displayable _value_for>} = __keyboard($args{keyboard}, $id);
   return \%args;
} ## end sub BUILDARGS

sub _decode {
   my ($self, $x, $name) = @_;
   if (ref($x) eq 'HASH') {
      $x = $x->{payload} if exists $x->{payload};
      $x = $x->{text} // undef;
   }
   elsif (ref($x)) {
      ouch 500, "$name(): pass either hash references or plain scalars";
   }

   return __decode($x);
} ## end sub _decode

sub get_value {
   my ($self, $x) = @_;
   my (undef, undef, $code) = $self->_decode($x, 'get_value');
   return undef unless defined $code;

   my $vf = $self->_value_for;
   if (!exists($vf->{$code})) {
      $log->warn("get_value(): received code $code is unknown");
      return undef;
   }
   return $vf->{$code};
} ## end sub get_value

sub get_keyboard_id {
   my ($self, $x) = @_;
   my (undef, $keyboard_id) = $self->_decode($x, 'get_keyboard_id');
   return $keyboard_id;
}

sub __keyboard {
   my ($input, $keyboard_id) = @_;
   ouch 500, 'invalid input keyboard, not an ARRAY'
     unless ref($input) eq 'ARRAY';
   ouch 500, 'invalid empty keyboard' unless @$input;

   my $code = 0;
   my @display_keyboard;
   my (%value_for, %code_for);
   for my $row (@$input) {
      ouch 500, 'invalid input keyboard, not an AoA'
        unless ref($row) eq 'ARRAY';

      my @display_row;
      push @display_keyboard, \@display_row;
      for my $item (@$row) {
         ouch 500, 'invalid input keyboard, not an AoAoH'
           unless ref($item) eq 'HASH';

         my %display_item = %$item;
         push @display_row, \%display_item;

         my $command = delete $display_item{_value};
         next unless defined $command;
         my $cc = $code_for{$command} //= $code++;
         $value_for{$cc} //= $command;
         $display_item{text} =
           __encode($display_item{text}, $keyboard_id, $cc);
      } ## end for my $item (@$row)
   } ## end for my $row (@$input)
   return (\@display_keyboard, \%value_for);
} ## end sub __keyboard

sub keyboard {
   my %args;
   if (@_ > 1) {
      if (ref($_[0])) {
         $args{keyboard} = [@_];
      }
      else {
         %args = @_;
      }
   } ## end if (@_ > 1)
   elsif (@_ == 1) {
      my $x = shift;
      if (@$x > 0) {
         if (ref($x->[0]) eq 'ARRAY') {
            $args{keyboard} = $x;
         }
         else {
            $args{keyboard} = [$x];    # one row only
         }
      } ## end if (@$x > 0)
   } ## end elsif (@_ == 1)
   return Bot::ChatBots::Telegram::Keyboard->new(%args);
} ## end sub keyboard

1;
