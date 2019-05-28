package Data::Promise;

=head1 NAME

Data::Promise - simple promise like interface

=head1 SYNOPSIS

  use Modern::Perl;
  use Data::Promose;

  my $p=new Data::Promise(cb=>sub {
    my ($resolve,$reject)=@_;

    if(...) {
      # pass context
      $resolve->('ok');
    } else {
      $reject->('something went wrong');
    }
  });

  sub pass_function { ... }
  sub fail_function { ... }
  $p->then(\&pass_function,\&fail_function);


  # delayed example
  my $p=new Data::Promise(
    delayed=>1,
    cb=>sub {

    if(...) {
      # pass context
      $resolve->('ok');
    } else {
      $reject->('something went wrong');
    }
  });

  $p->then(\&pass_function,\&fail_function);
  # pass and fail functions will not be called until now
  $p->do_resolve;

  ## create a rejected promise
  my $p=Data::Promise->reject(42);

  # you can be sure your fail funtion will be called
  $p->then(\&pass_function,\&fail_function);

  ## create a resolved promise
  my $p=Data::Promise->resolve(42);

  # you can be sure your pass funtion will be called
  $p->then(\&pass_function,\&fail_function);

=head1 DESCRIPTION

A light and simple Promise object based on the current es6 implementation.   This promise object class was written to mimic how promise(s) are implemnted in the wild.  This may or may not be the class you are looking for.

=cut

our $VERSION=0.001;

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use namespace::clean;

=head1 OO Constructor Arguments

=over 4

=item * cb=>sub { my ($resovle,$reject)=@_ }

The callback function used to resolve the object.  If no function is passed in then the object will never resolve!

=cut

has cb=>(
  isa=>CodeRef,
  default=>\&_build_stub,
  is=>'ro',
);

=item * delayed=>0|1

This enables or disables manual control over when your cb function will be called.  The default is false.

=cut

has delayed=>(
  isa=>Bool,
  is=>'ro',
  default=>0,
);

=back

=cut

has _jobs=>(
  isa=>ArrayRef,
  is=>'ro',
  default=>sub {[]},
);

has _finally=>(
  isa=>ArrayRef,
  is=>'ro',
  default=>sub {[]},
);

has _then_catch=>(
  isa=>ArrayRef,
  is=>'ro',
  default=>sub {[]},
);

has _pending=>(
  is=>'rw',
);

has _result=>(
  is=>'rw',
);

sub _build_stub {
  return \&_default_stub
}

sub _default_stub { }

=head1 Promise functions

=head2 if($p->pending) { ... }

Used as a state checking interface, this method returns true if the promise is still being resolved, false if it is not.

=cut

sub pending {
  my ($self)=@_;
  return defined($self->_pending) ? 0 : 1;
}

=head2 my $p=$p->then(\&resolve,\&reject)

This method provides a way to attach functions that will be called when the object is either rejected or resovled.

=cut

sub then {
  my ($self,$resolve,$reject)=@_;

  $resolve=sub {} unless defined($resolve);
  $reject=sub {} unless defined($reject);
  if($self->pending) {
    push @{$self->_jobs},[$resolve,$reject];
  } else {
    my $code=$self->_pending==0 ? $resolve : $reject;
    eval { $code->(@{$self->_result}) };
  }
  return $self;
}

=head2 my $p=$p->catch(\&reject)

This is really a wrapper function for: $p->then(undef,\&reject);

=cut

sub catch {
  my ($self,$code)=@_;
  $self->then(undef,$code);
}

=head2 my $p=Data::Promise->reject(@args)

Creates a rejected promise with @args as the rejected data.

=cut

sub reject {
  my ($class,@args)=@_;
  return __PACKAGE__->new(cb=>sub {
    my ($pass,$fail)=@_;
    $fail->(@args);
  });
}

=head2 my $p=Data::Promise->resolve(@args)

Creates a resolved promise with @args as the resolved data.

=cut

sub resolve {
  my ($class,@args)=@_;
  return __PACKAGE__->new(cb=>sub {
    my ($pass,$fail)=@_;
    $pass->(@args);
  });
}

=head2 my $p=$p->finally(sub {});

Allows the addition of functions that will be called once the object is resolved.  The functions will recive no arguments, and are called reguardless of the resolved or rejected state.

=cut

sub finally {
  my ($self,$code)=@_;

  $code=sub {} unless defined($code);

  if($self->pending) {
    push @{$self->_finally},$code;
  } else {
    eval { $code->() }
  }
  return $self;
}

sub _resolver {
  my ($self,$col)=@_;
  return sub {

    return unless $self->pending;
    my $args=[@_];
    $self->_result($args);
    $self->_pending($col);
    foreach my $funcs (@{$self->_jobs}) {
      eval {
        $funcs->[$col]->(@{$args});
      };
    }
  }
}

sub BUILD {
  my ($self)=@_;

  return if $self->delayed;
  $self->do_resolve;
}

=head2 my $p=$p->do_resolve

When the promise is constructed in a delayed state, this method must be called to activate the cb method.

=cut

sub do_resolve {
  my ($self)=@_;

  return unless $self->pending;
  my ($pass,$fail)=($self->_resolver(0),$self->_resolver(1));
  eval {
    $self->cb->(
      $pass,
      $fail,
    );
  };
  if($@) {
    $fail->($@);
  }
  foreach my $f (@{$self->_finally}) {
    eval {
      $f->();
    };
  }

  # clean up all code refs
  @{$self->_jobs}=();
  @{$self->_finally}=();
  return $self;
}

sub DEMOLISH {
  my ($self)=@_;
  return unless defined($self);
  %{$self}=();
  undef $self;
}

=head1 AUTHOR

Michael Shipper <AKALINUX@CPAN.ORG>

=cut

1;
