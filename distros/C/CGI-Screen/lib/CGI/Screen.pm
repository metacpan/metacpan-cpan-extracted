#                              -*- Mode: Perl -*- 
# $Basename: Screen.pm $
# $Revision: 1.27 $
# Author          : Ulrich Pfeifer
# Created On      : Thu Dec 18 09:26:31 1997
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Fri Feb  5 17:05:16 1999
# Language        : CPerl
# 
# (C) Copyright 1997, Ulrich Pfeifer
# 

package CGI::Screen;
use CGI;
use strict;
use vars qw($VERSION $AUTOLOAD);

# $Format: "$\VERSION = sprintf '%5.3f', ($ProjectMajorVersion$ * 100 + ($ProjectMinorVersion$-1))/1000;"$
$VERSION = sprintf '%5.3f', (1 * 100 + (22))/1000;

sub _set_screen {
  my ($self, $screen, $title)  = @_;
  my $func;

  if      ($self->{screen_func} = $self->can($screen . '_data'  )) {
    $self->{no_headers}  = 1;
  } elsif ($self->{screen_func} = $self->can($screen . '_screen')) {
  } else {
    warn "No such screen: '$screen'\n";
    return;
  }
  $self->{screen_name}  = $screen;
  $self->{screen_title} = $title || $self->param('screen_'.$screen);

  # We keep track of the screens here in order to be able to jump back
  my @screen_last_name  = $self->param('screen_last_name');
  my @screen_last_title = $self->param('screen_last_title');
  if ( @screen_last_name > 1 and $screen_last_name[-2] eq $screen) {
    # User did hit a 'back' button
    pop @screen_last_name; pop @screen_last_title;
  } elsif (not $self->{dont_cut_loops} and
           @screen_last_name and $screen_last_name[-1] eq $screen) {
    # Do nothing. We did jump to the same screen again
  } else {
    while (@screen_last_name > 7) {shift @screen_last_name; shift @screen_last_title;}
    push @screen_last_name,  $self->{screen_name};
    push @screen_last_title, $self->{screen_title};
  }
  $self->param('screen_last_name',  @screen_last_name);
  $self->param('screen_last_title', @screen_last_title);
  $self->{screen_last_name}  = $screen_last_name[-2];
  $self->{screen_last_title} = $screen_last_title[-2];

  $self;                        # return true
}

sub last_screen {
  my $self = shift;
  
  if (wantarray) {
    ($self->{screen_last_name}, $self->{screen_last_title}||$self->{screen_last_name});
  } else {
    $self->{screen_last_name};
  }
}

sub _check_auth_user {
  my $query  = shift;
  my $user   = $query->param('screen_user')   or return;
  my $passwd = $query->param('screen_passwd') or return;


  $query->check_auth_user($user, $passwd);
}
my $D;

sub new {
  my $type  = shift;
  my $self  = {};

  if (@_>1 and $_[0] eq '-screen') { # grab our parameters
    shift; $self = shift;
  }

  $self->{cgi} = CGI->new(@_);

  bless $self, $type; $D = $self;

  # Poor man's Authentication. 
  if (my $func = $self->can('check_auth_ip')) {
    &$func($self, $ENV{REMOTE_ADDR})
      or $self->_set_screen('login', 'Will not serve your ip address')
        && return $self;           # shortcut the rest
  }
  if (my $func = $self->can('check_auth_user')) {
    $self->_check_auth_user 
      or $self->_set_screen('login', 'Need user id and password')
        && return $self;           # shortcut the rest
  }

  for ($self->{cgi}->param) {      # hunt for the target screen
    if (/^screen_function(.*)$/) {
      if ($self->_set_screen($1)) {
        $self->{cgi}->delete($_);
        return $self;              # shortcut the rest
      } 
    }
  }

  # provide a default screen
  $self->_set_screen('main', '');
}

sub import {
  my $pkg = shift;
  my ($callpack, $callfile, $callline) = caller;
  my %old;

  package CGI::Screen::import;

  for my $sym (keys %CGI::Screen::import) {
    $old{$sym}++;# if defined &$sym;
  }

  CGI->import(@_);

  no strict 'refs';
  for my $sym (keys %CGI::Screen::import::) {
    if (not exists $old{$sym} and
        not defined &{"CGI::Screen::${sym}"}) {
      next if $sym =~ /^(BEGIN|DESTROY|END)$/;
      *{"${callpack}::$sym"} = sub {
        my $self = $D;
        if (
            ref $_[0] and
            eval { $_[0]->isa('CGI::Screen') }
           ) {
          $self = shift;
        }
        if (@_ and $_[0] eq '-name') {
          $self->{passed}->{$_[1]} = 1;
        }
        #warn "CGI $sym(@_)\n";
        &{"CGI::$sym"}(@_);
      }
    }
  }

}

sub AUTOLOAD {
  my $func = $AUTOLOAD; $func =~ s/.*:://;
  my $self = $_[0];

  if (my $code = $self->{cgi}->can($func)) {
    no strict 'refs';
    *$func = sub {
      my $self = shift;

      if (@_>1 and $_[0] eq '-name') {
        $self->{passed}->{$_[1]} = 1;
      }
      #warn "AL $func(@_)\n";
      &$code($self->{cgi}, @_);
    };
    goto &$func;
  } else {                      # Function not yet AUTOLOADED in CGI.pm
    my $self = shift;

    if (@_>1 and $_[0] eq '-name') {
      $self->{passed}->{$_[1]} = 1;
    }
    $self->{cgi}->$func(@_);    # Force autoloading in CGI.pm
  }
}

sub _call {
  my ($query, $method)  = @_;

  my $func = ref($method) eq 'CODE' ? $method : $query->can($method)
    or die "No method '$method' defined";

  @_ = ($query, $query->{screen_name}, $query->{screen_title});
  
  goto &$func;
}

sub dispatch {
  my $query  = shift;
  my $func;
  
  $query->_call('prologue') unless $query->{no_headers};
  $query->_call($query->{screen_func});
  $query->_call('epilogue') unless $query->{no_headers};
}

sub application { 'CGI::Screen Test' }
sub default_title { 'Welcome' }

sub title {
  my ($query, $screen, $title)  = @_;

  $query->application . ': ' . ($title || $screen || $query->default_title);
}

sub headline {
  my $query  = shift;

  $query->h1($query->title(@_));
}

sub prologue {
  my $query  = shift;
  my $screen = $query->{'screen_name'};
  my $title  = $query->{'screen_title'} || $query->default_title;
  print
    $query->header    ('-type'  => 'text/html', -expires => '+10s'),
    $query->start_html('-title' => $query->title($screen, $title)),
    $query->_call('headline'),
    $query->start_form
      ;
}

sub trailer {''}

sub epilogue {
  my $query  = shift;

  print
    $query->_call('trailer'),
    $query->close_form,
    $query->end_html;
}


sub start_form {
  my $query  = shift;
  my $screen = $query->param('screen');

  $query->{passed} = {};
  $query->startform(-method=>'POST', -action=>$query->url);
}

sub new_form {
  my $query  = shift;
  my $screen = $query->param('screen');

 $query->close_form .
    $query->start_form;
}

sub close_form {
  my $query = shift;
  my $html;

  for my $param ($query->param) {
    next if exists $query->{passed}->{$param};
    $html .= $query->hidden(-name=>$param) if defined $query->param($param);
  }
  $html .= $query->endform;
}

sub goto_screen {
  my ($query, $screen, $name) = @_;

  $query->submit
    (
     -name  => 'screen_function' . $screen,
     -value => $name,
    );
}

sub url_to_screen {
  my ($query, $screen, $title, %parm) = @_;
  my $url = $query->url . '?';
  my $escape = $query->{cgi}->can('escape'); # should have our own
                                             # since CGI does not
                                             # announce this function
                                             # ;-(
  
  $url .= $escape->('screen_function' . $screen) . '=' . $escape->($title||'');
  for my $param ($query->param) {
    next if exists $parm{$param};
    for my $value ($query->param($param)) {
      $url .=  '&' . $escape->($param) . '=' .
        $escape->($value);
    }
  }

  for my $param (keys %parm) {
    $url .=  '&' . $escape->($param) . '=' . $escape->($parm{$param});
  }
  
  $url;
}

sub link_to_screen {
  my ($query, $screen, $title, %parm) = @_;

  $query->a({href => $query->url_to_screen($screen, $title, %parm)}, $title);
}

sub login_screen {
  my $query = shift;

  print
    $query->table
      (
       $query->TR($query->td('Login'),
                  $query->td($query->textfield('-name' => 'screen_user')),
                 ),
       $query->TR($query->td('Passwd'),
                  $query->td($query->password_field('-name'=>'screen_passwd')),
                 )
      );
  print
    $query->submit
      (
       -name =>'screen',
       -value=>'login',
      );
}

sub main_screen {
  my $query  = shift;

  print
    $query->p("Users of this module should overwrite this method");
}

package CGI::Screen::Debug;
use vars qw(@ISA);

@ISA = qw(CGI::Screen);

sub prologue {
  my $query = shift;
  my @tab = $query->TR($query->td({colspan => 2}, 'CGI Parameters'));
  
  $query->SUPER::prologue;
  
  for ($query->param) {
    next if /^screen_/; # you don't want to know!
    push @tab, $query->TR($query->td($_),
                          $query->td(join ', ', $query->param($_)));
  }
  print $query->table({border => 1}, @tab);
}

1;

__END__

=head1 NAME

CGI::Screen - Perl extension for easy creation of multi screen CGI scripts

=head1 SYNOPSIS

  use CGI::Screen;
  use vars qw(@ISA);
  @ISA = qw(CGI::Screen);

  my $query = __PACKAGE__->new;

  $query->dispatch;

=head1 WARNING

This is B<alpha> software. User visible changes can happen any time.

=head1 DESCRIPTION

B<CGI::Screen> is a subclass of C<CGI> which allows the esay(TM)
creation of simple multi screen CGI scripts. By 'multi screen' I mean
scripts which present different screens to the user when called with
different parameters. This is the common case for scripts linking to
themselves.

To use B<CGI::Screen>, you have to subclass it. For each screen you
want to present to the user, you must create a method
I<screen_name>C<screen_>. This method has to produce the HTML code for
the screen. CGI::Screen does generate HTTP headers and an HTML
framework for you. The HTML framework already contains the C<FORM>
tags.  You can customize the HTTP headers and the HTML framework by 
providing callback methods.

CGI::Screen keeps track of the CGI parameters used in your screen and
passes old parameters which are not used in the current screen.

It highjacks the parameters C<screen_>* to dispatch the different
screens the script implements. The C<screen_user> and C<screen_passwd>
fields are used if you enable the builtin simple authentication.  In
general you should advice your HTTP server to do authentication. But
sometimes it is convenient to check the authentication at the script
level. Especially if you do not have access to your server's
configuration.

=head2 The constructor C<new>

If the first parameter of C<new> is the string C<-screen> the second
argument must be a hash reference specifying the options for the
subclass. Other parameters are passed to the constructor of C<CGI>.

=over

=item C<-dont_cut_loops>

Normaly the history of pages will not be extended if the current page is
the same as the last page. So looping on a page will not change the
result of the C<last_screen> method. If the option C<-dont_cut_loops>
is provided and true, the page will recorded twice. A third visit will
be interpreted as jump back to the first visit.

I<That sounds weird. Will have to figure out a way to recognize back
jumps independent of the history.>

=back

=head2 Adding Screens

All applications should provide a B<main> screen by defining a method
C<main_screen>. This method is called if no (existing) screen is
specified in the parameters. The method is called with three
arguments: The query object, the screen name and the screen title
(More precisely the third parameter, if present, is the text on the
button or anchor which caused the jump to this page).

So the minimal application looks like this:

  use CGI::Screen;
  use vars qw(@ISA);
  @ISA = qw(CGI::Screen);
  
  my $query = __PACKAGE__->new;
  
  $query->dispatch;
  
  sub main_screen {
    my $query = shift;
  
    print $query->p('This is the Main Screen');
  }

That is not too exciting. Let us add a second screen and allow
navigation between the screens:

  sub main_screen {
    my $query = shift;
  
    print
      $query->p('This is the Main Screen'),
      $query->goto_screen('second', 'Another Screen');
  }
  sub second_screen {
    my $query = shift;
  
    print
      $query->p('This is the Other Screen'),
      $query->goto_screen('main', 'Back to Main Screen');

  }


=head2 Moving between screens

Use the method C<goto_screen> to produce a button for switching to
another screen.  You can also produce an anchor instead of a button by
calling C<link_to_screen> instead of C<goto_screen>. You may pass
additional parameters to encode:

    for my $docid (keys %score) {
      print $query->link_to_screen('display', $title{$docid},
                                   'docid' => $docid,
                                   'score' => $score{$docid});
    }

For convenience, CGI::Screen keeps track of the last screen for you so
that you can link to the previous page. Note that only the last seven
screens are saved:

  my $screen = $query->last_screen;
  print
    $query->p("You came from screen $screen. Press "),
    $query->goto_screen($query->last_screen),
    $query->p(" to go back");

C<last_screen> returns screen name and title in list context and
screen name in scalar context. Do not use the CGI parameters
C<screen_last_*> since they are changed before you can get hold of
them C<;-P>

=head2 The callbacks

All callbacks are called with three arguments: The query object, the
screen name and the screen title (= button/anchor text). Callbacks
should return a string.

=item C<application>

The C<application> method returns a string which is used
in the default C<title> and C<headline> callbacks. The Default method
returns the string C<"CGI::Screen Test"> and should definitely be
overwritten by your application.

=item C<title>

The result of the method is used in the HTTP header and in the default
headline. It defaults to the I<application>.

=item C<headline>

The C<headline> method should return a chunk of HTML code to start the
Screen. It defaults to the I<title> enclosed in C<H1> tags.

=head2 Authentication

To enable password authentication, define a method
C<check_auth_user>. The dispatcher will call the method with the user
and password entered by the user. The method should return true if the
authentication succeeded and false otherwise. The dispatcher will
present the C<login_screen> if the authentication failed.

  sub check_auth_user {
    my ($query, $user, $passwd) = @_;

    $user eq 'pfeifer';
  }


For IP address based authentication define the method
C<check_auth_ip>.

  sub check_auth_ip {
    my ($query, $ipaddr) = @_;

   $ipaddr =~ /^(193\.96\.65\.|139\.4\.36\.)/;
  }


If you do not like the default login screen, overwrite with your own
C<login_screen>. Use the CGI parameters C<screen_user> and
C<screen_passwd>.

=head2 Customizing the Title

You may provide a custom C<title> method to generate a title for your
screens.

  sub title {
    my ($query, $screen)  = shift;
  
    $query->application . ': ' . $screen;
  }

=head2 Customizing the Headline

You may provide a custom C<headline> method to generate a HTML chunk
to start your screens.

  sub headline { $_[0]->h1(title(@_)) }

You should overwrite the C<application> method if you use the default
title and headline.

  sub application { 'CGI::Screen Test' }

=head2 Customizing the Trailer

For a custom Trailer, define the C<trailer> method.

  sub trailer {
    my ($query, $screen)  = shift;
  
    "End of Screen $screen";
  }

=head2 Multiple Forms

If you want to have multiple forms on one screen, call the method
C<new_form>.

  sub multi_screen {
     my $query = shift;

     print
       $query->p('This is the Main Screen'),
       $query->textfield('foo'),
       $query->goto('First'),
       $query->new_form,
       $query->textfield('foo'),
       $query->goto('Second');
  }

=head2 Non HTML screens

You can create non HTML screens by defining a I<name>C<_data> method
instead of a <name>C<_screen> method. For C<data> screens you have
to generate HTTP headers yourself.

  sub gif_data {
    my $query = shift;
    
    print $query->header(
                         -type    => 'image/gif',
                         -status  => '200 OK',
                         -expires => '+120s',
                        );
    my $font  = $query->param('font');
    my $w     = GD::Font->$font()->width;
    my $h     = GD::Font->$font()->height;
    my $im    = GD::Image->new((length($query->param('foo'))+2)*$w,$h);
    my $white = $im->colorAllocate(255,255,255);
    my $red   = $im->colorAllocate(255,0,0);
    my $black = $im->colorAllocate(0,0,0);
    $im->transparent($white);
    $im->arc(8,8,5,5,0,360,$red);
    $im->string(GD::Font->$font(),10,0,$query->param('foo'),$black);
    print $im->gif;
  }

=head2 Keeping parameter values

CGI::Screen keeps track of the CGI parameters used in the current
form. It simply looks at the first parameter in any call to a CGI
method.  If the first parameter is C<-name>, the second parameter is
marked as I<used parameter>.  CGI::Screen passed all current parameter
values not used in hidden fields or in the query string of an
anchor. So do not use old style CGI calls to bypass this mechanism or
you will end up with multiple values for the parameters.

If you want to get rid of a parameter, you must explicitly call the
C<delete> method of CGI.

=head1 BUGS

Support for importing from CGI.pm is incomplete.

=head1 AUTHOR

Ulrich Pfeifer E<lt>F<pfeifer@wait.de>E<gt>

=head1 SEE ALSO

The CGI(3) manual and the demo CGI script F<eg/screen> included in the
distribution.

=head1 ACKNOWLEDGEMENTS

I wish to thank Andreas Koenig F<koenig@kulturbox.de> for the
fruitful discussion about the design of this module. 

=head1 Copyright

The B<CGI::Screen> module is Copyright (c) 1997,1998 Ulrich
Pfeifer. Germany.  All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=cut
