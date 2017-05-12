## no critic (RequireUseStrict RequireUseWarnings)
package DSL::Tiny::InstanceEval;
## critic
# ABSTRACT: Add DSL features to your class.

use Moo::Role;

use MooX::Types::MooseLike::Base qw(CodeRef Str);
{
    $DSL::Tiny::InstanceEval::VERSION = '0.001';
}

has _anon_pkg_name => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build__anon_pkg_name',
);

{
    # no one can see me if I have my curly braces over my eyes....
    my $ANON_SERIAL = 0;

    # close over $ANON_SERIAL
    sub _build__anon_pkg_name { ## no critic(ProhibitUnusedPrivateSubroutines)
        return __PACKAGE__ . "::ANON_" . ++$ANON_SERIAL;
    }
}

has _instance_evalator => (
    is       => 'ro',
    isa      => CodeRef,
    lazy     => 1,
    builder  => '_build__instance_evalator',
    init_arg => undef,
);

##
## - set up an environment (anonymous package) in which to execute code that is
##   being instance_eval'ed,
## - push curried closures into the package for each of the closures,
## - and build a coderef that switches to that package, does the eval,
##   dies if the eval had trouble and otherwise returns the eval's return value.
##
sub _build__instance_evalator { ## no critic(ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    # make up a fairly unique package
    my $pkg_name = $self->_anon_pkg_name();

    # stuff the DSL into the fairly unique package
    $self->install_dsl( { into => $pkg_name }, qw(-install_dsl) );

    # stuff an evalator routine into the same package,
    # closed over $pkg_name
    # evals a string, dies if there was trouble, returns result otherwise.

    # return a coderef to the evalator routine that
    # we pushed into the package.
    return sub {
        my $code = 'package ' . $pkg_name . '; ' . shift;
        my $result = eval $code;    ## no critic (ProhibitStringyEval)
        die $@ if $@;               ## no critic (RequireCarping)
        return $result;
    };
}

sub instance_eval {                 ## no critic(RequireArgUnpacking)
    my $self = shift;

    return $self->_instance_evalator()->(@_);
}

requires qw(build_dsl_keywords);

1;

__END__

=pod

=head1 NAME

DSL::Tiny::InstanceEval - Add DSL features to your class.

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Test::More;
    use Test::Deep;

    # put together class with a simple dsl
    {
      package MyClassWithDSL;
      use Moo;                      # or Moose
      with qw(DSL::Tiny::Role DSL::Tiny::InstanceEval);

      sub _build_dsl_keywords { [ qw(add_values) ] };

      has values => (is => 'ro',
                     default => sub { [] },
                    );

      sub add_values {
          my $self = shift;
          push @{$self->values}, @_;
      }
    }

    # make a new instance
    my $dsl = MyClassWithDSL->new();

    my $code = <<EOC;
    add_values(qw(2 1));
    add_values(qw(3));
    EOC

    my $return_value = $dsl->instance_eval($code);
    cmp_deeply($dsl->values, bag(qw(1 2 3)), "Values were added");

    done_testing;

=head1 DESCRIPTION

I<This is an initial release.  It's all subject to rethinking.  Comments
welcome.>

This package provides a simple interface, L</instance_eval>, for evaluating
snippets of a DSL (implemented with L<DSL::Tiny::Role>) with respect to a
particular instance of a class that consumes the role.

=head1 ATTRIBUTES

=head2 _anon_pkg_name

Private attribute, used to set up a package to stash private stuff.

=head2 _instance_evalator

PRIVATE

There is no 'u' in _instance_evalator.  That means there should be no
you in there either....

Returns a coderef that is used by the instance_eval() method.

=head1 METHODS

=head2 instance_eval

Something kind-a-similar to Ruby's instance_eval.  Takes a string and evaluates
it using eval(), The evaluation happens in a package that has been populated
with a set of functions that map to methods in this class with the instance
curried out.

See the synopsis for an example.

=head1 REQUIRES

=head2 _build_dsl_keywords

Requires _build_dsl_keywords, as a proxy for being used in a class that consumes
DSL::Tiny::Role.

=head1 AUTHOR

George Hartzell <hartzell@alerce.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by George Hartzell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
