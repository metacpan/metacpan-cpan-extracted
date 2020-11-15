package
  Greetings;
use strict;
use warnings;

sub new  { my $class = shift; bless +{@_}, $class }

sub hello { my $self = shift; join " ", "Hello", $self->{name} }

sub hi { my $self = shift; join(" ", "Hi" => $self->{name}, @_)}

1;

__END__

perl -Ilib -MGreetings -le 'print Greetings->new(name => "world")->hello'
