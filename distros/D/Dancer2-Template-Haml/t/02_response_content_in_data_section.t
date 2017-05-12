package MyApp;

use strict;
use warnings;

use Test::More tests => 2;

use Dancer2;
use Dancer2::Test;
use Dancer2::FileUtils;

use Data::Section::Simple 'get_data_section';

my $vpath_tmp = get_data_section;
my @data = %$vpath_tmp;
my $vpath = {};
while (@data) {
  my ($name, $content) = splice @data, 0, 2;

  # from linux/unix to windows: 'path/file.name' -> 'path\file.name'
  # from windows to linux/unix: 'path\file.name' -> 'path/file.name'
  $name = Dancer2::FileUtils::path(split /\\|\//, $name); 
  $vpath->{$name} = $content;
}

set engines => {
      template => {
        Haml => {
          cache => 0,
          path => $vpath,
        },
      },
};
set template => 'haml';

# without layouts
#---------------------
get '/' => sub {
  template 'index', {foo => 'Bar!'}, {layout => undef};
};

response_content_is '/' => <<'EOF';
<strong>Bar!</strong>
<em>text 2 texts 3</em>
EOF
#---------------------

# with layouts
#---------------------
set layout => 'main';
set charset => 'utf8';
set appname => 'hello world';

get '/index' => sub {
    template 'index' => {
      foo => 'Bar!',
    };
};

response_content_is '/index' => <<'EOF';
<!DOCTYPE html>
<html>
  <head>
    <meta charset='utf8' />
    <title>hello world</title>
  </head>
  <body>
    <div style='color: green'><strong>Bar!</strong>
<em>text 2 texts 3</em>
</div>
    <div id='footer'>
      Powered by
      <a href='https://metacpan.org/release/Dancer2'>Dancer2</a>
    </div>
  </body>
</html>
EOF
#---------------------

__DATA__
@@ layouts/main.haml
!!! 5
%html
  %head
    %meta(charset = $settings->{charset})
    %title= $settings->{appname} 
  %body
    %div(style="color: green")= $content
    #footer
      Powered by
      %a(href="https://metacpan.org/release/Dancer2") Dancer2

@@ index.haml
%strong= $foo
%em text 2 texts 3
