package test_CGI_mocked;

use CGI ':standard';

our $VERSION = '0.1';

sub test_param {
    if (param()) {
        print "Your name is: ", em(param('name')),
          p,
          "The keywords are: ", em(join(", ", param('words'))),
          p,
          "Your favorite color is: ", em(param('color')),
          hr;
    }
}

sub test {
    my $name = 'A Simple mocked CGI Example';

    print header('text/html');
    print start_html($name),
      h1($name),
      start_form,
      "What's your name? ", textfield('name'), p, "What's the combination?", p,
      checkbox_group(
        -name   => 'words',
        -values => ['eenie', 'meenie', 'minie', 'moe'],
        -defaults => ['eenie', 'minie']
      ),
      p, "What's your favorite color? ",
      popup_menu(
        -name   => 'color',
        -values => ['red', 'green', 'blue', 'chartreuse']
      ),
      p,
      submit,
      end_form,
      hr;
    &test_param();
    print end_html;
}

1;
