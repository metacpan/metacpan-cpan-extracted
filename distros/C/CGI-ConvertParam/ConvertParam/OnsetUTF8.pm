package CGI::ConvertParam::OnsetUTF8;
use base 'CGI::ConvertParam';
use Jcode;
use strict;


sub do_convert_on_set
{
    my $self    = shift;
    my $strings = shift;
    return Jcode->new($strings)->h2z->utf8;
}

1;
__END__
