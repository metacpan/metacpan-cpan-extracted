
package ASP4::Config;

use strict;
use warnings 'all';
use Carp 'confess';
use base 'ASP4::ConfigNode';


sub new
{
  my ($class, $ref, $root) = @_;
  
  my $s = $class->SUPER::new( $ref );
  
  $s->init_server_root( $root );
  
  $s->_init_inc();
  
  my $vars = $s->system->env_vars;
  foreach my $var ( keys %$vars )
  {
    $ENV{$var} = $vars->{$var};
  }# end foreach()
  
  map { $s->load_class( $_ ) } $s->system->load_modules;
  
  return $s;
}# end new()


sub _init_inc
{
  my $s = shift;
  
  my %saw = map { $_ => 1 } @INC;
  my $web = $s->web;
  push @INC, grep { ! $saw{$_}++ } ( $s->system->libs, $web->handler_root, $web->page_cache_root );
}# end _init_inc()


sub init_server_root
{
  my ($s, $root) = @_;
  
  my $project_root = (sub{
    my @parts = split /\//, $root;
    pop(@parts);
    join '/', @parts;
  })->();
  $s->{web}->{project_root} = $project_root;
  no warnings 'uninitialized';
  foreach( @{ $s->{system}->{libs} } )
  {
    $_ =~ s/\@ServerRoot\@/$root/;
    $_ =~ s/\@ProjectRoot\@/$project_root/;
  }# end foreach()
  
  my $settings = $s->{system}->{settings};
  foreach( keys %$settings )
  {
    $settings->{$_} =~ s/\@ServerRoot\@/$root/;
    $settings->{$_} =~ s/\@ProjectRoot\@/$project_root/;
  }# end foreach()
  
  foreach my $key (qw/ application handler www page_cache /)
  {
    $s->{web}->{"$key\_root"} =~ s/\@ServerRoot\@/$root/;
    $s->{web}->{"$key\_root"} =~ s/\@ProjectRoot\@/$project_root/;
    $s->{web}->{"$key\_root"} =~ s{\\\\}{\\}g;
  }# end foreach()
  $s->{web}->{project_root} = $project_root;
  
  # Just in case we're dealing with a file-based db like SQLite:
  foreach my $key (qw/ session main /)
  {
    $s->{data_connections}->{$key}->{dsn} =~ s/\@ServerRoot\@/$root/;
    $s->{data_connections}->{$key}->{dsn} =~ s/\@ProjectRoot\@/$project_root/;
    $s->{data_connections}->{$key}->{dsn} =~ s{\\\\}{\\}g;
  }# end foreach()
  
  # Make sure that $s->page_cache_root exists:
  unless( $s->{web}{page_cache_root} )
  {
    if( $^O =~ m{win32}i )
    {
      my $temp_root = $ENV{TMP} || $ENV{TEMP};
      $s->{web}{page_cache_root} = "$temp_root\\PAGE_CACHE";
    }
    else
    {
      $s->{web}{page_cache_root} = "/tmp/PAGE_CACHE";
    }# end if()
  }# end unless()
   
  unless( -d $s->{web}{page_cache_root} )
  {
    my @parts = split /[\/\\]/, $s->{web}{page_cache_root};
    my $root = $^O =~ m{win32}i ? '' : "/";
    while( my $next = shift(@parts) )
    {
      $root .= "$next/";
      mkdir($root) unless -d $root;
      die "Cannot create path to '@{[ $s->web->page_cache_root ]}' - stopped at '$root': $!"
        unless -d $root;
      chmod(0777, $root);
    }# end while()
  }# end unless()
  
  (my $compiled_root = $s->{web}->{page_cache_root} . '/' . $s->{web}->{application_name}) =~ s/::/\//g;
  my $folder = $^O =~ m{win32}i ? '' : "/";
  foreach my $part ( grep { $_ } split /[\/\\]/, $compiled_root )
  {
    $folder .= "$part/";
    unless( -d $folder )
    {
      mkdir($folder);
      chmod(0777, $folder)
    }# end unless()
    confess "Folder '$folder' does not exist and cannot be created"
      unless -d $folder;
  }# end foreach()
  
  confess "Folder '$folder' exists but cannot be written to"
    unless -w $folder;
}# end init_server_root()


sub load_class
{
  my ($s, $class) = @_;
  
  (my $file = "$class.pm") =~ s/::/\//g;
  eval { require $file; }
    or confess "Cannot load $class: $@";
}# end load_class()


sub DESTROY
{
  my $s = shift;
  undef(%$s);
}


1;# return true:

=pod

=head1 NAME

ASP4::Config - Central configuration for ASP4

=head1 SYNOPSIS

  # Settings:
  $Config->system->settings->some_setting;
  $Config->system->settings->another_setting;
  
  # Error-handling:
  $Config->errors->error_handler;
  $Config->errors->mail_errors_to;
  $Config->errors->mail_errors_from;
  $Config->errors->smtp_server;
  
  # Web:
  $Config->web->application_name;
  $Config->web->application_root;
  $Config->web->project_root;
  $Config->web->www_root;
  $Config->web->handler_root;
  $Config->web->media_manager_upload_root;
  $Config->web->page_cache_root;
  
  # Data Connections:
  foreach my $conn ( map { $Config->data_connections->$_ } qw/ session application main / )
  {
    my $dbh = DBI->connect(
      $conn->dsn,
      $conn->username,
      $conn->password
    );
  }# end foreach()

=head1 JSON Config File

ASP4::ASP keeps all of its configuration inside of C</conf/asp4-config.json>

Here is an example:

  {
    "system": {
      "post_processors": [
        
      ],
      "libs": [
        "@ServerRoot@/lib",
        "@ProjectRoot@/lib"
      ],
      "load_modules": [
        "DBI",
        "DBD::SQLite"
      ],
      "env_vars": {
        "myvar":        "Some-Value",
        "another_var":  "Another Value"
      },
      "settings": {
        "foo": "bar",
        "baz": "bux"
      }
    },
    "errors": {
      "error_handler":    "ASP4::ErrorHandler",
      "mail_errors_to":   "you@yours.com",
      "mail_errors_from": "root@localhost",
      "smtp_server":      "localhost"
    },
    "web": {
      "application_name": "DefaultApp",
      "application_root": "@ServerRoot@",
      "www_root":         "@ServerRoot@/htdocs",
      "handler_root":     "@ServerRoot@/handlers",
      "page_cache_root":  "/tmp/PAGE_CACHE",
      "handler_resolver": "ASP4::HandlerResolver",
      "handler_runner":   "ASP4::HandlerRunner",
      "filter_resolver":  "ASP4::FilterResolver",
      "request_filters": [
        {
          "uri_match":  "^/.*",
          "class":      "My::Filter"
        }
      ],
      "disable_persistence": [
        {
          "uri_match":            "^/handlers/dev\\.speed",
          "disable_session":      true
        },
        {
          "uri_match":            "^/index\\.asp",
          "disable_session":      true
        }
      ]
    },
    "data_connections": {
      "session": {
        "manager":          "ASP4::SessionStateManager",
        "cookie_name":      "session-id",
        "cookie_domain":    ".mysite.com",
        "session_timeout":  30,
        "dsn":              "DBI:SQLite:dbname=/tmp/db_asp4",
        "username":         "",
        "password":         ""
      },
      "main": {
        "dsn":      "DBI:SQLite:dbname=/tmp/db_asp4",
        "username": "",
        "password": ""
      }
    }
  }

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut


