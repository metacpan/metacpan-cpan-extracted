package DBIx::PasswordIniFile;

use strict;
use vars qw($VERSION $AUTOLOAD);

$VERSION = '2.00';

use DBI();
use Config::IniFiles;
use Crypt::CBC;       # Requires Crypt::Blowfish
use File::HomeDir;

my %connect_cache;

=head1 NAME

DBIx::PasswordIniFile - Manages DBI connections with password and other params stored in a C<.ini> style file.

=head1 SYNOPSIS

    use DBIx::PasswordIniFile;
    $conn = DBIx::PasswordIniFile->new( 
              -file    => 'path/to/config.ini',
              -section => 'database connection',
              -key     => 'encrypt and decrypt key',
              -cipher  => 'Blowfish'
    );

    $ary = $conn->getDBIConnectParams();
    $dbh = DBI->connect( @$ary ) or die $DBI::errstr;
    
    $encrypted_passw = $conn->changePassword('new_password');
    
    $encrypted = $conn->encryptPassword( 'clear_password' );
    $clear     = $conn->decryptPassword( $encrypted );
    
    
    # THIS METHODS ARE DEPRECATED:
    
    $conn->connect( \%attributes ); # or
    $conn->connect(); 

    $conn->connectCached( \%attributes ); # or
    $conn->connectCached();

    $conn = DBIx::PasswordIniFile->getCachedConnection( 'path/to/file.ini' );

    $hash_ref = DBIx::PasswordIniFile->getCache();

    $dbh = $conn->dbh();

=head1 DESCRIPTION

Manages DBI connection parameters stored in a C<.ini> style configuration file 
(really a C<Config::IniFiles> config file), with B<password stored 
encrypted>.

This module allows you to store L<DBI> C<connect> params in a C<.ini> style
configuration file, with password encrypted. C<.ini> configuration files are 
plain text files managed with C<Config::IniFiles> module. Once written, there 
is a command line utility called C<encpassw.pl> that re-writes the C<.ini> file,
encrypting the password. The same may be done programatically, calling 
C<changePassword> .

This module is similar to C<DBIx::Password>. The differences are that
DBI connection parameters aren't stored as part of the module source
code (but in an external C<.ini> style file), and that this module lets
you only one virtual user (i.e. one connection specification) per C<.ini> file. 

(THIS IS DEPRECATED) Like <DBIx::Password>, this is a subclass of DBI, so you
may call DBI function objects using C<DBIx::PasswordIniFile> objects.  

=head1 FUNCTIONS

=head2 new

    $conn = DBIx::PasswordIniFile->new( -file=>'path/to/file.ini', ...);

Creates a C<DBIx::PasswordIniFile> object from DBI connection parameters
specified in C<path/to/file.ini> file.

Apart from C<-file>, other (optional) arguments are:

=over 4

=item -section

    -section => 'db_config_section'

If specified, C<db_config_section> is the section name of C<.ini> file where
DBI connection parameters live.
If not specified, assumes that DBI connection parameters are in a section
with one of these names:

    dsn
    connect
    connection
    database
    db
    virtual user

If specified, but the section name doesn't exist, returns C<undef>.

!! IMPORTANT !!
There are two alternate models for the content of this section, the old one
being deprecated. See L<CONTENT OF C<.ini> file> for more info about what 
properties may be specified in this section of C<.ini> file.

=item -key and -cipher

    -key    => 'encrypt_decrypt_key'
    -cipher => 'name_of_encryption_module'

If specified, C<-key> and C<-cipher> are the encryption/decription key used for
storing/reading the password in C<.ini> file, and the cipher algoritm.

If not specified C<-key>, it's read from (with this order of preference):

  $HOME/.DEFAULT_KEY file 
  DBIx/DEFAULT_KEY file (from same dir as PasswordIniFile.pm)

(see L<FILES> for more info)

Because default value for C<-key> is stored in a file, it's a security break 
to not specify this argument.

If not specified C<-cipher>, it's assumed C<Blowfish>. Note at least one 
encription algorithm have to be installed (they live in C<Crypt::> spacename).

=back

Usage sample:

    use DBI;
    use DBIx::PasswordIniFile;
    
    $conn = new DBIx::PasswordIniFile( -file => 'my.ini');
    $ary = $conn->getDBIConnectParams;
    
    $dbh = DBI->connect( @$ary ) or die $DBI::errstr;

(DEPRECATED SAMPLE) Once a C<DBIx::PasswordIniFile> object is created, use it 
to call DBI object methods. For example:

    use DBIx::PasswordIniFile;
    $conn = new DBIx::PasswordIniFile( -file => 'my.ini');
    $conn->connect();
    ...
    $conn->disconnect(); # DBI object method.

=cut

sub new
{
    my $class = shift;
    my %args = @_;

    # Check that -file => $ini_file is a file
    return undef if !exists($args{-file}) || ! -e $args{-file};

    my $config = new Config::IniFiles( -file => $args{-file} );

    # If specified -section => $section, check it exists
    return undef if $args{-section} && ! $config->SectionExists($args{-section});

    my $section = $args{-section};
    if( ! $args{-section} )
    {
        # Search section and assign to $section
        my @sections = grep( /^(dsn|connect|connection|database|db|virtual user)$/i, 
                              $config->Sections() );
        return undef  if !@sections;

        $section = $sections[0];
    }

    return bless { 
                   config_  => $config, 
                   section_ => $section,
                   key_     => ( $args{-key} || &get_default_key_ ),
                   cipher_  => ( $args{-cipher} || 'Blowfish' ),
                   dbh_     => 'dbh_'

                 }, $class;
}

=head2 getDBIConnectParams

  $ary = $conn->getDBIConnectParams();

Reads from C<.ini> configuration file specified in C<new> and returns an array 
ref like this:

  [$dsn, $username, $password, $attributes]

Where C<$dsn>, C<$username> and C<$password> are strings (C<$password> in clear
form), and C<$attributes> is a hash ref with connect attributes.

You may call a DBI connect as this:

  $ary = $conn->getDBIConnectParams();
  DBI->connect( @$ary );

!! IMPORTANT !!

This method assumes a different content in section of configuration C<.ini> 
file specified in C<new>, than deprecated methods. See L<CONTENTS OF C<.ini> file>
for what parameters may be specified in C<.ini> file.

=cut

sub getDBIConnectParams
{
    my $self = shift;

    my( $config, $section) = ( $self->{config_},
                               $self->{section_} );
    
    # This is what we return
    my($dsn, $username, $password, $attributes);

    $dsn      = $config->val($section,'dsn'); 
    $username = $config->val($section,'user');
    $password = $config->val($section,'pass');
    
    # Don«t decrypt if value of pass parameter was undef
    $password = $self->decryptPassword( $password ) if defined($password);
 
    # This method, unlike deprecated getConnectParams_ , assumes attributes 
    # (%attr in DBI connect method) live in same file section.
    # All parameters distinct from 'dsn', 'user' and 'pass' are assumed to be
    # attributes.
    
    $attributes = {};
    foreach my $attr ( $config->Parameters($section) )
    {
        $attributes->{$attr} = $config->val($section,$attr)
            if $attr ne 'dsn' && $attr ne 'user' && $attr ne 'pass';
    }

    return [ $dsn, $username, $password, $attributes ];
}


=head2 changePassword

  $encrypted_passw = $conn->changePassword('new_clear_password')>

Replaces the encrypted password stored in C<.ini> file with the result of
encrypting C<new_clear_password> password (so, C<new_clear_password> is the new
password in clear form).

Returns the new encrypted password saved in C<.ini> file.

=cut

sub changePassword
{
    my $self = shift;
    my $pass = shift;

    my $encrypt_pass = $self->encryptPassword($pass);

    my $param;
    my $cfg = $self->{config_};
    
    $param = undef;
    $param = 'password' if $cfg->exists($self->{section_},'password') ;
    $param = 'pass' if $cfg->exists($self->{section_},'pass') ;
    
    if( ! $param )
    {
      # Not specified. Guess pass or password  
      # With old content model for .ini file, 'driver' param was mandatory,
      # and with new content model, this param does't exist.
      # So, existence or not existence of this param determines content model.
      #
      $param = ( $cfg->exists($self->{section_},'driver') 
                 ? 'password' 
                 : 'pass');
      $cfg->newval( $self->{section_}, $param, $encrypt_pass );
    }
    else
    {       
      $cfg->setval($self->{section_}, $param, $encrypt_pass);
    }
    
    $cfg->RewriteConfig();
    $cfg->ReadConfig();
            
    return $encrypt_pass;
}

=head2 encryptPassword

    $encrypted_password = $conn->encryptPassword( $clear_password );
    
Encrypts a clear password.

=cut

sub encryptPassword
{
    my $self = shift;
    my $pass = shift;
  
    my $cipher = Crypt::CBC->new( {'key'             => $self->{key_},
                                   'cipher'          => $self->{cipher_}
                                  });
    $cipher->start('Encript');
    my $ciphertext = $cipher->encrypt_hex($pass);
    $cipher->finish();
    
    return $ciphertext;
}

=head2 decryptPassword

    $clear_password = $conn->decryptPassword( $encrypted_password );
    
Decrypts an encrypted password.

=cut

sub decryptPassword
{
    my $self = shift;
    my $pass = shift;
  
    my $cipher = Crypt::CBC->new( {'key'             => $self->{key_},
                                   'cipher'          => $self->{cipher_}
                                  });
    $cipher->start('Decript');
    my $plaintext = $cipher->decrypt_hex($pass);
    $cipher->finish();
    
    return $plaintext;
}


=head2 C<$conn-E<gt>connect( [\%attributes] )>  (DEPRECATED)

Calls C<DBI-E<gt>connect> with values stored in C<.ini> file specified in 
C<new>. C<\%attributes> refers to last parameter of C<DBI-E<gt>connect>.

If specified, C<\%attributes> take precedence over any conflicting stored in
C<..._attributes> section of C<.ini> file.

=cut

sub connect
{
    my($self,$options) = @_;

    my @params = @{$self->getConnectParams_()};
    $params[-1] = { %{$params[-1]}, %$options } if $options && @params == 4;
    $params[3]  = $options if $options && @params == 3;
    $self->{dbh_} = DBI->connect( @params );

    return $self->{dbh_};
}

=head2 C<$conn-E<gt>connectCached( [\%attributes] )>  (DEPRECATED)

Same as C<connect>, but caches a copy of C<$conn> object.

Cached objects may be retrieved with L<C<getCachedConnection>>.

=cut

sub connectCached
{

    my($self,$options) = @_;
 
    my @params = @{$self->getConnectParams_()};
    $params[-1] = { %{$params[-1]}, %$options } if $options && @params == 4;
    $params[3]  = $options if $options && @params == 3;
    $self->{dbh_} = DBI->connect( @params );

    $connect_cache{$self} = $self;

    return $self->{dbh_};
}

=head2 C<$conn = DBIx::PasswordIniFile-E<gt>getCachedConnection( 'path/to/file.ini' )> (DEPRECATED)

Returns a valid C<DBIx::PasswordIniFile> object corresponding to the C<.ini>
file argument, if its C<connectCached> was launched. Or returns C<undef> if argument
doesn't correspond to a cached connection.

=cut

sub getCachedConnection
{
    my $class = shift;
    my $arg = shift;
    
    return undef if !$arg;

    foreach (keys %connect_cache)
    {
        my $cfg = $connect_cache{$_}->{config_};        
        return $connect_cache{$_} if $cfg->GetFileName() eq $arg;
    }
}

=head2 C<$cache = DBIx::PasswordIniFile-E<gt>getCache()>  (DEPRECATED)

Return a hash reference that is the cache. Keys are object references converted to
strings and values are valid C<DBIx::PasswordIniFile> objects.

=cut

sub getCache
{
    my $class = shift;
    return \%connect_cache;
}

=head2 C<$dbh = $conn-E<gt>dbh()>  (DEPRECATED)

Returns the DBI database handler object (a C<DBIx::PasswordIniFile> object
is a composition of a C<DBI> object among others).

=cut

sub dbh
{
    my $self = shift;
    return $self->{dbh_};
}

# =head2 get_default_key_
# 
#     $def_key = &get_default_key_;
#     
# Reads a default value for C<-key> argument from a .DEFAULT_KEY file in user's 
# home directory, or from a DEFAULT_KEY file in a @INC directory, the first one 
# found. In either case, reads the first line only.
# 
# =cut
                        
sub get_default_key_
{
    my $dot_default_key_filepath =
        File::Spec->catfile(File::HomeDir->my_home, '.DEFAULT_KEY');
        
    my $default_key_filepath = undef;
        
    unless( -e $dot_default_key_filepath )
    {
        my $fp = undef;
        foreach my $path ( @INC )
        {
            $fp = File::Spec->catfile($path, 'DBIx', 'DEFAULT_KEY');
            if( -e $fp )
            {
                $default_key_filepath = $fp; 
                last;  
            }
        }
    }
    else
    {
        $default_key_filepath = $dot_default_key_filepath;
    }
    
    die <<"DIE_MSG" if ! $default_key_filepath;
!! Cannot find $dot_default_key_filepath nor a DEFAULT_KEY file in \@INC.
   Perhaps this last was accidentally removed. Create a new one with your 
   default key, or specify -key in new. See perldoc __PACKAGE__ 
DIE_MSG
        
    open( my $fh, '<', $default_key_filepath ) or die $!;
    my $default_key = <$fh>; # one line only
    chomp($default_key);
    close $fh;
    
    return $default_key;
}

# =head2 getConnectParams_  (PRIVATE FUNCTION and DEPRECATED)
# 
#   $ary = $conn->getConnectParams_();
# 
# Reads from C<.ini> configuration file specified in C<new> and returns an array 
# ref like this:
# 
#   [$dsn, $username, $password, $attributes]
# 
# Where C<$dsn>, C<$username> and C<$password> are strings (C<$password> in clear
# form), and C<$attributes> is a hash ref with connect attributes.
# 
# You may call a DBI connect as this:
# 
#   $ary = $conn->getConnectParams_();
#   DBI->connect( @$ary );
# 
# =cut

sub getConnectParams_
{
    my $self = shift;

    my( $config, $section) = ( $self->{config_},
                               $self->{section_} );
    
    # This is what we return
    my($dsn, $username, $password, $attributes);

    my($driver,$database,$host,$port);
    $driver   = $config->val($section,'driver');
    $database = $config->val($section,'database');
    $host     = $config->val($section,'host');
    $port     = $config->val($section,'port');
    $dsn      = $config->val($section,'dsn');
 
    $dsn  = "DBI:ODBC:${dsn}" if uc($driver) eq 'ODBC';
    $dsn  = "DBI:${driver}:database=${database}" . 
                      ($host ? ";host=${host}" : '') .
                      ($port ? ";port=${port}" : '')  if uc($driver) ne 'ODBC';
  
    $username = $config->val($section,'username');
    $password = $config->val($section,'password');
    
    # Don't decrypt if password parameter is undef
    $password = $self->decryptPassword( $password ) if $password;
 
    # attributes are supposed live in a file section called "$section_attributes" 
    # (without double quotes). In this section, each parameter is an attribute
    # name.
    
    return [ $dsn, $username, $password ]
    if ! $config->SectionExists("${section}_attributes") ;

    $attributes = {};
    if( $config->SectionExists("${section}_attributes") )
    {
        foreach my $attr ( $config->Parameters("${section}_attributes") )
        {
            $attributes->{$attr} = $config->val("${section}_attributes",$attr);
        }
    }

    return [ $dsn, $username, $password, $attributes ];
}

##############################################################################
# AUTOLOAD function
# Magically executes functions of DBI  (DEPRECATED)
##############################################################################

sub AUTOLOAD
{
    my $self = shift;
    my @args = @_;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    # Suppose we are calling a DBI function.
    return $self->{dbh_}->$name(@args) if ref($self);
    return DBI->$name(@args) if ! ref($self);
}

sub DESTROY
{
    return;
}

1;

__END__

=head1 FILES

=head2 CONTENTS OF .ini FILE

As explained in documentation of C<new>, the file specified with C<-file> is
a plain text file with a syntax compatible with C<Config::IniFiles>. 
Briefly (for more info see L<Config::IniFiles> documentation):

=over 4

=item *

Basically, this kind of file contains B<sections> and B<parameter>/B<value> 
pairs. A parameter/value pair is specified as this:

  parameter = value

And being a section a group of parameter/value pairs:

  [section]
  parameter1 = value1
  parameter2 = value2
  ...

A section name is a string (including whitespaces) between C<[> and C<]>.

=item *

Lines beginning with C<#> are comments and are ignored. Also, blank lines are
ignored. Use this with readability purposes.

=back

This module assumes the config file has a section whose name is specified as

    $c = DBIx::PasswordIniFile( ... -section => $name ... );

Or one of the default section names if C<-section> argument is not specified (if
more than one default section names exist and no C<-section> is specified, the
first default section, in order of appearance, is assumed).

Well, this module assumes two alternate content models for this section, being
DEPRECATED one of both:

=over 4

=item *

The section specify these params:

   dsn   (mandatory)
   user  (optional)
   pass  (optional)

Being values of C<dsn>, C<user> and C<pass> the fist three params passed to 
C<DBI::connect> .

And all other parameters specified within the section are taken as connection
attributes (key/value pairs for C<$%attr> param of L<DBI::connect>) .

Sample:

  [database]
  dsn=dbi:mysql:database=suppliers;host=192.168.2.101;port=3306
  user=ecastilla 
  pass=52616e646f6d495621c18a03330fee46600ace348beeec28
  
(value of pass is encrypted with C<encpassw.pl> utility see C<perldoc 
encpassw.pl> for more info)

=item * (DEPRECATED)

The section specify this parameters:

    driver    (mandatory)
    database
    host
    port
    username
    password
    dsn

If C<driver=ODBC> then C<dsn>, C<username> and C<password> are mandatory, and
all other parameters are ignored.
If C<driver> isn't ODBC, then all parameters except C<database>, C<username>
and C<password> are optional.

Also, if attributes for connection have to be specified, specify them as 
parameters of another section with same name and C<_attributes> at the end.
For example, if your C<.ini> file has a C<connect> section, connection
attributes (if specified) are assumed to be in C<connection_attributes>
section. If has a C<virtual user> section, attributes are assumed to be
in C<virtual user_attributes>, and so on.

Properties/Values in C<..._attributes> section aren't predefined and are used
as key/value pairs for C<\%attr> argument when DBI C<connect> method is
called.

All propertie values are stored as plain text in C<.ini> file, except
C<password> value, that is stored encrypted using an encription
algorithm (default is Blowfish_PP).

Below is an example of C<.ini> file content:

    [db_config_section]
    driver=mysql
    database=suppliers
    host=www.freesql.org
    port=3306
    username=ecastilla
    password=52616e646f6d495621c18a03330fee46600ace348beeec28
  
    [db_config_section_attributes]
    PrintError=1
    RaiseError=0
    AutoCommit=1

This is an example owith ODBC:

    [db_config_section]
    driver=ODBC
    dsn=FreeSQL

=back

Other sections and properties of the C<.ini> file are ignored, and do not
cause any undesired effect. This lets you use non dedicated C<.ini> files
for storing DBI connection parameters.

=head2 DEFAULT_KEY file

When installed, a C<DEFAULT_KEY> (NO dot prefixed) file is created at the same
directory of C<PasswordIniFile.pm>. It stores a default key used when no C<-key> 
argument is specified in C<new> .

You may override this file creating your own C<.DEFAULT_KEY> (note dot prefixed)
file at your home directory.

In either case, content of this files is ONE line with a string used as key for
C<Crypt::CBC> algorithm.

=head1 SECURITY CONSIDERATIONS

In C<.ini> file, password is stored encrypted, and never in clear form. But note
that the mechanism is not completely secured because passwords are stored clear
in memory. A hack may do a memory dump and see the password.

Although with this limitation, I think the module is a good balance between security
and simplicity.

=head1 REQUISITES

Perl v5.8.6 or above has to be installed. If not, an error

   Free to wrong pool XXX not YYY during global destruction

is displayed, and Perl crashes.

An encription module has to be installed. Default is to use
C<Crypt::Blowfish> for encription and decription. If not installed Blowfish, 
specify your preferred (without C<Crypt::> prefix).

=head1 SEE ALSO

There is an utility called L<encpassw.pl> that takes a C<.ini> file
and replaces the C<pass/password> param value with its encrypted form.
 
L<DBI>, L<Config::IniFiles>, L<DBIx::Password>.

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2008 Enrique Castilla.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

This program is distributed in the hope that it will be useful, but without any 
warranty; without even the implied warranty of merchantability or fitness for a 
particular purpose. 

=head1 AUTHOR

Enrique Castilla E<lt>L<mailto:ecastillacontreras@yahoo.es|ecastillacontreras@yahoo.es>E<gt>.

