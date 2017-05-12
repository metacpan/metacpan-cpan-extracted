package CGI::ConvertParam::OnsetEUC;
use base 'CGI::ConvertParam';
use Jcode;
use strict;


sub do_convert_on_set
{
    my $self    = shift;
    my $strings = shift;
    return Jcode->new($strings)->h2z->euc;
}

1;
__END__
