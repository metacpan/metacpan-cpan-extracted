package CGI::ConvertParam::JIS;
use base 'CGI::ConvertParam';
use Jcode;
use strict;

sub initialize
{
    my $self = shift;
    $self->convert_all_param;
}


sub do_convert_all_param
{
    my $self    = shift;
    my $strings = shift;
    return Jcode->new($strings)->h2z->jis;
}

1;
__END__
