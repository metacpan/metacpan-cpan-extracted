package TestApp4;

#
# Default behavior, EXCEPT:
#    fill_password => 0
#

use Catalyst qw( FillInForm );

__PACKAGE__->config(
    name=>"FillInForm test"
);

__PACKAGE__->setup();

my $html = <<EOT;
<html>
<head></head>
<body>
<form name="form1" action="" method="POST">
<input name="aaa">
<input name="bbb">
<input name="ccc" type="hidden">
<input name="ddd" type="password">
</form>

<form name="form2" action="" method="POST">
<input name="aaa">
<input name="bbb">
<input name="ccc" type="hidden">
<input name="ddd" type="password">
</form>
</body>
</html>
EOT


sub index : Path {
   my ( $self, $c, $arg ) = @_;
   $c->res->body($html);
}

sub end : Private {
   my ($self, $c) = @_;
   $c->forward('render');
   $c->fillform($c->req->params, {
      fill_password => 0,
   });
}
sub render : ActionClass('RenderView') { }

1;
