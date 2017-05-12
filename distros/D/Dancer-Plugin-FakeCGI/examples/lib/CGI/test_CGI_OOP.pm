package test_CGI_OOP;

use CGI;

#use CGI ':standard';

our $VERSION = '0.1';

sub test {

    my $q    = new CGI;
    my $name = 'A Simple OOP Example';


    print $q->header('text/html');
    print $q->start_html($name),
      $q->h1($name),
      $q->start_form,
      "What's your name? ", $q->textfield('name'), $q->p,
      "What's the combination?", $q->p,
      $q->checkbox_group(
        -name   => 'words',
        -values => ['eenie', 'meenie', 'minie', 'moe'],
        -defaults => ['eenie', 'minie']
      ),
      $q->p, "What's your favorite color? ",
      $q->popup_menu(
        -name   => 'color',
        -values => ['red', 'green', 'blue', 'chartreuse']
      ),
      $q->p,
      $q->submit,
      $q->end_form,
      $q->hr;

    if ($q->param()) {
        print "Your name is: ", $q->em($q->param('name')),
          $q->p,
          "The keywords are: ", $q->em(join(", ", $q->param('words'))),
          $q->p,
          "Your favorite color is: ", $q->em($q->param('color')),
          $q->hr;
    }
    print $q->end_html;
}

1;
