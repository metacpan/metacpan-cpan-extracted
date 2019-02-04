use 5.010;
use utf8;
use strict;
use warnings;

package Banal::Util::Mini; # git description: v0.001-3-gfdd78c4
# vim: set ts=2 sts=2 sw=2 tw=115 et :
# ABSTRACT: Provide several utility functions with minimal dependencies.
# KEYWORDS: Util utility light-weight

our $VERSION = '0.002';
# AUTHORITY

use Carp                     qw(croak);
use Scalar::Util             qw(blessed  refaddr reftype);
use List::Util 1.45          qw(any first none pairs uniq);
use List::MoreUtils 0.426    qw(arrayify firstres listcmp); # arrayify and listcmp were introduced in 0.420; stabilized by 0.426
# use overload;              # TAU : Required by flatten() and hence arrayify(), when they are defined here, as copied from List::MoreUtils;



use Data::Printer       qw(p np);  # During development only. TODO: comment this line out later.

use namespace::autoclean;


use Exporter::Shiny;
use vars qw(@EXPORT_OK);
BEGIN {
   @EXPORT_OK = qw(
    msg
    polyvalent

    hash_access
    hash_lookup
    hash_lookup_staged

    inverse_dict
    inverse_mapping

    maybe
    maybe_kv
    peek

    tidy_arrayify
    first_viable
    invoke_first_existing_method

    affixed
    prefixed
    suffixed

    sanitize_env_var_name
    sanitize_subroutine_name
    sanitize_identifier_name
  );

  # Add function aliases with underscore prefixes (single & double)
  my @ok = @EXPORT_OK;
  foreach my $pfx ('_', '__') {
    { no strict 'refs';
      *{ __PACKAGE__ . '::' . $pfx . $_ } = \&{ __PACKAGE__ . '::' . $_ } for @ok ;
    }
    push @EXPORT_OK, ( map {; $pfx . $_ } (@ok) );
  }
}
#say STDERR 'EXPORT_OK : ' . np @EXPORT_OK;



#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
# UTILITY FUNCTIONS
#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

#----------------------------------------------------------
# CLASS / OBJECT related functions
#----------------------------------------------------------

#######################################
sub polyvalent     {  # Helps with the parameter processing of polyvalent (object or class) methods
#######################################
  my $proto     = shift;
  my $self      = blessed $proto ? $proto : $proto->new();
  my $class     = blessed $self;
  wantarray ? ($self, $class, $proto) : $self;
}


#######################################
sub msg(@) {  # Message text builder to be used in error output (warn, die, ...)
#######################################
  my $o = blessed ($_[0]) ? shift : caller();
  state $pfx = eval { $o->_msg_pfx(@_) } // '';
  join ('', $pfx, @_, "\n")
}


#..........................................................
# STRING/TEXT processing functions
#..........................................................

sub prefixed ($@)  {
  my %opts = %{ ref ($_[0]) eq 'HASH' ? shift : +{ prefix => shift} };
  affixed(\%opts, @_ )
}

sub suffixed ($@)  {
  my %opts = %{ ref ($_[0]) eq 'HASH' ? shift : +{ suffix => shift} };
  affixed(\%opts, @_ )
}

sub affixed ($@)  {
    my %opts = %{ ref ($_[0]) eq 'HASH' ? shift : +{} };
    my $pfx  = exists $opts{prefix} ? ( $opts{prefix} // '') : '';
    my $sfx  = exists $opts{suffix} ? ( $opts{suffix} // '') : '';
    map {; $pfx . $_ . $sfx } @_
}

#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
sub sanitize_env_var_name    (;$) { &sanitize_identifier_name  }
sub sanitize_subroutine_name (;$) { &sanitize_identifier_name  }
sub sanitize_identifier_name (;$) {
#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
  # cleanse (sanitize) the name by replacing non-alphanumeric chars with underscores.
  my $name = (@_) ? shift : $_;    # If no argument is given, use the default SCALAR variable as our argument.

  $name  =~ s/[^_A-Za-z0-9]/_/g;
  return $name;
}


#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# HASH related functions
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
sub peek     {
#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
  my ($h, $keys)   = @_;
  my @keys = tidy_arrayify($keys);
  my $v;

  foreach my $key (@keys) {
    $v = exists $h->{$key} ? $h->{$key} : undef;
    return $v if defined($v);
  }

  # Allow falling back to a set of defaults
  # In scalar context, the first one defined wins.
  # In list context, we return a list that contains all of the defined results
  # wantarray ? ( grep { defined } @_ ) : first { defined } @_;

  # [TAU] @ [ 2019-02-02 ] :  Adopting a simpler behaviour, as below.
  $v = first { defined } @_;
  wantarray ? ( $v // () ) : $v;
}


# accumulate hash entries, given a set of ket value pairs.
# The result will only include those pairs where both the key
# and the value are 'defined'.
sub maybe     { &maybe_kv }
sub maybe_kv {
  my @r;  # result is accumulated in an array (instead of a hash), so that we can use 'push'
  push @r, ( shift // () )  if (@_ % 2);  # This is how we deal with an odd number of args (including a single arg)

  foreach my $pair ( pairs @_ ) {
    my ( $key, $value ) = @$pair;
      push @r, ($key => $value) if defined($key) && defined ($value);
  }
  wantarray ? (@r) : +{@r}
}


#######################################
sub hash_access {
#######################################
# FUNCTION: deep hash access via multiple succesive keys that each signify a level deeper than the previous.
#  hash_access ($h, key1, key2, key3, ...)
  my $node = shift;
  foreach my $k (@_) {
    return unless defined $node && defined $k;
    return unless eval { exists $node->{$k} };
    $node = $node->{$k};
  }
  $node
}

#######################################
sub inverse_mapping  {
#######################################
  my  @k  = tidy_arrayify (shift);
  my  @v  = tidy_arrayify (@_);
  my  @res;

  foreach my $v (@v) {
    do { push @res, ($v => $_) } for @k;
  }
  return wantarray ? (@res) : +{ @res };
}

########################################
sub inverse_dict {
########################################
  my  %h;
      %h = (%h, %{; shift } ) while ( ref($_[0]) eq 'HASH');
      %h = (%h, @_);
  my %res;

  while (my ($k, $v) = each %h) {
    %res = (%res, inverse_mapping($k, $v));
  }
  wantarray ? (%res) : \%res
}


########################################
sub hash_lookup {  # lookup($key, sources =>[], depots => [])
########################################
  my  $key      = (@_ % 2) ? shift : undef;
  my  %opts     = (@_);
      $key    //= $opts{key};
  my $debug     = $key =~ /dist/;
  local $_;     # allows us to be called in the likes of map / grep; as well as our little recursion below.

  #say STDERR "    Looking up '$key' ... OPTIONS are :  " . np %opts  if $debug;

  # DEPOTS are hash refs that will be used for looking up SOURCES themselves, when those are strings (instead of a hash refs)
  my  @depots     = ( grep { defined $_ } arrayify( @opts{qw(depot  depots)}) );

  # SOURCES are hash refs that will be tried in order for key lookup.
  # Alternatively, these may be denoted by strings, in which case they will themsleves be looked up in the 'depots'
  my  @sources    = ( grep { defined $_ } arrayify( @opts{qw(source sources)}) );
      @sources    = map { ref($_) ? $_ : ( eval { hash_lookup("$_", sources=>[ @depots] ) } // () ) }  @sources;

SOURCE:
  foreach my $h ( @sources ) {
    next SOURCE unless defined($h) && ref($h);    # Don't bother checking reftype. This allows for eventual fancy overloading to work.
    next SOURCE unless defined $h;
    next SOURCE unless exists $h->{$key};
    my  $v = $h->{$key};

    return wantarray ? ( $v ) :  $v;
  } # sources

  die "Can't find the '$key' in any of the hash sources."
}



#######################################
sub hash_lookup_staged   {
#######################################
# Returns the first found item (corresponding to any of the given keys) in any of the hash sources.
  local $_;
  my  %opt      = @_;
  my  @keys     = tidy_arrayify($opt{keys});
#  my  $sources  = $opt{sources}  // [ ];
#      $sources  = [ $sources ] if ref $sources eq 'HASH';
  my  @sources  = tidy_arrayify($opt{source}, $opt{sources});
  my  $debug    = $opt{debug};
  my  $res;

SOURCE :
  foreach my $h (@sources) {
    next SOURCE unless defined($h) && ( reftype($h) eq 'HASH');
    my $map_keys  = $opt{source_opts}{refaddr $h}{map_keys};
    my @mkeys     = defined($map_keys) ? ( $map_keys->(@keys) ) : (@keys);
KEY :
    foreach my $key (@mkeys) {
      next  KEY unless defined $key;
#      say STDERR "     Hash lookup for key '$key' in hash '$h' ..."    if $debug;
      next  KEY unless exists $h->{$key};
      $res = $h->{$key};
#      say STDERR "     Value found for key '$key'  => : '$res'\n"     if $debug;
      last  SOURCE if defined $res;
    }
  }

  die "Can't find (in any of the given sources) the given keys [@keys] !" unless defined $res;

  return $res;
}




#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# ARRAY & LIST related functions
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

######################################
sub tidy_arrayify(;@)  { local $_;  my @res = ( grep { defined $_ } ( uniq( arrayify( @_) ))) }
#######################################

#=begin STOLEN_FROM_List_MoreUtils
# ------------------------------------------------------
# TAU:  The two routines, as well as the comment about 'leaks' were stolen from C<List::MoreUtils>
#       The only thing I did was privatizing names and turning 'flatten' into a proper subroutine (instead of a scalar CODE closure)
#       That allowed me to get rid of a warning.
# ------------------------------------------------------
# apparently, "leaks" when lexically hidden in arrayify.
# sub flatten   { map { (ref $_ and ("ARRAY" eq ref $_ or overload::Method($_, '@{}'))) ? (flatten(@{$_})) : ($_) } @_; }
# sub arrayify  { map { flatten($_) } @_; }
# #=cut


#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
sub first_viable (&@) {
#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
  # RETURN the result of the first viable evaluation (i.e. first one that doesn't die on us, for whatever reason )
  my  $f    = shift;  # CODE BLOCK or subroutine ref. A closure is OK, too.
  my  @e    = ();
  local $_;

  #local $@; # so that we don't mess up caller's eval/error handling.
  eval { 1 };   # resets $@ to whatever perl considers to be 'success';

  # This part, as well as the general flow, is copied shamelessly from the 'first()' function in C<List::Util::PP>.
  unless ( length ref $f && eval { $f = \&$f; 1 } ) {
    require Carp;
    Carp::croak("Not a subroutine reference");
  }

  # Return the result of the first viable evaluation (i.e. first one that doesn't die on us, for whatever reason )
  foreach ( @_) {
    my ($item) = ($_);

    if (wantarray)  {  my @v = ( eval { $f->() } );  return @v unless $@;   }
    else            {  my $v =   eval { $f->() }  ;  return $v unless $@;   }

    # No luck. Save the error, for an eventual error stack output if we die.
    push @e, {
        item => $item, err => $@,
        msg=> "Failed to invoke CODE BLOCK on item '$item', with the error : '$@'\n",
      };
  }

  # NO LUCK with any invocation.
  # At this point, '$@' would normally be set to a true value by the last failed eval.
  if (@e) {
    my @emsg = map { $_->{msg} } @e;
    my $name = (caller(0))[3];  # The name of this particular subroutine.
    croak "$name : Failed to sucessfully invoke any of the given code blocks!\n"
      . "Here's the list of all errors:\n\n @emsg"
  }
  return;
}

#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
sub invoke_first_existing_method {
#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
  my  $o        = shift;
  my  @methods  = arrayify(@_);
  my  @args     = ();

  first_viable { $o->$_(@args) } @methods;
}




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Banal::Util::Mini - Provide several utility functions with minimal dependencies.

=head1 VERSION

version 0.002

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Banal-Util-Mini>
(or L<bug-Banal-Util-Mini@rt.cpan.org|mailto:bug-Banal-Util-Mini@rt.cpan.org>).

=head1 AUTHOR

Tabulo <tabulo@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Tabulo

Tabulo <dev@tabulo.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Tabulo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
