
package Apache2::ASP::Config;

use strict;
use warnings 'all';
use Carp 'confess';
use base 'Apache2::ASP::ConfigNode';


#==============================================================================
sub new
{
  my ($class, $ref, $root) = @_;
  
  my $s = $class->SUPER::new( $ref );
  
  $s->init_server_root( $root );
  
  $s->_init_inc();
  
  foreach my $var ( $s->system->env_vars )
  {
    while( my ($key,$val) = each(%$var) )
    {
      $ENV{$key} = $val;
    }# end while()
  }# end foreach()
  
  map { $s->load_class( $_ ) } $s->system->load_modules;
  
  return $s;
}# end new()


#==============================================================================
sub _init_inc
{
  my $s = shift;
  
  my %saw = map { $_ => 1 } @INC;
  push @INC, grep { ! $saw{$_}++ } ( $s->system->libs, $s->web->handler_root );
}# end _init_inc()


#==============================================================================
sub init_server_root
{
  my ($s, $root) = @_;
  
  no warnings 'uninitialized';
  foreach( @{ $s->{system}->{libs}->{lib} } )
  {
    $_ =~ s/\@ServerRoot\@/$root/;
  }# end foreach()
  
  foreach( @{ $s->{system}->{settings}->{setting} } )
  {
    $_->{value} =~ s/\@ServerRoot\@/$root/;
  }# end foreach()
  
  foreach my $key (qw/ application handler media_manager_upload www page_cache /)
  {
    $s->{web}->{"$key\_root"} =~ s/\@ServerRoot\@/$root/;
  }# end foreach()
}# end init_server_root()


#==============================================================================
sub load_class
{
  my ($s, $class) = @_;
  
  (my $file = "$class.pm") =~ s/::/\//g;
  eval { require $file unless $INC{$file}; 1 }
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

Apache2::ASP::Config - Central configuration for Apache2::ASP

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

=head1 XML Config File

Apache2::ASP keeps all of its configuration inside of C</conf/apache2-asp-conf.xml>

Here is an example:

  <?xml version="1.0" ?>
  <configuration>

    <system>
      <post_processors>
  <!--
        <class>My::PostProcessor</class>
        <class>My::PostProcessor2</class>
  -->
      </post_processors>
      <libs>
        <lib>@ServerRoot@/lib</lib>
      </libs>
      
      <load_modules>
        <module>DBI</module>
      </load_modules>
      
      <env_vars>
        <var>
          <name>myvar</name>
          <value>value</value>
        </var>
        <var>
          <name>myvar2</name>
          <value>value2</value>
        </var>
      </env_vars>
      
      <settings>
        <setting>
          <name>mysetting</name>
          <value>value</value>
        </setting>
        <setting>
          <name>mysetting2</name>
          <value>value2</value>
        </setting>
      </settings>
    </system>
    
    <errors>
      <error_handler>My::ErrorHandler</error_handler>
      <mail_errors_to>jdrago_999@yahoo.com</mail_errors_to>
      
      <mail_errors_from>root@localhost</mail_errors_from>
      <smtp_server>localhost</smtp_server>
    </errors>
    
    <web>
      <application_name>DefaultApp</application_name>
      <application_root>@ServerRoot@</application_root>
      <handler_root>@ServerRoot@/handlers</handler_root>
      <media_manager_upload_root>@ServerRoot@/MEDIA</media_manager_upload_root>
      <www_root>@ServerRoot@/htdocs</www_root>
      <page_cache_root>@ServerRoot@/PAGE_CACHE</page_cache_root>
      <request_filters>
  <!--
        <filter>
          <uri_match>/.*</uri_match>
          <class>My::MemberFilter</class>
        </filter>
        <filter>
          <uri_equals>/index.asp</uri_equals>
          <class>My::MemberFilter2</class>
        </filter>
  -->
      </request_filters>
      
    </web>
    
    <data_connections>
      <session>
        <manager>Apache2::ASP::SessionStateManager::SQLite</manager>
        <cookie_name>session-id</cookie_name>
        <dsn>DBI:SQLite:dbname=/tmp/apache2_asp_applications</dsn>
        <username></username>
        <password></password>
        <session_timeout>30</session_timeout>
      </session>
      <application>
        <manager>Apache2::ASP::ApplicationStateManager::SQLite</manager>
        <dsn>DBI:SQLite:dbname=/tmp/apache2_asp_applications</dsn>
        <username></username>
        <password></password>
      </application>
      <main>
        <dsn>DBI:SQLite:dbname=/tmp/apache2_asp_applications</dsn>
        <username></username>
        <password></password>
      </main>
      
    </data_connections>
    
  </configuration>

=head1 DESCRIPTION

=head1 PUBLIC PROPERTIES

=head1 PUBLIC METHODS

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut

