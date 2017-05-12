package Apache::JAF;

use 5.6.0;
use strict;

use Template ();
use Template::Provider;
use Template::Parser;
use Template::Document;

our @ISA = qw( Template::Provider );

use Apache ();
use Apache::Util ();
use Apache::JAF::Util ();
use JAF::Util ();

use Apache::Request ();
use Apache::Constants qw( :common REDIRECT );
use Apache::File ();

use Data::Dumper qw( Dumper );
use File::Find ();

our $WIN32 = $^O =~ /win32/i;
our $RX = $WIN32 ? qr/\:(?!(?:\/|\\))/ : qr/\:/;
our $VERSION = do { my @r = (q$Revision: 0.21 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

# Constructor
################################################################################
sub new {
  my ($ref, $r) = @_;
  my $self  = {};

  #
  # use as template provider
  #
  if (ref($r) eq 'HASH') {
    $self = $ref->SUPER::new($r);
    bless ($self, $ref);
    return $self;
  }

  #
  # use as framework
  #
  $r = Apache::Request->instance($r);
  bless ($self, $ref);

  # r - request (filter-aware)
  $self->{filter} = lc $r->dir_config('Filter') eq 'on';
  $self->{r} = $self->{filter} ? $r->filter_register() : $r;
  my $prefix = $r->dir_config('Apache_JAF_Prefix') || 0;

  # prefix - path|number of subdirs that must be removed from uri
  $prefix = ($prefix =~ /^\/(.*)$/) ? scalar(my @tmp = split '/', $1) : int($prefix);

  # uri - reference to array that contains uri plitted by '/'
  my @uri = split '/', $self->{r}->uri;
  shift @uri if $prefix;
  splice @uri, 0, ($prefix || 1);
  if (@uri) {
    $uri[-1] =~ s/\.html?$//i;
    my $i = 0;
    while ($i < @uri) {
      splice @uri, $i, 2 if $uri[$i] =~ /^\w+:$/ && !$uri[$i+1];
      $i++;
    }
  }
  $self->{uri} = \@uri;

  # res - result hash, that passed to the template
  $self->{res} = {};

  # for complex-name-handlers change '_' in handler name to '/' to provide
  # real document tree in Templates folder
  $self->{expand_path} = 1;

  # Level of warnings that will be written to the server's error_log
  # every next level includes all options from previous
  #  0: critical errors only
  #  1: request processing line
  #  2: client request
  #  3: response headers
  #  4: template variables
  #  9: loading additional handlers
  # 10: processed template
  $self->{debug_level} = $self->{r}->dir_config('Apache_JAF_Debug') || 0;

  # Default response status and content-type
  $self->{status} = NOT_FOUND;
  $self->{type} = 'text/html';

  # Default template and includes extensions
  $self->{template_ext} = '.html';
  $self->{include_ext} = '.inc';
  $self->{default_include} = 'default';

  # pre- and post-process templates (without extensions)
  $self->{header} = 'header';
  $self->{footer} = 'footer';
  $self->{pre_chomp} = $self->{post_chomp} = $self->{trim} = 1;

  # Templates folder
  $self->{templates} = $self->{r}->dir_config('Apache_JAF_Templates');
  # Modules folder
  $self->{modules} = $self->{r}->dir_config('Apache_JAF_Modules');

  # Compiled templates folder  
  $self->{compile_dir} = $self->{r}->dir_config('Apache_JAF_Compiled') || '/tmp';

  # This method must be implemented in derived class and must
  # provide $self->{handler} property
  $self->{handler} = $self->setup_handler();
  return undef unless $self->{handler};

  # Log real and uri without prefix
  $self->warn(1, "Starting $ref for " . $self->{r}->uri);
  $self->warn(1, "URI: /" . join '/', @{$self->{uri}});
  $self->warn(2, 'Request: ' . $self->{r}->as_string());

  # Load handlers if $HANDLERS_LOADED flag is unset or 
  # we are in debug mode ($self->{debug_level} > 0)
  # reload modified templates also
  my $package = ref $self;
  { no strict 'refs';
    $self->load_handlers($package, $self->{modules}) if $self->{debug_level} || !${ "${package}::HANDLERS_LOADED" };
    $self->load_templates($package, $self->{templates}, 1) if $self->{debug_level} && ${ "${package}::SELF_PROVIDER" };
  }

  # {page} key in result hash equals to current handler
  $self->{res}{page} = $self->{handler};

  return $self
}

# Load handlers and temlates during compile-time...
################################################################################
sub import {
  my ($package, %args) = @_;
  $package = (caller())[0];
  load_handlers(undef, $package, $args{handlers}) if $args{handlers};
  load_templates(undef, $package, $args{templates}) if $args{templates};
}

# Load handlers
################################################################################
our (%HANDLERS, $PACKAGE);

sub _process_as_handler {
  return unless /\.pm$/;
  my $text = undef;
  if (-f && -r) {
    open IN, $_;
    $text = do { local $/; <IN> };
    close IN;
    $HANDLERS{ $_ }{TEXT} = $text;
  }
}

sub load_handlers {
  my ($self, $package, $dir) = @_;
  $dir ||= $self->{modules} if $self;

  if ($dir eq 'auto') {
    $dir = $INC{ do { (my $dummy = $package) =~ s/::/\//g; "$dummy.pm"; } };
    $dir =~ s/\.pm$/\/pages\//;
    undef $dir unless -d $dir;
  } else {
    $dir .= '/' if $dir !~ /\/$/;
  }  

  if (defined $dir && -d $dir) {
    local %HANDLERS = ();
    File::Find::find({ wanted => \&_process_as_handler, no_chdir => 1 }, $dir);

    local $PACKAGE = qq{package $package; use strict;\n};
    my $line = 2;
    foreach my $file (keys %HANDLERS) {
      my $lines = $HANDLERS{ $file }{TEXT} =~ s/(\n)/$1/sg;
      $HANDLERS{ $file }{START} = $line;
      $HANDLERS{ $file }{END} = $line += $lines + 1;
      $PACKAGE .= $HANDLERS{ $file }{TEXT} . "\n";
    }
    $PACKAGE .= qq{\nour \$HANDLERS_LOADED=1;\n};

    $self && $self->warn(9, "Loading handlers for $package:\n $PACKAGE");
    eval $PACKAGE;

    if ($@) {
      (my $error = $@) =~ s/\(eval\s+\d+\)(\s+line\s+)(\d+)/
      do {
        my $replace = q{(can't find where...)};
        foreach my $file (keys %HANDLERS) {
          if ($HANDLERS{ $file }{START} <= $2 && $2 < $HANDLERS{ $file }{END}) {
            $replace = "($file)$1" . ($2 - $HANDLERS{ $file }{START} + 1);
            last;
          }
        }
        $replace;
      }
      /egx;

      $self && $self->warn(0, $error) || die $error;
    }
  }
}

# Load templates
################################################################################
our ($TEMPLATES, $PARSER);

sub _process_as_template {
  if (exists $TEMPLATES->{$_} && 
     (stat)[9] <= $TEMPLATES->{$_}{mtime} && 
     !$TEMPLATES->{$_}{error}) {
    return
  }

  if (-f && -r) {
    open IN, $_;
    my $text = do { local $/; <IN> };
    close IN;
    unless ($TEMPLATES->{$_}{code} = Template::Document->new( $PARSER->parse($text) )) {
      $TEMPLATES->{$_}{error} = $PARSER->error();
    } else {
      $TEMPLATES->{$_}{mtime} = (stat(_))[9];
    }
  }
}

sub load_templates {
  my ($self, $package, $dir, $reload) = @_;

  local $TEMPLATES = {};
  local $PARSER = Template::Parser->new();

  if ($reload) {
    no strict 'refs';
    $TEMPLATES = { %${ "${package}::TEMPLATES" } };
  }

  $dir ||= $self->{templates} if $self;
  if ($dir eq 'auto') {
    $dir = $INC{ do { (my $dummy = $package) =~ s/::/\//g; "$dummy.pm"; } };
    $dir =~ s/modules\/.*$/templates\//;
  }

  File::Find::find({ wanted => \&_process_as_template, no_chdir => 1 }, split $RX, $dir);

  { no strict 'refs';
    ${ "${package}::SELF_PROVIDER" } ||= 1;
    ${ "${package}::TEMPLATES" } = { ${ "${package}::TEMPLATES" } ? %${ "${package}::TEMPLATES" } : (), %${ 'TEMPLATES' } };
  }
}

sub fetch {
  my ($self, $name) = @_;
  my $ref;
  my $t = "${\( ref $self )}::TEMPLATES";
  { no strict 'refs';
    $ref = $$t;
  }
  foreach my $p (@{$self->paths()}) {
    my $full_name = "$p/$name";
    if (exists $ref->{$full_name}) {
      if ((stat($full_name))[9] > $ref->{$full_name}{mtime}) {
        load_templates(undef, ref $self, $p);
        no strict 'refs';
        $ref = $$t;
      }
      return wantarray ? ($ref->{$full_name}{code}, $ref->{$full_name}{error}) : $ref->{$full_name}{code};
    }
  }
  return (undef, undef);
}

# ABSTRACT: setup_handler must be implemented in derived 
# class to provide $self->{handler} property mandatory
################################################################################
sub setup_handler { $_[0]->warn(0, 'Abstract method call!') }

# Last modified
################################################################################
sub last_modified { time() }

# Cache
################################################################################
sub cache { undef }

# Log errors and warnings
################################################################################
sub warn { 
  my ($self, $level, $message) = @_;
  my $method = $level ? 'warn' : 'log_error';
  #
  # server_name included in warning string to distinguish different servers in
  # overall error log... (default behavior) 
  #
  $self->{r}->$method('[' . $self->{r}->get_server_name() . '] ' . $message) if $self->{debug_level} >= $level;
}

# Check template existance
################################################################################
sub _exists {
  my ($self, $dir, $name, $self_provider) = @_;
      
  return 0 unless $self_provider ? do { 
    no strict 'refs';
    my $t = "${\( ref $self )}::TEMPLATES";
    exists $$t->{"$dir/$name"};
  } : -f $dir . "/$name";

  $self->warn(1, 'Template: /' . $name);
  $self->{template} = $name;
  return 1
}

# Process template
################################################################################
sub process_template {
  my ($self) = @_;

  my $self_provider;
  { no strict 'refs'; $self_provider = ${ "${\( ref $self )}::SELF_PROVIDER" }; }
  local $Template::Config::PROVIDER = ref $self if $self_provider;
  local $Template::Config::STASH = 'Template::Stash::XS';

  unless ($self->{template}) {
    my $tx = "(\\$self->{template_ext})\$";
    foreach (split $RX, $self->{templates}) {
      my $test_name = (join '/', ($self->{handler}, @{$self->{uri}})) . $self->{template_ext};
      last if $self->_exists($_, $test_name, $self_provider);
      $test_name =~ s{$tx}{/index$1};
      last if $self->_exists($_, $test_name, $self_provider);
    }
    $self->{template} ||= $self->{handler} . $self->{template_ext};
  }
  $self->warn(1, 'Ready to process template for handler: ' . $self->{handler});

  my $tt = Template->new({
    INCLUDE_PATH => $self->{templates}, 
    $self_provider ? () : (
      PRE_CHOMP => $self->{pre_chomp}, 
      POST_CHOMP => $self->{post_chomp},
      TRIM => $self->{trim},
      ($self->{compile_dir} ? (COMPILE_DIR => $self->{compile_dir}) : ()),
    ),
    ($self->{default_include} || $self->{header} ? ('PRE_PROCESS'  => [$self->{default_include} && $self->{default_include} . $self->{include_ext} || (), $self->{header} && $self->{header} . $self->{include_ext} || ()]) : ()),
    ($self->{footer} ? ('POST_PROCESS' => $self->{footer} . $self->{include_ext}) : ())
  });
  $self->warn(4, 'Template variables: ' . Dumper $self->{res});

  my $result;
  $tt->process($self->{template}, $self->{res}, \$result);
  if (my $te = $tt->error()) {
    if ($te =~ /not found/) {
      $self->warn(1, "Template error: $te");
      $self->{status} = NOT_FOUND;
    } else {
      $self->warn(0, "Template error: $te");
      $self->{status} = SERVER_ERROR;
    } 
  } else {
    $self->warn(1, 'Template processed');
    $self->warn(10, $result);
  }

  undef $tt;
  return \$result;
}

# Reduce stat calls (only dynamic content from mod_perl-powered server)
################################################################################
sub trans_handler ($$) { OK }

# Actual Apache handler
################################################################################
sub handler ($$) {
  my ($self, $r) = @_;
  my $time;
  eval "use Time::HiRes ()";
  $time = Time::HiRes::time() unless $@;

  if (-f $r->document_root() . $r->uri() && -r _) {
    $r->filename($r->document_root() . $r->uri());
    $r->warn('Static file request: ' . $r->filename());
    return DECLINED;
  }

  $self = $self->new($r) unless ref($self);
  unless ($self) {
    $self->warn(0, "Can't create handler object!");
    return SERVER_ERROR;
  }

  my $result;
  $self->{status} = $self->site_handler();
  $result = $self->process_template() if $self->{status} == OK && $self->{type} =~ /^text/ && !$self->{r}->header_only;

  if ($self->{status} == OK) {
    $self->{r}->send_http_header($self->{type});
    return $self->{status} if $self->{r}->header_only;

    if ($self->{type} =~ /^text/) {
      #
      # Apache::Filter->print() must(?) be patched for printing referenced scalars
      #
      $self->{r}->print($self->{filter} ? $$result : $result);
    } else {
      #
      # if handler set $self->{type} other than text/(html|plain)
      # then data must be send to the client by on_send_..._data method
      #
      my $method = "on_send_${\($self->{handler})}_data";
      $self->$method(@{$self->{uri}}) if $self->can($method);
    }
  }

  $self->warn(3, 'Response headers: ' . Dumper {($self->{status} == OK) ? $self->{r}->headers_out() : $self->{r}->err_headers_out()});
  $self->warn(1, sprintf 'Request processed in %0.3f sec', Time::HiRes::time() - $time) if $time;

  my $status = $self->{status};
  undef $result;
  undef $self;

  return $status
}

# Global Apache::JAF handler. If you want some stuff before (and|or) after
# running handler you must override it like that:
#
# sub site_handler {
#   my $self = shift;
#
#   [before stuff goes here]
#
#   $self->{status} = $self->SUPER::site_handler(@_);
#
#   [after stuff goes here]
#
#   return $self->{status}
# }
################################################################################
sub site_handler {
  my ($self) = @_;

  my ($method, $last_modified, $cache, $mtime);
  foreach (($method, $last_modified, $cache) = map { $_ . $self->{handler} } qw(do_ last_modified_ cache_)) {
    $_ =~ tr{/}{_} if $self->{expand_path};
  }

  $self->warn(1, "Handler method: $method");

  $mtime = $self->last_modified(@{$self->{uri}});
  $mtime = $self->$last_modified(@{$self->{uri}}) if $self->can($last_modified);
  if ($mtime) {
    $self->{r}->update_mtime($mtime);
    $self->{r}->set_last_modified;
    $self->{status} = $self->{r}->meets_conditions;
    return $self->{status} unless $self->{status} == OK;
  }

  if ($self->can($method)) {
    #
    # process template with handler
    #
    $self->warn(1, "Can do $method: Y");

    my $cstat = $self->cache(@{$self->{uri}});
    $cstat = $self->$cache(@{$self->{uri}}) if $self->can($cache);
    if ($cstat) {
      $self->{status} = $cstat;
    } else {
      $self->{status} = $self->$method(@{$self->{uri}})
    }
    $self->{handler} =~ tr{_}{/} if $self->{expand_path} && $self->{type} =~ /^text/;
    $self->warn(1, 'Content-type: ' . $self->{type});
  } else {
    #
    # process template without handler (defaults variables only, header and footer)
    #
    $self->warn(1, "Can do $method: N");
    $self->{status} = OK unless $self->{status} == SERVER_ERROR;
  }

  return $self->{status};
}

### Additional utility methods for getting params

sub param {
  my ($self, $p) = @_;
  my @params = map { $_ = JAF::Util::trim($_); length > 0 ? $_ : undef} ($self->{r}->param($p));
  return $params[0];
} 

sub upload_fh {
  my ($self, $p) = @_;
  if($self->param($p)) {
    my $upl = $self->{r}->upload($p);
    return $upl->fh if($upl && $upl->fh)
  }
  return undef
}

### Methods for simplify handlers for download content instead of viewing it

sub disable_header { undef $_[0]->{header} }
sub disable_footer { undef $_[0]->{footer} }
sub disable_header_footer { $_[0]->disable_header(); $_[0]->disable_footer(); }
sub download_type { $_[0]->{type} = 'application/x-force-download'; }
sub download_it { $_[0]->disable_header_footer(); $_[0]->download_type(); }

### methods for JAF database editing

sub default_record_edit {
  my ($self, $tbl, $options) = @_;

  if ($self->{r}->method() eq 'POST' && $self->param('act') eq 'edit') {
    $tbl->update({
      $tbl->{key} => $self->param($tbl->{key}), 
      map {defined $self->{r}->param($_) ? ($_ => $self->param($_)) : $options->{checkbox} && exists $options->{checkbox}{$_} ? ($_ => $options->{checkbox}{$_}) : ()} @{$tbl->{cols}}
    }, $options);
  }
}

sub default_table_edit {
  my ($self, $tbl, $options) = @_;

  if ($self->{r}->method() eq 'POST' && $self->param('act') eq 'edit') {
    for (my $i=1; defined $self->param("$tbl->{key}_$i"); $i++) {
      $tbl->delete({
        $tbl->{key} => $self->param("$tbl->{key}_$i")
      }, $options) if $self->param("dowhat_$i") eq 'del';
      $tbl->update({
        $tbl->{key} => $self->param("$tbl->{key}_$i"), 
        map {defined $self->{r}->param("${_}_$i") ? ($_ => $self->param("${_}_$i")) : $options->{checkbox} && exists $options->{checkbox}{$_} ? ($_ => $options->{checkbox}{$_}) : ()} @{$tbl->{cols}}
      }, $options) if $self->param("dowhat_$i") eq 'upd';
    }
  } elsif ($self->param('act') eq 'add') {
    unless ($tbl->insert({
      map {defined $self->{r}->param($_) ? ($_ => $self->param($_)) : $options->{checkbox} && exists $options->{checkbox}{$_} ? ($_ => $options->{checkbox}{$_}) : ()} @{$tbl->{cols}}
    }, $options)) {
      foreach (@{$tbl->{cols}}) {
        $self->{res}{$_} = $self->param($_);
      }
    }
  }
}

sub default_messages {
  my ($self, $modeller) = @_;
  
  %{$self->{cookies}} = Apache::Cookie->fetch() unless $self->{cookies};
  if ($self->{status} == REDIRECT) {
    my $messages = $modeller->messages();
    if ($messages) {
      Apache::Cookie->new($self->{r},
                          -name => 'messages', 
                          -path => '/',
                          -value => Data::Dumper::Dumper $messages)->bake();
    }
  } elsif ($self->{status} == OK && $self->{type} =~ /^text/ && !$self->{r}->header_only) {
    my $VAR1;
    if (exists $self->{cookies}{messages} && eval $self->{cookies}{messages}->value) {
      $self->{res}{messages} = $VAR1;
      Apache::Cookie->new($self->{r},
                          -name => $self->{res}{messages} ? 'messages' : 'error', 
                          -path => '/', 
                          -value => '')->bake();
    } else {
      $self->{res}{messages} = $modeller->messages();
    }
  } 
}

=head1 NAME

Apache::JAF -- mod_perl and Template-Toolkit web applications framework

=head1 SYNOPSIS

=over 4

=item controller -- a mod_perl module that drives your application

 package Apache::JAF::MyJAF;
 use strict;
 use JAF::MyJAF; # optional
 # loading mini-handlers & templates during compilation time
 use Apache::JAF (
   handlers => '/examples/site/modules/Apache/JAF/MyJAF/pages/', # 'auto' if you want to use suggested file structure
   templates => '/examples/site/templates/'                      # the same comment
 );
 our @ISA = qw(Apache::JAF);

 # determine handler to call 
 sub setup_handler {
   my ($self) = @_;
   # the page handler for each URI of sample site is 'do_index'
   # you should swap left and right ||-parts for real application
   my $handler = 'index' || shift @{$self->{uri}};
   return $handler;
 }

 sub site_handler {
   my ($self) = @_;
   # common stuff before handler is called
   $self->{m} = JAF::MyJAF->new(); # create modeller -- if needed
   $self->SUPER::site_handler();
   # common stuff after handler is called
   return $self->{status}
 }
 1;

=item page handler -- controller's method that makes one (or more) pages

 sub do_index {
   my ($self) = @_;
   # page handler must fill $self->{res} hash that process with template
   $self->{res}{test} = __PACKAGE__ . 'test';
   # and return Apache constant according it's logic
   return OK;
 }

=item modeller -- a module that encapsulates application business-logic

 package JAF::MyJAF;
 use strict;
 use DBI;
 use base qw( JAF );

 sub new {
   my ($class, $self) = @_;
   $self->{dbh} = DBI->connect(...);
   return bless $self, $class;
 }
 1;

=item Apache configuration (F<httpd.conf>)

  DocumentRoot /examples/site/data
  <Location />
    <Perl>
      use lib qw(/examples/site/modules);
      use Apache::JAF::MyJAF;
    </Perl>
    SetHandler perl-script
    PerlHandler Apache::JAF::MyJAF
    PerlSetVar Apache_JAF_Templates /examples/site/templates
    # optional or can be specified in Apache::JAF descendant (default value is used in example)
    PerlSetVar Apache_JAF_Modules /examples/site/modules/Apache/JAF/MyJAF/pages
    # optional or can be specified in Apache::JAF descendant (default value is used in example)
    PerlSetVar Apache_JAF_Compiled /tmp
  </Location>

=back

=head1 DESCRIPTION

=head2 Introduction

Apache::JAF is designed for creation web applications based on MVC (Model-View-Controller)
concept.

=over 4

=item * 

I<Modeller> is JAF descendant

=item *

I<Controller> is Apache::JAF descendant

=item *

and the I<Viewer> is set of the templates using Template-Toolkit markup syntax

=back

This separation hardly simplifies the dynamic development of sites by designers and programmers.
Each programmer works on own part of the project writing separate controller's parts. 
Designers have to work only on visual performance of templates.

=head2 Suggested file structure

Suggested site's on-disk structure is:

  site
   |
   +-- data
   |
   +-- modules
   |
   +-- templates

=over 4

=item I<data> 

document_root of site. All static files (e.g. JavaScripts, pictures, CSSs etc)
must be placed here

=item I<modules>

Storage place for site modules -- must be in C<@INC>'s

=item I<templates>

The place of your site's templates. Framework is designed to reproduce
site's structure in this folder. It's just like document_root for static site.

=back

=head2 Request processing pipeline

The C<Apache::JAF::handler> intercepts every request for specified location, and 
process it's own way:

=over 4

=item 1

If requested file exists then nothing happens. The handle declines request with C<DECLINE>.

=item 2

Otherwise the instance of Apache::JAF's descendant is created and C<setup_handler> method is called. 
You B<must override> this method and return determined handler's name. Usually it's the first part of 
URI or just C<index>. Also handlers from C<Apache_JAF_Modules> folder is loaded into package's 
namespace if C<$self-E<gt>{debug_level}> E<gt> 0 or handlers were not loaded during module
compilation.

=item 3

Then goes C<site_handler> calling. If you have common tasks for each handler you can
override it. C<site_handler> calls your own handler. It's name is returned by C<setup_handler>. 
Usually this "mini-handler" is I<very> simple. It have to be implemented as package method with
C<do_I<E<lt>handler nameE<gt>>> name. You have to fill C<$self-E<gt>{res}> hash with
result and return Apache constant according to handler's logic (C<OK>, C<NOT_FOUND>, 
C<FORBIDDEN> and so on). The sample is shown in L<"SYNOPSIS">.

=item 4

If the previous step fulfills correctly, and C<$self-E<gt>{type}> property is C<text/*> then
result of processing template returns to client. If type of result is not 
like text, one more method is needed to implement: C<on_send_I<E<lt>handeler nameE<gt>>_data>.
It must return binary data to client. This way you may create handlers for
dynamic generation of images, M$ Excel workbooks and any other type of data.

=back

=head2 Apache::JAF methods

=over 4

=item setup_handler

This method you must override in your Apache::JAF descendant. You must return handler's 
name (that will be called as I<do_E<lt>handler nameE<gt>> method later) from it depending 
on URI requested by user. You may set site-wide properties such as I<debug_level>, I<header> 
or I<footer>, templates and includes extensions and so on. If handler name depends on 
application logic implemented in modeller then you have to create modeller in this method 
and store it in I<m> property for later use.
The primary I<setup_handler> is shown in L<"SYNOPSIS">.

=item site_handler

You can override this method to provide common tasks for each of your page-handlers. For
example you may create instance of modeller class, provide some custom 
authorization/authentication or sessions handling and so on. You must call 
C<$selfE<gt>SUPER::site_handler> and return C<$self-E<gt>{status}> from it.

=back

=head2 Apache::JAF properties

=over 4

=item r

Current C<Apache::Request> object.

=item filter

Using C<Apache::Filter> flag.

=item uri

Reference to the array of current URI (splitted by slash). Usually you need to modify
it in L<"setup_handler"> method to determine page's handler name. Remained array will be passed
to the page-handler method as a list of parameters.

=item res

Hash reference that holds page-handler results.

=item expand_path

Boolean flag for complex-name-handlers changes '_' to '/' in handler's name. 
It provides real-like document tree in the templates folder.

=item debug_level

Look at B<Apache_JAF_Debug> in L<"CONFIGURATION"> section.

=item status

Default handler status is C<NOT_FOUND>.

=item type

Default content-type is C<text/html>. You can call C<$self-E<gt>download_type()> 
for set unexisting MIME-type to force browser download content instead of viewing it.

=item template_ext, include_ext

Default template extension is C<.html>.
Default include template extension is C<.inc>.

=item default_include

Site-wide include template. Default value is... C<default>.

=item header, footer

Site-wide pre- and post-include templates. Defalut values are C<header> and C<footer>.
I<Note:>You must undef this properies if you want create page-template without it. For
example for page in pop-up window (C<disable_header>, C<disable_footer>, and 
C<disable_header_footer> methods).

=item templates

Path to the templates folder. You may have different sets of templates for different
views of results generated by your page-handlers.

=item handler

Result of C<setup_handler> method is stored here for later use.

=item I<other properites>

For internal use only.

=back

=head2 Implementing handlers

Page handlers are simple. 
Their methods are with C<do_E<lt>handler nameE<gt>> name. You have to
analyse given parameters, fill out C<$self-E<gt>{res}> hash with handler results that will 
be processed with template and return one of C<Apache::Constants>. Usually it's C<OK>, 
but may be C<NOT_FOUND> if parameters passed to handlers are invalid for some reason.

Look into F<examples/*> folder in the distribution package for some guidelines.

=head2 Templates structure and syntax

Template for a specific handler consists of:

=over 4

=item 1 default.inc

Common C<[% BLOCK %]>s for all site templates. Processed before header and main tamplate.

=item 2 header.inc

Header template. Processed before main handler's template.

=item 3 I<E<lt>handler nameE<gt>>.html

Main handler's template.

=item 4 footer.inc

Footer template. Processed after main handler's template.

=back

Default names and extensions are shown. All of them are configurable in processing 
handler methods. For example you have to disable processing header and footer for 
handler that produces not C<text/*> content.

Templates syntax is described at L<http://www.template-toolkit.org/docs/plain/Manual/>.

=head1 CONFIGURATION

=over 4

=item Apache_JAF_Prefix

Number of URI parts (between slashes) or path that must be removed from request URI.
Useful for implementing dynamic part of almost static site. It simplifies names of page handlers.


=item Apache_JAF_Templates

Path to templates folder. Several paths may be separated by semicolon.
I<Win32 note>:
This separator works too. Don't get confused with full paths with drive
letters.

=item Apache_JAF_Modules

Path to page handlers folder. By default it's controller location plus C</pages>.

=item Apache_JAF_Compiled

Path to compiled templates folder. Default is C</tmp>.
Saving compiled templates on disk dramatically improves overall site performance.

=item Apache_JAF_Debug

Application's debug level. The amount of debug info written to the Apache error_log.
Ranges from 0 to 10.

 0: critical errors only
 1: request processing line
 2: client request
 3: response headers
 4: template variables
 5-8: not used (for future enchancements)
 9: loading additional handlers
 10: processed template

Also this setting affecting page-handlers loading. If debug level is 0 -- handlers 
are loaded only on server-start. Else handlers loaded on every request. That simplifies
development process but increases request processing time. So it's not good to set 
debug level greater than 0 in production environment.

I<Note:>
This setting is overrided by setting C<$self-E<gt>{debug_level}>.

=back

=head1 SEE ALSO

=over 4

=item * 

B<mod_perl> -- Perl and Apache integration project (L<http://perl.apache.org>)

=item *

B<Template-Toolkit> -- template processing system (L<http://www.tt2.org>)

=item *

F<examples/*> -- sample site driven by Apache::JAF

=item *

L<http://jaf.webzavod.ru> -- Apache::JAF companion website

=back

=head1 AUTHOR

Greg "Grishace" Belenky <greg@webzavod.ru>

=head1 COPYRIGHT

 Copyright (C) 2001-2003 Greg Belenky
 Copyright (C) 2002-2003 WebZavod (http://www.webzavod.ru) programming team

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut

'Grishace';
