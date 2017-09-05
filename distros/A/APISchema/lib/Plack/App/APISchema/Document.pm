package Plack::App::APISchema::Document;
use strict;
use warnings;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(schema);
use Text::Markdown::Hoedown qw(markdown);
use Text::MicroTemplate qw(encoded_string);
use Text::MicroTemplate::DataSection qw(render_mt);
use Encode qw(encode_utf8);

use APISchema::Generator::Markdown;

sub call {
    my ($self, $env) = @_;

    my $generator = APISchema::Generator::Markdown->new;
    my $markdown = $generator->format_schema($self->schema);

    my $body = markdown(
        $markdown,
        extensions => int(
            0
                | Text::Markdown::Hoedown::HOEDOWN_EXT_TABLES
                | Text::Markdown::Hoedown::HOEDOWN_EXT_AUTOLINK
                | Text::Markdown::Hoedown::HOEDOWN_EXT_FENCED_CODE
                | Text::Markdown::Hoedown::HOEDOWN_EXT_NO_INTRA_EMPHASIS
            )
    );

    my $renderer = Text::MicroTemplate::DataSection->new(package => ref $self);
    my $title = $self->schema->title || '';
    my $html = $renderer->render_mt('template.mt', $title, $body);

    return [200, ['Content-Type' => 'text/html; charset=utf-8'], [encode_utf8 $html]];
}

1;
__DATA__
@@ template.mt
? my ($title, $body) = @_;
<!DOCTYPE html>
<html>
  <head>
    <title><?= $title ?></title>
  </head>
  <body>
    <?= encoded_string($body) ?>
  </body>
</html>
