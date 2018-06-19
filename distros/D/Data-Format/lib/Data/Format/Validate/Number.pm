package Data::Format::Validate::Number 0.3;

use base 'Exporter';

use Carp qw/croak/;

our @EXPORT_OK = qw/
    looks_like_money
/;

our %EXPORT_TAGS = (
    'money' => [qw/
        looks_like_money
    /]
);

sub looks_like_money {

    my $value = shift || croak 'Value must be provided';
    $value =~ /^\d{1,3}(\.\d{3})*\,\d+$/;
}
1;
