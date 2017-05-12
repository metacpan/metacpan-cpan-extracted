package CGI::ConvertParam::OngetJIS;
use base 'CGI::ConvertParam';
use Jcode;
use strict;


sub do_convert_on_get
{
    my $self    = shift;
    my $strings = shift;
    return Jcode->new($strings)->h2z->jis;
}

1;
__END__
