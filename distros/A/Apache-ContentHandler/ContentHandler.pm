package Apache::ContentHandler;

=head1 NAME

Apache::ContentHandler - mod_perl extension for uniform application
generation.

=head1 SYNOPSIS

    use Apache::ContentHandler;

    @ISA = 'Apache::ContentHandler';

    sub handler {
      my $r = shift;
      my $algometer = new Apache::Algometer($r);
      my $result = $algometer->run;
      return $result;
    }

    sub _init {
      my $self = shift || die 'need $self';
      $self->SUPER::_init(@_);

      # overrides
      $self->{title}     = 'Project Algometer';
      $self->{subtitle}  = "Version $VERSION";
      $self->{default_action} = 'hello';
      # other variable definitions
    }

    sub hello {
      return '<P>Hello World</P>';
    }

=head1 DESCRIPTION

Apache::ContentHandler is a generic framework for creating mod_perl
based applications. It provides a basic event mechanism and a
subclassable framework for customizing actions.

The synopsis shows a very simple example of what it can do. In this
case, we set the default_action to 'hello', which is automatically
executed. Hello in this case outputs a simple paragraph. Nothing big,
but it is very simple. Note that this app runs as-is in both CGI and
mod_perl.

=head2 Rapid Prototyping

This does not demonstrate the real power of ContentHandler. The real
power comes from rapid prototyping. For example, if we modifed the
example above to read:

    sub hello {
      my $self = shift || die 'need $self';
      my $s = '';
      $s .= '\<A HREF="$self-\>{url}?action=make"\>Make\</A\> something.';
      return $s;
    }

Then the page will output a url for the application that includes
"action=make" as a url parameter. This will tell ContentHandler to run
the method make when executed. But, 'make' does not exist at this
time. That is ok, because ContentHandler will deal with it by putting
a standard page up explaining that that feature is not yet
implemented. This allows you to quickly prototype one page, and move
on to the rest of the functionality one piece at a time.

I have used this style with clients on several different projects and
they were all extremely happy to get something tangible in a very
short period of time, usually 5 minutes to get the first page up and
running with skeletal functionality. From there, it is a very
interactive process with the client driving on one machine and
commenting, and me coding away at another machine as they talk.

=head1 PUBLIC METHODS

=over 4

=cut

use strict;
use vars qw($VERSION);
use Apache::Constants qw(:response);
use Mail::Mailer;

use CGI qw(:html2 :html3 :form param url *table);
local $^W = 1;

$VERSION = '1.3.3';

=item * $ch = Apache::ContentHandler->new

  Creates a new ContentHandler. You should not override this, override
  _init instead.

=cut

sub new {

  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};

  bless $self, $class;
  $self->_init(@_);

  return $self;
}

=item * $hc->run

The main application structure. Provides for a standard header, body,
and footer. You probably do not want to override this, override the 
individual methods instead.

=cut

sub run {
  my $self = shift || die 'need $self';

  my $work = $self->work;
  my $html = join("\n",
		  start_html(-Title=>$self->{title}
			     . ($self->{subtitle}
				? ": $self->{subtitle}" : ''),
			     -BGCOLOR=>'white'),
		  $self->header,
		  $work,
		  $self->footer,
		  end_html,
		 );

  if ($self->{redirect}) {
    print $self->{cgi}->redirect(-uri=>$self->{redirect});
    return REDIRECT;
  } elsif (! $self->{noprint}) {
    if ($self->{mod_perl}) {
      my $request = $self->{request};
      $request->content_type('text/html');
      $request->no_cache(1);
      $request->send_http_header;
      return OK if $request->header_only;
      print $html;
      return OK;
    } else {
      print $self->{cgi}->header;
      print $html;
    }
  } else {
    return $work;
  }
}

############################################################
# Standard CGI Functions:

=back

=head1 PROTECTED METHODS

=over 4

=item * _init

Private: called by new. Override to put your application specific
variables here.

=cut

sub _init {
  my $self = shift || die 'need $self';
  my $request = shift;

  $self->{mod_perl} = exists $ENV{"MOD_PERL"};

  if ($self->{mod_perl}) {
    $self->{request} = $request;
  }

  $self->{cgi} = new CGI; # used in various places regardless of mod_perl

  $self->{url}       = ($self->{mod_perl}
			? $request->uri
			: $self->url(-absolute=>1));

  $self->{title}     = 'Untitled Application';
  $self->{subtitle}  = '';
  $self->{action}    = $self->arg('action');
  $self->{default_action} = 'does_not_exist';
  $self->{debug}     = $self->arg('debug') || 0;
  $self->{error}     = {};
  $self->{redirect}  = '';
  $self->{noprint}   = 0;

  $self->{error_email}  = 'root';
  $self->{dbi_driver}   = '';
  $self->{dbi_user}     = '';
  $self->{dbi_password} = '';
}

=item * $val = $self->arg($key)

Returns a CGI/mod_perl parameter for the key $key.

=cut

sub arg {
  my $self = shift;
  my $key = shift;

  if ($self->{mod_perl}) {
    my %args = $self->{request}->args;
    return $args{$key};
  } else {
    return param($key);
  }
}

=item * @keys = $self->args

Returns a list of all of the mod_perl/cgi parameters.

=cut

sub args {
  my $self = shift;

  if ($self->{mod_perl}) {
    my %args = $self->{request}->args;
    return keys %args;
  } else {
    return param();
  }
}

=item * $s = $hc->header

Returns a string containing the preheader, an HTML title, and a
postheader. You probably do not want to override this unless you want
a different type of title.

=cut

sub header {
  my $self = shift || die 'need $self';

  return join(
	      '',
	      $self->preheader(),
	      h1($self->{title}),
	      ($self->{subtitle} ? "<small>$self->{subtitle}</small><BR>\n" : ''),
	      $self->postheader(),
	     );
}

=item * $s = $hc->work

Runs a method corresponding to the $action parameter, or the default
action, and returns the content as the body of the document. If the
$action does not exist, then it puts up a page stating that. This
makes rapid prototyping very easy and quick.

=cut

sub work {
  my $self = shift || die 'need $self';

  unless (defined $self->{action}) {
    $self->{action} = $self->{default_action};
  }

  my $action = $self->{action};
  my $method = $self->can($action);
  my $result = '';

  if (defined $method) {
    no strict 'refs';
    $result .= join(
		    '',
		    $self->prework(),
		    $method->($self),
		    $self->postwork(),
		    $self->errors,
		   );
    use strict 'refs';
  } else {
    $result .= h1('Page Not Implemented');
    $result .= p('The application encountered a request for a page that is not yet implemented or understood and was unable to complete your request.');
    $result .= p('The error is automatically logged and an email report is being sent.');
  }

  return $result;
}

=item * $s = $hc->footer

Returns a string containing the prefooter, and postfooter. This used
to have a standard footer as well, but I found it annoying.

=cut

sub footer {
  my $self = shift || die 'need $self';
  return join(
	      '',
	      $self->prefooter(),
	      $self->postfooter(),
	     );
}

=item * $s = $hc->errors

Returns a dictionary list detailing the contents of the error hash, if
any.

=cut

sub errors {
  my $result = '';
  my $self = shift || die 'need $self';

  if (%{$self->{error}}) {
    $result .= join("\n",
		    h1('Errors:'),
		    '<DL>',
		    map(dt($_) . dd($self->{error}{$_}),
			sort keys %{$self->{error}}),
		    '</DL>',
		   );
  }
  return $result;
}

############################################################
# Application Specific Hooks:

=item * $s = $hc->preheader

Returns the contents of the preheader. Override to add something
before the title.

=cut

sub preheader {
  return ''
}

=item * $s = $hc->postheader

Returns the contents of the postheader. Override to add something
after the title.

=cut

sub postheader {
  return '';
}

=item * $s = $hc->prework

Returns the contents of the prework. Override to add something
before the body.

=cut

sub prework {
  return '';
}

=item * $s = $hc->postwork

Returns the contents of the postwork. Override to add something
after the body.

=cut

sub postwork {
  return '';
}

=item * $s = $hc->prefooter

Returns the contents of the prefooter. Override to add something
before the footer.

=cut

sub prefooter {
  return '';
}

=item * $s = $hc->postfooter

Returns the contents of the postfooter. Override to add something
after the footer.

=cut

sub postfooter {
  return '';
}

############################################################
# Utility/Accessor/Helper Methods

=item * $s = $hc->reportError

Sends an email to the addresses listed in error_email, detailing an
error with as much debugging content as possible. Used for fatal
conditions.

=cut

sub reportError {
  my $self = shift;

  my $mailer = new Mail::Mailer;
  $mailer->open({
		'To' => $self->{error_email},
		'Subject' => "Error in " . $self->{url},
	       });

  print $mailer join ("\n",
		      "Error:",
		      ($self->{mod_perl}
		       ? '$url = ' . $self->{url} . '?' . $self->{request}->args
		       : $self->{cgi}->self_url),
		      @_);

  $mailer->close;
}

=item * $s = $hc->dbi

Returns a DBI connection. Override _init and add values for
dbi_driver, dbi_user, and dbi_password to make this connection.

=cut

sub dbi {
  my $self = shift;

  unless (defined $self->{dbi}) {
    $self->{dbi} = DBI->connect($self->{dbi_driver},
				$self->{dbi_user},
				$self->{dbi_password});

    if ($self->{dbi}) {
      $self->{dbi}->do('SET DateStyle = \'ISO\'') ||
	print '<H2>', $DBI::errstr, "</H2>\n";
    } else {
      print '<H2>', $DBI::errstr, "</H2>\n";
    }
  }

  return $self->{dbi};
}

=item * $s = $hc->sqlToTable

Returns an HTML representation of a SQL statement in table form.

=cut

sub sqlToTable {
  my $self = shift;
  my $sql = shift;

  my $result = '';
  my $dbi = $self->dbi();

  my $sth = $dbi->prepare($sql);
  if ( !defined $sth ) {
    die "Cannot prepare statement: $DBI::errstr\n";
  }
  $sth->execute();

  my $head = $sth->{NAME};

  $result .= "<TABLE>\n";
  $result .= "<TR><TH>\n";
  $result .= join("</TH> <TH>", @$head);
  $result .= "</TH></TR>\n";

  my @row;
  while (@row = $sth->fetchrow) {
    $result .= "<TR><TD>\n";
    $result .= join("</TD> <TD>", @row);
    $result .= "</TD></TR>\n";
  }
  $result .= "</TABLE>\n";

  $sth->finish;
  return $result;
}

=item * $s = $hc->sqlToArrays

Returns an array representing a SQL query.

=cut

sub sqlToArrays {
  my $self = shift;
  my $sql = shift;
  my $result = [];
  my $dbi = $self->dbi();

  my $sth = $dbi->prepare($sql);
  die "Cannot prepare statement: $DBI::errstr\n"
    unless ( defined $sth );
  $sth->execute();

  while (my @row = $sth->fetchrow) {
    push @{$result}, [@row];
  }

  $sth->finish;
  return $result;
}

=item * $s = $hc->sqlToHashes

Returns a hash representing a SQL query.

=cut

sub sqlToHashes {
  my $self = shift;
  my $sql = shift;
  my $result = [];
  my $dbi = $self->dbi();

  $self->{debug_str} = $sql;

  my $sth = $dbi->prepare($sql);
  die "Cannot prepare statement: $DBI::errstr\n"
    unless ( defined $sth );
  $sth->execute();

  my $head = $sth->{NAME};
  my $size = scalar @{$head} - 1;

  while (my @row = $sth->fetchrow) {
    my $data = {};

    map { $data->{$head->[$_]} = $row[$_] } 0 .. $size;

    push @{$result}, $data;
  }

  $sth->finish;
  return $result;
}

=item * $s = $hc->query1

Returns a single value from a SQL query. The query must return a
single column and row (ie SELECT name FROM users WHERE id=42).

=cut

sub query1 {
  my $self = shift;
  my $sql = shift || return -1;

  my $sth = $self->dbi->prepare($sql);
  if ( !defined $sth ) {
    die "Cannot prepare statement: $DBI::errstr\n";
  }
  $sth->execute;

  my @row = $sth->fetchrow();

  $sth->finish;

  return scalar(@row) == 1? $row[0] : @row;
}

1;

__END__

=back

=head1 LICENSE

(The MIT License)

Copyright (c) 2001 Ryan Davis, Zen Spider Software

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Ryan Davis <ryand-ch@zenspider.com>
Zen Spider Software <http://www.zenspider.com/ZSS/>

=cut

