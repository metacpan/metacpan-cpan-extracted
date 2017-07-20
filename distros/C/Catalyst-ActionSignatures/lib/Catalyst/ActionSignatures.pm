package Catalyst::ActionSignatures;

use Moose;
use B::Hooks::Parser;
use Carp;
extends 'signatures';

our $VERSION = '0.011';

around 'callback', sub {
  my ($orig, $self, $offset, $inject) = @_;

  # $inject =~s/\$c,?//g;

  my @parts = map { ($_ =~ /([\$\%\@]\w+)/g) } split ',', $inject;

  #Is this an action?  Sadly we have to guess using a hueristic...

  my $linestr = B::Hooks::Parser::get_linestr();
  my ($attribute_area) = ($linestr =~m/\)(.*)\{/s);
  my $signature;

  if($attribute_area =~m/\S/) {
    $signature = join(',', ('$self', '$c', @parts));
    if($inject) {
      $inject = '$c,'. $inject;
    } else {
      $inject = '$c';
    }
  } else {
    $signature = join(',', ('$self', @parts));
  }
  
  $self->$orig($offset, $signature);
  
  # If there's anything in the attribute area, we assume a catalyst action...
  # Sorry thats th best I can do for now, patches to make it smarter very 
  # welcomed.

  $linestr = B::Hooks::Parser::get_linestr(); # reload it since its been changed since we last looked

  if($attribute_area =~m/\S/) {

    $linestr =~s/\{/:Does(MethodSignatureDependencyInjection) :ExecuteArgsTemplate($inject) \{/;

    # How many numbered or unnumberd args?
    my $count_args = scalar(my @countargs = $inject=~m/(Arg)[\d+\s\>]/ig);
    if($count_args and $attribute_area!~m/Args\(.+?\)/i) {
      
      my @constraints = ($inject=~m/Arg[\d+\s+][\$\%\@]\w+\s+isa\s+([\w"']+)/gi);
      if(@constraints) {
        if(scalar(@constraints) != $count_args) {
          confess "If you use constraints in a method signature, all args must have constraints";
        }
        my $constraint = join ',',@constraints;
        $linestr =~s/\{/ :Args($constraint) \{/;
      } else {
        $linestr =~s/\{/ :Args($count_args) \{/;
      }
    }

    my $count_capture = scalar(my @countcaps = $inject=~m/(capture)[\d+\s\>]/ig);
    if($count_capture and $attribute_area!~m/CaptureArgs\(.+?\)/i) {

      my @constraints = ($inject=~m/Capture[\d+\s+][\$\%\@]\w+\s+isa\s+([\w"']+)/gi);
      if(@constraints) {
        if(scalar(@constraints) != $count_capture) {
          confess "If you use constraints in a method signature, all args must have constraints";
        }
        my $constraint = join ',',@constraints;
        $linestr =~s/\{/ :CaptureArgs($constraint) \{/;
      } else {
        $linestr =~s/\{/ :CaptureArgs($count_capture) \{/;
      }
    }

    # Check for Args
    if(($inject=~m/Args/i) and ($attribute_area!~m/Args\s/)) {
      $linestr =~s/\{/ :Args \{/;
    }

    # If there's Chained($target/) thats the convention for last
    # action in chain with Args(0).  So if we detect that and there
    # is no Args present, add Args(0).
    ($attribute_area) = ($linestr =~m/\)(.*)\{/s);
    
    if($attribute_area =~m/Chained\(['"]?\w+?\/['"]?\)/) {
      if($attribute_area!~m/[\s\:]Args/i) {
        $linestr =~s/Chained\(["']?(\w+?)\/["']?\)/Chained\($1\)/;
        $linestr =~s/\{/ :Args(0) \{/;
      } else {
        # Ok so... someone used .../ BUT already declared Args.  Probably
        # a very common type of error to make.  For now lets fix it.
        $linestr =~s/Chained\(["']?(\w+?)\/["']?\)/Chained\($1\)/;
      }
    }

    # If this is chained but no Args, Args($n) or Captures($n), then add 
    # a CaptureArgs(0).  Gotta rebuild the attribute area since we might
    # have modified it above.
    ($attribute_area) = ($linestr =~m/\)(.*)\{/s);

    if(
      $attribute_area =~m/Chained/i && 
        $attribute_area!~m/[\s\:]Args/i &&
          $attribute_area!~m/CaptureArgs/i
    ) {
      $linestr =~s/\{/ :CaptureArgs(0) \{/;
    }

    B::Hooks::Parser::set_linestr($linestr);

    print "\n $linestr \n" if $ENV{CATALYST_METHODSIGNATURES_DEBUG};
  } 
};

1;

=head1 NAME

Catalyst::ActionSignatures - so you can stop looking at @_

=head1 SYNOPSIS

    package MyApp::Controller::Example;

    use Moose;
    use MooseX::MethodAttributes;
    use Catalyst::ActionSignatures;

    extends 'Catalyst::Controller';

    sub test($Req, $Res, Model::A $A, Model::Z $Z) :Local {
        # has $self and $c implicitly
        $Res->body('Look ma, no @_!')
    }

    sub regular_method ($arg1, $arg1) {
      # has $self implicitly
    }

    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

Lets you declare required action dependencies via the method signature.

This subclasses L<signatures> to allow you a more concise approach to
creating your controllers.  This injects your method signature into the
code so you don't need to use @_.  You should read L<signatures> to be
aware of any limitations.

For actions we automatically inject "$self" and "$c"; for regular methods we
inject just "$self".

You should review L<Catalyst::ActionRole::MethodSignatureDependencyInjection>
for more on how to construct signatures.

Also L<Catalyst::ActionSignatures::Rationale> may be useful.

=head1 Args and Captures

If you specify args and captures in your method signature, you can leave off the
associated method attributes (Args($n) and CaptureArgs($n)) IF the method 
signature is the full specification.  In other works instead of:

    sub chain(Model::A $a, Capture $id, $res) :Chained(/) CaptureArgs(1) {
      Test::Most::is $id, 100;
      Test::Most::ok $res->isa('Catalyst::Response');
    }

      sub endchain($res, Arg0 $name) :Chained(chain) Args(1) {
        $res->body($name);
      }
   
      sub endchain2($res, Arg $first, Arg $last) :Chained(chain) PathPart(endchain) Args(2) {
        $res->body("$first $last");
      }

You can do:

    sub chain(Model::A $a, Capture $id, $res) :Chained(/) {
      Test::Most::is $id, 100;
      Test::Most::ok $res->isa('Catalyst::Response');
    }

      sub endchain($res, Arg0 $name) :Chained(chain)  {
        $res->body($name);
      }
   
      sub endchain2($res, Arg $first, Arg $last) :Chained(chain) PathPart(endchain)  {
        $res->body("$first $last");
      }

=head1 Type Constraints

If you are using a newer L<Catalyst> (greater that 5.90090) you may declare your
Args and CaptureArgs typeconstraints via the method signature.

    use Types::Standard qw/Int Str/;

    sub chain(Model::A $a, Capture $id isa Int, $res) :Chained(/) {
      Test::Most::is $id, 100;
      Test::Most::ok $res->isa('Catalyst::Response');
    }

      sub typed0($res, Arg $id) :Chained(chain) PathPart(typed) {
        $res->body('any');
      }

      sub typed1($res, Arg $pid isa Int) :Chained(chain) PathPart(typed) {
        $res->body('int');
      }

B<NOTE> If you declare any type constraints on args or captures, all declared
args or captures must have them.

=head1 Implicit 'CaptureArgs(0)' and 'Args(0)' in chained actions

If you fail to use an Args or CaptureArgs attributes and you do not declare
any captures or args in your chained action method signatures, we automatically
add a CaptureArgs(0) attribute.  However, since we cannot properly detect the
end of a chain, you must still use Args(0) to terminate chains when the
last action has no arguments.  You may instead use "Chained(link/)" and
note the terminal '/' in the chained attribute value to declare a terminal
Chain with an implicit Args(0).

    sub another_chain() :Chained(/) { }

      sub another_end($res) :Chained(another_chain/) {
        $res->body('another_end');
      }

=head1 Models and Views

As in the documentation in L<Catalyst::ActionRole::MethodSignatureDependencyInjection>
you may declare the required models and views for you action via the method
prototype:

    sub myaction(Model::User $user) :Local { ... }

You can also access the default/current model and view:

    sub myaction(Model $current_model) :Local { ... }

You can declare models to be required and conform to a type constraint

    use MyApp::MyTypes 'User';

    sub find_user(Model::User $u isa User requires

=head1 Model and View parameters

If your Model or View is a factory that takes parameters, you may supply those
from other existing dependencies:

    # like $c->model('ReturnsArg', $id);
    sub from_arg($res, Model::ReturnsArg<Arg $id isa '"Int"'> $model) :Local {
      $res->body("model $model");
      # $id is also available.
    }

=head1 ENVIRONMENT VARIABLES.

Set C<CATALYST_METHODSIGNATURES_DEBUG> to true to get initial debugging output
of the generated method signatures and attribute changes. Useful if you are
having trouble and want some help to offer a patch!

=head1 SEE ALSO

L<Catalyst::Action>, L<Catalyst>, L<signatures>,
L<Catalyst::ActionRole::MethodSignatureDependencyInjection>

=head1 AUTHOR
 
John Napiorkowski L<email:jjnapiork@cpan.org>
  
=head1 COPYRIGHT & LICENSE
 
Copyright 2015, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
