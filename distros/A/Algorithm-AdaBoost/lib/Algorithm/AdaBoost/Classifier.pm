package Algorithm::AdaBoost::Classifier;

use 5.014;
use overload '&{}' => \&as_closure;
use List::Util;
use Scalar::Util;
use Smart::Args;

sub new {
  args
    my $class => 'ClassName',
    my $weak_classifiers => 'ArrayRef[HashRef]';
  bless +{
    weak_classifiers => $weak_classifiers,
  } => $class;
}

sub as_closure {
  args my $self;
  return sub { $self->classify(@_) };
}

sub classify {
  args_pos
    my $self,
    my $feature => 'Any';
  List::Util::sum(
    map {
      $_->{weight} * $_->{classifier}->($feature);
    } @{ $self->{weak_classifiers} }
  );
}

1;
__END__

=head1 NAME

Algorithm::AdaBoost::Classifier

=head1 DESCRIPTION

This class should be instanciated via C<< Algorithm::AdaBoost->train >>.

=head1 METHODS

=head2 as_closure

Returns a CodeRef which delegates given arguments to C<classify>.

Altough you can use the object itself like a CodeRef because C<&{}> operator is overloaded with this method, it constructs a closure for each call.
So if you classify many inputs, you should hold a closure explicitly or use C<classify> directly.

=head2 classify

Executes binary classification. Takes 1 argument as a feature and return a real number. If the number is positive, given feature is considered to belong to one class. Similary, If the number is negative, given feature is considered to belong to another one class. If zero is returned, it means that the feature cannot be classified (very rare case).

=head1 AUTHOR

Koichi SATOH E<lt>sekia@cpan.orgE<gt>

=cut
