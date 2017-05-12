package CGI::Ex;

=head1 NAME

CGI::Ex - CGI utility suite - makes powerful application writing fun and easy

=cut

###----------------------------------------------------------------###
#  Copyright 2003-2015 - Paul Seamons                                #
#  Distributed under the Perl Artistic License without warranty      #
###----------------------------------------------------------------###

### See perldoc at bottom

use strict;
use vars qw($VERSION
            $PREFERRED_CGI_MODULE
            $PREFERRED_CGI_REQUIRED
            $AUTOLOAD
            $DEBUG_LOCATION_BOUNCE
            @EXPORT @EXPORT_OK
            );
use base qw(Exporter);

BEGIN {
    $VERSION               = '2.44';
    $PREFERRED_CGI_MODULE  ||= 'CGI';
    @EXPORT = ();
    @EXPORT_OK = qw(get_form
                    get_cookies
                    print_content_type
                    content_type
                    content_typed
                    set_cookie
                    location_bounce
                    );

    ### cache mod_perl version (light if or if not mod_perl)
    my $v = (! $ENV{'MOD_PERL'}) ? 0
        # mod_perl/1.27 or mod_perl/1.99_16 or mod_perl/2.0.1
        # if MOD_PERL is set - don't die if regex fails - just assume 1.0
        : ($ENV{'MOD_PERL'} =~ m{ ^ mod_perl / (\d+\.[\d_]+) (?: \.\d+)? $ }x) ? $1
        : '1.0_0';
    sub _mod_perl_version () { $v }
    sub _is_mod_perl_1    () { $v <  1.98 && $v > 0 }
    sub _is_mod_perl_2    () { $v >= 1.98 }

    ### cache apache request getter (light if or if not mod_perl)
    my $sub;
    if (_is_mod_perl_1) { # old mod_perl
        require Apache;
        $sub = sub { Apache->request };
    } elsif (_is_mod_perl_2) {
        if (eval { require Apache2::RequestRec }) { # debian style
            require Apache2::RequestUtil;
            $sub = sub { Apache2::RequestUtil->request };
        } else { # fedora and mandrake style
            require Apache::RequestUtil;
            $sub = sub { Apache->request };
        }
    } else {
        $sub = sub {};
    }
    sub apache_request_sub () { $sub }
}

###----------------------------------------------------------------###

#   my $cgix = CGI::Ex->new;
sub new {
    my $class = shift || die "Missing class name";
    my $self  = ref($_[0]) ? shift : {@_};
    return bless $self, $class;
}

###----------------------------------------------------------------###

### allow for holding another classed CGI style object
#   my $query = $cgix->object;
#   $cgix->object(CGI->new);
sub object {
    my $self = shift || die 'Usage: my $query = $cgix_obj->object';
    $self->{'object'} = shift if $#_ != -1;

    if (! defined $self->{'object'}) {
        $PREFERRED_CGI_REQUIRED ||= do {
            my $file = $self->{'cgi_module'} || $PREFERRED_CGI_MODULE;
            $file .= ".pm";
            $file =~ s|::|/|g;
            eval { require $file };
            die "Couldn't require $PREFERRED_CGI_MODULE: $@" if $@;
            1; # return of do
        };
        $self->{'object'} = $PREFERRED_CGI_MODULE->new;
    }

    return $self->{'object'};
}

### allow for calling CGI MODULE methods
sub AUTOLOAD {
    my $self = shift;
    my $meth = ($AUTOLOAD =~ /(\w+)$/) ? $1 : die "Invalid method $AUTOLOAD";
    return $self->object->$meth(@_);
}

sub DESTROY { }

###----------------------------------------------------------------###

### Form getter that will act like CGI->new->Vars only it will return arrayrefs
### for values that are arrays
#   my $hash = $cgix->get_form;
#   my $hash = $cgix->get_form(CGI->new);
#   my $hash = get_form();
#   my $hash = get_form(CGI->new);
sub get_form {
    my $self = shift || __PACKAGE__->new;
    if (! $self->isa(__PACKAGE__)) { # get_form(CGI->new) syntax
        my $obj = $self;
        $self = __PACKAGE__->new;
        $self->object($obj);
    }
    return $self->{'form'} if $self->{'form'};

    ### get the info out of the object
    my $obj  = shift || $self->object;
    my %hash = ();
    foreach my $key ($obj->param) {
        my @val = $obj->param($key);
        $hash{$key} = ($#val <= 0) ? $val[0] : \@val;
    }
    return $self->{'form'} = \%hash;
}

### allow for a setter
### $cgix->set_form(\%form);
sub set_form {
    my $self = shift || die 'Usage: $cgix_obj->set_form(\%form)';
    return $self->{'form'} = shift || {};
}

### Combined get and set form
#   my $hash = $cgix->form;
#   $cgix->form(\%form);
sub form {
    my $self = shift;
    return $self->set_form(shift) if @_ == 1;
    return $self->get_form;
}

### allow for creating a url encoded key value sequence
#   my $str = $cgix->make_form(\%form);
#   my $str = $cgix->make_form(\%form, \@keys_to_include);
sub make_form {
    my $self = shift || die 'Usage: $cgix_obj->make_form(\%form)';
    my $form = shift || $self->get_form;
    my $keys = ref($_[0]) ? shift : [sort keys %$form];
    my $str = '';
    foreach (@$keys) {
        my $key = $_; # make a copy
        my $val = $form->{$key};
        $key =~ s/([^\w.\-\ ])/sprintf('%%%02X', ord $1)/eg;
        $key =~ y/ /+/;
        foreach (ref($val) eq 'ARRAY' ? @$val : $val) {
            my $_val = $_; # make a copy
            $_val =~ s/([^\w.\-\ ])/sprintf('%%%02X', ord $1)/eg;
            $_val =~ y/ /+/;
            $str .= "$key=$_val&"; # intentionally not using join
        }
    }
    chop $str;
    return $str;
}

###----------------------------------------------------------------###

### like get_form - but a hashref of cookies
### cookies are parsed depending upon the functionality of ->cookie
#   my $hash = $cgix->get_cookies;
#   my $hash = $cgix->get_cookies(CGI->new);
#   my $hash = get_cookies();
#   my $hash = get_cookies(CGI->new);
sub get_cookies {
    my $self = shift || __PACKAGE__->new;
    if (! $self->isa(__PACKAGE__)) { # get_cookies(CGI->new) syntax
        my $obj = $self;
        $self = __PACKAGE__->new;
        $self->object($obj);
    }
    return $self->{'cookies'} if $self->{'cookies'};

    my $obj  = shift || $self->object;
    my %hash = ();
    foreach my $key ($obj->cookie) {
        my @val = $obj->cookie($key);
        $hash{$key} = ($#val == -1) ? "" : ($#val == 0) ? $val[0] : \@val;
    }
    return $self->{'cookies'} = \%hash;
}

### Allow for a setter
### $cgix->set_cookies(\%cookies);
sub set_cookies {
    my $self = shift || die 'Usage: $cgix_obj->set_cookies(\%cookies)';
    return $self->{'cookies'} = shift || {};
}

### Combined get and set cookies
#   my $hash = $cgix->cookies;
#   $cgix->cookies(\%cookies);
sub cookies {
    my $self = shift;
    return $self->set_cookies(shift) if @_ == 1;
    return $self->get_cookies;
}

###----------------------------------------------------------------###

### Allow for shared apache request object
#   my $r = $cgix->apache_request
#   $cgix->apache_request($r);
sub apache_request {
    my $self = shift || die 'Usage: $cgix_obj->apache_request';
    $self->{'apache_request'} = shift if $#_ != -1;

    return $self->{'apache_request'} ||= apache_request_sub()->();
}

### Get the version of mod_perl running (0 if not mod_perl)
#   my $version = $cgix->mod_perl_version;
sub mod_perl_version { _mod_perl_version }
sub is_mod_perl_1    { _is_mod_perl_1    }
sub is_mod_perl_2    { _is_mod_perl_2    }

### Allow for a setter
#   $cgix->set_apache_request($r)
sub set_apache_request { shift->apache_request(shift) }

###----------------------------------------------------------------###

### same signature as print_content_type
sub content_type { &print_content_type }

### will send the Content-type header
#   $cgix->print_content_type;
#   $cgix->print_content_type('text/plain');
#   print_content_type();
#   print_content_type('text/plain);
sub print_content_type {
    my ($self, $type, $charset) = (@_ && ref $_[0]) ? @_ : (undef, @_);
    $self = __PACKAGE__->new if ! $self;

    if ($type) {
        die "Invalid type: $type" if $type !~ m|^[\w\-\.]+/[\w\-\.\+]+$|; # image/vid.x-foo
    } else {
        $type = 'text/html';
    }
    $type .= "; charset=$charset" if $charset && $charset =~ m|^[\w\-\.\:\+]+$|;

    if (my $r = $self->apache_request) {
        return if $r->bytes_sent;
        $r->content_type($type);
        $r->send_http_header if $self->is_mod_perl_1;
    } else {
        if (! $ENV{'CONTENT_TYPED'}) {
            print "Content-Type: $type\r\n\r\n";
            $ENV{'CONTENT_TYPED'} = '';
        }
        $ENV{'CONTENT_TYPED'} .= sprintf("%s, %d\n", (caller)[1,2]);
    }
}

### Boolean check if content has been typed
#   $cgix->content_typed;
#   content_typed();
sub content_typed {
    my $self = shift || __PACKAGE__->new;

    if (my $r = $self->apache_request) {
        return $r->bytes_sent;
    } else {
        return $ENV{'CONTENT_TYPED'} ? 1 : undef;
    }
}

###----------------------------------------------------------------###

### location bounce nicely - even if we have already sent content
### may be called as function or a method
#   $cgix->location_bounce($url);
#   location_bounce($url);
sub location_bounce {
    my ($self, $loc) = ($#_ == 1) ? (@_) : (undef, shift);
    $self = __PACKAGE__->new if ! $self;
    $loc =~ s{(\s)}{sprintf("%%%02X", ord $1)}xge if $loc;
    my $html_loc = $loc;
    if ($html_loc) {
        $html_loc =~ s/&/&amp;/g;
        $html_loc =~ s/</&lt;/g;
        $html_loc =~ s/>/&gt;/g;
        $html_loc =~ s/\"/&quot;/g;
    }

    if ($self->content_typed) {
        if ($DEBUG_LOCATION_BOUNCE) {
            print "<a class=debug href=\"$html_loc\">Location: $html_loc</a><br />\n";
        } else {
            print "<meta http-equiv=\"refresh\" content=\"0;url=$html_loc\" />\n";
        }

    } elsif (my $r = $self->apache_request) {
        $r->status(302);
        if ($self->is_mod_perl_1) {
            $r->header_out("Location", $loc);
            $r->content_type('text/html');
            $r->send_http_header;
            $r->print("Bounced to $html_loc\n");
        } else {
            $r->headers_out->add("Location", $loc);
            $r->content_type('text/html');
            $r->rflush;
        }

    } else {
        print "Location: $loc\r\n",
        "Status: 302 Bounce\r\n",
        "Content-Type: text/html\r\n\r\n",
        "Bounced to $html_loc\r\n";
    }
}

### set a cookie nicely - even if we have already sent content
### may be called as function or a method - fancy algo to allow for first argument of args hash
#   $cgix->set_cookie({name => $name, ...});
#   $cgix->set_cookie( name => $name, ... );
#   set_cookie({name => $name, ...});
#   set_cookie( name => $name, ... );
sub set_cookie {
    my $self = UNIVERSAL::isa($_[0], __PACKAGE__) ? shift : __PACKAGE__->new;

    my $args = ref($_[0]) ? shift : {@_};
    foreach (keys %$args) {
        next if /^-/;
        $args->{"-$_"} = delete $args->{$_};
    }

    ### default path to / and allow for 1hour instead of 1h
    $args->{-path} ||= '/';
    $args->{-expires} = time_calc($args->{-expires}) if $args->{-expires};

    my $obj    = $self->object;
    my $cookie = "" . $obj->cookie(%$args);

    if ($self->content_typed) {
        print "<meta http-equiv=\"Set-Cookie\" content=\"$cookie\" />\n";
    } else {
        if (my $r = $self->apache_request) {
            if ($self->is_mod_perl_1) {
                $r->header_out("Set-cookie", $cookie);
            } else {
                $r->headers_out->add("Set-Cookie", $cookie);
            }
        } else {
            print "Set-Cookie: $cookie\r\n";
        }
    }
}

### print the last modified time
### takes a time or filename and an optional keyname
#   $cgix->last_modified; # now
#   $cgix->last_modified((stat $file)[9]); # file's time
#   $cgix->last_modified(time, 'Expires'); # different header
sub last_modified {
    my $self = shift || die 'Usage: $cgix_obj->last_modified($time)'; # may be called as function or method
    my $time = shift || time;
    my $key  = shift || 'Last-Modified';

    ### get a time string - looks like:
    ### Mon Dec  9 18:03:21 2002
    ### valid RFC (although not prefered)
    $time = scalar gmtime time_calc($time);

    if ($self->content_typed) {
        print "<meta http-equiv=\"$key\" content=\"$time\" />\n";
    } elsif (my $r = $self->apache_request) {
        if ($self->is_mod_perl_1) {
            $r->header_out($key, $time);
        } else {
            $r->headers_out->add($key, $time);
        }
    } else {
        print "$key: $time\r\n";
    }
}

### add expires header
sub expires {
    my $self = ref($_[0]) ? shift : __PACKAGE__->new; # may be called as a function or method
    my $time = shift || time;
    return $self->last_modified($time, 'Expires');
}

### similar to expires_calc from CGI::Util
### allows for lenient calling, hour instead of just h, etc
### takes time or 0 or now or filename or types of -23minutes 
sub time_calc {
    my $time = shift; # may only be called as a function
    if (! $time || lc($time) eq 'now') {
        return time;
    } elsif ($time =~ m/^\d+$/) {
        return $time;
    } elsif ($time =~ m/^([+-]?)\s*(\d+|\d*\.\d+)\s*([a-z])[a-z]*$/i) {
        my $m = {
            's' => 1,
            'm' => 60,
            'h' => 60 * 60,
            'd' => 60 * 60 * 24,
            'w' => 60 * 60 * 24 * 7,
            'M' => 60 * 60 * 24 * 30,
            'y' => 60 * 60 * 24 * 365,
        };
        return time + ($m->{lc($3)} || 1) * "$1$2";
    } else {
        my @stat = stat $time;
        die "Could not find file \"$time\" for time_calc.  You should pass one of \"now\", time(), \"[+-] \\d+ [smhdwMy]\" or a filename." if $#stat == -1;
        return $stat[9];
    }
}


### allow for generic status send
sub send_status {
    my $self = shift || die 'Usage: $cgix_obj->send_status(302 => "Bounced")';
    my $code = shift || die "Missing status";
    my $mesg = shift;
    if (! defined $mesg) {
        $mesg = "HTTP Status of $code received\n";
    }
    if ($self->content_typed) {
        die "Cannot send a status ($code - $mesg) after content has been sent";
    }
    if (my $r = $self->apache_request) {
        $r->status($code);
        if ($self->is_mod_perl_1) {
            $r->content_type('text/html');
            $r->send_http_header;
            $r->print($mesg);
        } else {
            $r->content_type('text/html');
            $r->print($mesg);
            $r->rflush;
        }
    } else {
        print "Status: $code\r\n";
        $self->print_content_type;
        print $mesg;
    }
}

### allow for sending a simple header
sub send_header {
    my $self = shift || die 'Usage: $cgix_obj->send_header';
    my $key  = shift;
    my $val  = shift;
    if ($self->content_typed) {
        die "Cannot send a header ($key - $val) after content has been sent";
    }
    if (my $r = $self->apache_request) {
        if ($self->is_mod_perl_1) {
            $r->header_out($key, $val);
        } else {
            $r->headers_out->add($key, $val);
        }
    } else {
        print "$key: $val\r\n";
    }
}

###----------------------------------------------------------------###

### allow for printing out a static javascript file
### for example $self->print_js("CGI::Ex::validate.js");
sub print_js {
    my $self    = shift || die 'Usage: $cgix_obj->print_js($js_file)';
    my $js_file = shift || '';
    $self = $self->new if ! ref $self;

    ### fix up the file - force .js on the end
    $js_file .= '.js' if $js_file && $js_file !~ /\.js$/i;
    $js_file =~ s|::|/|g;

    ### get file info
    my $stat;
    if ($js_file && $js_file =~ m|^/*(\w+(?:/+\w+)*\.js)$|i) {
        foreach my $path (@INC) {
            my $_file = "$path/$1";
            next if ! -f $_file;
            $js_file = $_file;
            $stat = [stat _];
            last;
        }
    }

    ### no file = 404
    if (! $stat) {
        if (! $self->content_typed) {
            $self->send_status(404, "JS File not found for print_js\n");
        } else {
            print "<h1>JS File not found for print_js</h1>\n";
        }
        return;
    }

    ### do headers
    if (! $self->content_typed) {
        $self->last_modified($stat->[9]);
        $self->expires('+ 1 year');
        $self->print_content_type('application/x-javascript');
    }

    return if $ENV{'REQUEST_METHOD'} && $ENV{'REQUEST_METHOD'} eq 'HEAD';

    ### send the contents
    local *FH;
    open(FH, "<$js_file") || die "Couldn't open file  $js_file: $!";
    local $/ = undef;
    print <FH>;
    close FH;
}

###----------------------------------------------------------------###

### form filler that will use either HTML::FillInForm, CGI::Ex::Fill
### or another specified filler.  Argument style is similar to
### HTML::FillInForm.  May be called as a method or a function.
sub fill {
    my $self = shift;
    my $args = shift;
    if (ref($args)) {
        if (! UNIVERSAL::isa($args, 'HASH')) {
            $args = {text => $args};
            @$args{'form','target','fill_password','ignore_fields'} = @_;
        }
    } else {
        $args = {$args, @_};
    }

    my $module = $self->{'fill_module'} || 'CGI::Ex::Fill';

    ### allow for using the standard HTML::FillInForm
    ### too bad it won't modify our file in place for us
    if ($module eq 'HTML::FillInForm') {
        eval { require HTML::FillInForm };
        if ($@) {
            die "Couldn't require HTML::FillInForm: $@";
        }
        $args->{scalarref} = $args->{text} if $args->{text};
        $args->{fdat}      = $args->{form} if $args->{form};
        my $filled = HTML::FillInForm->new->fill(%$args);
        if ($args->{text}) {
            my $ref = $args->{text};
            $$ref = $filled;
            return 1;
        }
        return $filled;

    } else {
        require CGI::Ex::Fill;

        ### get the text to work on
        my $ref;
        if ($args->{text}) {           # preferred method - gets modified in place
            $ref = $args->{text};
        } elsif ($args->{scalarref}) { # copy to mimic HTML::FillInForm
            my $str = ${ $args->{scalarref} };
            $ref = \$str;
        } elsif ($args->{arrayref}) {  # joined together (copy)
            my $str = join "", @{ $args->{arrayref} };
            $ref = \$str;
        } elsif ($args->{file}) {      # read it in
            open (IN, $args->{file}) || die "Couldn't open $args->{file}: $!";
            my $str = '';
            read(IN, $str, -s _) || die "Couldn't read $args->{file}: $!";
            close IN;
            $ref = \$str;
        } else {
            die "No suitable text found for fill.";
        }

        ### allow for data to be passed many ways
        my $form = $args->{form} || $args->{fobject}
        || $args->{fdat} || $self->object;

        CGI::Ex::Fill::form_fill($ref,
                                 $form,
                                 $args->{target},
                                 $args->{fill_password},
                                 $args->{ignore_fields},
                                 );
        return ! $args->{text} ? $$ref : 1;
    }

}

###----------------------------------------------------------------###

sub validate {
    my $self = shift || die 'Usage: my $er = $cgix_obj->validate($form, $val_hash_or_file)';
    my ($form, $file) = (@_ == 2) ? (shift, shift) : ($self->object, shift);

    require CGI::Ex::Validate;

    my $args = {};
    $args->{raise_error} = 1 if $self->{raise_error};
    return CGI::Ex::Validate->new($args)->validate($form, $file);
}

###----------------------------------------------------------------###

sub conf_obj {
    my $self = shift || die 'Usage: my $ob = $cgix_obj->conf_obj($args)';
    return $self->{conf_obj} ||= do {
        require CGI::Ex::Conf;
        CGI::Ex::Conf->new(@_);
    };
}

sub conf_read {
    my $self = shift || die 'Usage: my $conf = $cgix_obj->conf_read($file)';
    return $self->conf_obj->read(@_);
}

###----------------------------------------------------------------###

sub swap_template {
    my $self = shift || die 'Usage: my $out = $cgix_obj->swap_template($file, \%vars, $template_args)';
    my $str  = shift;
    my $form = shift;
    my $args = shift || {};
    $form = $self if ! $form && ref($self);
    $form = $self->get_form if UNIVERSAL::isa($form, __PACKAGE__);

    my ($ref, $return) = ref($str) ? ($str, 0) : (\$str, 1);

    ### look up the module
    my $module = $self->{'template_module'} || 'CGI::Ex::Template';
    my $pkg = "$module.pm";
    $pkg =~ s|::|/|g;
    require $pkg;

    ### swap it
    my $out = '';
    $module->new($args)->process($ref, $form, \$out);

    if (! $return) {
        $$ref = $out;
        return 1;
    } else {
        return $out;
    }
}

###----------------------------------------------------------------###

1;

__END__

=head1 CGI::Ex SYNOPSIS

    ### You probably don't want to use CGI::Ex directly
    ### You probably should use CGI::Ex::App instead.

    my $cgix = CGI::Ex->new;

    $cgix->print_content_type;

    my $hash = $cgix->form;

    if ($hash->{'bounce'}) {

        $cgix->set_cookie({
            name  => ...,
            value => ...,
        });

        $cgix->location_bounce($new_url_location);
        exit;
    }

    if (scalar keys %$form) {
         my $val_hash = $cgix->conf_read($pathtovalidation);
         my $err_obj = $cgix->validate($hash, $val_hash);
         if ($err_obj) {
             my $errors  = $err_obj->as_hash;
             my $input   = "Some content";
             my $content = "";
             $cgix->swap_template(\$input, $errors, $content);
             $cgix->fill({text => \$content, form => $hashref});
             print $content;
             exit;
         } else {
             print "Success";
         }
    } else {
         print "Main page";
    }

=head1 DESCRIPTION

CGI::Ex provides a suite of utilities to make writing CGI scripts
more enjoyable.  Although they can all be used separately, the
main functionality of each of the modules is best represented in
the CGI::Ex::App module.  CGI::Ex::App takes CGI application building
to the next step.  CGI::Ex::App is not quite a framework (which normally
includes pre-built html) instead CGI::Ex::App is an extended application
flow that dramatically reduces CGI build time in most cases.  It does so
using as little magic as possible.  See L<CGI::Ex::App>.

The main functionality is provided by several other modules that
may be used separately, or together through the CGI::Ex interface.

=over 4

=item C<CGI::Ex::Template>

A Template::Toolkit compatible processing engine.  With a few limitations,
CGI::Ex::Template can be a drop in replacement for Template::Toolkit.

=item C<CGI::Ex::Fill>

A regular expression based form filler inner (accessed through B<-E<gt>fill>
or directly via its own functions).  Can be a drop in replacement for
HTML::FillInForm.  See L<CGI::Ex::Fill> for more information.

=item C<CGI::Ex::Validate>

A form field / cgi parameter / any parameter validator (accessed through
B<-E<gt>validate> or directly via its own methods).  Not quite a drop in
for most validators, although it has most of the functionality of most
of the validators but with the key additions of conditional validation.
Has a tightly integrated JavaScript portion that allows for duplicate client
side validation.  See L<CGI::Ex::Validate> for more information.

=item C<CGI::Ex::Conf>

A general use configuration, or settings, or key / value file reader.  Has
ability for providing key fallback as well as immutable key definitions.  Has
default support for yaml, storable, perl, ini, and xml and open architecture
for definition of others.  See L<CGI::Ex::Conf> for more information.

=item C<CGI::Ex::Auth>

A highly configurable web based authentication system.  See L<CGI::Ex::Auth> for
more information.

=back

=head1 CGI::Ex METHODS

=over 4

=item C<-E<gt>fill>

fill is used for filling hash or cgi object values into an existing
html document (it doesn't deal at all with how you got the document).
Arguments may be given as a hash, or a hashref or positional.  Some
of the following arguments will only work using CGI::Ex::Fill - most
will work with either CGI::Ex::Fill or HTML::FillInForm (assume they
are available unless specified otherwise).  (See L<CGI::Ex::Fill> for
a full explanation of functionality).  The arguments to fill are as
follows (and in order of position):

=over 4

=item C<text>

Text should be a reference to a scalar string containing the html to
be modified (actually it could be any reference or object reference
that can be modified as a string).  It will be modified in place.
Another named argument B<scalarref> is available if you would like to
copy rather than modify.

=item C<form>

Form may be a hashref, a cgi style object, a coderef, or an array of
multiple hashrefs, cgi objects, and coderefs.  Hashes should be key
value pairs.  CGI objects should be able
to call the method B<param> (This can be overrided).  Coderefs should
expect the field name as an argument and should return a value.
Values returned by form may be undef, scalar, arrayref, or coderef
(coderef values should expect an argument of field name and should
return a value).  The code ref options are available to delay or add
options to the bringing in of form information - without having to
tie the hash.  Coderefs are not available in HTML::FillInForm.  Also
HTML::FillInForm only allows CGI objects if an arrayref is used.

NOTE: Only one of the form, fdat, and fobject arguments are allowed at
a time.

=item C<target>

The name of the form that the fields should be filled to.  The default
value of undef, means to fill in all forms in the html.

=item C<fill_passwords>

Boolean value defaults to 1.  If set to zero - password fields will
not be filled.

=item C<ignore_fields>

Specify which fields to not fill in.  It takes either array ref of
names, or a hashref with the names as keys.  The hashref option is
not available in CGI::Ex::Fill.

=back

Other named arguments are available for compatibility with HTML::FillInForm.
They may only be used as named arguments.

=over 4

=item C<scalarref>

Almost the same as the argument text.  If scalarref is used, the filled
html will be returned.  If text is used the html passed is filled in place.

=item C<arrayref>

An array ref of lines of the document.  Forces a returned filled html
document.

=item C<file>

An filename that will be opened, filled, and returned.

=item C<fdat>

A hashref of key value pairs.

=item C<fobject>

A cgi style object or arrayref of cgi style objects used for getting
the key value pairs.  Should be capable of the ->param method and
->cookie method as document in L<CGI>.

=back

See L<CGI::Ex::Fill> for more information about the filling process.

=item C<-E<gt>object>

Returns the CGI object that is currently being used by CGI::Ex.  If none
has been set it will automatically generate an object of type
$PREFERRED_CGI_MODULE which defaults to B<CGI>.

=item C<-E<gt>validate>

Validate has a wide range of options available. (See L<CGI::Ex::Validate>
for a full explanation of functionality).  Validate has two arguments:

=over 4

=item C<form>

Can be either a hashref to be validated, or a CGI style object (which
has the param method).

=item C<val_hash>

The val_hash can be one of three items.  First, it can be a straight
perl hashref containing the validation to be done.  Second, it can
be a YAML document string.  Third, it can be the path to a file
containing the validation.  The validation in a validation file will
be read in depending upon file extension.

=back

=item C<-E<gt>get_form>

Very similar to CGI->new->Vars except that arrays are returned as
arrays.  Not sure why CGI didn't do this anyway (well - yes -
legacy Perl 4 - but at some point things need to be updated).

    my $hash = $cgix->get_form;
    my $hash = $cgix->get_form(CGI->new);
    my $hash = get_form();
    my $hash = get_form(CGI->new);

=item C<-E<gt>set_form>

Allow for setting a custom form hash.  Useful for testing, or other
purposes.

    $cgix->set_form(\%new_form);

=item C<-E<gt>get_cookies>

Returns a hash of all cookies.

    my $hash = $cgix->get_cookies;
    my $hash = $cgix->get_cookies(CGI->new);
    my $hash = get_cookies();
    my $hash = get_cookies(CGI->new);

=item C<-E<gt>set_cookies>

Allow for setting a custom cookies hash.  Useful for testing, or other
purposes.

    $cgix->set_cookies(\%new_cookies);

=item C<-E<gt>make_form>

Takes a hash and returns a query_string.  A second optional argument
may contain an arrayref of keys to use from the hash in building the
query_string.  First argument is undef, it will use the form stored
in itself as the hash.

=item C<-E<gt>content_type>

Can be called multiple times during the same session.  Will only
print content-type once.  (Useful if you don't know if something
else already printed content-type).  Calling this sends the Content-type
header.  Trying to print -E<gt>content_type is an error.  For clarity,
the method -E<gt>print_content_type is available.

    $cgix->print_content_type;

    # OR
    $cgix->print_content_type('text/html');

    # OR
    $cgix->print_content_type('text/html', 'utf-8');

=item C<-E<gt>set_cookie>

Arguments are the same as those to CGI->new->cookie({}).
Uses CGI's cookie method to create a cookie, but then, depending on
if content has already been sent to the browser will either print
a Set-cookie header, or will add a <meta http-equiv='set-cookie'>
tag (this is supported on most major browsers).  This is useful if
you don't know if something else already printed content-type.

=item C<-E<gt>location_bounce>

Depending on if content has already been sent to the browser will either print
a Location header, or will add a <meta http-equiv='refresh'>
tag (this is supported on all major browsers).  This is useful if
you don't know if something else already printed content-type.  Takes
single argument of a url.

=item C<-E<gt>last_modified>

Depending on if content has already been sent to the browser will either print
a Last-Modified header, or will add a <meta http-equiv='Last-Modified'>
tag (this is supported on most major browsers).  This is useful if
you don't know if something else already printed content-type.  Takes an
argument of either a time (may be a CGI -expires style time) or a filename.

=item C<-E<gt>expires>

Depending on if content has already been sent to the browser will either print
a Expires header, or will add a <meta http-equiv='Expires'>
tag (this is supported on most major browsers).  This is useful if
you don't know if something else already printed content-type.  Takes an
argument of a time (may be a CGI -expires style time).

=item C<-E<gt>send_status>

Send a custom status.  Works in both CGI and mod_perl.  Arguments are
a status code and the content (optional).

=item C<-E<gt>send_header>

Send a http header.  Works in both CGI and mod_perl.  Arguments are
a header name and the value for that header.

=item C<-E<gt>print_js>

Prints out a javascript file.  Does everything it can to make sure
that the javascript will cache.  Takes either a full filename,
or a shortened name which will be looked for in @INC. (ie /full/path/to/my.js
or CGI/Ex/validate.js or CGI::Ex::validate)

    #!/usr/bin/perl
    use CGI::Ex;
    CGI::Ex->print_js($ENV{'PATH_INFO'});

=item C<-E<gt>swap_template>

This is intended as a simple yet strong subroutine to swap
in tags to a document.  It is intended to be very basic
for those who may not want the full features of a Templating
system such as Template::Toolkit (even though they should
investigate them because they are pretty nice).  The default allows
for basic template toolkit variable swapping.  There are two arguments.
First is a string or a reference to a string.  If a string is passed,
a copy of that string is swapped and returned.  If a reference to a
string is passed, it is modified in place.  The second argument is
a form, or a CGI object, or a cgiex object, or a coderef (if the second
argument is missing, the cgiex object which called the method will be
used).  If it is a coderef, it should accept key as its only argument and
return the proper value.

  my $cgix = CGI::Ex->new;
  my $form = {foo  => 'bar',
              this => {is => {nested => ['wow', 'wee']}}
             };

  my $str =  $cgix->swap_template("<html>[% foo %]<br>[% foo %]</html>", $form));
  # $str eq '<html>bar<br>bar</html>'

  $str = $cgix->swap_template("[% this.is.nested.1 %]", $form));
  # $str eq 'wee'

  $str = "[% this.is.nested.0 %]";
  $cgix->swap_template(\$str, $form);
  # $str eq 'wow'

  # may also be called with only one argument as follows:
  # assuming $cgix had a query string of ?foo=bar&baz=wow&this=wee
  $str = "<html>([% foo %]) <br>
          ([% baz %]) <br>
          ([% this %]) </html>";
  $cgix->swap_template(\$str);
  #$str eq "<html>(bar) <br>
  #        (wow) <br>
  #        (wee) </html>";

For further examples, please see the code contained in t/samples/cgi_ex_*
of this distribution.

If at a later date, the developer upgrades to Template::Toolkit, the
templates that were being swapped by CGI::Ex::swap_template should
be compatible with Template::Toolkit.

=back

=head1 MODULES

See also L<CGI::Ex::App>.

See also L<CGI::Ex::Auth>.

See also L<CGI::Ex::Conf>.

See also L<CGI::Ex::Die>.

See also L<CGI::Ex::Dump>.

See also L<CGI::Ex::Fill>.

See also L<CGI::Ex::Template>.

See also L<CGI::Ex::Validate>.

=head1 LICENSE

This module may be distributed under the same terms as Perl itself.

=head1 AUTHOR

Paul Seamons <perl at seamons dot com>

=cut
