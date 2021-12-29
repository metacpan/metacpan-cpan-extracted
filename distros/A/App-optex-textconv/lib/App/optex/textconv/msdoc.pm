package App::optex::textconv::msdoc;

our $VERSION = '0.1401';

use v5.14;
use warnings;
use Carp;

##
## Import to_text() and get_list() for backward compatibility.
##
our @EXPORT_OK = qw(to_text get_list);
use App::optex::textconv::ooxml::regex qw(to_text get_list);

require App::optex::textconv::ooxml;

use App::optex::textconv::Converter 'import';

our @CONVERTER = (
    [ qr/\.doc$/ => \&extract_doc ],
    @App::optex::textconv::ooxml::CONVERTER,
    );

use Text::Extract::Word;
use Encode;

sub extract_doc {
    my $file = shift;
    my $type = ($file =~ /\.(doc)$/)[0] or return;
    my $text = Text::Extract::Word->new($file)->get_text() // die;
    $text = encode 'utf8', $text if utf8::is_utf8($text);
    $text;
}

1;
