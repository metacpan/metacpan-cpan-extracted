#line 1
package Module::Collect::Package;
use strict;
use warnings;
use Carp;

sub new {
    my ($class, @args) = @_;
    if (ref $class) {
        return $class->{package}->new(@args) if $class->{package}->can('new');
        croak qq{Can't locate object method "new" via package "$class->{package}"};
    } else {
        return bless { @args }, $class;
    }
}

sub require {
    my ($self) = shift;
    eval { require $self->{path} } or croak $@;
}

sub package { shift->{package} }
sub path { shift->{path} }

1;

__END__

#line 61
