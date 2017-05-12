package Autocache::Logger;

use Any::Moose;

extends 'Exporter';

has logger => (is => 'ro', isa => 'Object', handles => [qw(info debug warn error fatal)]);

our @EXPORT_OK = qw(get_logger);

sub get_logger {
    return __PACKAGE__->singleton;
}

my $SINGLETON;

sub singleton {
    my $class = shift;
    __PACKAGE__->initialise
        unless $SINGLETON;
    return $SINGLETON;
}

sub initialise {
    my $class = shift;
    my %args = @_ ? @_ : (logger => Autocache::Logger::Null->new);
    $SINGLETON = $class->new(%args);
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

package Autocache::Logger::Null;

use Any::Moose;

sub info {};
sub debug {};
sub warn {};
sub error {};
sub fatal {};

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
