package Apache::Emulator::Apache::Table;
package Apache::Table;
use strict;

sub new {
    my $class = shift;
    my $self = {};
    tie %{$self}, 'Apache::TableHash';
    %$self = @_ if @_;
    return bless $self, ref $class || $class;
}

sub set {
    my ($self, $header, $value) = @_;
    defined $value ? $self->{$header} = $value : delete $self->{$header};
}

sub unset {
    my $self = shift;
    delete $self->{shift()};
}

sub add {
    tied(%{shift()})->add(@_);
}

sub clear {
    %{shift()} = ();
}

sub get {
    tied(%{shift()})->get(@_);
}

sub merge {
    my ($self, $key, $value) = @_;
    if (defined $self->{$key}) {
        $self->{$key} .= ',' . $value;
    } else {
        $self->{$key} = "$value";
    }
}

sub do {
    my ($self, $code) = @_;
    while (my ($k, $val) = each %$self) {
        for my $v (ref $val ? @$val : $val) {
            return unless $code->($k => $v);
        }
    }
}

1;
