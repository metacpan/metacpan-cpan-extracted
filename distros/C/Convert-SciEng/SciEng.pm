package Convert::SciEng;

use strict;
use vars qw( $VERSION ) ;
use Carp;

require 5.004_04;      ##Last standard version of Perl that I use

$VERSION = '0.91';

# Preloaded methods go here.

##Begin forming the lookup hashes using arrays
my @SP_Postfixs = qw(   P    T    g    x    k        m    u    n     p     f     a);
my @SI_Postfixs = qw(   P    T    G    M    K        m    u    n     p     f     a);
my @factors     = qw(1e15 1e12  1e9  1e6  1e3 1e0 1e-3 1e-6 1e-9 1e-12 1e-15 1e-18);
my @CS_Postfixs = qw(    P     T     G     M     K     );
my @CS_factors  =   (2**50,2**40,2**30,2**20,2**10,2**0);

##Form the regexp for extracting the suffixes
my $SP_Suffixes = join '','[',@SP_Postfixs,']';
my $SI_Suffixes = join '','[',@SI_Postfixs,']';
my $CS_Suffixes = join '','[',@CS_Postfixs,']';

##Add the null index for unity
splice (@SP_Postfixs,5,0,'');
splice (@SI_Postfixs,5,0,'');
push   (@CS_Postfixs,   ,'');

##Form the lookup hashes
my %SP_Postfixs;
@SP_Postfixs{@SP_Postfixs} = @factors;

my %SI_Postfixs;
@SI_Postfixs{@SI_Postfixs} = @factors;

my %CS_Postfixs;
@CS_Postfixs{@CS_Postfixs} = @CS_factors;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  my $mode = shift;
  $mode = lc $mode;
  if ($mode eq 'spice') {
    $self->{'_SUFFIX'} = $SP_Suffixes;
    $self->{'_FACTORS'}  = \%SP_Postfixs;
    $self->{'_POSTFIXS'}  = \@SP_Postfixs;
  }
  elsif ($mode eq 'si') {
    $self->{'_SUFFIX'} = $SI_Suffixes;
    $self->{'_FACTORS'}  = \%SI_Postfixs;
    $self->{'_POSTFIXS'}  = \@SI_Postfixs;
  }
  elsif ($mode eq 'cs') {
    $self->{'_SUFFIX'} = $CS_Suffixes;
    $self->{'_FACTORS'}  = \%CS_Postfixs;
    $self->{'_POSTFIXS'}  = \@CS_Postfixs;
  }
  else {
    croak "Unrecoginized mode: $mode\n";
  }
  $self->{FORMAT} = '%5.5g';
  bless ($self,$class);
  return $self;
}

sub format {
  my $self = shift;
  return $self->{FORMAT} unless scalar @_;
  my $format = shift;
  unless ($format =~ /^\%\d+(\.\d+)?([scduxoefg]|l[duxo])$/) {
    croak "Illegal printf format: $format";
  }
  $self->{FORMAT} = $format;
  return $self->{FORMAT};
}

# remove postfix scale factor and convert to scientific
sub unfix {
  my $self = shift;
  my $char;
  my @num = @_;
  for (@num) {
    next unless index($self->{'_SUFFIX'}, substr($_,-1,1)) != -1;
    $char = chop; ##Remove that character
    $_ *= $self->{'_FACTORS'}->{$char};
  }
  return wantarray ? @num : $num[0];
}

# add postfix scale factor and convert from scientific
sub fix {
  my $self = shift;
  my (@SciNum) = @_;
  my ($pfix,$y);
  NUMBER: for (@SciNum) {
    $y = abs($_);
    foreach $pfix (@{ $self->{'_POSTFIXS'} }) {
      if ($y >= $self->{'_FACTORS'}->{$pfix}) {
	$_ = sprintf("$self->{FORMAT}${pfix}",$_/$self->{'_FACTORS'}->{$pfix});
	next NUMBER;
      }
    }
  }
  return wantarray ? @SciNum : $SciNum[0];
}

1;

__END__

=pod

=head1 NAME

Convert::SciEng - Convert 'numbers' with scientific postfixes

=head1 SYNOPSIS

  #!/usr/local/bin/perl -w

  use strict;
  use Convert::SciEng

  my $c = Convert::SciEng->new('spice');
  my $s = Convert::SciEng->new('si');

  print "Scalar\n";
  print $c->unfix('2.34u'), "\n\n";

  print "Array\n";
  print join "\n", $c->unfix(qw( 30.6k  10x  0.03456m  123n 45o)), "\n";

  ##Note, default format is 5.5g
  print "Default format is %5.5g\n";
  print join "\n", $c->fix(qw( 35e5 0.123e-4 200e3 )), "";
  $c->format('%8.2f');
  print "Change the format is %8.2g\n";
  print join "\n", $c->fix(qw( 35e5 0.123e-4 200e3 )), "";

  print "Check out the SI conversion\n";
  print join "\n", $s->unfix(qw( 30.6K  10M  0.03456m  123n 45o)), "";

=head1 REQUIRES

perl5.004_04 or greater, Carp

=head1 DESCRIPTION

Convert::SciEng supplies an object for converting numbers to and from
scientific notation with user-defined formatting.  Three different styles
of fix are supported, standard CS, SI and SPICE:

 SPICE  =    P    T    g    x    k   ''    m    u    n     p     f     a
 SI     =    P    T    G    M    K   ''    m    u    n     p     f     a
 Fix    = 1e15 1e12  1e9  1e6  1e3  1e0 1e-3 1e-6 1e-9 1e-12 1e-15 1e-18

 CS     =    P    T    G    M    K   ''
 Fix    = 2^50 2^40 2^30 2^20 2^10  2^0

Methods are supplied for creating the object and defining which fix style
it will use, and defining for format of numbers as they are converted to
scientific notation.

=head1 METHODS

=head2 Creation

=over 4

=item Convert::SciEng->new('style');

Creates and returns a new Number::SI object of the appropiate style,
C<'cs'> or C<'si'> or C<'spice'>. The styles aren't case sensitive

=item $fix->format(FORMAT);

Sets the format of number converter B<TO> fix to be C<FORMAT>.
FORMAT is any valid format to sprintf, like C<'%5.5g'> or C<'%6.4e'>.
The default format is C<'%5.5g'>.

=back

=head2 Conversion

=over 4

=item $fix->fix(0.030405); # 30.405m

Convert a number to scientific notation with fixes.
Returns a string in the format given to it with the fix appended to
the end.  Also works with arrays, with an array of strings being
returned.

=item $fix->unfix('12u'); # 12e-06

Convert a string from scientific notation.  Returns a number in
exponential format.  Also works with arrays, with an array of numbers
being returned.

=back

Note, by examining the module it should be relatively easy to figure out
how to create an object for any other scientific notation abbreviations.
If you think it is something that might be useful to others, then
email me and I'll add it to the module.

=head1 DIAGNOSTICS

=over 4

=item Unrecognized mode: MODE

(F) Generated when you try specify an illegal mode like so:
  
  $a = Convert::SciEng->new('foo');

=item Illegal printf format: FORMAT

(F) An illegal format was specified.  Valid formats must match the following
regexp:

C</^\%\d+(\.\d+)?([scduxoefg]|l[duxo])$/>

=head1 AUTHOR

Colin Kuskie, ckuskie@cpan.org

=head1 KUDOS

Many thanks to Steven McDougall for his comments about the content and
style of my module and for sending me his templates for module
creation.  They can be found at:

http://world.std.com/~swmcd/steven/Perl/index.html

and I highly recommend them for beginning module writers.

Also thanks to Tom Christiansen for the perltoot podpage.

=cut

1;
