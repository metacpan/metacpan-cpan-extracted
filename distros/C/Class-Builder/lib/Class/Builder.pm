# ======================================================================== #
#   Class::Builder -- auto-generator of class accessors/special methods    #
# ======================================================================== #
# Author: Wei, Huang, Weitop Corp., 2003-8-30
# $Revision: 1.10 $ - $Date: 2003/10/05 07:28:03 $
# (c) Copyright: 2003 - 2006.

# *WARNNING* ALPHA RELEASE
#     This software is not ready for production use.

# *WARNING* TOTALLY NO WARRANTY
# This module is free software, you can use/modify or distribute
# it as the term of perlself. The software comes without any
# warranty of any type, use it at you own risk.

package Class::Builder;
our $VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };;

use 5.006001;
use strict;
use warnings;
use integer;
use autouse 'Carp' => qw(carp croak);
use Exporter;
use Storable qw(dclone);
use base qw{Exporter};
our @EXPORT = qw{struct};

# ========================= | PACKAGE VARIABLES |
$Class::Builder::current_class = '';
%Class::Builder::defaults = ();
%Class::Builder::initializers = ();
%Class::Builder::classdata = ();
# ===============================================

# ---------------- | Public Methods |
sub known_types{
  return qw(string number boolean counter classdata hashref arrayref);
}

sub struct{
  # to inherite from Class::Builder
  # overridden this functions with
  # same contents in your sub class
  __PACKAGE__->_struct(@_);
}

sub import {
  # two type of arguments possible here:
  # use Class::Builder { args };
  # use Class::Builder ( args );
  my $self = shift;
  my $class = (caller(0))[0];
  if(((scalar @_) == 1) and ((ref $_[0]) eq 'HASH')){
    $self->setup($_[0], $class);
  }elsif((scalar @_) > 1){
    my %hash = (@_);
    $self->setup(\%hash, $class);
  }else{ ; }
  $self->export_to_level( 1, $self, @EXPORT );
}

# ---------------- | Private Methods |
sub _struct{
  # three types of arguments are considerable:
  # 1. struct { args } # implicit class name, not recommended
  # 2. struct class => { args }, class2 => { args };
  # 3. struct [class => {args}, class2 => {args}];
    # same as above, with little perfomance improvement
  my $builder = shift;
  my @args = @_;
  if((@args == 1) and (ref $args[0]) eq 'HASH'){
    my $class ||= (caller(1))[0];
    $builder->setup($args[0], $class);
  }else{
    my $aref;
    if((@args == 1) and (ref $args[0]) eq 'ARRAY'){
      $aref = shift @args;
    }else{ $aref = \@args; }
    croak "wrong number of arguments for struct.\n"
      if(@$aref % 2);

    my $class;
    while ($class = shift @$aref){
      $builder->setup((shift @$aref), $class);
    }
    return scalar @$aref;
  }
  return 1;
}

sub setup{
  # for sub-classing: you may
  # add you own extension here
  shift->_setup(@_);
}

sub _setup{
  # typical args hash:
  #  {
  #    '-methods' => {
  #       <specialmethods> => <methodsname>
  #    },
  #    <field> => {
  #  		<type> => <default>,
  #  		final  => 1,
  #     forward => <joinlist>
  #  	 }
  #  }
  # <type>: number, string (or any scalar including references)
  #         boolean, counter, <Class>, classdata, hashref, arrayref
  # <special methods>: initializer, constructor, group
  #                    abstract, dumper, clone,
  my ($builder, $arg, $class) = @_;
  $class ||= (caller(1))[0];

  # initialize class variables:
  $Class::Builder::current_class = $class;
  $Class::Builder::defaults{$class} ||={};
  $Class::Builder::initializers{$class} ||= [];

  # a loosing way for classdata inheritage:
  my $inherite = {};
  $inherite = $class->__classdata() if($class->can('__classdata'));
  %{$Class::Builder::classdata{$class}} = %$inherite;

  # get definations about special methods first
  my $special_methods = {};
  if(exists $arg->{-methods}){
    $special_methods = $arg->{-methods};
    delete $arg->{-methods};

    if(exists $special_methods->{initializer}){
      my $list = $special_methods->{initializer};
      $Class::Builder::initializers{$class}
        = (ref $list) ?  $list : [$list];

      delete $special_methods->{initializer};
    }
  }
  $special_methods->{constructor} = 'new'
      unless($special_methods->{constructor} or $class->can('new'));

  # range field informations,
  my $field_methods = {};
  my $any_classdata = 0;
  {
    my %known = map {$_, 1} $builder->known_types();

    while(my ($field, $def) = each %$arg){
      my $fieldarg = {name=> $field, final => 0};
      foreach (qw(final forward)){
        next unless exists $def->{$_};
        $fieldarg->{$_} = $def->{$_};
        delete $def->{$_};
      }
      croak "santax error for field $field, check it again."
        unless((scalar keys %$def) == 1);
      ($fieldarg->{type}, $fieldarg->{default}) = each %$def;

      croak "can not set counter fields to be final, for ", $fieldarg->{name},
            ".\n" if($fieldarg->{final} and ($fieldarg->{type} eq 'counter'));

      my $type = $fieldarg->{type};
      unless($known{$type}){
        $fieldarg->{type} = 'object';
        # 1. Type => ['constructor', 'arg1', 'arg2']
        # 2. Type => 'constructor'
        # 3. Type => created_object
        $fieldarg->{class} = $type;
        my $default = $fieldarg->{default};
        if($default and !(ref $default)){
          $fieldarg->{default} = $type->$default();
        }elsif((ref $default) eq 'ARRAY'){
          my $constructor = shift @$default;
          $fieldarg->{default} = $type->$constructor(@$default);
        }else{;}
      }

      # class data default goes here
      if($fieldarg->{type} eq 'classdata'){
        ++ $any_classdata;
        $Class::Builder::classdata{$class}->{$field} = $fieldarg->{default};
      }else{
        $Class::Builder::defaults{$class}->{$field} = $fieldarg->{default}
      }

      $field_methods->{$field} = $fieldarg;
    }
  }

  # set up fields methods, localize `no strict'
  {
    my %methods = ();
    foreach my $name (keys %$field_methods){
      my $type = $field_methods->{$name}->{type};
      %methods = (%methods, $builder->$type( $field_methods->{$name} ));
    }

    no strict 'refs';
    *{"$class"."::"."__classdata"} = sub {$Class::Builder::classdata{$class}}
                              if($any_classdata);
    while (my ($name, $code) = each %methods){
      *{"$class"."::"."$name"} = $code;
    }
  }

  # setup methods for special methods (after defaults set):
  {
    my %methods = map {$builder->$_( $special_methods->{$_} )}
                  (keys %$special_methods);
      # $_ is a element of a subset of
      # qw[constructor, abstract, dumper, clone]
    no strict 'refs';
    while (my ($name, $code) = each %methods){
      *{"$class"."::"."$name"} = $code;
    }

    # if any of a field declared, add a function to clear it.
    # i hope this will make some perfomance improvement, if any,
    # than the x/clear_x approach of MethodMaker.
    if(scalar keys %$field_methods){
      *{"${class}"."::"."clear"} = sub {
        my $self = shift; foreach (@_){$self->{$_} = undef}; undef;
       };
      # in addtion, you can get a list of
      *{"${class}"."::"."get"} = sub {
        my $self = shift; my $valuelist = [];
        foreach (@_){push @$valuelist, $self->$_; }
        return @$valuelist;
      };
    }
  }

  return 1;
}

# -------------------------------------- | Field Methods Builder |
sub string{
  # args name, final, type, default
  shift;
  my $args = shift;
  my $name = $args->{name};
  return ($name, sub { shift->{$name}; }) if($args->{final});

  return ($name, sub : lvalue {
    my $self = shift;
    $self->{$name} = $_[0] if(@_ == 1);
    $self->{$name};
  });
}

sub number{
  # implemented nothing special :-)
  shift->string(@_);
}

sub arrayref{
  shift;
  my ($arg) = @_;
  my $class = $Class::Builder::current_class;
  my $defaults = $Class::Builder::defaults{$class};
  my $name = $arg->{name};
  return (
    $name,
    sub {
      my $self  = shift;
      $self->{$name} = $_[0] if(@_ == 1 and (ref $_[0] eq 'ARRAY'));
      wantarray ? @{$self->{$name}} : $self->{$name};
    },
    "${name}_push",
    sub {
      my $self = shift;
      $self->{$name} = [] unless((ref $self->{$name}) eq 'ARRAY');
      push @{$self->{$name}}, @_;
    },
    "${name}_pop",
    sub {
      my ($self, $new) = @_;
      pop @{$self->{$name}};
    },
    "${name}_shift",
    sub {
      my $self = shift;
      shift @{$self->{$name}};
    },
    "${name}_unshift",
    sub {
      my $self = shift;
      $self->{$name} = [] unless((ref $self->{$name}) eq 'ARRAY');
      unshift @{$self->{$name}}, @_;
    },
    "${name}_count",
    sub {
      my $self = shift;
      return exists $self->{$name} ? scalar @{$self->{$name}} : 0;
    },
    "${name}_splice",
    sub {
      my ($self, $offset, $len, @list) = @_;
      splice(@{$self->{$name}}, $offset, $len, @list);
    }
  );
}

sub hashref{
shift;
  my ($arg) = @_;
  my $class = $Class::Builder::current_class;
  my $defaults = $Class::Builder::defaults{$class};
  my $name = $arg->{name};
  return (
    $name,
    sub {
      my $self  = shift;
      $self->{$name} = {} unless((ref $self->{$name}) eq 'HASH');
      if(@_ == 1 and (ref $_[0] eq 'HASH')){
        $self->{$name} = $_[0];
        return $self->{$name};
      }
      return @{$self->{$name}}{@_} if(scalar @_);
      $self->{$name};
    },
    "${name}_keys",
    sub {
      my $self = shift;
      $self->{$name} = {} unless((ref $self->{$name}) eq 'HASH');
      keys %{$self->{$name}};
    },
    "${name}_values",
    sub {
      my $self = shift;
      $self->{$name} = {} unless((ref $self->{$name}) eq 'HASH');
      values %{$self->{$name}};
    },
    "${name}_exists",
    sub {
      my $self = shift;
      my $key = shift;
      return
        exists $self->{$name} && exists $self->{$name}->{$key};
    },
    "${name}_delete",
    sub {
      my ($self, @keys) = @_;
      delete @{$self->{$name}}{@keys};
    },
  );
}

sub object{
  shift;
  my $arg = shift;
  my $name = $arg->{name};
  my $forward = [];
  $forward = (ref $arg->{forward}) ? $arg->{forward}
                                   : [$arg->{forward}] if($arg->{forward});
  my %results = ();
  $results{$name} = sub : lvalue {
    my $self  = shift;
    $self->{$name} = $_[0] if(@_ == 1 and ref $_[0]);
    $self->{$name};
  };

  foreach my $meth (@$forward){
    $results{$meth} =
      sub {
        my ($self, @args) = @_;
        $self->$name()->$meth(@args);
      };
  }

  return %results;
}

sub boolean{
  # args name, final, type, default
  shift;
  my $args = shift;
  my $class = $Class::Builder::current_class;
  my $defaults = $Class::Builder::defaults{$class};
  my $name = $args->{name};

  return ($name, sub { shift->{$name}; }) if($args->{final});

  return (
    $name,
    sub : lvalue {
    my $self = shift;
    if(@_ == 1){ $self->{$name} = ($_[0]) ? 1 : 0; }
    $self->{$name};
    },
    "${name}_rev",
    sub {
      my $self = shift;
      $self->{$name} = ($self->{$name}) ? 0 : 1;
    },
    "${name}_reset",
    sub {
      my $self = shift;
      my $val = $defaults->{$name} || 0;
      $self->{$name} = $val;
    },
  );
}

sub counter{
  shift;
  my ($arg) = @_;
  my $class = $Class::Builder::current_class;
  my $defaults = $Class::Builder::defaults{$class};
  my $name = $arg->{name};
  return (
    $name,
    sub {
      my $self  = shift;
      $self->{$name} = $_[0] if(@_ == 1 and ref $_[0]);
      $self->{$name};
    },
    "${name}_add",
    sub {
      my ($self, $new) = @_;
      $new ||= 1;
      $self->{$name} += $new;
    },
    "${name}_remove",
    sub {
      my ($self, $new) = @_;
      $new ||= 1;
      $self->{$name} -= $new;
    },
    "${name}_reset",
    sub {
      my $self = shift;
      my $val = $defaults->{$name} || 0;
      $self->{$name} = $val;
    },
    "${name}_set",
    sub {
      my $self = shift;
      $self->{$name} = int(shift);
    }
  );
}

sub classdata{
  shift;
  my $args = shift;
  my $class = $Class::Builder::current_class;
  my $classdata = $Class::Builder::classdata{$class};
  my $name = $args->{name};
  return ($name, sub { $classdata->{$name}; }) if($args->{final});
  return ($name, sub : lvalue {
    shift;
    my $arg = shift;
    defined $arg and $classdata->{$name} = $arg;
    $classdata->{$name};
  });
}

# -------------------------------------- | Special Methods Builder |
sub constructor{
  shift;
  my $arg = shift;
  my @list = ref($arg) eq 'ARRAY' ? @$arg : ($arg);
  my $class = $Class::Builder::current_class;
  my $initializers = $Class::Builder::initializers{$class};
  my $defaults = $Class::Builder::defaults{$class};

  map {
    $_,
    sub {
      my $class = (ref $_[0]) ? ref shift : shift;
      my $self = {};
      $self = dclone($defaults); my @args = @_;
      bless $self, $class;

      my $hashref = {};
      if($args[0] and (ref $args[0] eq 'HASH')){
        $hashref = shift @args;
      }else{
        %$hashref = @args unless(scalar @$initializers);
      }
      map {$_, $self->$_($hashref->{$_})} (keys %$hashref);
      map {$_, $self->$_(@args)} @$initializers;
      return $self;
    }
  } @list;
}

sub abstract {
  # implement abstract methods:
  shift;
  my $arg = shift;
  my $class = $Class::Builder::current_class;
  my @list = ref($arg) eq 'ARRAY' ? @$arg : ($arg);
  map {
    my $name = $_;
    ($name,
     sub {
       my ($self) = @_;
       my $calling_class = ref $self;
       die "[ABSTRACT METHOD] you can not call ${calling_class}::$name ",
        "(defined in class '$class') without overridden.";
     }
    )
  } @list;
}

sub group{
  shift;
  my $arg = shift;
  croak "the argument for a group must be a reference."
    unless(ref $arg);
  my $hashref = {};
  my %results = ();
  if(ref $arg eq 'ARRAY'){
    %$hashref = @$arg;
  }else{
    $hashref = $arg;
  }
  while (my ($group, $garg) = each %$hashref){
    $results{$group} = sub {wantarray ? @$garg : $garg};
  }
  return %results;
}

sub dumper{
  shift;
  my $arg = shift;
  my @list = ref($arg) eq 'ARRAY' ? @$arg : ($arg);
  map {
    $_,
    sub { require Data::Dumper; return Data::Dumper::Dumper(shift); }
  } @list;
}

sub clone{
  shift;
  my $arg = shift;
  my @list = ref($arg) eq 'ARRAY' ? @$arg : ($arg);
  map {
    $_,
    sub { require Storable; return Storable::dclone(shift); }
  } @list;
}

1;

__END__

=pod

=head1 NAME

  Class::Builder - auto-generator of class accessors/special methods

=head1 SYNOPSIS

=head2 Creating Class Members (fields):

  package SystemUser;
  use Class::Builder {
    uid    => { number => undef },
    uname  => { string => 'default user' },
    group  => { arrayref => []},
    ctime  => { number => time },
    disable => { boolean => 0 },
    log_count => { counter => 0},
  };
  1;

  # then in your script:
  package main;
  use SystemUser;

  my $user = new SystemUser ({name => 'chopin'});
  print $user->uname(), "\n"; # print chopin;
  print scalar localtime $user->ctime(), "\n";

  foreach my $group ($user->group){
    &do_something($group);
  }

  my $user = new SystemUser ({uname => 'chopin'});
  print $user->uname(), "\n"; # print chopin;
  print scalar localtime $user->ctime(), "\n";

  sub system_user_loggin{
    if($user->disable){
      die "you account is disabled, contact system administrator.";
    }
    # ... do some thing
    $user->log_count_add;
    print "you are logged into the system. you have loged ",$user->log_count," times.";
  }

  system_user_loggin(); # print $user->log_count as 1.

=head2 Special Methods

  package SystemUser;
  use Class::Builder {
    '-methods' => {
      constructor => 'create',
      dumper => 'as_string',
      clone  => 'copy',
    },
    uid    => { number => undef },
    uname  => { string => '' },
  };
  1;

  package main;
  use SystemUser;

  my $user = SystemUser->create({name=>'mozart'});

  my $user_cp = $user->copy;
   # deep copy the structure, not only the pointer

  print $user_cp->as_string() # dump the contents of $user

There also a function `struct' opened for you, let you create
modules `on the fly':

  package SystemUser;
  use Class::Builder;

  struct Machine => {
    machine_name => { string => 'default name' },
    location => {string => '' }
  }; # define Machine before use it.

  struct {
    uname => {string => ''},
    main_machine => { Machine => undef },
  }; # implicit class name: 'SystemUser' in this case.


  package main;
  my $machine = new Machine( machine_name => 'veryslow' );
  my $user = new SystemUser( uname => 'mozart', main_machine => $machine );

  print $user->main_machine->machine_name();

=head1 DESCRIPTION

C<Class::Builder> is a module helps OOP programmers to create
`class's (packages, in terms of perl) in several ways of automation.

If you've used one of C<Class::MethodMaker>, C<Class::Struct> or
C<Class::Accessor>, the concept of C<Class::Builer> is not newer to you.
In fact, this module can be viewed as a combination of the above
modules. I'm trying to include most frequently used functions,
while keep the module as lightweight as possible.

=head2 Field Methods:

To create a new member field for you class, simply say:

  use Class::Builder {
    <fieldname> => { <fieldtype> => <default_vaule>, [ final => 1 ]},
  };

where <fieldname> is the name you want to set as a member field, it must be
legal as a name of perl function.

If you defined the field as `final', you can not use the accessor methods
to change the field's value. But you still can change it by directly access
data stored in the object (a blessed hashref).

`final' attribute is ignored by `hashref' and `arrayref' field, under
current implementation.

The following field types are available now:

=over 4

=item * string

You can get/set a string field via functions. For example

  $user->name("myname")

change `$user''s name to `myname'. You can even do:

  $user->name = "otername";

Then you can access the value by:
  print $user->name;

=item * number

Provide same functions as string field. (no extra checking for this field under
current implementation).

=item * boolean

Boolean field will be set to '1' if you passed a argument has `true'
values in perl.

Additionally, for each boolean field C<`x'>, you can:

  $obj->x_rev();    # reverse. 1 to 0, 0 to 1.
  $obj->x_reset();  # reset to it's default values.

=item * counter

Count is a number fields that provides some additional values:

  $obj->x_add();  # x becomes x+1
  $obj->x_add(2); # x becomes x+2
  $obj->x_remove(); # do the reverse of above
  $obj->x_set(19);  # directly set the value to 19
  $obj->x_reset();  # reset to 0 or any value you defined

=item * hashref

There a special methods provides for fields contains
reference to hashes and arraies. Those methods are simple
wrappers over perl build-in functions, as the following
example:

  package SysInfo;
  use Class::Builder {
    passwd => {hashref => {huang => 'passwdinsecret', phantom=>'longpasswd'}},
  };

  package main;
  my $sysinfo = new SysInfo;
  $sysinfo->passwd->{newuser} = 'validpasswd';
  do_something() if($sysinfo->passwd_exists('huang'));
  foreach my $user ($sysinfo->passwd_keys){ do_something($user); }
  foreach my $pass ($sysinfo->passwd_values){ checkpasswd($pass); }
  $sysinfo->passwd_delete('huang');

=item * arrayref

  package MusicCD;
  use Class::Builder {
    trackList => {
        arrayref => [qw(track1 silent noise)],
      },
  }

  package main;
  my $mcd = new MusicCD;
  foreach my $tract ($mcd->trackList){ ... }
  my $arrayref = $mcd->trackList;
  # use this to get the count
  my $count = $mcd->trackList_count;
  $mcd->trackList_push('newTrack');
  $mcd->trackList_pop(); # newTrack
  $mcd->trackList_unshift('firstTrack');
  $mcd->trackList_shift(); # firstTract
  $mcd->trackList_splice(1, 1);

=item * other object

Any other field name will be interpretered as external class names.
Sign a default value is little different than other fields:

  # if you passes a single scalar, it will be treated as
  # the constructor of the value:
  use Class::Builder {
    filehandler => {IO::File => 'new'},
  }; # create a new IO::File object

  # if you passes a array reference, it will be treated as
  # ['constructor, arg1, arg2, ...]
  use Class::Builder {
    filehandler => {IO::File => ['new', 'filename', 'r']},
  }; # this time, open filename for you too.

  # if a reference of other type passed, it will be treated
  # as the object itself:
  my $fh = new IO::File('filename', 'w') or die "$!";
  use Class::Builder {
    filehandler => {IO::File => $fh},
  }; # just use $fh

Note at the last example, we do not require C<ref $fh> to be C<IO::File>,
so, use a object drived from some subclass of IO::File is allowed.

=back

Two special functions applies for all member fields:

=over 4

=item * clear('field1', 'field2', ...)

will set member field 'field1', 'field2', ... to C<undef>.

=item * get('field1', 'field2', ...)

return a list contains values of  member fields 'field1', 'field2', ....

=back

Note that currently all types are implemented as a key of a perl hash, so
you can assign any scalar value to any field without causing errors.
Typically, C<number> field and C<string> field have no difference it all, it is
introduced only for future development (such as dynamic linkage with databases).
I.e, you can sign a perl string to a number field, but we do not recommend you
do that.

=head2 On-the-Fly Classes

You can use function C<struct()> in three styles:

=item * C<struct(\%args)>

where C<\%args> takes the same form as you used in

  use Class::Builder \%args;

C<Class::Builder> will take the current package as the class name.

=item * C<struct(Classname1 => \%args1, Classname2=> \%args2, ...)>

This form of C<struct> creates classes `on the fly', so, you do
not need to define C<classname1>, C<classname2> munually. You can
thinks the code:

  struct(Classname1 => \%args1, Classname2=> \%args2)

as a shortcut as:

  package Classname1;
  use Class::Builder \%args1;
  1;

  package Classname2;
  use Class::Builder \%args2;
  1;

=item * C<struct([classname => \%args, classname2=> \%args])>

Almost as same as the above case. Passes arguments as a reference of
a array is (theorically) little faster than passes them as a legacy array.
Use this form if you concerns with perfomance issues.

IMPORTANT: C<struct({classname => \%args, classname2=> \%args})>
do not work as you expected. (C<Class::Builder> interpreted the
hashref as arguments for current class, as the first style mentioned
above).

Note that

  package SomeClass;
  use Class::Builder { ... some defination ... };
  struct { ... some defination ... };

is not recommended, any field defined in struct could not get a chance to setup
it's default values.

=head2 Special Methods

C<Class::Builder> also has a ability to create special methods:

=item * constructor

By default, C<Class::Builder> will create a function C<new()> as the constructor.
you can change the name of constructor to others such like C<create()> by defining:

  use Class::Builder {
    '-methods' => { constructor => 'create' },
  };

or even you can define more than one constructor, each has same functions:

  use Class::Builder {
    '-methods' => { constructor => ['create', 'new'] },
  };

you can pass a hash reference to initialize member fields:

  package SomeClass;
  use Class::Builder {
    '-methods' => { constructor => 'create' },
    somefield => { string => '' },
  };
  1;
  package main;
  my $sc = new SomeClass ({somefield => 'newvalues'});

Pass initial values as a list is also acceptable:

  my $sc = new SomeClass (somefield => 'newvalues');

UNTIL you defined any initializers as below.

=item * initializer

You can define one or more initializers, each will by called by constructor (C<new()>
, by the default) in orders as you defined:

  package SomeBody;
  use Class::Builder {
    '-methods' => {initializer => ['init1', 'init2']},
  }

  sub init1{
      ...
    };

  sub init2{
      ...
    };

Then, C<init1()> and C<init2()> will get called whenever you create a new instance
of C<SomeBody>:

  package SystemUser;
    use Class::Builder {
      '-methods' => {
          initializer => ['init1', 'init2'],
        },
      name => {string => 'bethoven'},
    };

  sub init1{shift->{name} = 'chopin';}
  sub init2{shift->{name} = 'Walsh';}

  1;

  package main;
  my $user = new SystemUser( {name => 'mozart'} );

  print $user->name(); # print Walsh

You can pass arguments as a array (not a hash reference) to constructor, and all
of the initializers will get them also.

=head1 INHERITAGE

To create a subclass of Class::Builder, at lease you must define two functions:

=over 4

=item * struct();

use the following code:

  sub struct{
    __PACKAGE__->_struct(@_);
  }

=item * setup();

Do something before C<Class::Builder> takes actions.

=item * known_types();

If you want to provide some new field types, rewrite this function
to avoid fatal errors.

=head1 BUGS

  This package is not yet well tested.

=head1 AUTHOR

  Wei, Huang < huang@toki.waseda.jp >

=head1 SEE ALSO

=cut