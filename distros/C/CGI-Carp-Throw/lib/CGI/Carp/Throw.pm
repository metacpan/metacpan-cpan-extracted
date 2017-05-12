package CGI::Carp::Throw;

#####################################################################
# CGI::Carp::Throw
#
# Provide the ability to represent thrown exceptions as user oriented
# messages rather than obvious error messages with technical tracing
# information without losing any of the capabilities for providing
# error tracing from CGI::Carp.
#
#####################################################################

use strict;
use warnings;

use 5.006002;

our $VERSION = '0.04';

use Exporter;
# using !/ToBrowser/ on import doesn't work
use CGI::Carp (
    @CGI::Carp::EXPORT,
    (grep { ! /name=|^wrap$|ToBrowser/ } @CGI::Carp::EXPORT_OK)
);

use base qw(Exporter);

our @EXPORT = (qw(
    throw_browser
), @CGI::Carp::EXPORT);

our @EXPORT_OK = (qw(
    throw_browser_cloaked throw_format_sub
), @CGI::Carp::EXPORT_OK);

our %EXPORT_TAGS = (
    'all' => [ qw(
	throw_browser throw_browser_cloaked throw_format_sub
    ), @CGI::Carp::EXPORT, (grep { ! /\^name/ } @CGI::Carp::EXPORT_OK) ],
    'carp_browser' => [ qw(
        fatalsToBrowser warningsToBrowser throw_browser
    ) ]
);

*CGI::Carp::Throw::warningsToBrowser = *CGI::Carp::warningsToBrowser;

my $final_warn_browser;

#####################################################################
# Need to call CGI::Carp's import in a controlled manner and with
# a controlled environment.
#
# More complicated than I would like but guessing it's reasonably
# robust.
#####################################################################
sub import {
    my $pkg = shift;

    # this section mostly taken from CGI::Carp
    my @routines = grep { ! /^(?:name|:)/ } (@_, @EXPORT);
    my($oldlevel) = $Exporter::ExportLevel;
    $Exporter::ExportLevel = 1;
    Exporter::import($pkg,@routines);
    $Exporter::ExportLevel = $oldlevel;
    
    # already exported CGI:Carp methods but need to make sure
    # other CGI::Carp import/Exporter functionality sees its arguments
    my @forward_args = grep
        { /warningsToBrowser/ or not ($CGI::Carp::Throw::{ $_ } or /^:/) }
        @_;

    if (grep { /:(?:DEFAULT|carp_browser)/i } @_) {
        $final_warn_browser = 1;
        foreach my $to_brow (qw(fatalsToBrowser warningsToBrowser)) {
            push @forward_args, $to_brow
                unless (grep { /^$to_brow$/ } @forward_args);
        }
    }
    
    # compatibility with old CGI::Carp
    if ($CGI::Carp::VERSION =~ /(\d*\.?\d*)/ and $1 < 1.24) {
        @forward_args = grep { ! /^name=/ } @forward_args
    }

    # be a bit careful what we might (re?)import to Throw module
    local @CGI::Carp::EXPORT = ();
    CGI::Carp::import($pkg, @forward_args);    
}

my $throw_cloaked;

#####################################################################
# Do a little bit of message formatting where important.
# Basically get rid of some lines of confess information that reflect
# internal machinery and might be confusing and add a package marker.
#
# Add <html> <head> and <body> tags if they appear to be missing.
#####################################################################
sub massage_mess {
    my $mess = shift;

    unless ($throw_cloaked) {
        my $confess_mess = CGI::Carp::_longmess;
        $confess_mess =~ s/.*CGI::Carp(?!::Throw::)(?:.*?)line\s+\d*\s*//s;
        $confess_mess =~ s/\s*CGI::Carp::Throw::_throw(?:.*?)line\s+\d*\s*?\n//;
        # make package a variable
        $mess .= '<!-- ' . __PACKAGE__ . " tracing\n$confess_mess-->";
    }
    
    unless ($mess =~ /<\s*html\b/i) {
        unless ($mess =~ /<\s*body\b/i) {
            $mess = "\n<body>\n$mess\n</body>\n";
        }
        unless ($mess =~ /<\s*head\b/i) {
            $mess = "\n<head><title>CGI::Carp::Throw page.</title></head>\n$mess";
        }        
        $mess = "<html>\n$mess\n</html>\n";
    }    

    return $mess;    
}


#####################################################################
# Lifted in large part from CGI::Carp
#####################################################################
sub die_msg_io {
    my $mess = massage_mess(shift);

    my $mod_perl = exists $ENV{MOD_PERL};
    if ($mod_perl) {
        my $r;
        if ($ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
            $mod_perl = 2;
            require Apache2::RequestRec;
            require Apache2::RequestIO;
            require Apache2::RequestUtil;
            require APR::Pool;
            require ModPerl::Util;
            require Apache2::Response;
            $r = Apache2::RequestUtil->request;
        }
        else {
            $r = Apache->request;
        }
        # If bytes have already been sent, then
        # we print the message out directly.
        # Otherwise we make a custom error
        # handler to produce the doc for us.
        if ($r->bytes_sent) {
            $r->print($mess);
            $mod_perl == 2 ? ModPerl::Util::exit(0) : $r->exit;
        } else {
            # MSIE won't display a custom 500 response unless it is >512 bytes!
            if ($ENV{HTTP_USER_AGENT} =~ /MSIE/) {
                $mess = "<!-- " . (' ' x 513) . " -->\n$mess";
            }
            $r->custom_response(500,$mess);
        }
    } else {
        my $bytes_written = eval{tell STDOUT};
        if (defined $bytes_written && $bytes_written > 0) {
            print STDOUT $mess;
        }
        else {
            print STDOUT "Content-type: text/html\n\n";
            print STDOUT $mess;
        }
    }
}

my $throw_format_fref;

#####################################################################
# Set / retrieve the throw_format_sub class attribute
#
# throw_format_sub class attribute is a user supplied routine to
# format error messages in some format, probably using template
# technology, resulting in an appearance compatible with a web site.
#####################################################################
sub throw_format_sub {
    
    if (@_) {
        my $new_fref = shift;
        
        croak 'throw_format_sub setting must be code reference'
            if (    $new_fref                   and
                    (   (not ref($new_fref))          or
                        ref($new_fref) !~ /CODE/i
                    )
            );
        
        $throw_format_fref = $new_fref;
    }
    
    return $throw_format_fref;
}

my $old_fatals_to_browser = \&CGI::Carp::fatalsToBrowser;

{
no warnings 'redefine';

#####################################################################
# Partially replace fatalsToBrowser so that it gets called
# unless the exception came from one of our throw_browser routines.
#####################################################################
*CGI::Carp::fatalsToBrowser = sub {
  my $msg = shift;
  
  my($pack,undef,undef,$sub) = caller(2);
  if (($sub || '') =~ /::_throw_browser$/) {
    die_msg_io($msg);
  }
  else {
    $old_fatals_to_browser->($msg)
  }
};
}

#####################################################################
# Shared throw browser logic for cloaked and non-cloaked variants.
#
# If you called this you wanted CGI::Carp wrapping (unless you're in
# an eval) so turn that on.  If a formatting routine was specified
# call it and die with its message.  Otherwise die and let the
# fatalsToBrowser replacement take over.
#####################################################################
sub _throw_browser {
    unless ($CGI::Carp::WRAP or CGI::Carp::ineval) {
        $CGI::Carp::WRAP++;
    }
    
    if ($throw_format_fref) {
        my $die_msg = $throw_format_fref->(@_);
        $die_msg =~ s/([^\n])$/$1\n/ if $die_msg;
        die $die_msg;
    }
    else {
        if ($_[-1] and $_[-1] !~ /\n$/) {
            die @_, "\n";
        }
        else {
            die @_;
        }
    }
}

#####################################################################
# Standard throw browser.  "Uncloaked" which includes stack trace
# HTML comment.
#####################################################################
sub throw_browser {
    undef $throw_cloaked;
    _throw_browser(@_);
}

#####################################################################
# Standard throw browser.  "Cloaked" to hide stack trace HTML comment.
#####################################################################
sub throw_browser_cloaked {
    $throw_cloaked = 1;
    _throw_browser(@_);
}

END {
    CGI::Carp::warningsToBrowser(1) if $final_warn_browser;
}

1;
__END__

=head1 NAME

CGI::Carp::Throw - CGI::Carp exceptions that don't look like errors.
                                                
=head1 SYNOPSIS

  use strict;
  use CGI qw/:standard/;
  use CGI::Carp::Throw qw/:carp_browser/;

  print header, start_html(-title => 'Throw test'),
    p('expecting parameter: "need_this".');

  if (my $need_this = param('need_this')) {
    if ($need_this =~ /^[\s\w.]+$/ and -e $need_this) {
        print h1('Thank you for providing parameter "need_this"'), end_html;
    }
    else {
        croak 'Invalid or non-existent file name: ', $need_this;
    }
  }
  else {
    throw_browser '***  Please provide parameter: need_this!  ***';
  }

  -- OR --

  use strict;
  use CGI qw/:standard/;
  use CGI::Carp::Throw qw/:carp_browser throw_format_sub/;
  use HTML::Template;

  my $t = HTML::Template->new(filehandle => *DATA);

  #####################################################################
  sub neaterThrowMsg {
    my $throw_msg = shift;
    $t->param(throw_msg => $throw_msg);
    return $t->output;
  }
  throw_format_sub(\&neaterThrowMsg);

  #####################################################################
  print header, start_html(-title => 'Throw test'),
    p('expecting parameter: "need_this".');

  if (my $need_this = param('need_this')) {
    if ($need_this =~ /^[\s\w.]+$/ and -e $need_this) {
        print h1('Thank you for providing parameter "need_this"'), end_html;
    }
    else {
        croak 'Invalid or non-existent file name: ', $need_this;
    }
  }
  else {
    throw_browser '***  Please provide parameter: need_this!  ***';
  }

  __DATA__
  <html>
  <head><title>A Template</title></head>
  <body>
  <p style="color: red; font-style: italic"><TMPL_VAR NAME=THROW_MSG></p>
  </body>
  </html>
  

=head1 DESCRIPTION

Extend CGI::Carp, without breaking CGI::Carp's functionality, to allow die
and croak calls to be selectively changed to throw_browser exceptions that
are displayed in the user's browser as application messages rather than errors
with trace information.  CGI::Carp has somewhat similar, but less flexible,
capabilities that allow for reformatting of all croak, die etc. exception
requests.  Trace information remains available in HTML comments, by default,
but may be left out entirely with the throw_browser_cloaked call.

With some reluctance, it was decided that CGI::Carp::Throw would not default
to invoking fatalsToBrowser or warningsToBrowser to better conform to the
default behavior of CGI::Carp.  The import tag :carp_browser was created as an
alternative that has the effect of requesting the import of both "ToBrowser"
methods/keywords.

=head1 Methods 

=over 4

=item class method C<< throw_browser 'browser message ', 'message param' ... >>

Throw an exception by "die"ing and send passed strings to the browser with
clean formatting that does not imply any kind of programmatic error.  Tracing
data still included in HTML comment on page.

=item class method C<< throw_browser_cloaked 'browser message ', 'message param' ... >>

Nearly the same as throw_browser but tracing data NOT automatically
included anywhere on page.

=item class method C<< throw_format_sub \&message_format_sub >>

Allow for custom formatting of exception message intended to include
formatting with template technology.  Custom formatting is done by user
supplied routine passed as parameter to this method.  Thrown exception is
passed to the user provided routine as list from throw_browser call and
return values are forwarded to browser as they would be from throw_browser.

=back

=head1 EXPORT

throw_browser by default.

=head1 SEE ALSO

CGI::Carp, Carp

=head1 AUTHOR

Ronald Schmidt, E<lt>ronaldxs at software-path.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by The Software Path

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
