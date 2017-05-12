package Catalyst::ActionRole::MethodSignatureDependencyInjection;

use Moose::Role;
use Carp;

our $VERSION = '0.020';

has use_prototype => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_prototype');

  sub _build_at {
    my ($self) = @_;
    my ($attr) =  @{$self->attributes->{UsePrototype}||[0]};
    return $attr;
  }

has execute_args_template => (
  is=>'ro',
  required=>1,
  lazy=>1,
  builder=>'_build_execute_args_template');

  sub _build_execute_args_template {
    my ($self) = @_;
    my ($attr) =  @{$self->attributes->{ExecuteArgsTemplate}||['']};
    return $attr;
  }

has prototype => (
  is=>'ro', 
  required=>1,
  lazy=>1, 
  builder=>'_build_prototype');

  sub _build_prototype {
    my ($self) = @_;
    if($INC{'Function/Parameters.pm'}) {
      return join ',',
        map {$_->type? $_->type->class : $_->name}
          Function::Parameters::info($self->code)->positional_required;
    } else {
      return prototype($self->code);
    }
  }

has template => (
  is=>'ro', 
  required=>1,
  lazy=>1, 
  builder=>'_build_template');

  sub _build_template {
    my ($self) = @_;
    return $self->use_prototype ?
      $self->prototype : $self->execute_args_template;
  }

sub parse_injection_spec_section {
  my ($self) = @_;

  # These Regexps could be better to allow more whitespace.
  my $p = qr/[^,]+/;
  my $p2 = qr/$p<.+?>$p/x;

  $_[1]=~/\s*($p2|$p)\s*/gxc;

  return $1;
}

has dependency_builder => (
  is=>'ro',
  required=>1,
  isa=>'ArrayRef',
  lazy=>1,
  builder=>'_dependency_builder');

  sub _dependency_builder {
    my $self = shift;
    my $template = $self->template;
    my @parsed = $self->_parse_dependencies($template);

    return \@parsed;
  }

  sub _parse_dependencies {
    my ($self, $template) = @_;
    my @what = ();
    for($template) {
      PARSE: {
        last PARSE unless length;
        do {  
          push @what, $self->parse_injection_spec_section($_) 
            || die "trouble parsing action $self template '$template'";
          last PARSE if (pos == length);
        } until (pos == length);
      }
    }

    #cope with older Perls trimming whitspace from prototypes.  I supposed
    #this kills any models that end in 'required'...
    if($self->use_prototype) {
      @what = map {
        $_=~m/\Srequired$/
          ? do { $_=~s/required$//; "$_ required" }
        : $_
      } @what;
    }

    return @what;
  }

has prepared_dependencies => (
  is=>'ro',
  required=>1,
  isa=>'ArrayRef',
  lazy=>1,
  builder=>'_build_prepared_dependencies');

  sub not_required { return bless \(my $cb = shift), __PACKAGE__.'::not_required'; }
  sub required { return bless \(my $cb = shift), __PACKAGE__.'required'; }

  sub _prepare_dependencies {
    my ($self, @what) = @_;
    my $arg_count = 0;
    my $capture_count = 0;
    my @dependencies = ();

    while(my $what = shift @what) {
      my $method = $what =~m/required/ ? sub {required(shift) } : sub { not_required(shift) };
      do { push @dependencies, $method->(sub { shift }); next } if lc($what) eq '$ctx';
      do { push @dependencies, $method->(sub { shift }); next }  if lc($what) eq '$c';
      do { push @dependencies, $method->(sub { shift->state }); next }  if lc($what) eq '$state';
      do { push @dependencies, $method->(sub { shift->req }); next }  if lc($what) eq '$req';
      do { push @dependencies, $method->(sub { shift->req }); next }  if lc($what) eq '$request';
      do { push @dependencies, $method->(sub { shift->req->env }); next }  if lc($what) eq '$env';

      do { push @dependencies, $method->(sub { shift->res }); next }  if lc($what) eq '$res';
      do { push @dependencies, $method->(sub { shift->res }); next }  if lc($what) eq '$response';

      do { push @dependencies, $method->(sub { shift->req->args}); next }  if lc($what) eq '$args';
      do { push @dependencies, $method->(sub { shift->req->body_data||+{} }); next }   if lc($what) eq '$bodydata';
      do { push @dependencies, $method->(sub { shift->req->body_parameters}); next }  if lc($what) eq '$bodyparams';
      do { push @dependencies, $method->(sub { shift->req->query_parameters}); next }  if lc($what) eq '$queryparams';

      #This will blow stuff up unless its the last...
      do { push @dependencies, $method->(sub { @{shift->req->args}}) ; next }  if lc($what) eq '@args';
      do { push @dependencies, $method->(sub { %{shift->req->body_parameters}}); next }  if lc($what) eq '%bodyparams';
      do { push @dependencies, $method->(sub { %{shift->req->body_data||+{}}}); next }  if lc($what) eq '%bodydata';

      do { push @dependencies, $method->(sub { %{shift->req->query_parameters}}); next }  if lc($what) eq '%queryparams';
      do { push @dependencies, $method->(sub { %{shift->req->body_data||+{}}}); next }  if lc($what) eq '%body';
      do { push @dependencies, $method->(sub { %{shift->req->query_parameters}}); next }  if lc($what) eq '%query';

      # Default view and model
      # For now default model / view can't be parameterized.
      do { push @dependencies, $method->(sub { shift->model}) ; next }  if($what =~/^Model/ && $what!~/^Model\:/);
      do { push @dependencies, $method->(sub { shift->view}) ; next }  if($what =~/^View/ && $what!~/^View\:/);
 
      if(defined(my $arg_index = ($what =~/^\$?Arg(\d+).*$/i)[0])) {
        push @dependencies, $method->(sub { shift->req->args->[$arg_index] });
        $arg_count = undef;
        next;
      }

      if($what=~/^\$?Args\s/) {
        push @dependencies, $method->(sub { @{shift->req->args}}); # need to die if this is not the last..
        next;
      }

      if($what =~/^\$?Arg\s?.*/i) {
        # count arg
        confess "You can't mix numbered args and unnumbered args in the same signature" unless defined $arg_count;
        my $local = $arg_count;
        push @dependencies, $method->(sub { shift->req->args->[$local]}) ;
        $arg_count++;
        next;
      }

      if($what =~/^\$?Capture\s?.*/i) {
        # count arg
        my $local = $capture_count;
        confess "You can't mix numbered captures and unnumbered captures in the same signature" unless defined $arg_count;
        push @dependencies, $method->(sub { my ($c, @args) = @_; return $args[$local] });
        $capture_count++;
        next
      }

      if(defined(my $capture_index = ($what =~/^\$?Capture(\d+).*$/i)[0])) {
        # If they are asking for captures, we look at @args.. sorry
        my $local = $capture_index;
        push @dependencies, $method->(sub { my ($c, @args) = @_; $args[$local] });
        next;
      }

      if($what=~/^Model\:\:/i) {
        # Its a model. Could be:
        #   -- Model::Foo
        #   -- Model::Foo $foo
        #   -- Model::Foo $foo isa Int
        #   -- Model::Foo $foo isa Int required
        #   -- Model::Foo<$params>
        #   -- Model::Foo<$params> $foo
        #   -- Model::Foo<$params> $foo isa Int
        #   -- Model::Foo<$params> $foo isa Int required
        #   For where $params is any sort of parsable spec (Arg, Arg $id, Arg $id isa Int, ...)
  
        # first get the model name
        my @inner_deps = ();
        my ($model) = ($what=~m/^Model\:\:([\w\:]+)/i);

        die "Can't seem to extract a model name from '$what'!" unless $model;

        my ($rest) = ($what =~/<([^>]+)/);

        # Is the model parameterized??
        if(defined($rest)) {
           @inner_deps = $self->_prepare_dependencies($self->_parse_dependencies($rest));
        }

        push @dependencies, @inner_deps if @inner_deps;
        push @dependencies, $method->(sub {
          my ($c, @args) = @_;

          # Make sure the $model is a component we already know about.
          die "'$model' is not a defined component (parsed out of '$what'"
            unless $c->components->{ ref($c).'::Model::'.$model };

          my ($ret, @rest) = $c->model($model, map { $$_->($c, @args) } @inner_deps);
          warn "$model returns more than one arg" if @rest;
          return $ret;
        });
        next;
      }

      if($what=~/^View\:\:/i) {
        my @inner_deps = ();
        my ($view) = ($what=~m/^View\:\:([\w\:]+)/i);

        die "Can't seem to extract a view name from '$what'!" unless $view;

        my ($rest) = ($what =~/<([^>]+)/);

        if(defined($rest)) {
           @inner_deps = $self->_prepare_dependencies($self->_parse_dependencies($rest));
        }

        push @dependencies, @inner_deps if @inner_deps;
        push @dependencies, $method->(sub {
          my ($c, @args) = @_;

          die "'$view' is not a defined component (parsed out of '$what'"
            unless $c->components->{ ref($c).'::View::'.$view };

          my ($ret, @rest) = $c->view($view, map { $$_->($c, @args) } @inner_deps);
          warn "$view returns more than one arg" if @rest;
          return $ret;
        });
        next;
      }

      if(my $controller = ($what =~/^Controller\:\:(.+?)\s+.+$/)[0] || ($what =~/^Controller\:\:(.+)\s+.+$/)[0]) {
        push @dependencies, $method->(sub {
          my $c = shift;

          # Make sure the $controller is a component we already know about.
          die "$controller is not a defined component"
            unless $c->components->{ ref($c).'::Controller::'.$controller };

          my ($ret, @rest) = $c->controller($controller);
          warn "$controller returns more than one arg" if @rest;
          return $ret;
        });
        next;
      }

      die "Found undefined Token in action $self signature '${\$self->template}' => '$what'";
    }

    unless(scalar @dependencies) {
      @dependencies = (
        not_required(sub { return $_[0] }),
        not_required(sub { return @{$_[0]->req->args} }),
      );
    }

    return @dependencies;
  }

  sub _build_prepared_dependencies {
    my ($self) = @_;
    my @what = @{$self->dependency_builder};
    return [ $self->_prepare_dependencies(@what) ];
  }

around ['match', 'match_captures'] => sub {
  my ($orig, $self, $ctx, $args) = @_;
  return 0 unless $self->$orig($ctx, $args);

  # For chain captures, we find @args, but not for args...
  # So we have to normalize.
  
  my @args = scalar(@{$args||[]}) ?  @{$args||[]} : @{$ctx->req->args||[]};

  my @resolved = ();
  foreach my $dependency (@{ $self->prepared_dependencies }) {
    my $required = $dependency=~m/not_required/ ? 0:1;
    if($required) {
      my $ret = $$dependency->($ctx, @args);
      unless(defined $ret) {
        return 0;
      } else {
        push @resolved, $ret;
      }
    } else {
      push @resolved, $dependency;
    }
  }

  $ctx->stash->{__method_signature_dependencies_keys}->{"$self"} = \@resolved;
  return 1;
};

around 'execute', sub {
  my ($orig, $self, $controller, $ctx, @args) = @_;
  my $stash_key = $self .'__method_signature_dependencies';
  my @dependencies = map { $_=~m/not_required/ ? $$_->($ctx, @args) : $_ }  
    @{$ctx->stash->{__method_signature_dependencies_keys}->{"$self"}};

  return $self->$orig($controller, @dependencies);
};

1;

=head1 NAME

Catalyst::ActionRole::MethodSignatureDependencyInjection - Experimental Action Signature Dependency Injection

=head1 SYNOPSIS

Attribute syntax:

    package MyApp::Controller
    use base 'Catalyst::Controller';

    sub test_model :Local :Does(MethodSignatureDependencyInjection)
      ExecuteArgsTemplate($c, $Req, $Res, $BodyData, $BodyParams, $QueryParams, Model::A, Model::B)
    {
      my ($self, $c, $Req, $Res, $Data, $Params, $Query, $A, $B) = @_;
    }

Prototype syntax

    package MyApp::Controller
    use base 'Catalyst::Controller';

    no warnings::illegalproto;

    sub test_model($c, $Req, $Res, $BodyData, $BodyParams, $QueryParams, Model::A required, Model::B)
      :Local :Does(MethodSignatureDependencyInjection) UsePrototype(1)
    {
      my ($self, $c, $Req, $Res, $Data, $Params, $Query, $A, $B) = @_;
    }

With required model injection:

    package MyApp::Controller
    use base 'Catalyst::Controller';

    no warnings::illegalproto;

    sub chainroot :Chained(/) PathPrefix CaptureArgs(0) {  }

      sub no_null_chain_1( $c, Model::ReturnsNull, Model::ReturnsTrue)
       :Chained(chainroot) PathPart('no_null_chain')
       :Does(MethodSignatureDependencyInjection) UsePrototype(1)
      {
        my ($self, $c) = @_;
        return $c->res->body('no_null_chain_1');
      }

      sub no_null_chain_2( $c, Model::ReturnsNull required, Model::ReturnsTrue required) 
       :Chained(chainroot) PathPart('no_null_chain')
       :Does(MethodSignatureDependencyInjection) UsePrototype(1)
      {
        my ($self, $c) = @_;
        return $c->res->body('no_null_chain_2');
      }


=head1 WARNING

Lets you declare required action dependencies via the a subroutine attribute
and additionally via the prototype (if you dare)

This is a weakly documented, early access prototype.  The author reserves the
right to totally change everything and potentially disavow all knowledge of it.
Only report bugs if you are capable of offering a patch and discussion.

B<UPDATE> This module is starting to stablize, and I'd be interested in seeing
people use it and getting back to me on it.  But I do recommend using it only
if you feel like its code you understand.

Please note if any of the declared dependencies return undef, that will cause
the action to not match.  This could probably be better warning wise...

=head1 DESCRIPTION

L<Catalyst> when dispatching a request to an action calls the L<Action::Class>
execute method with the following arguments ($self, $c, @args).  This you likely
already know (if you are a L<Catalyst> programmer).

This action role lets you describe an alternative 'template' to be used for
what arguments go to the execute method.  This way instead of @args you can
get a model, or a view, or something else.  The goal of this action role is
to make your action bodies more concise and clear and to have your actions
declare what they want.

Additionally, when we build these arguments, we also check their values and
require them to be true during the match/match_captures phase.  This means
you can actually use this to control how an action is matched.

There are two ways to use this action role.  The default way is to describe
your execute template using the 'ExecuteArgsTemplate' attribute.  The
second is to enable UsePrototype (via the UsePrototype(1) attribute) and
then you can declare your argument template via the method prototype.  You
will of course need to use 'no warnings::illegalproto' for this to work.
The intention here is to work toward something that would play nice with
a system for method signatures like L<Kavorka>.

If this sounds really verbose it is.  This distribution is likely going to
be part of something larger that offers more sugar and less work, just it was
clearly also something that could be broken out and hacked pn separately.
If you use this you might for example set this action role in a base controller
such that all your controllers get it (one example usage).

Please note that you must still access your arguments via C<@_>, this is not
a method signature framework.  You can take a look at L<Catalyst::ActionSignatures>
for a system that bundles this all up more neatly.

=head1 DEPENDENCY INJECTION

You define your execute arguments as a positioned list (for now).  The system
recognizes the following 'built ins' (you always get $self automatically).

B<NOTE> These arguments are matched using a case insensitive regular expression
so generally whereever you see $arg you can also use $Arg or $ARG.

=head2 $c

=head2 $ctx

The current context.  You are encouraged to more clearly name your action
dependencies, but its here if you need it.

=head2 $req

=head2 $request

The current L<Catalyst::Request>

=head2 $res

=head2 $request

The current L<Catalyst::Response>

=head2 $args

An arrayref of the current args

=head2 args
=head2 @args

An array of the current args.  Only makes sense if this is the last specified
argument.

=head2 $arg0 .. $argN

=head2 arg0 ... argN

One of the indexed args, where $args0 => $args[0];

=head2 arg

=head2 $arg

If you use 'arg' without a numbered index, we assume an index based on the number
of such 'un-numbered' args in your signature.  For example:

    ExecuteArgsTemplate(Arg, Arg)

Would match two arguments $arg->[0] and $args->[1].  You cannot use both numbered
and un-numbered args in the same signature.

B<NOTE>This also works with the 'Args' special 'zero or more' match.  So for
example:

    sub argsargs($res, Args @ids) :Local {
      $res->body(join ',', @ids);
    }

Is the same as:

    sub argsargs($res, Args @ids) :Local Args {
      $res->body(join ',', @ids);
    }

=head2 $captures

An arrayref of the current CaptureArgs (used in Chained actions).

=head2 @captures

An array of the current CaptureArgs.  Only makes sense if this is the last specified
argument.

=head2 $capture0 .. $captureN

=head2 capture0 ... captureN

One of the indexed Capture Args, where $capture0 => $capture0[0];

=head2 capture

If you use 'capture' without a numbered index, we assume an index based on the number
of such 'un-numbered' args in your signature.  For example:

    ExecuteArgsTemplate(Capture, Capture)

Would match two arguments $capture->[0] and $capture->[1].  You cannot use both numbered
and un-numbered capture args in the same signature.

=head2 $bodyData

=head2 $bodydata

$c->req->body_data

=head2 $bodyParams

=head2 $bodyparams

$c->req->body_parameters

=head2 $QueryParams

=head2 $queryparams

$c->req->query_parameters

=head2 %query

A hash of the information in $c->req->query_parameters.  Must be the last argument in the
signature.

=head2 %body

A hash of the information in $c->req->body_data.  Must be the last argument in the
signature.

=head1 Accessing Components

You can request a L<Catalyst> component (a model, view or controller).  You
do this via [Model||View||Controller]::$component_name.  For example if you
have a model that you'd normally access like this:

    $c->model("Schema::User");

You would say "Model::Schema::User". For example:

    ExecuteArgsTemplate(Model::Schema::User)

Or via the prototype

    sub myaction(Model::Schema::User) ...

You can also pass arguments to your models.  For example:

    ExecuteArgsTemplate(Model::UserForm<Model::User>)

same as $c->model('UserForm', $c->model('User'));

=head1 Default Components

You may specify the current view or model by just using the declaration 'Model'
or 'View'.  For example:

    package MyApp;
    use Catalyst;
    
    # We assume MyApp::Model::Default
    MyApp->config(default_model=>'Default');
    MyApp->setup;


    sub default_model($res,Model) :Local 
     :Does(MethodSignatureDependencyInjection) UsePrototype(1)
    {
      my ($self, $res, $model) = @_;
      $res->body($model); # isa Model::Default
    }

    sub chainroot :Chained(/) PathPrefix CaptureArgs(0) {
      my ($self, $ctx) = @_;
      $ctx->stash(current_model_instance => 100);
    }

      sub default_again($res,Model required) :Chained(chainroot)
       :Does(MethodSignatureDependencyInjection) UsePrototype(1)
      {
        my ($self, $res, $model) = @_;
        return $res->body($model);  # is 100
      }

Can be useful to help make controllers less tightly bound.

=head1 Component Modifiers

=head2 required

Used to declare a component injection (Model, View or Controller) is 'required'.  This means
it must return something that Perl thinks of as true (for now we exclude both undef and 0 since
I think that is less surprising and the use cases where a model validately return 0 seems
small).  When a component is required, we resolve it during the match/match_captures phase of
dispatch and the action will fail to match should the component fail the required condition.
Useful if you use models as a we to determine if an action should run or no.

B<NOTE> Since 'required' components get resolved during the match/match_captures phase, this
means that certain parts of the context have not been completed.  For example $c->action will
be null (since we have not yet determined a matching action or not).  If your model does
ACCEPT_CONTEXT and need $c->action, it cannot be required.  I think this is the main thing
undefined with context at this phase but other bits may emerge so test carefully.

=head1 Integration with Catalyst::ActionSignatures

This action role will work with L<Catalyst::ActionSignatures> automatically and
all features are present.

=head1 Integration with Function::Parameters

For those of you that would like to push the limits even harder, we have
experimental support for L<Function::Parameters>.  You may use like in the
following example.

    package MyApp::Controller::Root;

    use base 'Catalyst::Controller';

    use Function::Parameters({
      method => {defaults => 'method'},
      action => {
        attributes => ':method :Does(MethodSignatureDependencyInjection) UsePrototype(1)',
        shift => '$self',
        check_argument_types => 0,
        strict => 0,
        default_arguments => 1,
      }});

    action test_model($c, $res, Model::A $A, Model::Z $Z) 
      :Local 
    {
      # ...
      $res->body(...);
    }

    method test($a) {
      return $a;
    }

Please note that currently you cannot use the 'parameterized' syntax for component
injection (no Model::A<Model::Z> support).

=head1 SEE ALSO

L<Catalyst::Action>, L<Catalyst>, L<warnings::illegalproto>,
L<Catalyst::ActionSignatures>

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
