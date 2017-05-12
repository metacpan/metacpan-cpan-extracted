package ArangoDB::BindVars;
use strict;
use warnings;
use utf8;
use 5.008001;

sub new {
    my $class = shift;
    my $self = bless { _values => +{} }, $class;
    return $self;
}

sub get_all {
    $_[0]->{_values};
}

sub get {
    $_[0]->{_values}{ $_[1] };
}

sub set {
    my ( $self, $name, $val ) = @_;
    if ( ArangoDB::BindVars::Validator::is_hash_ref($name) ) {
        for my $value ( values %$name ) {
            ArangoDB::BindVars::Validator::validate($value);
        }
        $self->{_values} = $name;
    }
    elsif ( ArangoDB::BindVars::Validator::is_integer($name) || ArangoDB::BindVars::Validator::is_string($name) ) {
        ArangoDB::BindVars::Validator::validate($val);
        $self->{_values}{$name} = $val;
    }
}

sub count {
    return scalar keys %{ $_[0]->{_values} };
}

{

    package    #Hiding package
        ArangoDB::BindVars::Validator;
    use strict;
    use warnings;
    use Scalar::Util qw(looks_like_number);
    use Data::Util qw(:check);
    use ArangoDB::ClientException;

    sub validate {
        my $val = shift;
        return if !defined($val) || is_string($val) || $val eq q{};
        if ( is_array_ref($val) ) {
            for my $v (@$val) {
                validate($v);
            }
            return;
        }
        die ArangoDB::ClientException->new('Invalid bind parameter value');
    }
}

1;
__END__
