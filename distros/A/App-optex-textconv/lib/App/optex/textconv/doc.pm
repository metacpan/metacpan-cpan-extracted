package App::optex::textconv::doc;

our $VERSION = '1.01';

use v5.14;
use warnings;
use Carp;

our @EXPORT_OK = qw(to_text);

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.doc$/ => \&to_text ],
    );

use Text::Extract::Word;

sub to_text {
    my $file = shift;
    my $type = ($file =~ /\.(doc)$/)[0] or return;
    Text::Extract::Word->new($file)->get_text() // die;
}

1;
