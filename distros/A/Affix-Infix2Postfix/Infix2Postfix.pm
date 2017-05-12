package Affix::Infix2Postfix;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

#use Data::Dumper;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.03';


sub new { 
    my $class = shift;
    my %hsh=@_;
    my $self=\%hsh; 
    my $op;

# add some check code here

# create regular expressions
# combined lists insert defaults etc.

    for $op (@{$self->{'ops'}}) {
      if (!exists( $op->{'type'} )) { $op->{'type'}='binary'; }
      if (!exists( $op->{'assoc'} )) { $op->{'assoc'}='left'; }
      if (!exists( $op->{'trans'} )) { $op->{'trans'}=$op->{'op'}; }
    }

    @{$self->{'opr'}}=map { $_->{'op'} } @{$self->{'ops'}};

    @{$self->{'tokens'}}=(@{$self->{'opr'}},@{$self->{'func'}},@{$self->{'vars'}},@{$self->{'grouping'}});

    $self->{'varre'}=join('|',map { quotemeta($_) } @{$self->{'vars'}});
    $self->{'funcre'}=join('|',map { quotemeta($_) } @{$self->{'func'}});

    $self->{'numre'}='[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?';

    $self->{'re'}=join('|',(map { quotemeta($_).'(?!'.quotemeta($_).')' } @{$self->{'tokens'}}),$self->{'numre'});
    $self->{'ree'}=$self->{'re'}.'|.+?';
    $self->{ERRSTR}='';
    bless $self,$class;
    return $self;
}

sub tokenize {
    my $self=shift;
    my $str=shift;
    my $ree=$self->{'ree'};
#    print "ree: $ree\n";
    return ( $str =~ m/($ree)/g ); # tokenize
#    return ( $str =~ m/($ree)/xg ); # tokenize
}

# Returns the indices of non recognized tokens

sub verify {
    my $self=shift;
    my $re=$self->{'re'};
    my @matches=@_;
    return grep { $matches[$_] !~ /^$re$/ } 0..$#matches;
}

sub translate {
    my $self=shift;
    my $str=shift;
    my (@matches,@errors,@res);
    
    @matches=$self->tokenize($str);
    @errors=$self->verify(@matches);

    if (@errors) {
      $self->{ERRSTR}='Bad tokens: '.join(' ',@matches[@errors]);
      return undef;
    }

    @res=$self->elist(@matches);
    return @res;
}


sub elist {
  my $self=shift;
  my (@poss,$i,$cop); # possible breaks
  my $b=0;
  my $numre=$self->{'numre'};
  my $varre=$self->{'varre'};
  my (%func,@func,@ops,$un,$fn,$as,$rop,$op,$bi,$bd,$las,@trlist);
  @func=@{$self->{'func'}};
  @func{@func}=1..@func;
  @ops=@{$self->{'ops'}};

#    print Dumper(\%func);
#    print "elist: ",join(" ",map { "$_" } @_ ),"\n";

#    the only single elements should be numbers or vars 

  if ($#_ == 0) {
    if ( $_[0] =~ m/^($numre|$varre)$/ ) {
      return $_[0];
    } else {
      die "Single element '$_[0]' wrong\n";
    }
  }
  
# All operators and functions

  for $cop(@ops) {
    $un=($cop->{'type'} eq 'unary') ? 1:0;
    $las=($cop->{'assoc'} eq 'left') ? 1:0;
    $fn=($cop->{'op'} eq 'func') ? 1:0;
    $op=$cop->{'op'};
    $rop=$cop->{'trans'};

#    print Dumper($cop);

    if ($un) {  # unary operator    
      if ($fn) {  # magic type for functions
	if ($las) { # left  associative
	  if ($func{$_[0]}) { return ( $self->elist(@_[1..$#_]) , $_[0] ); }
	} else {    # right associative
	  if ($func{$_[-1]}) { return ( $self->elist(@_[0..$#_-1]) , $_[-1] ); }
	}
      } else {
#	print "op: $op\n";
	if ($las) { # left  associative   # normal unary ops
	  if ($_[0] eq $op) { return ( $self->elist(@_[1..$#_]) , $rop ); }
	} else {    # right associative
	  if ($func{$_[-1]}) { return ( $self->elist(@_[0..$#_-1]) , $rop ); }
	}
      }
    } else { # binary operator
      $bi=$las ? ')':'(';
      $bd=$las ? '(':')';
      # we only need to inspect the ones not at the since they could only be
      # unary ops
      @trlist=$las ? (reverse 0..$#_) : (0..$#_); 

      $b=0;  #brace count
      for $i(@trlist) {
	$_=$_[$i];
	#	print "item: ",$_,"\n";
	($b++,next) if $_ eq $bi;
	($b--,next) if $_ eq $bd;
	if ($b < 0) { die "Too many ')'\n"; }
	next if $b;
	next if $i==0 or $i==$#_;
	# if we made it here we are outside of braces
	if ( $_ eq $op ) { return ( $self->elist(@_[(0..$i-1)]) , $self->elist(@_[$i+1..$#_]) ,$rop ); } # this is the magic line
      }

      # end of binary
    }
  }
#  print Dumper($cop);
  
# this is just for parens

  if ( $_[0] eq '(' and $_[$#_] eq ')' ) {
    if ( $#_<2 ) { die "Empty parens\n"; }
    return $self->elist(@_[1..$#_-1]);
  }
  
  die "error stack is: @_ error\n";
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Affix::Infix2Postfix - Perl extension for converting from infix
notation to postfix notation.

=head1 SYNOPSIS

  use Affix::Infix2Postfix;

  $inst=Affix::Infix2Postfix->new(
    'ops'=>[
	  {op=>'+'},
	  {op=>'-'},
	  {op=>'*'},
	  {op=>'/'},
	  {op=>'-',type=>'unary',trans=>'u-'},
	  {op=>'func',type=>'unary'},
	 ],
	  'grouping'=>[qw( \( \) )],
	  'func'=>[qw( sin cos exp log )],
	  'vars'=>[qw( x y z)]
	 );
  $rc=$inst->translate($str)
  || die "Error in '$str': ".$inst->{ERRSTR}."\n";


=head1 DESCRIPTION

Infix2Postfix as the name suggests converts from infix to postfix
notation. The reason why someone would like to do this is that postfix
notation is generally much easier to do in computers. For example take
an expression like: a+b+c*d. For us humans it's pretty easy to do that
calculation.  But it's actually much better for computers to get a
string of operations such as: a b + c d * +, where the variable names
mean put variable on stack.

=head1 AUTHOR

addi@umich.edu

=head1 SEE ALSO

perl(1).

=cut
