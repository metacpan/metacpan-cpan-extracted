package Apertur::SDK::Error;

use strict;
use warnings;

use overload
    '""'     => \&_stringify,
    fallback => 1;

sub new {
    my ($class, %args) = @_;
    return bless {
        status_code => $args{status_code} // 0,
        code        => $args{code}        // '',
        message     => $args{message}     // 'Unknown error',
    }, $class;
}

sub throw {
    my ($class, %args) = @_;
    die $class->new(%args);
}

sub status_code { return $_[0]->{status_code} }
sub code        { return $_[0]->{code} }
sub message     { return $_[0]->{message} }

sub _stringify {
    my ($self) = @_;
    my $class = ref $self;
    my $code  = $self->{code} ? " [$self->{code}]" : '';
    return "$class: $self->{status_code}$code $self->{message}";
}

1;

__END__

=head1 NAME

Apertur::SDK::Error - Base exception class for Apertur API errors

=head1 SYNOPSIS

    use Apertur::SDK::Error;

    eval {
        Apertur::SDK::Error->throw(
            status_code => 500,
            code        => 'INTERNAL',
            message     => 'Something went wrong',
        );
    };
    if (my $err = $@) {
        if (ref $err && $err->isa('Apertur::SDK::Error')) {
            warn "API error: " . $err->message;
        }
    }

=head1 DESCRIPTION

Base error class for all Apertur SDK errors. All API errors are represented
as blessed objects that can be thrown with C<die> and caught with C<eval>.

=head1 METHODS

=over 4

=item B<new(%args)>

Constructor. Accepted keys: C<status_code>, C<code>, C<message>.

=item B<throw(%args)>

Class method that creates and throws (via C<die>) a new error.

=item B<status_code>

Returns the HTTP status code.

=item B<code>

Returns the error code string (e.g. C<NOT_FOUND>).

=item B<message>

Returns the human-readable error message.

=back

=cut
