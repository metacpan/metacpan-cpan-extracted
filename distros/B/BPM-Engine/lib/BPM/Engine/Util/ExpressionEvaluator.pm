package BPM::Engine::Util::ExpressionEvaluator;
BEGIN {
    $BPM::Engine::Util::ExpressionEvaluator::VERSION   = '0.01';
    $BPM::Engine::Util::ExpressionEvaluator::AUTHORITY = 'cpan:SITETECH';
    }

use strict;
use warnings;
use Scalar::Util qw/blessed/;
use BPM::Engine::Util::Expression::Xslate;
use BPM::Engine::Exceptions qw/throw_param/;

sub load {
    my ($class, %args) = @_;
    
    my $pi = $args{process_instance} 
        or throw_param error => 'Need a process instance';
    my $params = {
        arguments => delete $args{arguments} || [],
        var => BPM::Engine::ExprVar->new(pi => $pi),
        attribute => sub {
            my $name = shift or #die("Need an attribute name"); 
                return BPM::Engine::ExprVar->new(pi => $pi);
            my $attr = $pi->attribute($name);
            return $attr->value; 
            },
        };
    
    foreach my $param(qw/
        process process_instance activity activity_instance transition
        /) {
        next unless($args{$param});
        throw_param error => "Not an object: $param" 
            unless(blessed $args{$param});
        #eval { $args{$param} = sub { $args{$param}->TO_JSON; } };
        eval { $params->{$param} = delete($args{$param})->TO_JSON; };
        if($@) {
            throw_param error => "Could not jsonize $param: $@";
            }
        }

    throw_param("Invalid ExpressionEval arguments: " . join(', ', keys %args))
        if keys %args;

    return BPM::Engine::Util::Expression::Xslate->new(
        process_instance => $pi, 
        params           => $params 
        );
    }

## no critic (ProhibitMultiplePackages)
package BPM::Engine::ExprVar;

use strict;
use warnings;
our $AUTOLOAD;

sub new {
    my ($this, @args) = @_;
    my $class = ref($this) || $this;
    my $self = bless { @args }, $class;
    return $self;
    }

## no critic (ProhibitAutoloading)
sub AUTOLOAD {
    my $self = shift;
    (my $method = $AUTOLOAD) =~ s/.*:://;
    return if $method eq 'DESTROY';   
    my $pi = $self->{pi};
    my $attr = $pi->attribute($method);
    return $attr->value;
    }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

BPM::Engine::Util::ExpressionEvaluator - Inference engine loader

=head1 SYNOPSIS

  use BPM::Engine::Util::ExpressionEvaluator;
  
  my $evaluator = BPM::Engine::Util::ExpressionEvaluator->load(
    process_instance  => $pi,        
    process           => $pi->process,
    activity          => $activity_instance->activity,
    activity_instance => $activity_instance,
    transition        => $transition
    );
  
  $evaluator->render()

=head1 DESCRIPTION

This module loads an instance of 
L<BPM::Engine::Util::Expression::Xslate|BPM::Engine::Util::Expression::Xslate>
suitable for evaluating XPDL expressions.

=head1 CLASS METHODS

=head2 load

Accepts a hash of options, and returns a new 
L<BPM::Engine::Util::Expression::Xslate|BPM::Engine::Util::Expression::Xslate>
instance suitable for rendering and evaluating XPDL expressions. In addition 
to providing the supplied options in the template strings as simple hash 
references, the expression evaluator will be supplied with an C<attribute> 
function to make use of process instance variables in expressions.

Possible options are:

=over

=item C<process_instance>

L<BPM::Engine::Store::Result::ProcessInstance|BPM::Engine::Store::Result::ProcessInstance> 
instance whose attributes will be rendered or evaluated. This is the only 
required option.

=item C<process>

A L<BPM::Engine::Store::Result::Process|BPM::Engine::Store::Result::Process> 
result row.

=item C<activity>
 
A L<BPM::Engine::Store::Result::Activity|BPM::Engine::Store::Result::Activity>
result row.

=item C<activity_instance>

A L<BPM::Engine::Store::Result::ActivityInstance|BPM::Engine::Store::Result::ActivityInstance>
result row.

=item C<transition>

A L<BPM::Engine::Store::Result::Transition|BPM::Engine::Store::Result::Transition>
result row.

=back

The L<BPM::Engine::Util::Expression::Xslate|BPM::Engine::Util::Expression::Xslate>
instance that is returned contains all options which are available to template 
strings as simple hash references. In addition, the C<process_instance> result 
row is used as a constructor argument.

=head1 AUTHOR

Peter de Vos, C<< <sitetech@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010, 2011 Peter de Vos.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.

=cut
