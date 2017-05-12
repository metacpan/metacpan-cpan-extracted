package Crypt::Keyczar::KeyVersion;
use strict;
use warnings;
use Crypt::Keyczar::Util qw(json_true json_false);
use Carp;



sub new {
    my $class = shift;
    my ($version, $status, $exportable) = @_;
    my $self = bless {
        exportable    => json_false(),
        status        => 'ACTIVE',
        version_number => 0,
    }, $class;
    $self->exportable($exportable) if defined $exportable;
    $self->status($status) if defined $status;
    $self->{version_number} = $version if defined $version;
    return $self;
}

sub create {
    my $class = shift;
    my $opt = shift;
    return $class->new($opt->{versionNumber}, $opt->{status}, $opt->{exportable});
}

sub read {
    my $class = shift;
    my $json_string = shift;
    my $obj = from_json($json_string);
    return bless $obj, $class;
}



sub exportable {
    my $self = shift;
    $self->{exportable} = $_[0] ? json_true() : json_false() if @_;
    return $self->{exportable} eq json_true() ? 1 : undef;
}


sub status {
    my $self = shift;
    if (@_) {
        if (uc $_[0] eq 'ACTIVE') {
            $self->{status} = uc $_[0];
        }
        elsif (uc $_[0] eq 'PRIMARY') {
            $self->{status} = uc $_[0];
        }
        elsif (uc $_[0] eq 'INACTIVE') {
            $self->{status} = uc $_[0];
        }
        else {
            croak "unknown key status: $_[0]";
        }
    }
    return $self->{status};
}


sub get_number {
    my $self = shift;
    $self->{version_number} = shift if @_;
    return $self->{version_number};
}



sub expose {
    my $self = shift;
    my $expose = {};
    $expose->{exportable} = $self->{exportable} ? json_true() : json_false();
    $expose->{status}     = $self->{status};
    $expose->{versionNumber} = $self->{version_number};
    return $expose;
}
sub to_string { return to_json($_[0]->expose) }



1;
__END__
