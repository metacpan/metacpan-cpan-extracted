package t::test::InheritedDocument;
use strict;
use warnings;
use parent qw(Plack::App::APISchema::Document);

1;
__DATA__
@@ template.mt
? my ($title, $body) = @_;
<!DOCTYPE html>
<html>
  <head>
    <title><?= $title ?></title>
    <style>* { color: pink; }</style>
  </head>
  <body>
    <?= encoded_string($body) ?>
  </body>
</html>
