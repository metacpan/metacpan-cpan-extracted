package App::Glacier::Signature;

# A wrapper class over Net::Amazon::Signature::V4, that supplies
# the X-Amz-Security-Token header for EC2 instance profile authentication.
sub new {
    my ($class, $sig, $token) = @_;
    bless { _sig => $sig, _token => $token }, $class;
};

sub sign {
    my ($self, $request) = @_;
    $request->header('X-Amz-Security-Token' => $self->{_token});
    return $self->{_sig}->sign($request);
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    (my $meth = $AUTOLOAD) =~ s/.*:://;
    $self->{_sig}->method(@_);
}

1;
