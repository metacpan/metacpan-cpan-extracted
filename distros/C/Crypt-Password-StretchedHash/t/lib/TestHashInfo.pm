package TestHashInfo;

use parent 'Crypt::Password::StretchedHash::HashInfo';
use Digest::SHA;
   
my $_delimiter = q{$};
my $_identifier = q{1};
my $_hash = Digest::SHA->new("sha256");
my $_salt = q{test_salt_1234567890};
my $_stretch_count = 5000;
my $_format = q{base64};

sub delimiter {
    my $self = shift;
    return $_delimiter;
}

sub identifier {
    my $self = shift;
    return $_identifier;
}

sub hash {
    my $self = shift;
    return $_hash;
}

sub salt {
    my $self = shift;
    return $_salt;
}

sub stretch_count {
    my $self = shift;
    return $_stretch_count;
}

sub format {
    my $self = shift;
    return $_format;
}

# setter
sub set_delimiter {
    my ($self, $delimiter) = @_;
    $_delimiter = $delimiter;
}

sub set_identifier {
    my ($self, $identifier) = @_;
    $_identifier = $identifier;
}

sub set_hash {
    my ($self, $hash) = @_;
    $_hash = $hash;
}

sub set_salt {
    my ($self, $salt) = @_;
    $_salt = $salt;
}

sub set_stretch_count {
    my ($self, $stretch_count) = @_;
    $_stretch_count = $stretch_count;
}

sub set_format {
    my ($self, $format) = @_;
    $_format = $format;
}

1;
