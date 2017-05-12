#!/usr/bin/perl -w

package Apache::Sling::LDAPSynch;

use 5.008001;
use strict;
use warnings;
use Carp;
use Getopt::Long qw(:config bundling);
use Apache::Sling;
use Apache::Sling::Authn;
use Apache::Sling::Content;
use Apache::Sling::User;
use Data::Dumper;
use Fcntl ':flock';
use File::Temp;
use Net::LDAP;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = qw(command_line);

our $VERSION = '0.27';

#{{{sub new

sub new {
    my (
        $class, $ldap_host, $ldap_base, $filter,  $dn,
        $pass,  $authn,     $disabled,  $verbose, $log
    ) = @_;
    if ( !defined $authn ) { croak 'no authn provided!'; }
    $disabled = ( defined $disabled ? $disabled : q(sling:disabled) );
    $filter   = ( defined $filter   ? $filter   : q(uid) );
    $verbose  = ( defined $verbose  ? $verbose  : 0 );

    # Directory containing the cache and user_list files:
    my $synch_cache_path =
      q(_user/a/ad/admin/private/ldap_synch_cache_system_files);

    # Directory containing backups of the cache and user_list files:
    my $synch_cache_backup_path =
      q(_user/a/ad/admin/private/ldap_synch_cache_system_files_backup);

# List of specific users previously ingested in to the sling system and their status:
    my $synch_cache_file = q(cache.txt);

   # List of specific ldap users that are to be ingested in to the sling system:
    my $synch_user_list = q(user_list.txt);
    my $ldap;
    my $content = Apache::Sling::Content->new( $authn, $verbose, $log )
      or croak q(Problem creating Sling content object!);
    my $user = Apache::Sling::User->new( $authn, $verbose, $log )
      or croak q(Problem creating Sling user object!);
    my $ldap_synch = {
        CacheBackupPath => $synch_cache_backup_path,
        CachePath       => $synch_cache_path,
        CacheFile       => $synch_cache_file,
        Content         => \$content,
        Disabled        => $disabled,
        LDAP            => \$ldap,
        LDAPbase        => $ldap_base,
        LDAPDN          => $dn,
        LDAPHost        => $ldap_host,
        LDAPPass        => $pass,
        Filter          => $filter,
        Log             => $log,
        Message         => q(),
        User            => \$user,
        UserList        => $synch_user_list,
        Verbose         => $verbose
    };
    bless $ldap_synch, $class;
    return $ldap_synch;
}

#}}}

#{{{sub ldap_connect

sub ldap_connect {
    my ($class) = @_;
    $class->{'LDAP'} = Net::LDAP->new( $class->{'LDAPHost'} )
      or croak 'Problem opening a connection to the LDAP server!';
    if ( defined $class->{'LDAPDN'} && defined $class->{'LDAPPASS'} ) {
        my $mesg = $class->{'LDAP'}->bind(
            $class->{'LDAPDN'},
            password => $class->{'LDAPPASS'},
            version  => '3'
        ) or croak 'Problem with authenticated bind to LDAP server!';
    }
    else {
        my $mesg = $class->{'LDAP'}->bind( version => '3' )
          or croak 'Problem with anonymous bind to LDAP server!';
    }
    return 1;
}

#}}}

#{{{sub ldap_search

sub ldap_search {
    my ( $class, $search, $attrs ) = @_;
    $class->ldap_connect;
    return $class->{'LDAP'}->search(
        base   => $class->{'LDAPbase'},
        scope  => 'sub',
        filter => "$search",
        attrs  => $attrs
    )->as_struct;
}

#}}}

#{{{sub init_synch_cache

sub init_synch_cache {
    my ($class) = @_;
    if ( !${ $class->{'Content'} }
        ->check_exists( $class->{'CachePath'} . q(/) . $class->{'CacheFile'} ) )
    {
        my ( $tmp_cache_file_handle, $tmp_cache_file_name ) =
          File::Temp::tempfile();
        my %synch_cache;
        print {$tmp_cache_file_handle}
          Data::Dumper->Dump( [ \%synch_cache ], [qw( synch_cache )] )
          or croak q(Unable to print initial data dump of synch cache to file!);
        close $tmp_cache_file_handle
          or croak
q(Problem closing temporary file handle when initializing synch cache);
        ${ $class->{'Content'} }
          ->upload_file( $tmp_cache_file_name, $class->{'CachePath'},
            $class->{'CacheFile'} )
          or croak q(Unable to initialize LDAP synch cache file!);
        unlink $tmp_cache_file_name
          or croak
          q(Problem clearing up temporary file after init of synch cache!);
    }
    return 1;
}

#}}}

#{{{sub get_synch_cache

sub get_synch_cache {
    my ($class) = @_;
    $class->init_synch_cache();
    if ( !${ $class->{'Content'} }
        ->check_exists( $class->{'CachePath'} . q(/) . $class->{'CacheFile'} ) )
    {
        croak q(No synch cache file present - initialization must have failed!);
    }
    ${ $class->{'Content'} }
      ->view_file( $class->{'CachePath'} . q(/) . $class->{'CacheFile'} )
      or croak q(Problem viewing synch cache file);
    my $synch_cache;
    my $success = eval ${ $class->{'Content'} }->{'Message'};
    if ( !defined $success ) {
        croak q{Error parsing synchronized cache dump.};
    }
    return $synch_cache;
}

#}}}

#{{{sub update_synch_cache

sub update_synch_cache {
    my ( $class, $synch_cache ) = @_;
    my ( $tmp_cache_file_handle, $tmp_cache_file_name ) =
      File::Temp::tempfile();
    print {$tmp_cache_file_handle}
      Data::Dumper->Dump( [$synch_cache], [qw( synch_cache )] )
      or croak q(Unable to print data dump of synch cache to file!);
    close $tmp_cache_file_handle
      or croak
      q(Problem closing temporary file handle when updating synch cache);
    ${ $class->{'Content'} }
      ->upload_file( $tmp_cache_file_name, $class->{'CachePath'},
        $class->{'CacheFile'} )
      or croak q(Unable to update LDAP synch cache file!);
    my $time = time;
    ${ $class->{'Content'} }
      ->upload_file( $tmp_cache_file_name, $class->{'CacheBackupPath'},
        "cache$time.txt" )
      or croak q(Unable to create LDAP synch cache backup file!);
    unlink $tmp_cache_file_name
      or croak
      q(Problem clearing up temporary file after updating synch cache!);
    return 1;
}

#}}}

#{{{sub get_synch_user_list

sub get_synch_user_list {
    my ($class) = @_;
    if ( !${ $class->{'Content'} }
        ->check_exists( $class->{'CachePath'} . q(/) . $class->{'UserList'} ) )
    {
        croak q(No user list file present - you need to create one!);
    }
    ${ $class->{'Content'} }
      ->view_file( $class->{'CachePath'} . q(/) . $class->{'UserList'} )
      or croak q(Problem viewing synch user list);
    my $synch_user_list;
    my $success = eval ${ $class->{'Content'} }->{'Message'};
    if ( !defined $success ) {
        croak q{Error parsing synchronized user list dump.};
    }
    return $synch_user_list;
}

#}}}

#{{{sub update_synch_user_list

sub update_synch_user_list {
    my ( $class, $synch_user_list ) = @_;
    my ( $tmp_user_list_file_handle, $tmp_user_list_file_name ) =
      File::Temp::tempfile();
    print {$tmp_user_list_file_handle}
      Data::Dumper->Dump( [$synch_user_list], [qw( synch_user_list )] )
      or croak q(Unable to print data dump of synch user list to file!);
    close $tmp_user_list_file_handle
      or croak
      q(Problem closing temporary file handle when writing synch user list);
    ${ $class->{'Content'} }
      ->upload_file( $tmp_user_list_file_name, $class->{'CachePath'},
        $class->{'UserList'} )
      or croak
      q(Unable to upload LDAP synch user list file into sling instance!);
    Apache::Sling::Print::print_result( ${ $class->{'Content'} } );
    my $time = time;
    ${ $class->{'Content'} }
      ->upload_file( $tmp_user_list_file_name, $class->{'CacheBackupPath'},
        "user_list$time.txt" )
      or croak q(Unable to create LDAP synch user list backup file!);
    unlink $tmp_user_list_file_name
      or croak
      q(Problem clearing up temporary file after updating synch user list!);
    return 1;
}

#}}}

#{{{sub download_synch_user_list

sub download_synch_user_list {
    my ( $class, $user_list_file ) = @_;
    my $synch_user_list = $class->get_synch_user_list;
    foreach my $user ( sort keys %{$synch_user_list} ) {
        if ( open my $out, '>>', $user_list_file ) {
            flock $out, LOCK_EX;
            print {$out} $user . "\n"
              or croak
              q(Problem printing when downloading synchronized user list!);
            flock $out, LOCK_UN;
            close $out
              or croak
q(Problem closing file handle when downloading synchronized user list!);
        }
        else {
            croak q(Could not open file to download synchronized user list to!);
        }
    }
    $class->{'Message'} =
      "Successfully downloaded user list to $user_list_file!";
    return 1;
}

#}}}

#{{{sub upload_synch_user_list

sub upload_synch_user_list {
    my ( $class, $user_list_file ) = @_;
    my %user_list_hash;
    if ( open my ($input), '<', $user_list_file ) {
        while (<$input>) {
            chomp;
            $user_list_hash{$_} = 1;
        }
        close $input or croak q(Problem closing upload user list file handle!);
    }
    else {
        croak q(Unable to open synch user list file to parse for upload!);
    }
    $class->update_synch_user_list( \%user_list_hash );
    $class->{'Message'} =
q(Successfully uploaded user list for use in subsequent synchronizations!);
    return 1;
}

#}}}

#{{{sub parse_attributes

sub parse_attributes {
    my ( $ldap_attrs, $sling_attrs, $ldap_attrs_array, $sling_attrs_array ) =
      @_;
    if ( defined $ldap_attrs_array && defined $sling_attrs_array ) {
        if ( defined $ldap_attrs ) {
            @{$ldap_attrs_array} = split /,/msx, $ldap_attrs;
        }
        if ( defined $sling_attrs ) {
            @{$sling_attrs_array} = split /,/msx, $sling_attrs;
        }
        if ( @{$ldap_attrs_array} != @{$sling_attrs_array} ) {
            croak
q(Number of ldap attributes must match number of sling attributes, )
              . @{$ldap_attrs_array} . ' != '
              . @{$sling_attrs_array};
        }
    }
    return 1;
}

#}}}

#{{{sub check_for_property_modifications

sub check_for_property_modifications {
    my ( $new_properties, $cached_properties ) = @_;
    foreach my $property_key ( keys %{$new_properties} ) {
        if ( !defined $cached_properties->{$property_key} ) {

            # Found a newly specified property:
            return 1;
        }
        if ( $new_properties->{$property_key} ne
            $cached_properties->{$property_key} )
        {

            # Found a modified property:
            return 1;
        }
    }
    return 0;
}

#}}}

#{{{sub perform_synchronization

sub perform_synchronization {
    my ( $class, $array_of_dns, $search_result, $seen_user_ids, $synch_cache,
        $ldap_attrs_array, $sling_attrs_array )
      = @_;
    foreach my $dn ( @{$array_of_dns} ) {
        my $valref  = $search_result->{$dn};
        my $index   = 0;
        my $user_id = @{ $valref->{ $class->{'Filter'} } }[0];
        $seen_user_ids->{$user_id} = 1;
        my @properties_array;
        my %properties_hash;
        foreach my $ldap_attr ( @{$ldap_attrs_array} ) {
            my $value = @{ $valref->{$ldap_attr} }[0];
            if ( defined $value ) {
                push @properties_array,
                  @{$sling_attrs_array}[$index] . q(=) . $value;
                $properties_hash{ @{$sling_attrs_array}[$index] } = $value;
            }
            $index++;
        }
        if ( defined $synch_cache->{$user_id} ) {

            # We already know about this user from a previous run:
            if ( $synch_cache->{$user_id}->{ $class->{'Disabled'} } eq '1' ) {

                # User was previously disabled. Re-enabling:
                push @properties_array, $class->{'Disabled'} . '=0';
                print "Re-enabling previously disabled user: $user_id\n"
                  or croak q{Problem printing!};
                ${ $class->{'User'} }->update( $user_id, \@properties_array )
                  or croak q(Problem re-enabling user in sling instance!);
                $synch_cache->{$user_id} = \%properties_hash;
                $synch_cache->{$user_id}->{ $class->{'Disabled'} } = '0';
            }
            else {

                # User is enabled in sling already, check for modifications:
                if (
                    check_for_property_modifications(
                        \%properties_hash, \%{ $synch_cache->{$user_id} }
                    )
                  )
                {

                    # Modifications are present, so we need to update:
                    print "Updating existing user $user_id\n"
                      or croak q{Problem printing!};
                    ${ $class->{'User'} }
                      ->update( $user_id, \@properties_array )
                      or croak q(Problem updating user in sling instance!);
                    $properties_hash{ $class->{'Disabled'} } = '0';
                    $synch_cache->{$user_id} = \%properties_hash;
                }
                else {

                    # No modifications present, nothing to do!
                    print "No user modifications, skipping: $user_id\n"
                      or croak q{Problem printing!};
                }
            }
        }
        else {

            # We have never seen this user before:
            print "Creating new user: $user_id\n" or croak q{Problem printing!};
            ${ $class->{'User'} }
              ->add( $user_id, 'password', \@properties_array )
              or croak q(Problem adding new user to sling instance!);
            $properties_hash{ $class->{'Disabled'} } = '0';
            $synch_cache->{$user_id} = \%properties_hash;
        }
    }
    return 0;
}

#}}}

#{{{sub synch_full

sub synch_full {
    my ( $class, $ldap_attrs, $sling_attrs ) = @_;
    my $search = q{(} . $class->{'Filter'} . q{=*)};
    my @ldap_attrs_array;
    my @sling_attrs_array;
    parse_attributes( $ldap_attrs, $sling_attrs, \@ldap_attrs_array,
        \@sling_attrs_array )
      or croak q(Problem parsing attributes!);

    # We need to capture the id as well as any attributes:
    unshift @ldap_attrs_array, $class->{'Filter'};
    my $search_result = $class->ldap_search( $search, \@ldap_attrs_array );
    shift @ldap_attrs_array;

    my $synch_cache = $class->get_synch_cache;
    my %seen_user_ids;

    # process each DN using it as a key
    my @array_of_dns = sort keys %{$search_result};

    $class->perform_synchronization(
        \@array_of_dns, $search_result,     \%seen_user_ids,
        $synch_cache,   \@ldap_attrs_array, \@sling_attrs_array
    );

    # Clean up records no longer in ldap:
    my @disable_property;
    push @disable_property, $class->{'Disabled'} . '=1';
    foreach my $cache_entry ( sort keys %{$synch_cache} ) {
        if ( $synch_cache->{$cache_entry}->{ $class->{'Disabled'} } eq '0'
            && !defined $seen_user_ids{$cache_entry} )
        {
            print
"Disabling user record in sling that no longer exists in ldap: $cache_entry\n"
              or croak q{Problem printing!};
            ${ $class->{'User'} }->update( $cache_entry, \@disable_property )
              or croak q(Problem disabling user in sling instance!);
            $synch_cache->{$cache_entry}->{ $class->{'Disabled'} } = '1';
        }
    }
    $class->update_synch_cache($synch_cache);

    $class->{'Message'} = 'Successfully performed a full synchronization!';
    return 1;
}

#}}}

#{{{sub synch_full_since

sub synch_full_since {
    my ( $class, $ldap_attrs, $sling_attrs, $synch_since ) = @_;
    my $search = q{(modifytimestamp>=} . $synch_since . q{)};
    my $search_result = $class->ldap_search( $search, $ldap_attrs );
    croak q(Function not yet fully supported!);

    # return 1;
}

#}}}

#{{{sub synch_listed

sub synch_listed {
    my ( $class, $ldap_attrs, $sling_attrs ) = @_;
    my $search = q{(} . $class->{'Filter'} . q{=*)};
    my $search_result = $class->ldap_search( $search, $ldap_attrs );
    croak q(Function not yet fully supported!);

    # return 1;
}

#}}}

#{{{sub synch_listed_since

sub synch_listed_since {
    my ( $class, $ldap_attrs, $sling_attrs, $synch_since ) = @_;
    my $search = q{(} . $class->{'Filter'} . q{=*)};
    my $search_result = $class->ldap_search( $search, $ldap_attrs );
    croak q(Function not yet fully supported!);

    # return 1;
}

#}}}

#{{{ sub command_line
sub command_line {
    my ( $ldap_synch, @ARGV ) = @_;
    my $sling = Apache::Sling->new;
    my $config = $ldap_synch->config( $sling, @ARGV );
    return $ldap_synch->run( $sling, $config );
}

#}}}

#{{{sub config

sub config {
    my ( $ldap_synch, $sling, @ARGV ) = @_;
    my $ldap_synch_config = $ldap_synch->config_hash( $sling, @ARGV );

    GetOptions(
        $ldap_synch_config,      'auth=s',
        'help|?',                 'log|L=s',
        'man|M',                  'pass|p=s',
        'threads|t=s',            'url|U=s',
        'user|u=s',               'verbose|v+',
        'download-user-list',     'ldap-attributes|a=s',
        'ldap-base|b=s',          'ldap-dn|d=s',
        'ldap-filter|f=s',        'ldap-host|h=s',
        'ldap-pass|P=s',          'attributes|A=s',
        'synch-full|s',           'synch-full-since|S=s',
        'synch-listed|l',         'synch-listed-since',
        'upload-user-list'
    ) or $ldap_synch->help();

    return $ldap_synch_config;
}

#}}}

#{{{sub config_hash

sub config_hash {
    my ( $ldap_synch, $sling, @ARGV ) = @_;
    my $attributes;
    my $download_user_list;
    my $flag_disabled;
    my $ldap_attributes;
    my $ldap_base;
    my $ldap_dn;
    my $ldap_filter;
    my $ldap_host;
    my $ldap_pass;
    my $synch_full;
    my $synch_full_since;
    my $synch_listed;
    my $synch_listed_since;
    my $upload_user_list;

    my %ldap_synch_config = (
        'auth'               => \$sling->{'Auth'},
        'help'               => \$sling->{'Help'},
        'log'                => \$sling->{'Log'},
        'man'                => \$sling->{'Man'},
        'pass'               => \$sling->{'Pass'},
        'threads'            => \$sling->{'Threads'},
        'url'                => \$sling->{'URL'},
        'user'               => \$sling->{'User'},
        'verbose'            => \$sling->{'Verbose'},
        'attributes'         => $attributes,
        'download-user-list' => $download_user_list,
        'flag-disabled'      => $flag_disabled,
        'ldap-attributes'    => $ldap_attributes,
        'ldap-base'          => $ldap_base,
        'ldap-dn'            => $ldap_dn,
        'ldap-filter'        => $ldap_filter,
        'ldap-host'          => $ldap_host,
        'ldap-pass'          => $ldap_pass,
        'synch-full'         => $synch_full,
        'synch-full-since'   => $synch_full_since,
        'synch-listed'       => $synch_listed,
        'synch-listed-since' => $synch_listed_since,
        'upload-user-list'   => $upload_user_list
    );

    return \%ldap_synch_config;
}

#}}}

#{{{ sub help
sub help {

    print <<"EOF";
Usage: perl $0 [-OPTIONS [-MORE_OPTIONS]] [--] [PROGRAM_ARG1 ...]
The following options are accepted:

 --attributes or -a (attribs)          - Comma separated list of attributes.
 --auth (type)                         - Specify auth type. If ommitted, default is used.
 --download-user-list (userList)       - Download user list to file userList
 --flag-disabled or -f                 - property to denote user should be disabled.
 --help or -?                          - View the script synopsis and options.
 --ldap-attributes or -A (attribs)     - Specify ldap attributes to be updated.
 --ldap-base or -B (ldapBase)          - Specify ldap base to synchronize users from.
 --ldap-dn or -D (ldapDN)              - Specify ldap DN for authentication.
 --ldap-filter or -F (filter)          - Specify ldap attribute to search for users with.
 --ldap-host or -H (host)              - Specify ldap host to synchronize from.
 --ldap-pass or -P (pass)              - Specify ldap pass for authentication.
 --log or -L (log)                     - Log script output to specified log file.
 --man or -M                           - View the full script documentation.
 --pass or -p (password)               - Password of user performing actions.
 --synch-full or -s                    - Perform a full synchronization from ldap to sling.
 --synch-full-since or -S (since)      - Perform a full synchronization from ldap to sling using changes since specified time.
 --synch-listed or -l                  - Perform a sychronization of listed users from ldap to sling.
 --synch-listed-since (since)          - Perform a sychronization of listed users from ldap to sling using changes since specified time.
 --upload-user-list (userList)         - Upload user list specified by file userList.
 --url or -U (URL)                     - URL for system being tested against.
 --user or -u (username)               - Name of user to perform any actions as.
 --verbose or -v or -vv or -vvv        - Increase verbosity of output.

Options may be merged together. -- stops processing of options.
Space is not required between options and their arguments.
For full details run: perl $0 --man
EOF

    return 1;
}

#}}}

#{{{ sub man
sub man {

    my ($ldap_synch) = @_;

    print <<'EOF';
LDAP synchronization perl script. Provides a means of synchronizing user
information from an LDAP server into a running sling instance from the command
line. The script also acts as a reference implementation for the LDAPSynch perl
library.

EOF

    $ldap_synch->help();

    print <<"EOF";
Example Usage

* Upload a restricted list of users (one id per line of specified file) to use in synchronizations:

 perl $0 --upload-user-list user_list.txt --sling-host http://localhost:8080 --sling-user admin --sling-pass admin

* Download a previously specified list of users to be synchronized to a specified file:

 perl $0 --download-user-list user_list.txt --sling-host http://localhost:8080 --sling-user admin --sling-pass admin

* Authenticate and perform a full synchronization:

 perl $0 -s -h ldap://ldap.org -b "ou=people,o=ldap,dc=org" -H http://localhost:8080 -u admin -P admin -a "displayname,mail,sn" -A "name,email,surname"
EOF

    return 1;
}

#}}}

#{{{sub run
sub run {
    my ( $ldap_synch, $sling, $config ) = @_;
    if ( !defined $config ) {
        croak 'No ldap_synch config supplied!';
    }
    $sling->check_forks;

    my $authn = new Apache::Sling::Authn( \$sling );
    $authn->login_user();

    my $success = 1;

    if ( $sling->{'Help'} ) { $ldap_synch->help(); }
    elsif ( $sling->{'Man'} )  { $ldap_synch->man(); }
    elsif ( defined ${ $config->{'download-user-list'} } ) {
        $ldap_synch = new Apache::Sling::LDAPSynch(
            ${ $config->{'ldap-host'} },
            ${ $config->{'ldap-base'} },
            ${ $config->{'ldap-filter'} },
            ${ $config->{'ldap-dn'} },
            ${ $config->{'ldap-pass'} },
            \$authn,
            ${ $config->{'flag-disabled'} },
            $sling->{'Verbose'},
            $sling->{'Log'}
        );
        $success = $ldap_synch->download_synch_user_list(
            ${ $config->{'download-user-list'} } );
    }
    elsif ( defined ${ $config->{'upload-user-list'} } ) {
        $ldap_synch = new Apache::Sling::LDAPSynch(
            ${ $config->{'ldap-host'} },
            ${ $config->{'ldap-base'} },
            ${ $config->{'ldap-filter'} },
            ${ $config->{'ldap-dn'} },
            ${ $config->{'ldap-pass'} },
            \$authn,
            ${ $config->{'flag-disabled'} },
            $sling->{'Verbose'},
            $sling->{'Log'}
        );
        $success = $ldap_synch->upload_synch_user_list(
            ${ $config->{'upload-user-list'} } );
    }
    elsif ( defined ${ $config->{'synch-full'} } ) {
        $ldap_synch = new Apache::Sling::LDAPSynch(
            ${ $config->{'ldap-host'} },
            ${ $config->{'ldap-base'} },
            ${ $config->{'ldap-filter'} },
            ${ $config->{'ldap-dn'} },
            ${ $config->{'ldap-pass'} },
            \$authn,
            ${ $config->{'flag-disabled'} },
            $sling->{'Verbose'},
            $sling->{'Log'}
        );
        $success = $ldap_synch->synch_full( ${ $config->{'ldap-attributes'} },
            ${ $config->{'attributes'} } );
    }
    elsif ( defined ${ $config->{'synch-full-since'} } ) {
        $ldap_synch = new Apache::Sling::LDAPSynch(
            ${ $config->{'ldap-host'} },
            ${ $config->{'ldap-base'} },
            ${ $config->{'ldap-filter'} },
            ${ $config->{'ldap-dn'} },
            ${ $config->{'ldap-pass'} },
            \$authn,
            ${ $config->{'flag-disabled'} },
            $sling->{'Verbose'},
            $sling->{'Log'}
        );
        $success = $ldap_synch->synch_full_since(
            ${ $config->{'ldap-attributes'} },
            ${ $config->{'attributes'} },
            ${ $config->{'synch-full-since'} }
        );
    }
    elsif ( defined ${ $config->{'synch-listed'} } ) {
        $ldap_synch = new Apache::Sling::LDAPSynch(
            ${ $config->{'ldap-host'} },
            ${ $config->{'ldap-base'} },
            ${ $config->{'ldap-filter'} },
            ${ $config->{'ldap-dn'} },
            ${ $config->{'ldap-pass'} },
            \$authn,
            ${ $config->{'flag-disabled'} },
            $sling->{'Verbose'},
            $sling->{'Log'}
        );
        $success = $ldap_synch->synch_listed( ${ $config->{'ldap-attributes'} },
            ${ $config->{'attributes'} } );
    }
    elsif ( defined ${ $config->{'synch-listed-since'} } ) {
        $ldap_synch = new Apache::Sling::LDAPSynch(
            ${ $config->{'ldap-host'} },
            ${ $config->{'ldap-base'} },
            ${ $config->{'ldap-filter'} },
            ${ $config->{'ldap-dn'} },
            ${ $config->{'ldap-pass'} },
            \$authn,
            ${ $config->{'flag-disabled'} },
            $sling->{'Verbose'},
            $sling->{'Log'}
        );
        $success = $ldap_synch->synch_listed_since(
            ${ $config->{'ldap-attributes'} },
            ${ $config->{'attributes'} },
            ${ $config->{'synch-listed-since'} }
        );
    }
    else {
        $ldap_synch->help();
        return 1;
    }
    Apache::Sling::Print::print_result($ldap_synch);
    return $success;
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::LDAPSynch - synchronize users from an external LDAP server into an Apache Sling instance.

=head1 ABSTRACT

Synchronize users from an external LDAP server with the internal users
in an Apache Sling instance.

=head1 METHODS

=head2 new

Create, set up, and return an LDAPSynch object.

=head2 ldap_connect

Connect to the ldap server.

=head2 ldap_search

Perform an ldap search.

=head2 init_synch_cache

Initialize the Apache Sling synch cache.

=head2 get_synch_cache

Fetch the synchronization cache file.

=head2 update_synch_cache

Update the synchronization cache file with the latest state.

=head2 get_synch_user_list

Fetch the synchronization user list file.

=head2 update_synch_user_list

Update the synchronization user_list file with the latest state.

=head2 download_synch_user_list

Download the current synchronization user list file.

=head2 upload_synch_user_list

Upload a list of users to be synchronized into the sling system.

=head2 parse_attributes

Read the given ldap and sling attributes into two separate specified arrays.
Check that the length of the arrays match.

=head2 check_for_property_modifications

Compare a new property hash with a cached version. If any changes to properties
have been made, then return true. Else return false.

=head2 perform_synchronization

Carry out the synchronization from LDAP to Sling.

=head2 synch_full

Perform a full synchronization of Sling internal users with the external LDAP
users.

=head2 synch_full_since

Perform a synchronization of Sling internal users with the external LDAP users,
using LDAP changes since a given timestamp.

=head2 synch_listed

Perform a synchronization of Sling internal users with the external LDAP users
for a set of users listed in a specified file.

=head2 synch_listed_since

Perform a synchronization of Sling internal users with the external LDAP users,
using LDAP changes since a given timestamp for a set of users listed in a
specified file.

=head2 config

Fetch hash of ldap synchronization configuration.

=head2 run

Run ldap synchronization related actions.

=head1 USAGE

use Apache::Sling::LDAPSynch;

=head1 DESCRIPTION

Perl library providing a means to synchronize users from an external
LDAP server with the internal users in an Apache Sling instance.

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>
