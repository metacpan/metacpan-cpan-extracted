package Class::AutoClass;
our $VERSION = '1.56';
$VERSION=eval $VERSION;         # I think this is the accepted idiom..

use strict;
use Carp;
use Storable qw(dclone);
use Hash::AutoHash::Args qw(fix_keyword fix_keywords);
use Class::AutoClass::Root;
use base qw(Class::AutoClass::Root);

use vars qw($AUTOCLASS $AUTODB %CACHE @EXPORT);
$AUTOCLASS = __PACKAGE__;

sub new {
  # NG 09-11-07: when called 'from below' via SUPER::new, respect existing object
  my ( $self_or_class, @args ) = @_;
  my $class = ( ref $self_or_class ) || $self_or_class;
  # NG 06-02-03: 1st attempt to call declare at runtime if not declared at compile-time
  # declare($class) unless $class->DECLARED;
  # NG 06-02-03: 2nd attempt to declare at runtime if not declared at compile-time
  #              include $case and flag to indicate this is runtime
  declare($class,CASE($class),'runtime') unless $class->DECLARED;

  my $classes = $class->ANCESTORS || [];    # NG 04-12-03. In case declare not called
  my $can_new = $class->CAN_NEW;
  if ( !@$classes ) {    # compute on the fly for backwards compatibility
  # enumerate internal super-classes and find a class to create object
    ( $classes, $can_new ) = _enumerate($class);
  }
  # NG 09-11-07: when called 'from below' via SUPER::new, respect existing object
  my $self;
  if (ref $self_or_class) {
    $self=$self_or_class;
  } else {
    $self = $can_new ? $can_new->new(@args) : {};
    bless $self, $class;    # Rebless what comes from new just in case
  }
  my $args     = new Hash::AutoHash::Args(@args);
  # NG 09-03-19: put defaults processing under 'if' since rarely used
  #              minor efficiency gain (avoids creation of empty Args object)
  if ($args->defaults) {
    my $defaults = new Hash::AutoHash::Args( $args->defaults );
    # set arg defaults into args
    while ( my ( $keyword, $value ) = each %$defaults ) {
      $args->{$keyword} = $value unless exists $args->{$keyword};
    }}

################################################################################
# NG 05-12-08: initialization strategy changed. instead of init'ing class by class
#              down the hierarchy, it's now done all at once.
 $self->_init($class,$args);	# init attributes from args and defaults

# $defaults=new Hash::AutoHash::Args; # NG 05-12-07: reset $defaults. 
#				       # will accumulate instance defaults during initialization
# my $default2code={};

 for my $class (@$classes) {
   my $init_self = $class->can('_init_self');
   $self->$init_self( $class, $args ) if $init_self;
   # NG 10-08-22: moved test for OVERRIDE to here to fix bug in which subsequent
   #              calls to _init_self continue to operate on original $self !
   $self=$self->{__OVERRIDE__} if $self->{__OVERRIDE__};
   #  $self->_init( $class, $args, $defaults, $default2code );
 }
################################################################################

   if($self->{__NULLIFY__}) {
   	return undef;
    # NG 10-08-22: moved test for OVERRIDE to here to fix bug in which subsequent
    #              calls to _init_self continue to operate on original $self !
    # } elsif ($self->{__OVERRIDE__}) { # override self with the passed object
    #    $self=$self->{__OVERRIDE__};
    #    return $self;
      } else {
     return $self;
   }
}

################################################################################
# NG 05-12-08: initialization strategy changed. instead of init'ing class by class
#              down the hierarchy, it's now done all at once.
sub _init {
  my($self,$class,$args)=@_;
  my @attributes=ATTRIBUTES_RECURSIVE($class);
  my $defaults=DEFAULTS_RECURSIVE($class); # Args object
  my %fixed_attributes=FIXED_ATTRIBUTES_RECURSIVE($class);
  my %synonyms=SYNONYMS_RECURSIVE($class);
  my %reverse=SYNONYMS_REVERSE($class);    # reverse of SYNONYMS_RECURSIVE
  my %cattributes=CATTRIBUTES_RECURSIVE($class);
  my @cattributes=keys %cattributes;
  my %iattributes=IATTRIBUTES_RECURSIVE($class);
  my @iattributes=keys %iattributes;
  for my $func (@cattributes) {	# class attributes
    my $fixed_func=$fixed_attributes{$func};
    next unless exists $args->{$fixed_func};
#     no strict 'refs';
#     next unless ref $self eq $class;
    $class->$func($args->{$fixed_func});
  }
  # NG 08-03-21: moved default processing to separate loop before arg processing to fix bug.
  #              Bug: if attribute early in @iattributes sets attribute that comes later, 
  #              and later attribute has default, default clobbers value previously set!!
  for my $fixed_func (keys %$defaults) {
    # NG 09-04-22: skip class attributes. defaults should only be set at declare-time
    next if $cattributes{$fixed_func};
    
    # because of synonyms, this is more complicated than it might appear.
    # there are 4 cases: consider syn=>real 
    # 1) args sets syn,  defaults sets syn
    # 2) args sets real, defaults sets syn
    # 3) args sets syn,  defaults sets real
    # 4) args sets real, defaults sets real
    next if exists $args->{$fixed_func}; # handles cases 1,4 plus case of not synonym
    my $real=$synonyms{$fixed_func};
    next if $real && exists $args->{$fixed_attributes{$real}}; # case 2
    my $syn_list=$reverse{$fixed_func};
    next if $syn_list && 
      grep {exists $args->{$fixed_attributes{$_}}} @$syn_list; # case 3
    # okay to set default!!
    my $value=$defaults->{$fixed_func};
    # NG 10-01-06: allow CODE and GLOB defaults. dclone can't copy these...
    #              deep copy other refs so each instance has own copy
    my $copy;
    if (ref $value) {
      $copy=eval{dclone($value)};
      $value=$copy unless $@;	# use $copy unless dclone failed
    }
    # $value=ref $value? dclone($value): $value;
    $self->$fixed_func($value);
  }

  for my $func (@iattributes) {	# instance attributes
    my $fixed_func=$fixed_attributes{$func};
    if (exists $args->{$fixed_func}) {
      $self->$func( $args->{$fixed_func} );
#     } elsif (exists $defaults->{$fixed_func}) { 
#       # because of synonyms, this is more complicated than it might appear.
#       # there are 4 cases: consider syn=>real 
#       # 1) args sets syn,  defaults sets syn
#       # 2) args sets real, defaults sets syn
#       # 3) args sets syn,  defaults sets real
#       # 4) args sets real, defaults sets real
#       next if exists $args->{$fixed_func}; # handles cases 1,4 plus case of not synonym
#       my $real=$synonyms{$func};
#       next if $real && exists $args->{$fixed_attributes{$real}}; # case 2
#       my $syn_list=$reverse{$func};
#       next if $syn_list && 
# 	grep {exists $args->{$fixed_attributes{$_}}} @$syn_list; # case 3
#       # okay to set default!!
#       my $value=$defaults->{$fixed_func};
#       $value=ref $value? dclone($value): $value; # deep copy refs so each instance has own copy
#       $self->$func($value);
    }
  }
}

########################################

#sub _init {
# my ( $self, $class, $args, $defaults, $default2code ) = @_;
# my %synonyms = SYNONYMS($class);
# my $attributes = ATTRIBUTES($class);
# # only object methods here
# $self->set_instance_defaults( $args, $defaults, $default2code, $class );       # NG 05-12-07
# $self->set_attributes( $attributes, $args, $defaults, $default2code, $class ); # NG 05-12-07
# my $init_self = $class->can('_init_self');
# $self->$init_self( $class, $args ) if $init_self;
#}

sub set {
 my $self = shift;
 my $args = new Hash::AutoHash::Args(@_);
 while ( my ( $key, $value ) = each %$args ) {
  my $func = $self->can($key);
  $self->$func($value) if $func;
 }
}

sub get {
 my $self = shift;
 my @keys = fix_keyword(@_);
 my @results;
 for my $key (@keys) {
  my $func = $self->can($key);
  my $result = $func ? $self->$func() : undef;
  push( @results, $result );
 }
 wantarray ? @results : $results[0];
}

########################################
# NG 05-12-09: changed to always call method. previous version just stored
#              value for class attributes.
# note: this is user level method -- not just internal!!!
sub set_attributes {
  my ( $self, $attributes, $args ) = @_;
  my $class=ref $self;
  $self->throw('Atrribute list must be an array ref') unless ref $attributes eq 'ARRAY';
  # NG 09-03-19: fix_keywords now handled by Args tied hash
  # my @attributes=fix_keyword(@$attributes);
  for my $func (@$attributes) {
    next unless exists $args->{$func} && $class->can($func);
    $self->$func( $args->{$func} );
  }
}

 ## NG 05-12-07: process defaults.  $defaults contains defaults seen so far in the
# #  recursive initialization process that are NOT in $args. As we descend, also
# #  have to check synonyms: 
# @keywords=$class->ATTRIBUTES_RECURSIVE;
# for my $func (@keywords) {
#   next unless exists $defaults->{$func};
#   my $code=$class->can($func);
#   next if $default2code->{$func} == $code;
#   $self->$func($defaults->{$func});
#   $default2code->{$func}=$code;
# }
## for my $func (keys %$defaults) {
##   next if !$class->can($func);
##   $self->$func($defaults->{$func});
##   delete $defaults->{$func};
## }
#}

## sets default attributes on a newly created instance
## NG 05-12-07: changed to accumulate defaults in $defaults.  setting done in set_attributes.
##              previous version set values directly into object HASH.  this is wrong, since 
##              it skips the important step of running the attribute's 'set' method.
#sub set_instance_defaults {
# my ( $self, $args, $defaults, $default2code, $class ) = @_;
# my %class_funcs;
# my $class_defaults = DEFAULTS($class);
# map { $class_funcs{$_}++ } CLASS_ATTRIBUTES($class);
# while ( my ( $key, $value ) = each %$class_defaults ) {
#   next if exists $class_funcs{$key} || exists $args->{$key};
#   $defaults->{$key} = ref $value? dclone($value): $value; # deep copy refs;
#   delete $default2code->{$key};	# NG 05-12-07: so new default will be set
# }
#}

########################################
# NG 05-12-09: rewrote to use CATTRIBUTES_RECURSIVE. also changed to always call 
#              method. previous version just stored values
# sets class defaults at "declare time"
sub set_class_defaults {
 my ( $class ) = @_;
 my $defaults = DEFAULTS_RECURSIVE($class); # Args object
 my %fixed_attributes=FIXED_ATTRIBUTES_RECURSIVE($class);
 my %cattributes=CATTRIBUTES_RECURSIVE($class);
 my @cattributes=keys %cattributes;
 for my $func (@cattributes) {	# class attributes
   my $fixed_func=$fixed_attributes{$func};
   next unless exists $defaults->{$fixed_func};
   my $value=$defaults->{$fixed_func};
   # NG 06-02-03. vcassen observed that dclone not needed here since there
   #               can only be one copy of each class attribute
#   $value=ref $value? dclone($value): $value; # deep copy refs so each instance has own copy
   $class->$func($value);
 }
}
########################################
# NG 09-11-12: removed this sub, since it pollutes namespace unreasonably 
#               also changed all uses, of course. here and in AutoDB
# sub class { ref $_[0]; }

sub ISA {
 my ($class) = @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 @{ $class . '::ISA' };
}

sub AUTO_ATTRIBUTES {
 my ($class) = @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 @{ $class . '::AUTO_ATTRIBUTES' };
}

sub OTHER_ATTRIBUTES {
 my ($class) = @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 @{ $class . '::OTHER_ATTRIBUTES' };
}

sub CLASS_ATTRIBUTES {
 my ($class) = @_;
 no strict 'refs';
 no warnings;                             # supress unitialized var warning
 @{ $class . '::CLASS_ATTRIBUTES' };
}

sub SYNONYMS {
 my ($class) = @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 %{ $class . '::SYNONYMS' };
}
sub SYNONYMS_RECURSIVE {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my %synonyms;
 if (@_) {
   %synonyms=%{ $class . '::SYNONYMS_RECURSIVE' } = @_;
   my %reverse;
   while(my($syn,$real)=each %synonyms) {
     my $list=$reverse{$real} || ($reverse{$real}=[]);
     push(@$list,$syn);
   }
   SYNONYMS_REVERSE($class, %reverse);
 } else {
   %synonyms=%{ $class . '::SYNONYMS_RECURSIVE' };
 }
 wantarray? %synonyms: \%synonyms;
}
sub SYNONYMS_REVERSE {		# reverse of SYNONYMS_RECURSIVE. used to set instance defaults
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my %synonyms=@_ ? %{ $class . '::SYNONYMS_REVERSE' } = @_: 
   %{ $class . '::SYNONYMS_REVERSE' };
 wantarray? %synonyms: \%synonyms;
}
# ATTRIBUTES -- all attributes
sub ATTRIBUTES {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my @attributes=@_ ? @{ $class . '::ATTRIBUTES' } = @_ : @{ $class . '::ATTRIBUTES' };
 wantarray? @attributes: \@attributes;
}
sub ATTRIBUTES_RECURSIVE {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 sub _uniq {my %h; @h{@_}=@_; values %h;}
 my @attributes=@_ ? @{ $class . '::ATTRIBUTES_RECURSIVE' } = _uniq(@_): 
   @{ $class . '::ATTRIBUTES_RECURSIVE' };
 wantarray? @attributes: \@attributes;
}
# maps attributes to fixed (ie, de-cased) attributes. use when initializing attributes
# to args or defaults
sub FIXED_ATTRIBUTES_RECURSIVE {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my %attributes=@_ ? %{ $class . '::FIXED_ATTRIBUTES_RECURSIVE' } = @_:
   %{ $class . '::FIXED_ATTRIBUTES_RECURSIVE' };
 wantarray? %attributes: \%attributes;
}
# IATTRIBUTES -- instance attributes -- hash
sub IATTRIBUTES {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my %attributes=@_ ? %{ $class . '::IATTRIBUTES' } = @_ : %{ $class . '::IATTRIBUTES' };
 wantarray? %attributes: \%attributes;
}
sub IATTRIBUTES_RECURSIVE {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my %attributes=@_ ? %{ $class . '::IATTRIBUTES_RECURSIVE' } = @_:
   %{ $class . '::IATTRIBUTES_RECURSIVE' };
 wantarray? %attributes: \%attributes;
}
# CATTRIBUTES -- class attributes -- hash

# NG 05-12-08: commented out. DEFAULTS_ARGS renamed to DEFAULTS
#sub DEFAULTS {
# my ($class) = @_;
# $class = (ref $class) || $class;    # get class if called as object method
# no strict 'refs';
# %{ $class . '::DEFAULTS' };
#}
sub CATTRIBUTES {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my %attributes=@_ ? %{ $class . '::CATTRIBUTES' } = @_ : %{ $class . '::CATTRIBUTES' };
 wantarray? %attributes: \%attributes;
}
sub CATTRIBUTES_RECURSIVE {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my %attributes=@_ ? %{ $class . '::CATTRIBUTES_RECURSIVE' } = @_:
   %{ $class . '::CATTRIBUTES_RECURSIVE' };
 wantarray? %attributes: \%attributes;
}
# NG 05-12-08: DEFAULTS_ARGS renamed to DEFAULTS.  
#              incorporates logic to convert %DEFAULTS to Args object
sub DEFAULTS {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 ${ $class . '::DEFAULTS_ARGS' } or
  ${ $class . '::DEFAULTS_ARGS' } = new Hash::AutoHash::Args(%{ $class . '::DEFAULTS' }); # convert DEFAULTS hash into AutoArgs
}
sub DEFAULTS_RECURSIVE {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my $defaults=@_ ? ${ $class . '::DEFAULTS_RECURSIVE' } = $_[0]: 
   ${ $class . '::DEFAULTS_RECURSIVE' };
wantarray? %$defaults: $defaults;
}
# NG 06-03-14: Used to save $case from compile-time declare for use by run-time declare
sub CASE {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 my $case=@_ ? $ { $class . '::CASE' } = $_[0] : $ { $class . '::CASE' };
 $case;
}
sub AUTODB {
 my ($class) = @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 %{ $class . '::AUTODB' };
}

sub ANCESTORS {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 @_ ? ${ $class . '::ANCESTORS' } = $_[0] : ${ $class . '::ANCESTORS' };
}

sub CAN_NEW {
 my $class = shift @_;
 $class = (ref $class) || $class;    # get class if called as object method
 no strict 'refs';
 @_ ? ${ $class . '::CAN_NEW' } = $_[0] : ${ $class . '::CAN_NEW' };
}

sub FORCE_NEW {
  my $class = shift @_;
  $class = (ref $class) || $class;    # get class if called as object method
  no strict 'refs';
  ${ $class . '::FORCE_NEW' };
}
sub DECLARED {			# set to 1 by declare. tested in new
  my $class = shift @_;
  $class = (ref $class) || $class;    # get class if called as object method
  no strict 'refs';
  @_ ? ${ $class . '::DECLARED' } = $_[0] : ${ $class . '::DECLARED' };
}
sub AUTOCLASS_DEFERRED_DECLARE {
  my $class = shift @_;
  $class = (ref $class) || $class;    # get class if called as object method
  no strict 'refs';
  ${ $class . '::AUTOCLASS_DEFERRED_DECLARE' }{$_[0]}=$_[0] if @_;
#  push(@{ $class . '::AUTOCLASS_DEFERRED_DECLARE' }, @_) if @_;
#  @{ $class . '::AUTOCLASS_DEFERRED_DECLARE' };
  keys %{ $class . '::AUTOCLASS_DEFERRED_DECLARE' };
}
sub declare {
 my ( $class, $case, $is_runtime ) = @_;
 $class or $class=caller;	# NG 09-11-02: make $class optional

 # NG 06-03-18: improved code to recognize that user can set $CASE in module
 #              this is first step toward deprecating this parameter
 if (defined $case) {
    CASE($class,$case);		# save $case for run-time
  } else {
    $case=CASE($class);		# else, set $case from $CASE
  }
 ########################################
 # NG 05-12-08,09: added code to compute RECURSIVE values, IATTRIBUTES, CATTRIBUTES
 my @attributes_recursive;
 my %iattributes_recursive;
 my %cattributes_recursive;
 my %synonyms_recursive;
 my $defaults_recursive;
 # get info from superclasses.  recursively, this includes all ancestors
 # NG 06-03-14: split loop to get all supers that are AutoClasses
 #              and make sure they are declared. If any not declared,
 #              have to defer this declaration to run-time
 my $defer;
 for my $super (ISA($class)) {
   next if $super eq 'Class::AutoClass';
   ####################
   # NG 05-12-09: added check for super classes not yet used
   # Caution: this all works fine if people follow the Perl convention of
   #  placing module Foo in file Foo.pm.  Else, there's no easy way to
   #  translate a classname into a string that can be 'used'
   # The test 'unless %{$class.'::'}' cause the 'use' to be skipped if
   #  the class is already loaded.  This should reduce the opportunities
   #  for messing up the class-to-file translation.
   # Note that %{$super.'::'} is the symbol table for the class
   
   # NG 09-01-14: fixed dumb ass bug: the eval "use..." below is, of course, not run 
   #   if the class is already loaded.  This means that the value of $@ is not reset
   #   by the eval.  So, if it had a true value before the eval, it will have the 
   #   same value afterwards causing the error code to be run!
   #   FIX: changed "use" to "require" (which returns true on success) and use the
   #   return value to control whether error code run
   { no strict 'refs';
     unless (%{$super.'::'}) {
       eval "require $super" or
	 confess "'use $super' failed while declaring class $class. Note that class $super is listed in \@ISA for class $class, but is not explicitly used in the code.  We suggest, as a matter of coding style, that classes listed in \@ISA be explicitly used";
     }}
#   next unless UNIVERSAL::isa($super,'Class::AutoClass');
   # NG 06-03-14: handle different cases of $super being declared
   #              at runtime, okay to declare $super now since entire module
   #              has been parsed.
   #              at compile time, there is no guarantee that AutoClass variables 
   #              have yet been parsed. so, we defer declaration of current class 
   #              until $super is declared. CAUTION: this writes into $super's 
   #              namespace which is rude if $super is not an AutoClass class !!!
   if (!DECLARED($super)) {
     if ($is_runtime) {
       if (UNIVERSAL::isa($super,'Class::AutoClass')) {
	 declare($super,CASE($class),$is_runtime);
       } else {			# not AutoClass class, so just call it declared
	 DECLARED($class,1);
       }
     } else {
       AUTOCLASS_DEFERRED_DECLARE($super,$class); # push class onto super's deferred list
       $defer=1;		# causes return before loop that does the work 
     }
   }
 }
 # NG 06-03-14: AutoDB registration must be done at compile-time. if this code get
 #              moved later, remember that hacking of @ISA has to happen before class
 #              hierarchy enumerated
 my %autodb     = AUTODB($class);
 if (%autodb) { 
  no strict 'refs';
  # add AutoDB::Object to @ISA if necessary
  unless ( grep /^Class::AutoDB::Object/, @{ $class . '::ISA' } ) {
    unshift @{ $class . '::ISA' }, 'Class::AutoDB::Object';
    # NG 10-09-16: I thought it work work to push Object onto end of @ISA instead of 
    #              unshifting it onto front to reduce impact of namespace pollution.
    #              It does that okay, but introduces a new bug: oid generation and
    #              all that is doen by Serialize which is a base class of Object. In
    #              old implementation, that happened early; in new implementation, it
    #              happens late.  Screws up a lot of things.:(
    #              Back to the dawing boards...
    # push @{ $class . '::ISA' }, 'Class::AutoDB::Object';
  }
  require 'Class/AutoDB/Object.pm';
  require 'Class/AutoDB.pm';    # AutoDB.pm is needed for calling auto_register
 }
 # NG 05-12-02: auto-register subclasses which do not set %AUTODB
 # if (%autodb) {               # register after setting ANCESTORS
 if (UNIVERSAL::isa($class,'Class::AutoDB::Object')) {
   require 'Class/AutoDB.pm';    # AutoDB.pm is needed for calling auto_register
   # NG 09-12-04: handle %AUTODB=0. (any single false value)
   #              explicitly handle %AUTODB=1. previous version worked 'by luck' :)
   confess "Illegal form of \%AUTODB. \%AUTODB=<false> reserved for future use"
     if (scalar(keys %autodb)==1) && !(keys %autodb)[0];
   delete $autodb{1};		# delete '1=>anything' if it exists 
   my $args = Hash::AutoHash::Args->new( %autodb, -class => $class );
  Class::AutoDB::auto_register($args);
 }
 
 return if $defer;
 # NG 06-03-14: this part of the loop does the work
 for my $super (ISA($class)) {
   next if $super eq 'Class::AutoClass' || !UNIVERSAL::isa($super,'Class::AutoClass');
   push(@attributes_recursive,ATTRIBUTES_RECURSIVE($super));
   my %h;
   %h=IATTRIBUTES_RECURSIVE($super);
   @iattributes_recursive{keys %h}=values %h;
   undef %h;
   %h=CATTRIBUTES_RECURSIVE($super);
   @cattributes_recursive{keys %h}=values %h;
   undef %h;
   %h=SYNONYMS_RECURSIVE($super);
   @synonyms_recursive{keys %h}=values %h;
   my $d=DEFAULTS_RECURSIVE($super);
   @$defaults_recursive{keys %$d}=values %$d;
 }

 # add info from self. do this after parents so our defaults, synonyms override parents
 # for IATTRIBUTES, don't add in any that are already defined, since this just creates 
 #  redundant methods
 my %synonyms   = SYNONYMS($class);
 my %iattributes;
 my %cattributes;
 # init cattributes to declared CLASS_ATTRIBUTES
 map {$cattributes{$_}=$class} CLASS_ATTRIBUTES($class);
 # iattributes = all attributes that are not cattributes
 map {$iattributes{$_}=$class unless $iattributes_recursive{$_} || $cattributes{$_}}
   (AUTO_ATTRIBUTES($class),OTHER_ATTRIBUTES($class));
 # add in synonyms
 while(my($syn,$real)=each %synonyms) {
   confess "Inconsistent declaration for attribute $syn: both synonym and real attribute"
     if $cattributes{$syn} && $iattributes{$syn};
   $cattributes{$syn}=$class if $cattributes{$real} || $cattributes_recursive{$real};
   $iattributes{$syn}=$class if $iattributes{$real} || $iattributes_recursive{$real};
 }
 IATTRIBUTES($class,%iattributes);
 CATTRIBUTES($class,%cattributes);
 ATTRIBUTES($class,keys %iattributes,keys %cattributes);

 # store our attributes into recursives
 @iattributes_recursive{keys %iattributes}=values %iattributes;
 @cattributes_recursive{keys %cattributes}=values %cattributes;
 push(@attributes_recursive,keys %iattributes,keys %cattributes);
 # are all these declarations consistent?
 if (my @inconsistents=grep {exists $cattributes_recursive{$_}} keys %iattributes_recursive) {
   # inconsistent class vs. instance declarations
   my @errstr=("Inconsistent declarations for attribute(s) @inconsistents");
   map {
     push(@errstr,
	  "\tAttribute $_: declared instance attribute in $iattributes_recursive{$_}, class attribute in $cattributes_recursive{$_}");
   } @inconsistents;
   confess join("\n",@errstr);
 }
 # store our synonyms into recursive
 @synonyms_recursive{keys %synonyms}=values %synonyms;
 # store our defaults into recursive

 my $d=DEFAULTS($class);
 @$defaults_recursive{keys %$d}=values %$d;
 # store computed values into class
 ATTRIBUTES_RECURSIVE($class,@attributes_recursive);
 IATTRIBUTES_RECURSIVE($class,%iattributes_recursive);
 CATTRIBUTES_RECURSIVE($class,%cattributes_recursive);
 SYNONYMS_RECURSIVE($class,%synonyms_recursive);
 DEFAULTS_RECURSIVE($class,$defaults_recursive);

 # note that attributes are case sensitive, while defaults and args are not.
 # (this may be a crock, but it's documented this way). to deal with this, we build
 # a map from de-cased attributes to attributes. really, the map takes use from
 # id's as fixed by Args to attributes as they exist here
 my %fixed_attributes;
 my @fixed_attributes=fix_keywords(@attributes_recursive);
 @fixed_attributes{@attributes_recursive}=@fixed_attributes;
 FIXED_ATTRIBUTES_RECURSIVE($class,%fixed_attributes);

 ########################################

 # enumerate internal super-classes and find an external class to create object

# NG 06-03-14: moved code for AutoDB registration higher.
# my %autodb     = AUTODB($class);
# if (%autodb) {    # hack ISA before setting ancestors
#  no strict 'refs';

#  # add AutoDB::Object to @ISA if necessary
#  unless ( grep /^Class::AutoDB::Object/, @{ $class . '::ISA' } ) {
#   unshift @{ $class . '::ISA' }, 'Class::AutoDB::Object';
#  }
#  require 'Class/AutoDB/Object.pm';
#  require 'Class/AutoDB.pm';    # AutoDB.pm is needed for calling auto_register
# }

 my ( $ancestors, $can_new ) = _enumerate($class);
 ANCESTORS( $class, $ancestors );
 CAN_NEW( $class, $can_new );

# DEFAULTS_ARGS( $class, new Hash::AutoHash::Args( DEFAULTS($class) ) ); # convert DEFAULTS hash into AutoArgs. NG 05-12-08: commented out since logic moved to DEFAULTS sub

# # NG 05-12-02: auto-register subclasses which do not set %AUTODB
# # if (%autodb) {               # register after setting ANCESTORS
# if (UNIVERSAL::isa($class,'Class::AutoDB::Object')) { # register after setting ANCESTORS
#   require 'Class/AutoDB.pm';    # AutoDB.pm is needed for calling auto_register
#   my $args = Hash::AutoHash::Args->new( %autodb, -class => $class ); # TODO - spec says %AUTODB=(1) should work
#  Class::AutoDB::auto_register($args);
# }

 ########################################
 # NG 05-12-09: changed loops to iterate separately over instance and class attributes.
 #              commented out code for AutoDB dispatch -- could never have run anyway
 #              since %keys never set.  also not longer compatible with new
 #              Registration format.
 # generate the methods
 
 my @auto_attributes=AUTO_ATTRIBUTES($class);
 undef %iattributes;
 %iattributes=IATTRIBUTES($class);
 my @iattributes=grep {$iattributes{$_} && !exists $synonyms{$_}} @auto_attributes;
 my @class_attributes=(@auto_attributes,CLASS_ATTRIBUTES($class));
 my @cattributes=grep {$cattributes{$_} && !exists $synonyms{$_}} @class_attributes;

 for my $func (@iattributes) {
  my $fixed_func = fix_keyword($func);
  my $sub = '*' . $class . '::' . $func . "=sub{\@_>1?
             \$_[0]->{\'$fixed_func\'}=\$_[1]:
             \$_[0]->{\'$fixed_func\'};}";
  eval $sub;
  }
 for my $func (@cattributes) {
  my $fixed_func = fix_keyword($func);
  my $sub = '*' . $class . '::' . $func . "=sub{\@_>1?
             \${$class\:\:$fixed_func\}=\$_[1]: 
             \${$class\:\:$fixed_func\};}";
  eval $sub;
  }
# NG 05-12-08: commented out.  $args was never set anyway...  This renders moot the
#              'then' clause of the 'if' below.  I left it in just in case I have to
#              revert the change :)
# TODO: eliminate 'then' clause if not needed
#  if ( $args and $args->{keys} ) {
#   %keys = map { split } split /,/, $args->{keys};
#  }
#  if ( $keys{$func} ) {         # AutoDB dispatch
#   $sub = '*' . $class . '::' . $func . "=sub{\@_>1?
#        \$_[0] . '::AUTOLOAD'->{\'$fixed_func\'}=\$_[1]: 
#        \$_[0] . '::AUTOLOAD'->{\'$fixed_func\'};}";
#  } else {
#   if ( exists $cattributes{$func} ) {
#    $sub = '*' . $class . '::' . $func . "=sub{\@_>1?
#              \${$class\:\:$fixed_func\}=\$_[1]: 
#              \${$class\:\:$fixed_func\};}";
#   } else {
#    $sub = '*' . $class . '::' . $func . "=sub{\@_>1?
#             \$_[0]->{\'$fixed_func\'}=\$_[1]:
#             \$_[0]->{\'$fixed_func\'};}";
#   }
#  }
#  eval $sub;
# }
 while ( my ( $func, $old_func ) = each %synonyms ) {
  next if $func eq $old_func;	# avoid redundant def if old same as new
#  my $class_defined=$iattributes_recursive{$old_func} || $cattributes_recursive{$old_func};
#  my $sub=
#    '*' . $class . '::' . $func . '=\& ' . $class_defined . '::' . $old_func;
  my $sub =
    '*' . $class . '::' . $func . "=sub {\$_[0]->$old_func(\@_[1..\$\#_])}";
  eval $sub;
 }
 if ( defined $case && $case =~ /lower|lc/i )
 {                # create lowercase versions of each method, too
  for my $func (@iattributes,@cattributes) {
   my $lc_func = lc $func;
   next
     if $lc_func eq $func;  # avoid redundant def if func already lowercase
  my $sub=
    '*' . $class . '::' . $lc_func . '=\& '. $class . '::' . $func;
#   my $sub =
#     '*' . $class . '::' . $lc_func . "=sub {\$_[0]->$func(\@_[1..\$\#_])}";
   eval $sub;
  }
 }
 if ( defined $case && $case =~ /upper|uc/i )
 {                          # create uppercase versions of each method, too
  for my $func (@iattributes,@cattributes) {
   my $uc_func = uc $func;
   next
     if $uc_func eq $func;  # avoid redundant def if func already uppercase
  my $sub=
    '*' . $class . '::' . $uc_func . '=\& '. $class . '::' . $func;
#   my $sub =
#     '*' . $class . '::' . $uc_func . "=sub {\$_[0]->$func(\@_[1..\$\#_])}";
   eval $sub;
  }
 }
 # NG 05-12-08: removed $args from parameter list
 # NG 05-12-09: converted call from method ($class->...) to function. removed eval that 
 #              wrappped call. provided regression test for class that does not inherit 
 #              from AutoClass
 set_class_defaults($class);
 DECLARED($class,1);		# NG 06-02-03: so 'new' can know when to call declare

 # NG 06-03-14: Process deferred subclasses
 my @deferreds=AUTOCLASS_DEFERRED_DECLARE($class);
 for my $subclass (@deferreds) {
   declare($subclass,CASE($subclass),$is_runtime) unless DECLARED($subclass);
 }
}

sub _enumerate {
 my ($class) = @_;
 my $classes = [];
 my $types   = {};
 my $can_new;
 __enumerate( $classes, $types, \$can_new, $class );
 return ( $classes, $can_new );
}

sub __enumerate {
 no warnings;
 my ( $classes, $types, $can_new, $class ) = @_;
 die "Circular inheritance structure. \$class=$class"
   if ( $types->{$class} eq 'pending' );
 return $types->{$class} if defined $types->{$class};
 $types->{$class} = 'pending';
 my @isa;
 {
  no strict "refs";
  @isa = @{ $class . '::ISA' };
 }
 my $type = 'external';
 for my $super (@isa) {
  $type = 'internal', next if $super eq $AUTOCLASS;
  my $super_type = __enumerate( $classes, $types, $can_new, $super );
  $type = $super_type unless $type eq 'internal';
 }
 if ( !FORCE_NEW($class) && !$$can_new && $type eq 'internal' ) {
  for my $super (@isa) {
   next unless $types->{$super} eq 'external';
   $$can_new = $super, last if $super->can('new');
  }
 }
 push( @$classes, $class ) if $type eq 'internal';
 $types->{$class} = $type;
 return $types->{$class};
}

sub _is_positional {
 @_ % 2 || $_[0] !~ /^-/;
}
1;



__END__

=head1 NAME

Class::AutoClass - Create get and set methods and simplify object initialization

=head1 VERSION

Version 1.56

=head1 SYNOPSIS

  # code that defines class
  #
  package Person;
  use base qw(Class::AutoClass);
  use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES 
              %SYNONYMS %DEFAULTS);
  @AUTO_ATTRIBUTES=qw(first_name last_name sex friends);
  @OTHER_ATTRIBUTES=qw(full_name);
  @CLASS_ATTRIBUTES=qw(count);
  %DEFAULTS=(friends=>[]);
  %SYNONYMS=(gender=>'sex',name=>'full_name');
  Class::AutoClass::declare;

  # method to perform non-standard initialization, if any
  sub _init_self {
    my ($self,$class,$args) = @_;
    return unless $class eq __PACKAGE__;
    # any non-standard initialization goes here
    $self->count($self->count + 1); # increment number of objects created
  }

  # implementation of non-automatic attribute 'full_name' 
  # computed from first_name and last_name
  sub full_name {
    my $self=shift;
    if (@_) {			    # to set full_name, have to set first & last 
      my $full_name=shift;
      my($first_name,$last_name)=split(/\s+/,$full_name);
      $self->first_name($first_name);
      $self->last_name($last_name);
    }
    return join(' ',$self->first_name,$self->last_name);
  }

  ########################################
  # code that uses class
  #
  use Person;
  my $john=new Person(name=>'John Smith',sex=>'M');
  my $first_name=$john->first_name; # 'John'
  my $gender=$john->gender;         # 'M'
  my $friends=$john->friends;       # []
  $john->last_name('Doe');          # set last_name
  my $name=$john->name;             # 'John Doe'
  my $count=$john->count;           # 1


=head1 DESCRIPTION

This is yet another module that generates standard 'get' and 'set'
methods for Perl classes.  It also handles initialization of object
and class data from parameter lists or defaults, and arranges for
object creation and initialization to occur in top-down, textbook
order even in the presence of multiple inheritance.

CAUTION: This module is old. We use it internally, and while it works
well for our purposes, we urge new users to heed the warnings in
L<"BUGS"> and to look at other modules listed in L<SEE ALSO>.  This
release brings the CPAN version of the module up-to-date relative to
our internal version, something we should have done long ago.  We do
not expect further releases of this code base, except for bug fixes.
Future development, if any, will entail a redesign building on newer
CPAN modules.

=head2 Defining the class

We use the term "attribute" for object and class variables being
managed by this module.  This was appropriate usage when we wrote the
code several years ago, but we recognize that "attribute" now means
something else in Perl-dom.  It's too late for us to change.  Sorry.

Class::AutoClass provides a number of variables for specifying
attributes and default values.

@AUTO_ATTRIBUTES is a list of attribute names. The software generates
'get' and 'set' methods for each attribute.  By default, the name of
the method is identical to the attribute (but see $CASE below). Values
of attributes can be set via the 'new' constructor, %DEFAULTS, or the
'set' method as discussed below.

@OTHER_ATTRIBUTES is a list of attributes for which 'get' and 'set'
methods are NOT generated, but whose values can be set via the 'new'
constructor or the 'set' method as discussed below.

@CLASS_ATTRIBUTES is a list of class attributes.  The module generates
'get' and 'set' methods for each attribute just as for
@AUTO_ATTRIBUTES.  Values of attributes can be set via the 'new'
constructor, %DEFAULTS (initialized when the 'declare' function is
called), or the 'set' method as discussed below. Normal inheritance
rules apply to class attributes (but instances of the same class share
the same class variable).

%SYNONYMS is a hash that defines synonyms for attributes. Each entry is
of the form 'new_attribute_name'=>'old_attribute_name'. 'get' and
'set' methods are generated for the new names; these methods simply
call the methods for the old name.  

%DEFAULTS is a hash that defines default values for attributes. Each
entry is of the form 'attribute_name'=>'default_value'.

$CASE controls whether additional methods are generated with all upper
or all lower case names.  It should be a string containing the strings
'upper' or 'lower' (case insensitive) if the desired case is
desired. [BUG: This is hopelessly broken and ill-conceived. Most of
the code assumes that attributes are lower case. Even when upper or
mixed case methods are present, the attribute setting code ignores
them.]

The 'declare' function actually generates the methods. This should be
called once in the main code of the class after the variables
described above are set.

Class::AutoClass must be the first class in @ISA or 'use base'!! As
usual, you create objects by calling 'new'. Since Class::AutoClass is
the first class in @ISA, its 'new' method is the one that's called.
Class::AutoClass's 'new' examines the rest of @ISA looking for a
superclass capable of creating the object.  If no such superclass is
found, Class::AutoClass creates the object itself.  Once the object is
created, Class::AutoClass arranges to have all subclasses run their
initialization methods (_init_self) in a top-down order.

=head2 Object creation and initialization

We expect objects to be created by invoking 'new' on its class.  For
example

  $john=new Person(first_name=>'John',last_name=>'Smith')

To correctly initialize objects that participate in multiple
inheritance, we use a technique described in Chapter 10 of Paul
Fenwick's tutorial on Object Oriented Perl
L<http://perltraining.com.au/notes/perloo.pdf>.  (We experimented with
Damian Conway's L<NEXT> pseudo-pseudo-class but could not get it to
traverse the inheritance structure in the desired top-down order; this
 may be fixed in recent versions. See L<SEE ALSO> for other
modules addressing this issue.)

Class::AutoClass provides a 'new' method that expects a keyword
argument list.  It converts the argument list into a
L<Hash::AutoHash::Args> object, which normalizes the keywords to
ignore case and leading dashes. 'new' then initializes all attributes
using the arguments and default values in %DEFAULTS.  This works for
synonyms, too, of course.

CAUTION: If you supply a default value for both a synonym and its
target, the one that sticks is arbitrary.  Likewise if you supply an
initial value for both a synonym and its target, the one that sticks
is arbitrary.

Initialization of attributes is done for all classes in the object's
class structure at the same time. If a given attribute is defined
multiple times, the most specific definition wins.  This is only an
issue if the attribute is defined differently in different classes,
eg, as an 'auto' attribute in one class and an 'other' attribute,
class atribute, or synonym in another.

Class::AutoClass::new initializes attributes by calling the 'set'
methods for these elements with the like-named parameter or default.
For 'other' attributes, the class writer can implement non-standard
initialization within the 'set' method.

The class writer can provide an _init_self method for any classes
requiring additional initialization.  'new' calls _init_self after
initializing all attributes for all classes in the object's class
structure.

The _init_self method is responsible for initializing just the
"current level" of the object, not its superclasses.  'new' calls
_init_self for each class in the class hierarchy from top to bottom,
being careful to call the method exactly once per class even in the
presence of multiple inheritance.  The _init_self method should not
call SUPER::_init_self as this would cause redundant initialization of
superclasses.

Subclasses of Class::AutoClass do not usually need their own 'new'
methods.  The main exception is a subclass whose 'new' allows
positional arguments. In this case, the subclass 'new' is responsible
for converting the positional arguments into keyword=>value form. At
this point, the method should call Class::AutoClass::new with the
converted argument list. In most cases, the subclass should not call
SUPER::new as this would force redundant argument processing in any
superclass that also has a 'new' method.

=head2 Traps for the unwary

Two aspects of object initialization seem particularly troublesome,
causing subtle bugs and ensuing grief.

One trap is that attribute-initialization occurs in arbitrary order.
There is a temptation when writing 'set' methods to assume that
attributes are initialized in the natural order that you would set
them if you were writing the initialization code yourself.  I have
been burned by this many times. This is mainly an issue for
OTHER_ATTRIBUTES. The issue also arises with SYNONYMS. If your code
initializes both sides of a synonym with different values, it is
undefined which value will stick. This can happen when your codes sets
values explicitly or via DEFAULTS.

The second trap involves "method resolution", ie, the way Perl chooses
which sub to call when you invoke a method. Consider a class hierarchy
C<A-B> with C<A> at the top, and imagine that each class defines a
method C<f>.  Invoking C<f> on an object of class C<A>
will call the code in class C<A>, whereas invoking C<f> on an object of
class C<B> will call the code in C<A>.  No surprise yet.

Now suppose the object initialization code for C<A> calls C<f> and think
about what will happen when creating an object of class C<B>.  Invoking
C<f> on this object will call the version of C<f> in C<B>, which means we
will be running code that may depend on the initialization of C<B>
which hasn't happened yet!

This gotcha can arise in a fairly obvious way if the call to C<f> is in
the _init_self method. It can arise more subtly if the call is in the
'set' method of an OTHER_ATTRIBUTE.  It can arise even more subtly if
C<f> is an AUTO_ATTRIBUTE in one class and a CLASS_ATTRIBUTE in the
other.  The opportunity for mischief multiplies when SYNONYMS are
involved.

=head1 METHODS AND FUNCTIONS FOR CLASS DEVELOPERS

=head2 declare

 Title   : declare
 Usage   : Class::AutoClass::declare;
 Function: Setup Class::AutoClass machinery for a class
 Returns : nothing
 Args    : Optional name of class being created; default is __PACKAGE__
 Note    : Uses current values of @AUTO_ATTRIBUTES, @OTHER_ATTRIBUTES, 
           @CLASS_ATTRIBUTES, %SYNONYMS, %DEFAULTS, $CASE.

=head2 _init_self

 Title   : _init_self
 Usage   : $self->_init_self($class,$args)
 Function: Called by 'new' to initialize new object
 Returns : nothing
 Args    : class being initialized and Hash::AutoHash::Args object
 Notes   : Implemented by subclasses requiring non-standard initialization. Not
           implemented by Class::AutoClass itself

The original design of Class::AutoClass provided no way for _init_self
to control the return-value of 'new'.  All _init_self could do was
modify the contents of the object already constructed by 'new'.  This
proved too limiting, and we added two workarounds: (1) If _init_self
sets the __NULLIFY__ element of the object to a true value (eg, by
saying $self->{__NULLIFY__}=1), 'new' will return undef. (2) If
_init_self sets the __OVERRIDE__ element of the object to true value
(usually an object), 'new' will return that value.  If both
__NULLIFY__ and __OVERRIDE__ are set, it is arbitrary which one will
win.

=head1 METHODS AND FUNCTIONS FOR CLASS USERS

=head2 new

 Title   : new
 Usage   : $john=new Person(first_name=>'John',last_name=>'Smith')
           where Person is a subclass of Class::AutoClass
 Function: Create and initialize object
 Returns : New object of the given class or undef
 Args    : Any arguments needed by the class in keyword=>value form
 Notes   : Implemented by Class::AutoClass and usually not by subclasses

=head2 set

 Title   : set
 Usage   : $john->set(last_name=>'Doe',sex=>'M')
 Function: Set multiple attributes in existing object
 Args    : Parameter list in same format as for new
 Returns : nothing

=head2 set_attributes

 Title   : set_attributes
 Usage   : $john->set_attributes([qw(first_name last_name)],$args)
 Function: Set multiple attributes from a Hash::AutoHash::Args object
           Any attribute value that is present in $args is set
 Args    : ARRAY ref of attributes
           Hash::AutoHash::Args object
 Returns : nothing

=head2 get

 Title   : get
 Usage   : ($first,$last)=$john->get(qw(first_name last_name))
 Function: Get values for multiple attributes
 Args    : Attribute names
 Returns : List of attribute values

=head1 SEE ALSO

L<mro>, L<Compat::MRO>, and L<Class::C3> deal with "method resolution
order" and may offer better ways to control the order in which class
initialization occurs.  L<NEXT> is an older approach still in use.

CPAN has many modules that generate 'get' and 'set' methods including
L<Class::Accessor>, L<Class::Builer>, L<Class::Class>,
L<Class::Frame>, L<Class::Generate>, L<Class::MethodMaker>,
L<Class::Struct>.

This class uses L<Hash::AutoHash::Args> to represent keyword=>value argument lists.

=head1 AUTHOR

Nat Goodman, C<< <natg at shore.net> >>

=head1 BUGS AND CAVEATS

Please report any bugs or feature requests to C<bug-class-autoclass at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-AutoClass>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head2 Known Bugs and Caveats

=over 2

=item 1. This module is old

The current code does not build on recent CPAN modules that cover much
of the same ground. Future releases, if any, will entail a redesign.

=item 2. Inheriting 'new' from an external class often fails

We intended to support class hierarchies containing "external"
classes, ie, ones that are not derived from Class::AutoClass. A
use-case we really wanted to handle was letting an external class
construct the object by running its 'new' method.  The code tries to do
this, but it doesn't work in most cases, because we provided no way to
manipulate the arguments that are sent to the external class's 'new'
method. So, for example, if the external 'new' expects a positional
argument list, you're hosed.

=item 3. Non-lower case attribute names don't work well

The design is schizophrenic in its treatment of attribute case.  We
process argument lists using L<Hash::AutoHash::Args>, which explicitly
converts all keywords to lower-case.  Yet we provide the $CASE
variable which is supposed to control attribute case conversion.  What
were we thinking??

Lower-case attribute names are the only ones that work well.

=item 4. The workarounds that let _init_self control the value
returned by 'new' are crude.

=item 5. Accessing class attributes sometimes fails when a parent
class "uses" its children.

This happens rarely, but can occur legitimately, e.g., when a base
class dispatches to a child based on the value of a parameter.  The
issue arises only if the parent class uses its children at
compile-time (typically by including them in the list of uses at the
top of the module); run-time uses or requires don't seem to be a
problem.

A workaround is implemented that handles such cases "most of the
time".  The case that is not fully handled arises when a
Class::AutoClass class inherits from a non-Class::AutoClass class. In
this case, declaration of the class is deferred until run-time, more
specifically until the first time 'new' is called for the class or a
subclass.  This works fine except for class attributes, since class
attributes (unlike instance attributes) can be accessed before 'new'
is called.  To be clear, in this one case, it does not work to access
class attributes before creating an object of the class - this is
clearly a bug.

=item 6. No special support for DESTROY

Object destruction should occur bottom-to-top, opposite to the direction of object initialization.  Making this happen is a challenge in the presence of multiple inheritance.  Class::AutoClass does nothing to help.

=item 7. Subtle bugs in object initialization

See L<Traps for the unwary>.

=item 8.  Initialization of synonyms

It works fine to provide a default value for a synonym (via
%DEFAULTS), but if you supply a default value for both a synonym and
its target, the one that sticks is arbitrary. Likewise it works fine
to provide an initial value for a synonym (via 'new'), but if you
supply an initial value for both a synonym and its target, the one
that sticks is arbitrary.

=item 9.  Inconsistent attribute declarations

Inconsistent attribute declarations are not detected in all cases. The code successfully detects cases where an attribute is defined as a class attribute in one class, and an instance attribute ('auto' or 'other') in a superclass or subclass.  It does not reliably detect inconsistencies that occur in a single class.  The following cases are not detected:

=over 2

=item - attribute declared 'auto' and 'other'

=item - attribute declared 'auto' and 'class'

=item - attribute declared 'other' and 'class' when no implementation is provided for 'other'

=item - attribute declared 'synonym' and 'other'

=back

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::AutoClass


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-AutoClass>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-AutoClass>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-AutoClass>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-AutoClass/>

=back


=head1 ACKNOWLEDGEMENTS

Chris Cavnor maintained the CPAN version of the module for several
years after its initial release.

=head1 COPYRIGHT & LICENSE

Copyright 2003, 2009 Nat Goodman, Institute for Systems Biology
(ISB). All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Class::AutoClass
