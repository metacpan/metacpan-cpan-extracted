package DBIx::FileStore::ConfigFile;
use strict;

use List::Util qw(first);
use File::Spec::Functions qw(catfile); # to concat dirs & filenames portably 
use Config::File;

use DBIx::FileStore::UtilityFunctions qw(get_user_homedir);

use fields qw( vars_hash verbose ); # you can set $obj->{verbose} for debugging

######################################
# my $conf = new DBIx::FileStore::ConfigFile() 
sub new {
    my DBIx::FileStore::ConfigFile $self = shift;
    unless (ref $self) {
        $self = fields::new($self);
    }
    return $self;
}


############################################
# my $hashref = $conf->read_config_file()
#  or
# my $hashref = $conf->read_config_file( "/etc/fdb-alternate.conf" )
sub read_config_file {
    my ($self, $opt_filename) = @_;

    # choose which config file we're going to use
    my $filename = $opt_filename;
    my $user_dotfile = catfile( get_user_homedir(), ".fdbrc" ); # ~/.fdbrc
    my $etc_conffile = "/etc/fdb.conf";
    unless( $filename ) {
        # explicit sub{} like this for perl 5.6.2
        $filename = first( sub { -e }, $user_dotfile, $etc_conffile );
    }

    unless($filename) {
        die ("$0: Can't find config file to open " . 
            "(tried $user_dotfile and $etc_conffile)\n");
    }
    print "$0: reading $filename\n" if $self->{verbose};

    $self->{vars_hash} = Config::File::read_config_file( $filename );

    # sanity check that there's a dbuser passed.
    unless( $self->{vars_hash}->{dbuser} ) {
        warn "$0: Can't find a 'dbuser' setting in $filename\n";
    }

    return $self->{vars_hash};
}

1;

=pod

=head1 NAME

DBIx::FileStore::ConfigFile -- Find and read filestore conf files.

=head1 SYNOPSIS

    my $conf = new DBIx::FileStore::ConfigFile();
    my $hashref = $conf->read_config_file();

    # these are the fields we use, along wth dbpasswd
    print "db: $hashref->{dbname}, user: $hashref->{dbuser}\n";

=head1 DESCRIPTION

Provides interface to read DBIx::FileStore configuration files.

The read_config_file() method reads from the optionally 
passed configuration file, the file .fdbrc in the user's 
home directory , or /etc/fdb.conf, whichever is found first.

=head1 METHODS

=over 4

=item new DBIx::FileStore::ConfigFile();

my $conf = new DBIx::FileStore::ConfigFile();

Returns a new DBIx::FileStore::ConfigFile object.  

=item $conf->read_config_file() 

my $conf_hash = $conf->read_config_file();

my $conf_hash = $conf->read_config_file( $filename )

Returns a hashref with the name/value pairs parsed from 
the configuration file. The settings expected by 
DBIx-Filestore are: dbname, dbuser, and dbpasswd.

If a $filename is passed by the caller, that file is used as 
the configuration file. Otherwise the module uses 
the file .fdbrc in the current user's home directory, 
or /etc/fdb.conf, whichever is found first. 

If no configuration file can be found, the method dies 
with an error message.

=back

=head1 COPYRIGHT

Copyright (c) 2010-2015 Josh Rabinowitz, All Rights Reserved.

=head1 AUTHORS

Josh Rabinowitz

=cut    

