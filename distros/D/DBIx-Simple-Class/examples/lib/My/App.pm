package    #hide
  My::App;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use CGI qw(:html *form);
use My;
use My::Group;
use My::User;


#Controlers

sub action_list_users {
  my $app   = shift;
  my $out   = '';
  my @users = My::User->query('SELECT * from users');
  my $rows  = [th({class => "header_cols"}, [qw(id login_name login_password)]),];
  for (@users) {
    push @$rows, td([$_->id, $_->login_name, $_->login_password]);
  }
  $out .= table({id => 'users'}, caption('Users'), Tr({}, $rows))
    . a({class => "button", href => '?do=add_user'}, 'Add User');
  return $out;
}

sub action_add_user {
  my $app = shift;
  my $q   = $app->q;
  my $out = '';
  if ($q->request_method eq 'POST') {
    my ($user, $user_id);
    my $ok = eval {
      $user = My::User->new(
        login_name     => $q->param('login_name'),
        login_password => $q->param('login_password'),
      );
      $user_id = $user->save();
    };
    $ok || ($out = div({class => 'error'}, p($@)));
    $ok
      && (
      $out = div(
        {class => 'info'},
        p('Added new user '
            . a(
            {href => '?do=list_users'}, b($user->login_name) . ' with id ' . $user_id
            )
            . '.'
        )
      )
      );
  }
  $out .= start_form
    . div(
    input({type => 'hidden', name => 'do', value => 'add_user'}),
    legend('User Name'),
    input({name => 'login_name'}),
    br(),
    legend('Password'),
    input({name => 'login_password'}),
    br(),
    input({type => 'submit', class => 'submit', value => 'Add User'})
    ) . end_form;


  return $out;
}

sub action_list_groups {
  my $app    = shift;
  my $G      = 'My::Group';
  my @groups = $G->query('SELECT * from groups');
  my $out    = '';

  if (@groups) {

    #For your home work
  }
  else {
    $out .= h1('Please addd a group'), a({-href => 'action=add_group'}, 'Add');

  }

  return $out;
}

sub action_add_group {
  my $app = shift;
  my $out = '';

  #For your home work
  return $out;
}

#Underlying self-made mini-framework

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  return $self;
}

sub run {
  my $class = shift;

  #initialise
  my $app = $class->new();
  $app->initialise_db;
  my $action = 'action_' . ($app->q->param('do') || 'list_users');

  #warn $action . $app->can($action);

  #run
  if ($app->can($action)) {
    print $app->q->header(
      -type    => 'text/html',
      -status  => '200 OK',
      -charset => 'utf-8',
      ),
      '<!DOCTYPE html>', html(
      {xmlns => "http://www.w3.org/1999/xhtml"},
      head(
        meta({'http-equiv' => "Content-Type", content => "text/html; charset=utf-8"}),
        title('Example application'),

        script(
          {src => '//ajax.googleapis.com/ajax/libs/jquery/1.8.0/jquery.min.js'}, ''
        ),
        $/,
        script(
          {src => '//ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/jquery-ui.min.js'},
          ''
        ),
        $/,
        Link(
          { href =>
              "//ajax.googleapis.com/ajax/libs/jqueryui/1.8.18/themes/base/jquery-ui.css",
            rel  => "stylesheet",
            type => "text/css"
          }
        ),
        $/,
        script(<<'JS')
$(function(){
    $('a.button,input.submit').button();
    $('table').addClass('ui-widget');
    $('th,caption,legend').addClass('ui-widget-header');
    $('td, input').addClass('ui-widget-content');
    $('div.error').addClass('ui-state-error ui-corner-all')
    $('div.info').addClass('ui-state-highlight ui-corner-all')
})
JS
        ,
        style(<<'CSS')
form div {width:30ex}
form div input, form div legend {width:100%}
.error p,.info p {margin:1ex; font-family:sans-serif}
CSS

      ),
      body($app->$action())
      );
  }
  else {
    print $app->q->header(
      -type    => 'text/html',
      -status  => '404 Not Found',
      -charset => 'utf-8',
      ),
      start_html(-title => 'Page Not Found'), h1('Page Not Found'), end_html();
  }
}


sub initialise_db {
  my $app = shift;
  DBIx::Simple::Class->DEBUG(1);

  my $dbix = DBIx::Simple->connect(
    "dbi:SQLite:dbname=$ENV{users_HOME}/db.sqlite",
    {sqlite_unicode => 1, RaiseError => 1}
  ) || die $DBI::errstr;
  DBIx::Simple::Class->dbix($dbix);
  $dbix->query(<<"TAB");
        CREATE TABLE IF NOT EXISTS groups(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_name VARCHAR(12),
          "foo-bar" VARCHAR(13),
          data TEXT
          )
TAB
  $dbix->query(<<"TAB");
        CREATE TABLE IF NOT EXISTS users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INT default 1,
          login_name VARCHAR(12) UNIQUE,
          login_password VARCHAR(100), 
          disabled INT DEFAULT 1
          )
TAB

  sub My::Group::ALIASES {
    {data => 'group_data', 'foo-bar' => 'foo_bar'};
  }
  My::Group->QUOTE_IDENTIFIERS(1);
  My::User->QUOTE_IDENTIFIERS(1);

}

sub q { $_[0]->{q} ||= CGI->new() }


1;
