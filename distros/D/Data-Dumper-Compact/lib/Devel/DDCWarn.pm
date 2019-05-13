package Devel::DDCWarn;

use strictures 2;
use Data::Dumper::Compact;

use base qw(Exporter);

our @EXPORT = map +($_, $_.'T'), qw(Df Dto Dwarn Derr);

our $ddc = Data::Dumper::Compact->new;

sub import {
  my ($class, @args) = @_;
  my $opts;
  if (@args and ref($args[0]) eq 'HASH') {
    $opts = shift @args;
  } else {
    while (@args and $args[0] =~ /^-(.*)$/) {
      my $k = $1;
      my $v = (shift(@args), shift(@args));
      $opts->{$k} = $v;
    }
  }
  $ddc = Data::Dumper::Compact->new($opts) if $opts;
  return if @args == 1 and $args[0] eq ':none';
  $class->export_to_level(1, @args);
}

sub _ef {
  map +(@_ > 1 ? [ list => $_ ] : $_->[0]),
    [ map $ddc->expand($_), @_ ];
}

sub Df { $ddc->format(_ef(@_)) }

sub DfT {
  my ($tag, @args) = @_;
  $ddc->format([ list => [ [ key => $tag ], _ef(@args) ] ]);
}

sub _dto {
  my ($fmt, $noret, $to, @args) = @_;
  return unless @args > $noret;
  $to->($fmt->(@args));
  return wantarray ? @args[$noret..$#args] : $args[$noret];
}

sub Dto { _dto(\&Df, 0, @_) }
sub DtoT { _dto(\&DfT, 1, @_) }

my $W = sub { warn $_[0] };

sub Dwarn { Dto($W, @_) }
sub DwarnT { DtoT($W, @_) }

my $E = sub { print STDERR $_[0] };

sub Derr { Dto($E, @_) }
sub DerrT { DtoT($E, @_) }

1;

=head1 NAME

Devel::DDCWarn - Easy printf-style debugging with L<Data::Dumper::Compact>

=head1 SYNOPSIS

  use Devel::DDCWarn;
  
  my $x = Dwarn some_sub_call(); # warns and returns value
  my @y = Derr other_sub_call(); # prints to STDERR and returns value
  
  my $x = DwarnT X => some_sub_call(); # warns with tag 'X' and returns value
  my @y = DerrT X => other_sub_call(); # similar

=head1 DESCRIPTION

L<Devel::DDCWarn> is a L<Devel::Dwarn> equivalent for L<Data::Dumper::Compact>.

The idea, basically, is that it's incredibly annoying to start off with code
like this:

  return some_sub_call();

and then realise you need the value, so you have to write:

  my @ret = some_sub_call();
  warn Dumper [ THE_THING => @ret ];
  return @ret;

With L<Devel::DDCWarn>, one can instead write:

  return DwarnT THE_THING => some_sub_call();

and expect it to Just Work.

To integrate with your logging, you can do:

  our $L = sub { $log->debug("DDC debugging: ".$_[0] };
  ...
  return DtoT $L, THE_THING => some_sub_call();

When applying printf debugging style approaches, it's also very useful to
be able to do:

  perl -MDevel::DDCwarn ...

and then within the code being debugged, abusing the fact that a prefix of ::
is short for main:: so we can add:

  return ::DwarnT THE_THING => some_sub_call();

and if we forget to remove them, the lack of command-line L<Devel::DDCWarn>
exported into main:: will produce a compile time failure. This is exceedingly
useful for noticing you forgot to remove a debug statement I<before> you
commit it along with the test and fix.

=head1 EXPORTS

All of these subroutines are exported by default.

L<Data::Dumper::Compact> is referred to herein as DDC.

=head2 Dwarn

  my $x = Dwarn make_x();
  my @y = Dwarn make_y_array();

C<warn()>s the L</Df> DDC dump of its input, then returns the first element
in scalar context or all arguments in list context.

=head2 Derr

  my $x = Derr make_x();
  my @y = Derr make_y_array();

prints the L</Df> DDC dump of its input to STDERR, then returns the first
element in scalar context or all arguments in list context.

=head2 DwarnT

  my $x = Dwarn TAG => make_x();
  my @y = Dwarn TAG => make_y_array();

Like L</Dwarn>, but passes its first argument, the tag, through to L</DfT>
but skips it for the return value.

=head2 DerrT

  my $x = Derr TAG => make_x();
  my @y = Derr TAG => make_y_array();

Like L</Derr>, but accepts a tag argument that is included in the output
but is skipped for the return value.

=head2 Dto

  Dto(sub { warn $_[0] }, @args);

Like L</Dwarn>, but instead of warning, calls the subroutine passed as the
first argument - this function is low level but still returns the C<@args>.

=head2 DtoT

  DtoT(sub { err $_[0] }, $tag, @args);

The tagged version of L<Dto>.

=head2 Df

  my $x = Df($thing);
  my $y = Df(@other_things);

A single value is returned formatted by DDC. Multiple values are transformed
to a DDC list.

=head2 DfT

  my $x = Df($tag => $thing);
  my $y = Df($tag => @other_things);

A tag plus a single value is formatted as a two element list. A tag plus
multiple values is formatted as a list containing the tag and a list of the
values.

=head1 CONFIGURATION

  use Devel::DDCWarn \%options, ...;

  perl -MDevel::DDCWarn=-optname,value,-other,value ...;

  $Devel::DDCWarn::ddc = Data::Dumper::Compact->new(\%options);

Options passed as a hashref on a C<use> line or using - prefixing on the
command line are used to initialise the L<Data::Dumper::Compact> object.

Note that this primarily being a debugging and/or scripting oriented tool, if
something initialises us again later, this will reset the (single) global
C<$ddc> used by this code and change all output throught the process.

However, if you need a localised change of formatting style, C<$ddc> is a full
fledged global so you are absolutely allowed to C<local> it:

  my $ddc = Data::Dumper::Compact->new(\%my_local_options);
  local $Devel::DDCWarn::ddc = $ddc;

If you have a convincing reason for using this functionality in a way where
the globality is a bug rather than a feature, please start a conversation
with the authors so we can figure out what to do about it.

=head1 COPYRIGHT

Copyright (c) 2019 the L<Data::Dumper::Compact/AUTHOR> and
L<Data::Dumper::Compact/CONTRIBUTORS> as listed in L<Data::Dumper::Compact>.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<https://dev.perl.org/licenses/>.

=cut
