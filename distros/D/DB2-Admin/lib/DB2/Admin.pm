#
# DB2::Admin - Access to DB2 administrative API
#
# Copyright (c) 2007-2009, Morgan Stanley & Co. Incorporated
# See ..../COPYING for terms of distribution.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation;
# version 2.1 of the License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser
# General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301  USA
#
# THE FOLLOWING DISCLAIMER APPLIES TO ALL SOFTWARE CODE AND OTHER
# MATERIALS CONTRIBUTED IN CONNECTION WITH THIS DB2 ADMINISTRATIVE API
# LIBRARY:
#
# THIS SOFTWARE IS LICENSED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE AND ANY WARRANTY OF NON-INFRINGEMENT, ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THIS
# SOFTWARE MAY BE REDISTRIBUTED TO OTHERS ONLY BY EFFECTIVELY USING
# THIS OR ANOTHER EQUIVALENT DISCLAIMER AS WELL AS ANY OTHER LICENSE
# TERMS THAT MAY APPLY.
#
# $Id: Admin.pm,v 165.5 2009/04/22 14:06:25 biersma Exp $
#

package DB2::Admin;

use 5.006;
use strict;
use Carp;

use base qw(DynaLoader);
use Params::Validate qw(:all);
use DB2::Admin::Constants;
use DB2::Admin::DataStream;

use vars qw($VERSION);
$VERSION = '3.1';
bootstrap DB2::Admin $VERSION;

#
# Options:
# - RaiseError: die if an error occurs
# - RaiseWarn: die if a warning occurs
# - PrintError: warn if an error occurs
# - PrintWarn: warn if an error occurs
#
my %options;
BEGIN {
    %options = ('PrintError' => 1,
                'PrintWarn'  => 1,
                'RaiseError' => 0,
                'RaiseWarn'  => 0,
               );
}

#
# Connect attributes.  Can be set with ConnectAttributes() and
# overridden at the Connect() method.  We use the same parameter names
# as the db2cli.ini file.
#
my %connect_attr;
BEGIN {
    my $prog_name = $0;
    $prog_name =~ s!^.*/(?=[^/]+$)!!;
    $connect_attr{ProgramName} = $prog_name;
    $connect_attr{ConnectTimeout} = 60;
}


#
# Change option setting
#
sub SetOptions {
    my ($class, %params) = @_;

    while (my ($option, $value) = each %params) {
        confess "Invalid option '$option'"
          unless (defined $options{$option});
        $options{$option} = $value;
    }
    return %options;
}


#
# Set and return connect attributes
#
sub SetConnectAttributes {
    my ($class, %params) = @_;
    while (my ($option, $value) = each %params) {
        confess "Invalid connect attribute '$option'"
          unless (defined $connect_attr{$option});
        $connect_attr{$option} = $value;
    }
    return %connect_attr;
}


#
# Attach to a database instance
#
# Hash with named parameters, all optional:
# - Instance
# - Userid
# - Password
# Returns:
# - Ref to hash with attach information / undef
#
sub Attach {
    my $class = shift;
    my %params = validate(@_, { 'Instance' => 0,
                                'Userid'   => 0,
                                'Password' => 0,
                              });
    unless (defined $params{Instance}) {
        $params{Instance} = $ENV{DB2INSTANCE} ||
          die "Must specify 'Instance' or \$ENV{DB2INSTANCE}\n";
    }
    my $retval = sqleatin($params{'Instance'},
                          $params{'Userid'} || '',
                          $params{'Password'} || '');
    if (defined $retval) {
        return $class->_decode_attach_info($retval);
    } else {
        $class->_handle_error("Attach");
        return;
    }
}


#
# Inquire the attach state
#
# Returns:
# - Ref to hash with attach information / undef
#
sub InquireAttach {
    my $class = shift;

    my $retval = sqleatin('', '', '');
    if (defined $retval) {
        return $class->_decode_attach_info($retval);
    } else {
        $class->_handle_error("InquireAttach");
        return;
    }
}


#
# Detach from the database instance
#
sub Detach {
    my $class = shift;

    my $rc = sqledtin() || $class->_handle_error("Detach");
    return $rc;
}


#
# Get the monitor switches
#
# Ref with optional named parameters:
# - Version (defaults to SQLM_CURRENT_VERSION)
# - Node (defaults to SQLM_CURRENT_NODE)
#
sub GetMonitorSwitches {
    my $class = shift;
    my %params = validate(@_, { 'Version' => 0,
                                'Node'    => 0,
                              });

    $params{Version} ||= 'SQLM_CURRENT_VERSION';
    $params{Node} = 'SQLM_CURRENT_NODE' unless (defined $params{Node});
    my $db2_version = DB2::Admin::Constants::->GetValue($params{Version});
    my $db2_node = $params{Node};
    $db2_node = DB2::Admin::Constants::->GetValue($params{Node})
      if ($db2_node =~ /\D/);

    my $elem_stream = db2MonitorSwitches({}, $db2_version, $db2_node) || do {
        $class->_handle_error("GetMonitorSwitches");
        return;
    };

    return $class->_decode_monitor_switches($elem_stream);
}


#
# Set the monitor switches
#
# Ref with named parameters:
# - Switches: reference to hash with switches to enable/disable
# - Version (defaults to SQLM_CURRENT_VERSION)
# - Node (defaults to SQLM_CURRENT_NODE)
#
sub SetMonitorSwitches {
    my $class = shift;
    my %params = validate(@_, { 'Switches' => 1,
                                'Version'  => 0,
                                'Node'     => 0,
                              });

    $params{Version} ||= 'SQLM_CURRENT_VERSION';
    $params{Node} = 'SQLM_CURRENT_NODE' unless (defined $params{Node});
    my $db2_version = DB2::Admin::Constants::->GetValue($params{Version});
    my $db2_node = $params{Node};
    $db2_node = DB2::Admin::Constants::->GetValue($params{Node})
      if ($db2_node =~ /\D/);

    my $elem_stream  = db2MonitorSwitches($params{Switches},
                                          $db2_version, $db2_node);
    unless ($elem_stream) {
        $class->_handle_error("SetMonitorSwitches");
        return;
    }

    return $class->_decode_monitor_switches($elem_stream);
}


#
# Get a snapshot.
#
# Hash with named parameters:
# - Subject: ref to array with monitor areas to be collected
# - Version (defaults to SQLM_CURRENT_VERSION)
# - Node (defaults to SQLM_CURRENT_NODE)
# - Class (defaults to SQLM_DEFAULT_CLASS)
# - Store (defaults to 0)
# Returns:
# - DB2::Admin::DataStream object / undef
# - Binary data (only when invoked in array context)
#
my $snapshot_sizes;             # Key -> [ 10 last sizes ]
sub GetSnapshot {
    my $class = shift;
    my %params = validate(@_, { 'Subject' => 1,
                                'Version' => 0,
                                'Node'    => 0,
                                'Class'   => 0,
                                'Store'   => 0,
                              });

    $params{Version} ||= 'SQLM_CURRENT_VERSION';
    $params{Node} = 'SQLM_CURRENT_NODE' unless (defined $params{Node});
    $params{Class} ||= 'SQLM_CLASS_DEFAULT';
    $params{Store} ||= 0;

    my %values;
    $values{Node} = ($params{Node} =~ /\D/ ?
                     DB2::Admin::Constants::->GetValue($params{Node}) :
                     $params{Node});
    foreach my $key (qw(Version Class)) {
        $values{$key} = DB2::Admin::Constants::->GetValue($params{$key});
    }

    #
    # Build a numerical 'monitor area' data structure
    # and a key of the format
    #   area_num:agent_id:object,...
    #
    # The key is used to index in the 'sizes' hash,
    # so we can avoid calling db2GetSnapshotSize
    #
    my (@areas, @keys);
    my $subject = $params{'Subject'};
    $subject = [ $subject ] unless (ref($subject) &&
                                    ref($subject) eq 'ARRAY');
    foreach my $elem (@$subject) {
        my $elem_key;
        if (ref($elem)) {
            my $type_name = $elem->{'Type'};
            my $entry = { Type => DB2::Admin::Constants::->GetValue($type_name) };
            $elem_key = $type_name;
            foreach (qw(AgentId Object)) {
                $elem_key .= ':';
                if (defined $elem->{$_}) {
                    $entry->{$_} = $elem->{$_};
                    $elem_key .= $elem->{$_};
                }
            }
            push @areas, $entry;
            push @keys, $elem_key;
        } else {
            my $value = DB2::Admin::Constants::->GetValue($elem);
            push @areas, { 'Type' =>  $value };
            push @keys, $elem . "::";
        }
    }                           # End foreach: entry in subject list
    my $size_key = join(',', @keys);
    my $initial_size = 0;
    if (defined $snapshot_sizes->{$size_key}) {
        foreach my $size (@{ $snapshot_sizes->{$size_key} }) {
            $initial_size = $size if ($initial_size < $size);
        }
        $initial_size += 4096;  # Add 4K poker space
    } elsif ($params{Class} eq 'SQLM_CLASS_DEFAULT') {
        #
        # Call db2GetSnapshotSize, round up to at least 16K,
        # use size increment of 16K
        #
        $initial_size = db2GetSnapshotSize(\@areas, $values{Version},
                                           $values{Node}, $values{Class});
        unless (defined $initial_size) {
            $class->_handle_error("GetSnapshotSize");
            return;
        }
        $initial_size = 16384 if ($initial_size < 16384);
    } else {
        #
        # Health snapshots: db2GetSnapshotSize returns bogus data,
        # start with 50K
        #
        $initial_size = 50 * 1024;
    }

    my $snapshot_data = db2GetSnapshot(\@areas, $values{Version},
                                       $values{Node}, $values{Class},
                                       $initial_size, 16384,
                                       $params{Store});
    unless (defined $snapshot_data) {
        $class->_handle_error("GetSnapshot");
        return;
    }

    #
    # A zero-length output string is legal: no data to collect
    #
    return if (length $snapshot_data == 0);

    #
    # Keep track of required size for this snapshot type
    #
    push @{ $snapshot_sizes->{$size_key} }, length($snapshot_data);
    while (@{ $snapshot_sizes->{$size_key} } > 10) {
        shift @{ $snapshot_sizes->{$size_key} };
    }

    my $stream = DB2::Admin::DataStream::->new($snapshot_data);
    if (wantarray) {
        return ($stream, $snapshot_data);
    }
    return $stream;
}


#
# Reset the monitor
#
# Hash with named parameters:
# - Alias (optional)
# - Version (defaults to SQLM_CURRENT_VERSION)
# - Node (defaults to SQLM_CURRENT_NODE)
# Returns:
# - Success: 1 / Failure: undef
#
sub ResetMonitor {
    my $class = shift;
    my %params = validate(@_, { 'Alias'   => 0,
                                'Version' => 0,
                                'Node'    => 0,
                              });

    $params{Alias} ||= '';
    $params{Version} ||= 'SQLM_CURRENT_VERSION';
    $params{Node} = 'SQLM_CURRENT_NODE' unless (defined $params{Node});
    my $all = ($params{Alias} ? 0 : 1);
    my $db2_version = DB2::Admin::Constants::->GetValue($params{Version});
    my $db2_node = $params{Node};
    $db2_node = DB2::Admin::Constants::->GetValue($params{Node})
      if ($db2_node =~ /\D/);

    my $rc = db2ResetMonitor($all, $params{Alias}, $db2_version, $db2_node);
    unless ($rc) {
        $class->_handle_error("ResetMonitor");
        return;
    }
    return 1;
}


#
# Get database manager configuration
#
# Hash with named parameters:
# - Param: parameter name / ref to array of parameter names
#   (e.g. 'intra_parallel') (case-insensitive)
# - Flag (optional: 'Immediate' / 'Delayed' / 'Defaults')
# - Version (defaults to SQLM_CURRENT_VERSION)
# Returns:
# - Array with hash-references, each with:
#   - Name
#   - Value
#   - Automatic/Computed (optional)
#
sub GetDbmConfig {
    my $class = shift;
    my %params = validate(@_, { 'Param'    => 1,
                                'Flag'    => 0,
                                'Version' => 0,
                              });

    my $retval = $class->_get_config_params(%params);
    unless ($retval) {
        $class->_handle_error("GetDbmConfig");
        return;
    }
    return @$retval;
}


#
# Set database manager configuration
#
# Hash with named parameters:
# - Param: ref to hash / array of hash-refs
#   Each hash ref has:
#   - Name (value is case-insensitive)
#   - Value
#   - Automatic (optional)
#   - Computed (optional, V9.1)
#   - Manual (optional, V9.1; value is ignored)
# - Flag (optional: 'Immediate' / 'Delayed' / 'Reset')
# - Version (defaults to SQLM_CURRENT_VERSION)
# Returns:
# - Boolean
#
sub UpdateDbmConfig {
    my $class = shift;
    my %params = validate(@_, { 'Param'    => 1,
                                'Flag'    => 0,
                                'Version' => 0,
                              });

    my $retval = $class->_set_config_params(%params);
    unless ($retval) {
        $class->_handle_error("UpdateDbmConfig");
        return;
    }
    return $retval;
}


#
# Get database configuration
#
# Hash with named parameters:
# - Param: parameter name / ref to array of parameter names
#   (e.g. 'intra_parallel') (case-insensitive)
# - Database
# - Flag (optional: 'Immediate' / 'Delayed' / 'Defaults')
# - Version (defaults to SQLM_CURRENT_VERSION)
# Returns:
# - Array with hash-references, each with:
#   - Name
#   - Value
#   - Automatic/Computed (optional)
#
sub GetDatabaseConfig {
    my $class = shift;
    my %params = validate(@_, { 'Param'    => 1,
                                'Database' => 1,
                                'Flag'     => 0,
                                'Version'  => 0,
                              });

    my $retval = $class->_get_config_params(%params);
    unless ($retval) {
        $class->_handle_error("GetDatabaseConfig");
        return;
    }
    return @$retval;
}


#
# Set database configuration
#
# Hash with named parameters:
# - Param: ref to hash / array of hash-refs
#   Each hash ref has:
#   - Name (value is case-insensitive)
#   - Value
#   - Automatic (optional)
#   - Computed (optional, V9.1)
#   - Manual (optional, V9.1; value is ignored)
# - Database
# - Flag (optional: 'Immediate' / 'Delayed' / 'Reset')
# - Version (defaults to SQLM_CURRENT_VERSION)
# Returns:
# - Boolean
#
sub UpdateDatabaseConfig {
    my $class = shift;
    my %params = validate(@_, { 'Param'    => 1,
                                'Database' => 1,
                                'Flag'     => 0,
                                'Version'  => 0,
                              });

    my $retval = $class->_set_config_params(%params);
    unless ($retval) {
        $class->_handle_error("UpdateDatabaseConfig");
        return;
    }
    return $retval;
}


#
# Get the database directory
#
# Hash with named parameters:
# - Path (optional)
# Returns:
# - Array with hash-references
#
sub GetDatabaseDirectory {
    my $class = shift;
    my %params = validate(@_, { 'Path' => 0,
                              });
    my $path = (defined $params{Path} ? $params{Path} : '');

    my $retval = db2DatabaseDirectory($path);
    unless ($retval) {
        $class->_handle_error("GetDatabaseDirectory");
        return;
    }
    return @$retval;
}


#
# Catalog a database
#
sub CatalogDatabase {
    my $class = shift;
    my %params = validate(@_, { 'Alias'          => 1,
                                'Database'       => 1,
                                'NodeName'       => 0,
                                'Path'           => 0,
                                'Comment'        => 0,
                                'DBType'         => 1,
                                'Authentication' => 0,
                                'Principal'      => 0,
                              });

    my $retval = sqlecadb(\%params);
    unless ($retval) {
        $class->_handle_error("CatalogDatabase");
        return;
    }
    return $retval;             # 1
}


#
# Uncatalog a database
#
# Named parameters:
# - Alias
# Returns:
# - Boolean
#
sub UncatalogDatabase {
    my $class = shift;
    my %params = validate(@_, { 'Alias' => 1, });

    my $retval = sqleuncd($params{Alias});
    unless ($retval) {
        $class->_handle_error("UncatalogDatabase");
        return;
    }
    return $retval;             # 1
}


#
# Get the node directory
#
# Parameters: none
# Returns:
# - Array with hash-references
#
sub GetNodeDirectory {
    my $class = shift;

    my $retval = db2NodeDirectory();
    unless ($retval) {
        unless (sqlcode() == -1027) { # -1027: empty node dir
            $class->_handle_error("GetNodeDirectory");
        }
        return;
    }
    foreach my $entry (@$retval) {
        my $platform_code = delete $entry->{'OSType'};
        my $platform_name = DB2::Admin::Constants::->
          Lookup('Platform', $platform_code);
        if (defined $platform_name) {
            $platform_name =~ s/^SQLM_PLATFORM_//;
            $entry->{'OS Type'} = $platform_name;
        }
    }
    return @$retval;
}


#
# Catalog a node
#
sub CatalogNode {
    my $class = shift;
    my %params = validate(@_, { 'NodeName'     => 1,
                                'Comment'      => 0,
                                'Protocol'     => 1,
                                'HostName'     => 0,
                                'ServiceName'  => 0,
                                'InstanceName' => 0,
                              });

    my $retval = sqlectnd(\%params);
    unless ($retval) {
        $class->_handle_error("CatalogNode");
        return;
    }
    return $retval;             # 1
}


#
# Uncatalog a node
#
# Named parameters:
# - NodeName
# Returns:
# - Boolean
#
sub UncatalogNode {
    my $class = shift;
    my %params = validate(@_, { 'NodeName' => 1, });

    my $retval = sqleuncn($params{NodeName});
    unless ($retval) {
        $class->_handle_error("UncatalogNode");
        return;
    }
    return $retval;             # 1
}


#
# Get the DCS (gateway) directory
#
# Parameters: none
# Returns:
# - Array with hash-references
#
sub GetDCSDirectory {
    my $class = shift;

    my $retval = db2DCSDirectory();
    unless ($retval) {
        unless (sqlcode() == 1312) { # 1312: DCS directory empty
            $class->_handle_error("GetDCSDirectory");
        }
        return;
    }
    return @$retval;
}


#
# Catalog a DCS Database
#
sub CatalogDCSDatabase {
    my $class = shift;
    my %params = validate(@_, { 'Database'  => 1,
                                'Target'    => 1,
                                'Comment'   => 0,
                                'Library'   => 0,
                                'Parameter' => 0,
                              });

    my $retval = sqlegdad(\%params);
    unless ($retval) {
        $class->_handle_error("CatalogNode");
        return;
    }
    return $retval;             # 1
}


#
# Uncatalog a DCS directory entry
#
# Named parameters:
# - Database
# Returns:
# - Boolean
#
sub UncatalogDCSDatabase {
    my $class = shift;
    my %params = validate(@_, { 'Database' => 1, });

    my $retval = sqlegdel($params{Database});
    unless ($retval) {
        $class->_handle_error("UncatalogDCSDatabase");
        return;
    }
    return $retval;             # 1
}


#
# Force all applications (Danger Will Robinson! use with care...)
#
# Parameters: none
# Returns: boolean
#
sub ForceAllApplications {
    my $class = shift;

    my $rc = sqlefrce('All');
    unless ($rc) {
        $class->_handle_error("ForceAllApplications");
    }
    return $rc;
}


#
# Force selected applications (Danger Will Robinson! use with care...)
#
# Parameters: array of agent ids
# Returns: boolean
#
sub ForceApplications {
    my $class = shift;
    confess "Must specify at least one agent id" unless (@_);

    my $rc = sqlefrce(\@_);
    unless ($rc) {
        $class->_handle_error("ForceApplications");
    }
    return $rc;
}


#
# Connect to to a database.  the database handle is stored
# internally and does not need to be passed around.  Dependent
# functions will take the database name.
#
sub Connect {
    my $class = shift;
    my %params = validate(@_, { 'Database'    => 1,
                                'Userid'      => 0,
                                'Password'    => 0,
                                'ConnectAttr' => 0,
                              });
    my ($db_name, $userid, $passwd, $extra_attrs) =
      @params{qw(Database Userid Password ConnectAttr)};
    $userid = '' unless (defined $userid);
    $passwd = '' unless (defined $passwd);
    $extra_attrs ||= {};
    my %combined_attr = (%connect_attr, %$extra_attrs);

    #print STDERR "XXX: About to connect to [$db_name] using userid [$userid] and password [$passwd]\n";
    my $rc = db_connect($db_name, $userid, $passwd, \%combined_attr);
    unless ($rc) {
        #
        # We cannot call _handle_error(), as sqlcode() is not set for
        # this function.  Note this is an error, not a warning.
        #
        my $msg = "Error in Connect: cannot connect to database '$db_name'";
        if ($options{'PrintError'}) {
            warn $msg;
        }
        if ($options{'RaiseError'}) {
            die $msg;
        }
    }
    return $rc;
}


#
# Disconnect from a database
#
sub Disconnect {
    my $class = shift;
    my %params = validate(@_, { 'Database' => 1, });

    my $rc = db_disconnect($params{Database});
    unless ($rc) {
        #
        # We cannot call _handle_error(), as sqlcode() is not set for
        # this function.  Note we treat this as an error, not a
        # warning.
        #
        my $msg = "Error in Disconnect: cannot disconnect from database '$params{Database}'";
        if ($options{'PrintError'}) {
            warn $msg;
        }
        if ($options{'RaiseError'}) {
            die $msg;
        }
    }
    return $rc;
}


#
# Export a table to a file.  A database connection must already exist.
#
# Parameters:
# - Database name
# - Schema
# - Table
# - Columns (optional array-ref; defaults to '*')
# - Where (optional)
# - FileType (DEL/IXF)
# - FileOptions (for DEL)
# - ExportOptions (optional, hash-ref)
# - OutputFile
# - LogFile (optional; default is /dev/null)
# - LobPath (optional, string or array-ref)
# - LobFile (optional, string or array-ref)
# - XmlPath (optional, string or array-ref)
# - XmlFile (optional, string or array-ref)
# Returns:
# - Number of rows exported / -1 on error
#
sub Export {
    my $class = shift;
    my %params = validate(@_, { 'Database'      => 1,
                                'Schema'        => 1,
                                'Table'         => 1,
                                'Columns'       => 0,
                                'Where'         => 0,
                                'FinalClauses'  => 0,
                                'FileType'      => 1,
                                'FileOptions'   => 0,
                                'ExportOptions' => 0,
                                'OutputFile'    => 1,
                                'LogFile'       => 0,
                                'LobPath'       => 0,
                                'LobFile'       => 0,
                                'XmlPath'       => 0,
                                'XmlFile'       => 0,
                              });

    #
    # Construct a SQL select clause
    #
    my $select = "SELECT ";
    if (defined $params{Columns}) {
        $select .= join(',', @{ $params{Columns} });
    } else {
        $select .= '*';
    }
    $select .= " FROM $params{Schema}.$params{Table}";
    if (defined $params{Where}) {
        $select .= " WHERE $params{Where}";
    }
    if (defined $params{FinalClauses}) {
        $select .= " $params{FinalClauses}";
    }
    #print STDERR "XXX: Have export SELECT stmt [$select]\n";

    #
    # For file type DEL/IXF, create an options string
    #
    my $file_options = '';
    if ($params{FileType} eq 'DEL') {
        #$file_type = 'SQL_DEL';
        if (defined $params{FileOptions}) {
            my @opts = %{ $params{FileOptions} };
            my %opts = validate(@opts, { 'CharDel'         => 0,
                                         'CodePage'        => 0,
                                         'ColDel'          => 0,
                                         'DatesISO'        => 0,
                                         'DecPlusBlank'    => 0,
                                         'NoCharDel'       => 0,
                                         'StripZeros'      => 0,
                                         'TimestampFormat' => 0,
                                         'LobsInFile'      => 0,
                                         'XmlInSepFiles'   => 0,
                                       });
            if (defined $opts{CharDel}) { # Special quoting
                $file_options .= " chardel$opts{CharDel}";
                if ($opts{CharDel} eq '"' || $opts{CharDel} eq "'") {
                    $file_options .= $opts{CharDel};
                }
            }
            foreach my $opt (qw(ColDel)) { # option+value, no delimiter
                if (defined $opts{$opt}) {
                    $file_options .= " \L$opt\E$opts{$opt}";
                }
            }
            foreach my $opt (qw(CodePage)) {
                if (defined $opts{$opt}) {
                    my $value = $opts{$opt};
                    $file_options .= " \L$opt\E=$value";
                }
            }
            foreach my $opt (qw(TimestampFormat)) { # Quoted option+delimiter
                if (defined $opts{$opt}) {
                    my $value = $opts{$opt};
                    if ($value =~ /"/) {
                        confess "Invalid FileOptions '$opt' option value '$value' - cannot have embedded quotes";
                    }
                    $file_options .= " \L$opt\E=\"$value\"";
                }
            }
            foreach my $opt (qw(NoCharDel DatesISO DecPlusBlank
                                LobsInFile StripZeros XmlInSepFiles)) {
                if ($opts{$opt}) { # Boolean flag: present and set
                    $file_options .= " \L$opt\E";
                }
            }
        }
    } elsif ($params{FileType} eq 'IXF') {
        if (defined $params{FileOptions}) {
            my @opts = %{ $params{FileOptions} };
            my %opts = validate(@opts, { 'LobsInFile'    => 0,
                                         'XmlInSepFiles' => 0,
                                       });
            foreach my $opt (qw(LobsInFile XmlInSepFiles)) {
                if ($opts{$opt}) { # Boolean flag: present and set
                    $file_options .= " \L$opt\E";
                }
            }
        }
    } else {
        confess "Unexpected file type '$params{FileType}'; expected 'DEL' or 'IXF'";
    }

    #
    # Verify export options
    #
    if (defined $params{ExportOptions}) {
        my @opts = %{ $params{ExportOptions} };
        my %opts = validate(@opts, { 'XmlSaveSchema' => 1,
                                   });
    }

    #
    # Verify lob-related options
    #
    if (defined $params{FileOptions} && $params{FileOptions}{LobsInFile}) {
        confess "LobsInFile file option requires LobPath parameter"
          unless (defined $params{LobPath});
    }
    if (defined $params{LobPath} &&
        ( !defined $params{FileOptions} ||
          !defined $params{FileOptions}{LobsInFile} )) {
        confess "LobPath parameter requires LobsInFile file option";
    }
    if (defined $params{LobFile} && ! defined $params{LobPath}) {
        confess "LobFile parameter requires LobPath parameter";
    }

    #
    # Verify XML-related options
    #
    if (defined $params{FileOptions} && $params{FileOptions}{XmlInSepFiles}) {
        confess "XmlInSepFiles file option requires XmlPath parameter"
          unless (defined $params{XmlPath});
    }
    if (defined $params{ExportOptions} && $params{ExportOptions}{XmlSaveSchema}) {
        confess "XmlSaveSchema export option requires XmlPath parameter"
          unless (defined $params{XmlPath});
    }
    if (defined $params{XmlFile} && ! defined $params{XmlPath}) {
        confess "XmlFile parameter requires XmlPath parameter";
    }

    my $rc = db2Export($params{Database}, $select, $params{FileType},
                       $params{OutputFile},
                       $params{LogFile} || _null_device(),
                       $file_options,
                       $params{LobPath}, # May be undef
                       $params{LobFile}, # May be undef,
                       $params{ExportOptions} || {},
                       $params{XmlPath}, # May be undef
                       $params{XmlFile}, # May be undef
                      );
    if ($rc < 0) {
        $class->_handle_error("Export");
    }
    return $rc;
}


#
# Import into a table from a file.  A database connection must already exist.
#
# Parameters:
# - Database name
# - Schema
# - Table
# - TargetColumns (optional)
# - Operation (Insert / Insert_Update / Replace)
# - FileType (DEL/IXF)
# - FileOptions
# - InputFile
# - InputColumns (names for IXF / positions for DEL)
# - LogFile (optional; default is /dev/null)
# - ImportOptions
# - LobPath (optional, string or array-ref)
# - XmlPath (optional, string or array-ref)
# Returns:
# - Ref to hash with import details / undef on error
#
sub Import {
    my $class = shift;
    my %params = validate(@_, { 'Database'      => 1,
                                'Schema'        => 1,
                                'Table'         => 1,
                                'TargetColumns' => 0,
                                'Operation'     => 1,
                                'FileType'      => 1,
                                'FileOptions'   => 0,
                                'InputFile'     => 1,
                                'InputColumns'  => 0,
                                'LogFile'       => 0,
                                'ImportOptions' => 0,
                                'LobPath'       => 0,
                                'XmlPath'       => 0,
                              });

    #
    # Construct an action string
    #
    my $action = "\U$params{Operation}\E INTO $params{Schema}.$params{Table}";
    if (defined $params{TargetColumns}) {
        confess "Parameter 'TargetColumns' must be an array-reference"
          unless (ref $params{TargetColumns} eq 'ARRAY');
        confess "Parameter 'TargetColumns' may not be empty array"
          unless (@{ $params{TargetColumns} });
        $action .= " (" . join(', ', @{ $params{TargetColumns} }) . ')'; # FIXME: quoting
    }
    #print STDERR "XXX: Have import action string [$action]\n";

    #
    # Create an options string (generic / for the file type)
    #
    my $file_options = '';
    my $fopts = { %{ $params{FileOptions} || {} } };
    foreach my $flag (qw(GeneratedIgnore GeneratedMissing
                         IdentityIgnore IdentityMissing
                         LobsInFile NoDefaults UseDefaults
                        )) {
        my $set = delete $fopts->{$flag};
        if ($set) {
            $file_options .= lc($flag) . ' ';
        }
    }
    if ($params{FileType} eq 'DEL') {
        my @opts = %$fopts;
        validate(@opts, { 'CharDel'         => 0,
                          'CodePage'        => 0,
                          'ColDel'          => 0,
                          'DateFormat'      => 0,
                          'DelPriorityChar' => 0,
                          'ImpliedDecimal'  => 0,
                          'KeepBlanks'      => 0,
                          'NoCharDel'       => 0,
                          'StripTBlanks'    => 0,
                          'TimeFormat'      => 0,
                          'TimestampFormat' => 0,
                        });
        #
        # Boolean flags
        #
        foreach my $flag (qw(DelPriorityChar ImpliedDecimal
                             KeepBlanks NoCharDel StripTBlanks)) {
            if ($fopts->{$flag}) { # Boolean, not mere presence
                $file_options .= " \L$flag\E";
            }
        }
        #
        # File options with a non-quoted value that use '=' as a separator
        #
        foreach my $opt (qw(CodePage)) {
            if (defined $fopts->{$opt}) {
                my $value = $fopts->{$opt};
                $file_options .= " \L$opt\E=$value";
            }
        }
        #
        # File options with a quoted value that use '=' as a separator
        #
        foreach my $opt (qw(DateFormat TimeFormat TimestampFormat)) {
            if (defined $fopts->{$opt}) {
                my $value = $fopts->{$opt};
                if ($value =~ /"/) {
                    confess "Invalid FileOptions '$opt' option value '$value' - cannot have embedded quotes";
                }
                $file_options .= " \L$opt\E=\"$value\"";
            }
        }
        #
        # File option with a value that has no separator
        #
        foreach my $opt (qw(ColDel)) {
            if (defined $fopts->{$opt}) {
                $file_options .= " \L$opt\E$fopts->{$opt}";
            }
        }
        #
        # File option with special escape rules
        #
        if (defined $fopts->{CharDel}) {
            $file_options .= " chardel$fopts->{CharDel}";
            if ($fopts->{CharDel} eq '"' || $fopts->{CharDel} eq "'") {
                $file_options .= $fopts->{CharDel};
            }
        }
    } elsif ($params{FileType} eq 'IXF') {
        confess "No file-type specific options supported for IXF files"
          if (keys %$fopts);
    } else {
        confess "Unexpected file type '$params{FileType}'; expected 'DEL' or 'IXF'";
    }

    #
    # Verify lob-related options
    #
    if (defined $params{FileOptions} && $params{FileOptions}{LobsInFile}) {
        confess "LobsInFile file option requires LobPath parameter"
          unless (defined $params{LobPath});
    }
    if (defined $params{LobPath} &&
        ( !defined $params{FileOptions} ||
          !defined $params{FileOptions}{LobsInFile} )) {
        confess "LobPath parameter requires LobsInFile file option";
    }

    my $rc = db2Import($params{Database}, $action, $params{FileType},
                       $params{InputFile},
                       $params{InputColumns} || [],
                       $params{LogFile} || _null_device(),
                       $file_options,
                       $params{ImportOptions} || {},
                       $params{LobPath}, # May be undef
                       $params{XmlPath}, # May be undef
                      );
    if (! defined $rc) {
        $class->_handle_error("Import");
    }
    return $rc;
}


#
# Load a table from a file / SQL statement.
# A database connection must already exist.
#
# This method is a rats nest of options, and then we only support
# a subset of the LOAD command - IBM needs to learn API design...
#
# Parameters:
# - Database name
# - Schema
# - Table
# - TargetColumns
# - Operation (Insert /  Replace / Restart / Terminate)
# - SourceType (DEL/IXF/Statement)
# - FileOptions
# - InputFile (for SourceType DEL/IXF)
# - InputStatement (for SourceType Statement)
# - InputColumns (IXF: names, DEL: positions)
# - LogFile (optional; default is /dev/null)
# - TempFilesPath (optional)
# - LoadOptions
# - ExceptionSchema (defaults to Schema)
# - ExceptionTable
# - LobPath (optional, string or array-ref)
# - XmlPath (optional, string or array-ref)
# Returns:
# - Ref to hash with load details / undef on error
# - Ref to hash with DPF load details (only if wantarray set)
#
sub Load {
    my $class = shift;
    my %params = validate(@_, { 'Database'        => 1,
                                'Schema'          => 1,
                                'Table'           => 1,
                                'TargetColumns'   => 0,
                                'Operation'       => 1,
                                'SourceType'      => 1,
                                'FileLocation'    => 0, # Client / Server
                                'FileOptions'     => 0,
                                'InputFile'       => 0,
                                'InputStatement'  => 0,
                                'InputColumns'    => 0,
                                'CopyDirectory'   => 0,
                                'LogFile'         => 0,
                                'TempFilesPath'   => 0,
                                'LoadOptions'     => 0,
                                'DPFOptions'      => 0,
                                'ExceptionSchema' => 0,
                                'ExceptionTable'  => 0,
                                'LobPath'         => 0,
                                'XmlPath'         => 0,
                              });

    #
    # Construct an action string
    #
    my $action = "\U$params{Operation}\E INTO $params{Schema}.$params{Table}";
    if (defined $params{TargetColumns}) {
        confess "Parameter 'TargetColumns' must be an array-reference"
          unless (ref $params{TargetColumns} eq 'ARRAY');
        confess "Parameter 'TargetColumns' may not be empty array"
          unless (@{ $params{TargetColumns} });
        $action .= " (" . join(', ', @{ $params{TargetColumns} }) . ')'; # FIXME: quoting
    }
    if (defined $params{ExceptionTable}) {
        $params{ExceptionSchema} = $params{Schema}
          if (!defined $params{ExceptionSchema});
        $action .= " FOR EXCEPTION $params{ExceptionSchema}.$params{ExceptionTable}";
    }
    #print STDERR "XXX: Have load action string [$action]\n";

    #
    # Create an options string (generic / for the file type)
    #
    my $file_options = '';
    my $fopts = { %{ $params{FileOptions} || {} } };
    foreach my $flag (qw(AnyOrder
                         GeneratedIgnore GeneratedMissing GeneratedOverride
                         IdentityIgnore  IdentityMissing  IdentityOverride
                         LobsInFile NoRowWarnings UseDefaults
                        )) {
        my $set = delete $fopts->{$flag};
        if ($set) {
            $file_options .= ' ' . lc($flag);
        }
    }
    foreach my $opt (qw(IndexFreespace PageFreespace TotalFreespace)) {
        my $value = delete $fopts->{$opt};
        if (defined $value) {
            if ($value =~ /\S/) {
                if ($value =~ /"/) {
                    confess "Invalid FileOptions '$opt' option value '$value' - cannot have embedded blanks and quotes";
                }
                $value = "\"$value\"";
            }
            $file_options .= " \L$opt\E=$value";
        }
    }

    if ($params{SourceType} eq 'DEL') {
        my @opts = %$fopts;
        validate(@opts, { 'CharDel'           => 0,
                          'CodePage'          => 0,
                          'ColDel'            => 0,
                          'DateFormat'        => 0,
                          'DatesISO'          => 0,
                          'DecPlusBlank'      => 0,
                          'DecPt'             => 0,
                          'DelPriorityChar'   => 0,
                          'DumpFile'          => 0,
                          'DumpFileAccessAll' => 0,
                          'ImpliedDecimal'    => 0,
                          'KeepBlanks'        => 0,
                          'NoCharDel'         => 0,
                          'TimeFormat'        => 0,
                          'TimestampFormat'   => 0,
                        });
        #
        # Boolean flags
        #
        foreach my $flag (qw(DatesISO DecPlusBlank DelPriorityChar
                             DumpFileAccessAll ImpliedDecimal KeepBlanks
                             NoCharDel)) {
            if ($fopts->{$flag}) { # Boolean, not mere presence
                $file_options .= " \L$flag\E";
            }
        }
        #
        # File options with a value that use '=' as a separator - no
        # quotes
        #
        foreach my $opt (qw(CodePage)) {
            if (defined $fopts->{$opt}) {
                my $value = $fopts->{$opt};
                $file_options .= " \L$opt\E=$value";
            }
        }
        #
        # File options with a value that use '=' as a separator -
        # optional quotes
        #
        foreach my $opt (qw(DumpFile)) {
            if (defined $fopts->{$opt}) {
                my $value = $fopts->{$opt};
                if ($value =~ /\s/) {
                    if ($value =~ /"/) {
                        confess "Invalid FileOptions '$opt' option value '$value' - cannot have embedded blanks and quotes";
                    }
                    $value = "\"$value\"";
                }
                $file_options .= " \L$opt\E=$value";
            }
        }
        #
        # File options with a value that use '=' as a separator -
        # mandatory quotes
        #
        foreach my $opt (qw(DateFormat TimeFormat TimestampFormat)) {
            if (defined $fopts->{$opt}) {
                my $value = $fopts->{$opt};
                if ($value =~ /"/) {
                    confess "Invalid FileOptions '$opt' option value '$value' - cannot have embedded quotes";
                }
                $file_options .= " \L$opt\E=\"$value\"";
            }
        }
        #
        # File option with a value that has no separator
        #
        foreach my $opt (qw(ColDel DecPt)) {
            if (defined $fopts->{$opt}) {
                $file_options .= " \L$opt\E$fopts->{$opt}";
            }
        }
        #
        # File option with special escape rules
        #
        if (defined $fopts->{CharDel}) {
            $file_options .= " chardel$fopts->{CharDel}";
            if ($fopts->{CharDel} eq '"' || $fopts->{CharDel} eq "'") {
                $file_options .= $fopts->{CharDel};
            }
        }
    } elsif ($params{SourceType} eq 'IXF') {
        my @opts = %$fopts;
        validate(@opts, { 'ForceIn'        => 0,
                          'NoCheckLengths' => 0,
                        });
        #
        # Boolean flags
        #
        foreach my $flag (qw(ForceIn NoCheckLengths)) {
            if ($fopts->{$flag}) { # Boolean, not mere presence
                $file_options .= " \L$flag\E";
            }
        }
    } elsif ($params{SourceType} ne 'Statement' &&
             $params{SourceType} ne 'SQL') {
        confess "Unexpected file type '$params{SourceType}'; expected 'DEL' or 'IXF'";
    }
    #print STDERR "XXX: have file options string '$file_options'\n";

    my $source_list;
    if ($params{SourceType} eq 'DEL' || $params{SourceType} eq 'IXF') {
        $source_list = $params{InputFile} ||
          confess "Parameter 'InputFile' required with SourceType '$params{SourceType}'";
    } elsif ($params{SourceType} eq 'Statement' ||
             $params{SourceType} eq 'SQL') {
        $source_list = $params{InputStatement} ||
          confess "Parameter 'InputStatement' required with SourceType '$params{SourceType}'";
    } else {
        confess "Unexpected SourceType '$params{SourceType}'";
    }

    #
    # Input columns are names for IXF files and column numbers for DEL files
    #
    if (defined $params{InputColumns}) {
        confess "Parameter 'InputColumns' must be an array-reference"
          unless (ref $params{InputColumns} eq 'ARRAY');
        confess "Parameter 'InputColumns' requires SourceType 'IXF' / 'DEL'"
          unless ($params{SourceType} eq 'IXF' ||
                  $params{SourceType} eq 'DEL');
        confess "Parameter 'InputColumns' may not be empty array"
          unless (@{ $params{InputColumns} });
    }

    my $copy_list = $params{CopyDirectory} || '';

    #
    # Verify lob-related options
    #
    if (defined $params{FileOptions} && $params{FileOptions}{LobsInFile}) {
        confess "LobsInFile file option requires LobPath parameter"
          unless (defined $params{LobPath});
    }
    if (defined $params{LobPath} &&
        ( !defined $params{FileOptions} ||
          !defined $params{FileOptions}{LobsInFile} )) {
        confess "LobPath parameter requires LobsInFile file option";
    }

    my ($rc, $rc_dpf) = db2Load($params{Database},
                                $action,
                                $params{InputColumns} || [],
                                $params{SourceType},
                                $params{FileLocation} || 'Client', # MediaType
                                $source_list,
                                $copy_list,
                                $params{LogFile} || _null_device(),
                                $params{TempFilesPath} || '',
                                $file_options,
                                $params{LoadOptions} || {},
                                $params{DPFOptions}, # May be undef
                                $params{LobPath}, # May be undef
                                $params{XmlPath}, # May be undef
                               );
    if (! defined $rc) {
        $class->_handle_error("Load");
    }
    if (wantarray) {
        return ($rc, $rc_dpf);
    }
    return $rc;
}


#
# Query the status of a loaded table.  Requires a database connection.
#
sub LoadQuery {
    my $class = shift;
    my %params = validate(@_, { 'Schema'   => 1,
                                'Table'    => 1,
                                'LogFile'  => 1,
                                'Messages' => 1,
                              });
    my ($schema, $table, $logfile, $msg_type) =
      @params{qw(Schema Table LogFile Messages)};
    confess "Invalid 'Messages' specification '$msg_type' - must be one of 'All', 'None' or 'New'"
      unless ($msg_type =~ /^(?:All|None|New)$/);

    my $rc = db2LoadQuery("$schema.$table", $msg_type, $logfile);
    if (! defined $rc) {
        $class->_handle_error("LoadQuery");
    }
    return $rc;
}


#
# Rebind a package.  Requires a database connection.
#
sub Rebind {
    my $class = shift;
    my %params = validate(@_, { 'Database' => 1,
                                'Schema'   => 0,
                                'Package'  => 1,
                                'Options'  => 0,
                              });
    my ($dbname, $schema, $package, $options) =
      @params{qw(Database Schema Package Options)};
    $package = "$schema.$package" if (defined $schema);
    $options ||= {};

    my $rc = sqlarbnd($dbname, $package, $options);
    if (! defined $rc) {
        $class->_handle_error("Rebind");
    }
    return $rc;
}


#
# List history
#
# Parameters:
# - Database
# - Action (All / Backup / ...)
# - ObjectName (optional)
# - StartTime (optional)
# Returns:
# - Array of history records, each a hash reference
#
sub ListHistory {
    my $class = shift;
    my %params = validate(@_, { 'Database'   => 1,
                                'Action'     => 0,
                                'ObjectName' => 0,
                                'StartTime'  => 0,
                              });
    my ($db_name, $action, $obj_name, $start_time) =
      @params{qw(Database Action ObjectName StartTime)};
    $action ||= 'All';
    $obj_name ||= '';
    $start_time ||= '';

    my $rc = db2ListHistory($db_name, $action, $obj_name, $start_time);
    if (! defined $rc) {
        $class->_handle_error("ListHistory");
        return;
    }
    return @$rc;
}


#
# Using an instance snapshopt, list what utilities are currently
# running.  Optionally, filter for a specific database name.
#
sub ListUtilities {
    my $class = shift;
    my %params = validate(@_, { 'Database' => 0,
                                'Version'  => 0,
                              });
    $params{Version} ||= 'SQLM_CURRENT_VERSION';
    my ($db_name, $version) = @params{qw(Database Version)};

    #
    # Get an instance snapshot and check the listed utilities
    #
    my @retval;
    my $info = DB2::Admin::->GetSnapshot('Subject' => 'SQLMA_DB2',
                                         'Version' => $version,
                                        );
    foreach my $util_node ($info->findNodes('DB2/UTILITY')) {
        my $util_db_name = $util_node->findValue('UTILITY_DBNAME');
        $util_db_name =~ s/\s+$//;
        next if (defined $db_name && lc $util_db_name ne lc $db_name);

        my $start_ctime = $util_node->findValue('UTILITY_START_TIME/SECONDS');
        push @retval,
          { 'Database'     => $util_db_name,
            'ID'           => $util_node->findValue('UTILITY_ID'),
            'Utility'      => $util_node->findValue('UTILITY_TYPE'),
            'Priority'     => $util_node->findValue('UTILITY_PRIORITY'),
            'Description'  => $util_node->findValue('UTILITY_DESCRIPTION'),
            'StartTime'    => scalar(localtime $start_ctime),
            'StartTimeVal' => $start_ctime,
          };

        #
        # NOTE: We're not including the various phase / progress
        #       elements.  It would be simple to add these, but
        #       I'm not sure anyone would care...
        #
    }

    return @retval;
}


#
# The Runstats command (subset of features).  Requires a database
# connections.
#
# Parameters:
# - Database
# - Schema
# - Table
# - Columns (optional)
# - Indexes (optional)
# - Options (optional)
# Returns: boolean (1: okay, undef: failure)
#
sub Runstats {
    my $class = shift;
    my %params = validate(@_, { 'Database' => 1,
                                'Schema'   => 1,
                                'Table'    => 1,
                                'Columns'  => 0,
                                'Indexes'  => 0,
                                'Options'  => 0,
                              },
                         );

    #
    # If the indexes are specified, add the default schema name
    # if no schema specified.
    #
    my @indexes = (defined $params{Indexes} ? @{ $params{Indexes} } : ());
    foreach my $index (@indexes) {
        next if ($index =~ /\w\.\w/); # FIXME: better parsing for bizarre names
        $index = "$params{Schema}.$index";
    }

    my $table = "$params{Schema}.$params{Table}"; # FIXME: better quoting
    my $columns = $params{Columns} || {};
    my $options = $params{Options} || {};

    my $rc = db2Runstats($params{Database}, $table, $options, $columns, \@indexes);
    if ($rc) {
        $class->_handle_error("Runstats");
        return;
    }
    return 1;
}


#
# Get/Set DB2 client information
#
# Hash with named parameters, all optional:
# -Database (may be undef for "all databases")
# -ClientUserid
# -Workstation
# -Application
# -AccountingString
#
# Returns: hash with values for the following entries, if set:
# -ClientUserid
# -Workstation
# -Application
# -AccountingString
#
sub ClientInfo {
    my $class = shift;
    my %params = validate(@_, { 'Database'         => 0,
                                'ClientUserid'     => 0,
                                'Workstation'      => 0,
                                'Application'      => 0,
                                'AccountingString' => 0,
                              },
                         );
    my $dbname = delete $params{Database} || '';
    my $retval = db2ClientInfo($dbname, \%params);
    return %$retval;
}


#
# Backup a database, or specific tablespaces / nodes.
#
# Hash with named parameters, many optional:
# - Database
# - Target: directory/path or ref to array of same (optional for TSM)
# - Tablespaces: optional ref to list of tablespaces
# - Options (hash reference)
#   - Type: Full / Incremental / Delta (default Full)
#   - Action (Start, NoInterrupt, Continue, Terminate, DeviceTerminate,
#             ParamCheck, ParamCheckOnly) (default: NoInterrupt)
#   - Nodes: 'All', or reference to list of nodes (optional) (V9.5)
#   - ExceptNodes: reference to list of nodes to skip (optional) (V9.5)
#   - Online: boolean, default zero (offline)
#   - Compress: boolean (default zero)
#   - IncludeLogs: boolean (online only)
#   - ExcludeLogs: boolean (online only)
#   - ImpactPriority (0..100, default 50)
#   - Parallelism: 1..1024 (default computed by DB2)
#   - NumBuffers (integer, minimum 2)
#   - BufferSize (integer, minimum 8)
#   - TargetType (optional: Local, XBSA, Snapshot, TSM, Other; default Local)
#   - Userid (optional)
#   - Password (optional)
#
sub Backup {
    my $class = shift;
    my %params = validate(@_, { 'Database'    => 1,
                                'Target'      => 1,
                                'Tablespaces' => 0,
                                'Options'     => HASHREF,
                              },
                         );

    #
    # The XS code expects a reference to an array; we support either
    # a string or an array, and we translate this at the perl level.
    #
    unless (ref $params{Target}) {
        $params{Target} = [ $params{Target} ];
    }

    #
    # A full backup is indicated by an empty list of tablespaces.
    #
    $params{Tablespaces} ||= [];

    #
    # Handle default options
    #
    my $options = $params{Options};
    $options->{Type} ||= 'Full';
    $options->{Online} ||= 0;

    my $rc = db2Backup($params{Database},
                       $params{Target},
                       $params{Tablespaces},
                       $params{Options},
                      );
    $class->_handle_error("Backup");
    return $rc;
}


#------------------------------------------------------------------------

#
# Handle an error: print a warning, die (depending on options)
#
sub _handle_error {
    my ($class, $label) = @_;

    my $code = sqlcode();
    return if ($code == 0);     # No error
    my $level = ($code > 0 ? 'Warning' :'Error');
    my $errmsg = sqlaintp() || '(no error message available)';
    $errmsg =~ s!\s*$!!;
    my $state = sqlogstt() || '(no state available)';
    $state =~ s!\s*$!!;
    my $msg = "$level in $label: $errmsg / $state\n";

    #
    # Handle PrintError/PrintWarning and RaiseError/RaiseWarning
    #
    if ($options{'Print' . $level}) {
        warn $msg;
    }
    if ($options{'Raise' . $level}) {
        die $msg;
    }
    return $msg;
}


#
# Decode the instance attach information returned by sqleatin,
# used by 'Attach' and 'InquireAttach'.
#
sub _decode_attach_info {
    my ($class, $info) = @_;

    my $retval = {};
    @{$retval}{qw(Country CodePage AuthId NodeName ServerId
                  AgentId AgentIndex NodeNum Partitions)} =
                    split chr(0xff), $info;
    return $retval;
}


#
# Decode the binary data stream that describes monitor switches
#
sub _decode_monitor_switches {
    my ($class, $elem_stream) = @_;

    my $stream = DB2::Admin::DataStream::->new($elem_stream);
    my $switch_list = $stream->findNode('SWITCH_LIST') ||
      confess "No switch list present";

    my $retval = {};
    my %map = ('BUFFPOOL_SW'  => 'BufferPool',
               'LOCK_SW'      => 'Lock',
               'SORT_SW'      => 'Sort',
               'STATEMENT_SW' => 'Statement',
               'TABLE_SW'     => 'Table',
               'TIMESTAMP_SW' => 'Timestamp',
               'UOW_SW'       => 'UOW',
              );
    foreach my $node ($switch_list->getChildnodes()) {
        next unless ($node->isa("DB2::Admin::DataStream"));
        my $value = $node->findValue('OUTPUT_STATE');
        next unless (defined $value);
        my $elem_name = $node->getName();
        my $key = $map{$elem_name} ||
          confess "Unknown monitor switch [$elem_name]";
        $retval->{$key} = $value;
    }
    return $retval;
}


#
# Get database manager or database configuration
#
# Hash with named parameters:
# - Param: parameter name / ref to array of parameter names
#   (e.g. 'intra_parallel') (case-insensitive)
# - Database (optional; determines domain)
# - Flag (optional: 'Immediate' / 'Delayed' / 'Defaults'; or ref to hash with these as keys)
# - Version (defaults to SQLM_CURRENT_VERSION)
# Returns:
# - Ref to array with hash-references, each with:
#   - Name
#   - Value
#   - Automatic (optional)
#   - Computed (optional, V9.1)
#
my %type_sizes = ('16bit'  => 2,
                  'u16bit' => 2,
                  '32bit'  => 4,
                  'u32bit' => 4,
                  'float'  => 4,
                  '64bit'  => 8,
                  'u64bit' => 8,
                 );
sub _get_config_params {
    my $class = shift;
    my %params = validate(@_, { 'Param'    => 1,
                                'Flag'     => 0,
                                'Version'  => 0,
                                'Database' => 0,
                              });

    my $names = $params{Param};
    $names = [ $names ] unless (ref $names);
    confess "Invalid 'Param' parameters: must be string or array ref"
      unless (ref($names) eq 'ARRAY');
    confess "Invalid 'Param' parameter: must be at least one element"
      unless (@$names);

    $params{Version} ||= 'SQLM_CURRENT_VERSION';
    my $db2_version = DB2::Admin::Constants::->GetValue($params{Version});

    my $flags = $params{'Flag'} || {};
    $flags = { $flags => 1 } unless (ref $flags);
    foreach my $key (sort keys %$flags) {
        confess "Invalid 'Flag' parameter '$key'"
          unless ($key =~ /^(?:Immediate|Delayed|Defaults)$/);
    }

    #
    # The domain will be one of:
    # - Manager  (no 'Database' parameter present)
    # - Database
    #
    my ($domain, $database) = ('Manager', '');
    if (defined $params{Database}) {
        $domain = 'Database';
        $database = $params{Database};
    }

    my $params = [];
    my @info;
    foreach my $elem (@$names) {
        my $info = DB2::Admin::Constants::->
          GetConfigParam('Name'   => $elem,
                         'Domain' => $domain);
        confess "Invalid $domain config parameter '$elem'"
          unless (defined $info);

        my $token = DB2::Admin::Constants::->GetValue($info->{Constant});
        my $entry = { 'Token' => $token };
        if ($info->{Type} eq 'string') {
            $entry->{Size} = $info->{'Length'} ||
              confess "No length specified for string constant [$elem] [$info->{Name}]";
            $entry->{Size} += 1; # Allow DB2 to write terminating zero
        } else {
            $entry->{Size} = $type_sizes{ $info->{Type} } ||
              confess "No size known for type [$info->{Type}] and constant [$elem] [$info->{Name}]";
        }
        push @$params, $entry;
        push @info, { 'Token' => $token,
                      'Type'  => $info->{Type},
                      'Name'  => $elem,
                      'Size'  => $entry->{Size},
                    };
    }

    #
    # Make the API call
    #
    $flags->{$domain} = 1;
    my $results = db2CfgGet($params, $flags, $database, $db2_version);
    return unless ($results);   # Caller does error handling

    my $retval = [];
    foreach my $entry (@$results) {
        my $info = shift @info;

        confess "Token does not match (entry $entry->{Token}, info $info->{Token})"
          unless ($entry->{Token} == $info->{Token});
        my $elem =  { 'Name'  => $info->{Name} };
        $elem->{Value} = DB2::Admin::DataElement::->
          Decode($info->{Type}, $entry->{Value}, $info->{Size});
        foreach my $flag (qw(Automatic Computed)) {
            $elem->{$flag} = $entry->{$flag}
              if (defined $entry->{$flag});
        }
        push @$retval, $elem;
    }
    return $retval;
}


#
# Set database manager or database configuration
#
# Hash with named parameters:
# - Param: ref to hash with (Name,Value) / array of hash-refs
#   Each hash ref has:
#   - Name (value is case-insensitive)
#   - Value
#   - Automatic (optional)
#   - Computed (optional, V9.1)
#   - Manual (optional, V9.1; value is ignored)
# - Database (optional; determines domain)
# - Flag (optional: 'Immediate' / 'Delayed' / 'Reset'; or ref to hash with these as keys)
# - Version (defaults to SQLM_CURRENT_VERSION)
# Returns:
# - Boolean
#
sub _set_config_params {
    my $class = shift;
    my %params = validate(@_, { 'Param'    => 1,
                                'Flag'     => 0,
                                'Version'  => 0,
                                'Database' => 0,
                              });

    my $vals = $params{Param};
    confess "Invalid 'Param' parameters: must be hash ref or array ref of hash refs"
      unless (ref($vals) eq 'HASH' || ref($vals) eq 'ARRAY');
    $vals = [ $vals ] unless (ref $vals eq 'ARRAY');
    confess "Invalid 'Param' parameter: must be at least one element"
      unless (@$vals);

    $params{Version} ||= 'SQLM_CURRENT_VERSION';
    my $db2_version = DB2::Admin::Constants::->GetValue($params{Version});

    my $flags = $params{'Flag'} || {};
    $flags = { $flags => 1 } unless (ref $flags);
    foreach my $key (sort keys %$flags) {
        confess "Invalid 'Flag' parameter '$key'"
          unless ($key =~ /^(?:Immediate|Delayed|Reset)$/);
    }

    #
    # The domain will be one of:
    # - Manager  (no 'Database' parameter present)
    # - Database
    #
    my ($domain, $database) = ('Manager', '');
    if (defined $params{Database}) {
        $domain = 'Database';
        $database = $params{Database};
    }

    my $params = [];
    foreach my $elem (@$vals) {
        #
        # - Flag 'Immediate' / 'Delayed': value must be present
        # - Flag 'Reset': value may not be present
        #
        unless (defined $elem->{Name}) {
            confess "Invalid config parameter: required field 'Name' missing";
        }
        if (!$flags->{'Reset'} && !defined $elem->{Value}) {
            confess "Invalid config parameter with name '$elem->{Name}': required field 'Value' missing";
        } elsif ($flags->{'Reset'} && defined $elem->{Value}) {
            confess "Invalid config parameter with name '$elem->{Name}': field 'Value' not allowed with flag 'Reset'";
        }

        my $info = DB2::Admin::Constants::->
          GetConfigParam('Name'   => $elem->{Name},
                         'Domain' => $domain);
        confess "Invalid $domain config parameter '$elem->{Name}'"
          unless (defined $info);
        confess "$domain config parameter '$elem->{Name}' is not updatable"
          unless ($info->{Updatable});

        my $token = DB2::Admin::Constants::->GetValue($info->{Constant});
        my $entry = { 'Token' => $token };
        my $binary_value = DB2::Admin::DataElement::->
          Encode($info->{Type}, $elem->{Value});
        $entry->{Value} = $binary_value;
        foreach my $fld (qw(Automatic Computed Manual)) {
            $entry->{$fld} = 1 if ($elem->{$fld});
        }
        push @$params, $entry;
    }

    #
    # Make the API call; the caller performs the error handling
    #
    $flags->{$domain} = 1;
    return db2CfgSet($params, $flags, $database, $db2_version);
}


#
# Return the platform-specific null device
#
sub _null_device {
    if ($^O =~ /^MSWin/) {
        return 'nul:';
    }
    return '/dev/null';
}


#
# Cleanup when done
#
END {
    cleanup_connections(); # In XS code
}


1;                              # End on a positive note


__END__


=head1 NAME

DB2::Admin - Support for DB2 Administrative API from perl

=head1 SYNOPSIS

  use DB2::Admin;

  DB2::Admin::->SetOptions('RaiseError' => 1);
  DB2::Admin::->Attach('Instance' => 'FOO');

  # Monitor switches and snapshot
  DB2::Admin::->SetMonitorSwitches('Switches' => { 'Table' => 1,
                                                   'UOW'   => 0,
                                                 });
  my $retval = DB2::Admin::->GetSnapshot('Subject' => 'SQLMA_APPLINFO_ALL');
  DB2::Admin::->ResetMonitorSwitches();

  # Database manager configuration parameters
  my @options = DB2::Admin::->
    GetDbmConfig('Param' => [ qw(maxagents maxcagents) ]);
  print "Max agents: $options[0]{Value}\n";
  print "Max coord agents: $options[1]{Value}\n";
  DB2::Admin::->UpdateDbmConfig('Param' => [ { 'Name'  => 'jdk11_path',
                                               'Value' => '/opt/ibm/db2/...',
                                             },
                                             { 'Name'  => 'intra_parallel',
                                               'Value' => 1,
                                             },
                                           ],
                                 'Flag'  => 'Delayed');

  # Database configuration parameters
  @options = DB2::Admin::->GetDatabaseConfig('Param'    => [ qw(dbheap logpath) ],
                                             'Flag'     => 'Delayed',
                                             'Database' => 'sample',
                                            );
  print "Database heap size: $options[0]{Value}\n";
  print "Path to log files: $options[1]{Value}\n";
  DB2::Admin::->UpdateDatabaseConfig('Param'    => { 'Name'  => 'autorestart',
                                                     'Value' => 0,
                                                   },
                                     'Database' => 'sample',
                                     'Flag'     => 'Delayed');

  DB2::Admin::->Detach();

  # Database, node and DCS directories - no attach required
  my @db_dir = DB2::Admin::->GetDatabaseDirectory();
  my @db_dir = DB2::Admin::->GetDatabaseDirectory('Path' => $dbdir_path);
  my @node_dir = DB2::Admin::->GetNodeDirectory();
  my @dcs_dir = DB2::Admin::->GetDCSDirectory();

  # Catalog or uncatalog a database
  DB2::Admin::->CatalogDatabase('Database' => 'PRICES',
                                'Alias'    => 'TESTPRI',
                                'NodeName' => 'TESTNODE',
                                'Type'     => 'Remote');
  DB2::Admin::->UncatalogDatabase('Alias' => 'TESTPRI');

  # Catalog or uncatalog a node
  DB2::Admin::->CatalogNode('Protocol'    => 'TCP/IP',  # Or SOCKS/Local
                            'NodeName'    => 'TESTNODE',
                            'HostName'    => 'testhost.example.com',
                            'ServiceName' => 3700); # Service name or port number
  DB2::Admin::->UncatalogNode('NodeName' => 'TESTNODE');

  # Catalog or uncatalog a DCS database
  DB2::Admin::->CatalogDCSDatabase('Database' => 'PRICES',
                                   'Target'   => 'DCSDB');
  DB2::Admin::->UncatalogDCSDatabase('Databases' => 'PRICES');

  # Force applications - attach required. Use with care.
  DB2::Admin::->ForceApplications(@agent_ids);
  DB2::Admin::->ForceAllApplications();

  # Connect to database / Disconnect from database
  DB2::Admin::->Connect('Database' => 'mydb',
                        'Userid'   => 'myuser',
                        'Password' => 'mypass');
  DB2::Admin::->SetConnectAttributes('ConnectTimeout' => 120);
  DB2::Admin::->Connect('Database'    => 'mydb',
                        'Userid'      => 'myuser',
                        'Password'    => 'mypass',
                        'ConnectAttr' => { 'ProgramName' => 'myscript', },
                       );
  DB2::Admin::->Disconnect('Database' => 'mydb');

  # Get/set connection-level client information
  DB2::Admin::->ClientInfo('Database' => 'mydb', 'ClientUserid' => 'remote_user');
  %client_info = DB2::Admin::->ClientInfo('Database' => 'mydb');

  # Export data.  Requires a database connection.  Example omits options.
  DB2::Admin->Export('Database'   => $db_name,
                     'Schema'     => $schema_name,
                     'Table'      => $table_name,
                     'OutputFile' => "/var/tmp/data-$schema_name-$table_name.del",
                     'FileType'   => 'DEL');

  # Import data.  Requires a database connection.  Example omits options.
  DB2::Admin->Import('Database'   => $db_name,
                     'Schema'     => $schema_name,
                     'Table'      => $table_name,
                     'InputFile'  => "/var/tmp/data-$schema_name-$table_name.del",
                     'Operation'  => 'Insert',
                     'FileType'   => 'DEL');

  # Load data.  Requires a database connection.  Example omits options.
  my $rc = DB2::Admin->Load('Database'   => $db_name,
                            'Schema'     => $schema_name,
                            'Table'      => $table_name,
                            'InputFile'  => "/var/tmp/data-$schema_name-$table_name.del",
                            'Operation'  => 'Insert',
                            'SourceType' => 'DEL');
  my $state = DB2::Admin->LoadQuery('Schema'   => $schema_name,
                                    'Table'    => $table_name,
                                    'LogFile'  => $logfile,
                                    'Messages' => 'All');

  # Run table statistics.  Requires a database connection.  Example
  # omits options.
  $rc = DB2::Admin->Runstats('Database' => $db_name,
                            'Schema'   => $schema_name,
                             'Table'    => $table_name);

  # List history.  Requires an attachemnet, not a database connection.
  @history = DB2::Admin->
    ListHistory('Database'   => $db_name,
                'Action'     => 'Load', # Optional; default: all
                'StartTime'  => '20041201', # Optional; may also specify HHMMSS
                'ObjectName' => 'MYSCHEMA.MYTABLE', # Optional
                );

  # List what utilities are currently running
  my @utils = DB2::Admin->ListUtilities();
  my @utils = DB2::Admin->ListUtilities('Database' => $db_name);

  # Rebind a package.  Requires a database connection. Example omits options.
  DB2::Admin->Rebind('Database' => $db_name,
                     'Schema'   => $schema_name,
                     'Package'  => $pkg_name);

  # Backup a database (or database partition)
  DB2::Admin->Backup('Database' => $db_name,
                     'Target'   => $backup_dir,
                     'Options'  => { 'Online' => 1, 'Compress' => 1, });

  # Backup all nodes of a DPF database (V9.5 only)
  DB2::Admin->Backup('Database' => $db_name,
                     'Target'   => $backup_dir,
                     'Options'  => { 'Online' => 1, 'Nodes' => 'All', });

=head1 DESCRIPTION

This module provides perl language support for the DB2 administrative
API.  This loosely corresponds to the non-SQL functions provided by
the DB2 Command Line Processor (CLP), the 'db2' program.

This function is complementary to the DBD::DB2 database driver.  The
DBD::DB2 driver is intended for application developers and supports
SQL functions.  The DB2::Admin module is intended for administrators and
supports non-SQL database functionality, such as snapshot monitoring,
directory/catalog management, event processing, getting/setting
configuration parameters and data import/export.

This module is incomplete: not all of the DB2 administrative API is
implemented.  Features deemed useful will be added over time.

This module provides for two kinds of error handling, which can be
set using the C<SetOptions> method:

=over 4

=item *

Check return value of individual calls.  This means all the error
checking is in the application using this module.  The module
will print an error message by default, but that can be disabled.

=item *

Have the API throw an exception whenever an error occurs.  The exception
can be caught using an C<eval> block if desired.

=back

Many API calls take optional C<Version> and C<Node> parameters.  These
have the following meaning:

=over 4

=item Version

The database monitor version, a string in the format
C<SQLM_DBMON_VERSION8>.  The default is C<SQLM_CURRENT_VERSION>.

This parameter should only be set if the database that is attached to
is of a lower DB2 release level than the DB2::Admin was compiled for,
e.g. if the DB2::Admin was compiled for DB2 release 8 and the database
attached to is of DB2 release 6.

=item Node

The database node.  This can be the string C<SQLM_CURRENT_NODE> (the
default), the string C<SQLM_ALL_NODES>, or a node number.

This parameter should only be set for a partitioned database, and then
only if the API call should affect all database nodes, or a different
node than the one currently attached to.

=back

=head1 METHODS

The methods below are all intended for use by applications. The
underlying low-level functions in the XS module are not documented.

=head2 SetOptions

This method is used to set the options that determine how the DB2::Admin
module performs error-handling.  It takes a hash with option names and
option values and uses these to change the options in effect.  A hash
with the full set of options is returned.

At this time, four options are defined, named after C<DBI> connect
options:

=over 4

=item PrintError

When an error occurs, write it to STDERR using C<warn>.  This option
is on by default.

=item PrintWarn

When a warning occurs, write it to STDERR using C<warn>.  This option
is on by default.

=item RaiseError

When an error occurs, generate an exception using C<die>.  This option
is off by default.

=item RaiseWarn

When a warning occurs, generate an exception using C<die>.  This
option is off by default.

=back

=head2 SetConnectAttributes

This method is used to set default connect attributes.  (These
attributes can also be specified on the <Connect> call.)  It takes a
hash with connect attribute names and values and uses these to change
the connect attributes in effect.  A hash with the full set of connect
attributes is returned.

At this time, two options are defined, named after <db2cli.ini>
keywords:

=over 4

=item ProgramName

The name under which the database connection will be listed in the DB2
"list applications" command, DB2 snapshots, etc.  The default is the
perl script name (the basename of C<$0>).

=item ConnectTimeout

The connect (login) time-out, in seconds.  The default is 60 seconds.

=back

=head2 Attach

This method is used to attach to a database instance.  If you need to
attach to a remote instance, or need to provide a userid or password,
this method must be called before any other API function (except
C<SetOptions>).  If you attach to a local instance, this call can be
omitted; the first call to an API function will perform an implicit
local attach.

This method takes three optional named parameters:

=over 4

=item Instance

The name of the instance to attach to.  If omitted, the environment
variable C<DB2INSTANCE> must be set and will determine the instance
instead.

=item Userid

The userid used to attach.

=item Password

The password used to attach.

=back

If C<Attach> succeeds, it returns a hash reference with information on
the instance attached to, in the same format as the C<InquireAtatch>
method.  If C<Attach> fails, it returns C<undef>.

=head2 InquireAttach

This method describes the instance attached to.  On success, it
returns a hash reference with the following fields:

=over 4

=item Country

=item CodePage

=item AuthId

=item NodeName

=item ServerId

=item AgentId

=item AgentIndex

=item NodeNum

=item Partitions

=back

=head2 Detach

This method detaches from the database instance.  It returns a boolean
to indicate whether the operation succeeded.

=head2 Connect

This method is used to connect to a database.

A database connection is required for a small subset of functions
provided by this module, most notably the C<Import> and C<Export>
functions.  For those developers used to the perl DBI, it is
noteworthy that there is no <dbh> object: a database connection is not
an input parameter to those functions.  All that is required is that a
database connection exists and that the database name is provided.

This method takes one required named parameter, C<Database>, and three
optional named parameters, C<Userid>, C<Password> and C<ConnectAttr>.
Inside the module the database connections are stored in a hash
indexed by database name.  If the same database is opened twice
without a C<Disconnect> call, a warning will be issued and the old
database handle will be closed before a new one is created.

Up to 512 database connections to different databases can be made at
the same time.  The functions requiring database connections will
automatically switch between these connections.

The optional C<ConnectAttr> parameter is a referenece to a hash with
connect attributes and overrides the defaults specified with the
C<SetConnectAttributes> method.

=head2 Disconnect

This method is used to disconnect from a database.  It has one
mandatory named parameter, C<Database>.

If this method is not called before program termination, the C<END>
block in the C<DB2::Admin> module will automatically disconnect from all
databases and will issue a warning while doing so.

=head2 GetMonitorSwitches

This method returns the monitor switches in effect for the current
application.  In the absence of a C<SetMonitorSwitches> call, the
monitor switches will be inherited from the database configuration.
The monitor switches will affect the data returned by a C<GetSnapshot>
call.

This method takes two optional named parameters:

=over 4

=item Version

=item Node

=back

On success, this method returns a hash with the keys listed below.
The value will be 0 or 1, indicating whether the monitor is in effect
or not.  The same keys can be used for the C<SetMonitorSwitches>
method.

=over 4

=item UnitOfWork

=item Statement

=item Table

=item BufferPool

=item Lock

=item Sort

=item Timestamp

=back

=head2 SetMonitorSwitches

This method sets the monitor switches in effect for the current
application.  This will affect the data returned by a C<GetSnapshot>
call.

This method takes one required and two optional named parameters:

=over 4

=item Switches

A reference to a hash with the switches that should be enabled or
disabled.  Any switch option not named will be kept at the current
value.  See the C<GetMonitorSwitches> method for a list of switch
names supported.

=item Version

=item Node

=back

The return value for this method is the list of switches that was in
effect before the C<SetMonitorSwitches> call, in the same format as
returned by the C<GetMonitorSwitches> method.

=head2 ResetMonitor

This method will reset the monitor data (e.g. counters) in effect for
the current application.  It can do so globally (for all active
databases) or for a particular database.

This method takes three optional named parameters:

=over 4

=item Alias

The name of a database or alias to reset the monitor data for.  In the
absence of this parameter, monitor data will be reset for all active
databases.

=item Version

=item Node

=back

=head2 GetSnapshot

This method performs a database snapshot and returns the collected
snapshot data.  It can collect data in one or more monitoring areas,
then returns a hash reference with decoded snapshot results.

This method takes the following named parameters, of which only
C<Subject> is required:

=over 4

=item Subject

The area to be monitored.  This can be either a single value, or a
reference to an array of values.  Each value can be a string with an
object type, like C<SQLMA_APPLINFO_ALL>, or a reference to an hash
that contains a type, optional agent id, and optional object name.

For example, to get lock snapshot data for databases 'FOO' and
'BAR', call this method with the following C<Subject> parameter:

  'Subject' => [ { 'Type' => 'SQLMA_DBASE_LOCKS' }, 'Object' => 'FOO' },
                 { 'Type' => 'SQLMA_DBASE_LOCKS' }, 'Object' => 'BAR' },
               ];

To get lock snapshot data for a particular agent id, call this method
with the following C<Subject> parameter:

  'Subject' => { 'Type'    => 'SQLMA_APPL_LOCKS_AGENT_ID' },
                 'AgentId' => 12345,
               },

In all cases, the C<Type> is required, and C<Object> and C<AgentId>
are optional and mutually exclusive.

=item Version

=item Node

=item Class

The snapshot class.  This is a string that can be
C<SQLM_CLASS_DEFAULT> (a normal snapshot, which is the default),
C<SQLM_CLASS_HEALTH>, or C<SQLM_CLASS_HEALTH_WITH_DETAIL>.

Health snapshots are only available with DB2 release 8 or higher, and
if the health monitor is active.

=item Store

This boolean parameter indicates whether the snapshot results are to
be stored at the DB2 server for viewing using SQL table functions.
This is false by default.

=back

The return value from this method is a reference to a hash with data
in the C<DB2::Admin::DataStream> format.  When developing new applications,
users are recommended to use the C<Data::Dumper> module to study the
output format.

When called in array context, this function returns both the parsed
data in C<DB2::Admin::DataStream> format and the original binary data.  This
can be used to save the binary data for debugging or later analysis.

=head2 GetDbmConfig

This method is used to inquire database manager configuration
parameters.  The parameters supported are taken from a configuration
file, C<DB2::Admin/db2_config_params.pl>, which is currently known to be
incomplete and is extended on an as-needed basis.

This method takes the following named parameters:

=over 4

=item Param

The name of the configuration parameter; optionally, a reference to an
array of configuration parameters.  The names are case-insensitive.

=item Flag

An optional parameter that specifies where to get the configuration
parameters.  It can be set to C<Immediate>, C<Delayed> and
C<Defaults>.  In the absence of this parameter, DB2 defaults to
C<Immediate>.  If multiple flag values need to be combined
(e.g. Delayed + Defaults), a hash-reference with the flag names as
keys and a true value can be specified.

=item Version

=back

The return value is an array of results, each a hash reference with
C<Name> and C<Value> fields, and an optional C<Automatic> or
C<Computed> field if the database manager configuration parameter is
set automatically.  The order of the results matches the order
specified in the C<Name> parameter.

=head2 UpdateDbmConfig

This method is used to update database manager configuration
parameters.  The parameters supported are taken from a configuration
file, C<DB2::Admin/db2_config_params.pl>, which is currently known to be
incomplete and is extended on an as-needed basis.

This method takes the following named parameters:

=over 4

=item Param

A hash-reference with the fields C<Name>, C<Value> and optionally an
entry-level flag (C<Automatic>, C<Computed> or C<Manual>, see below).

Optionally, a reference to an array of hash-references of the same
structure.

The C<Name> field is case-insensitive.  The C<Value> field is required
when the C<Flag> is C<Immediate> or C<Delayed>, but not allowed when
the C<Flag> is C<Reset>.

The entry-level flags are:

=over 4

=item Automatic

Let DB2 set the value automatically.  The value specified in this
call is accepted but will be overriden by DB2.

=item Computed

Let DB2 set the value once at start-up.  The value specified in this
call is accepted but will be overriden by DB2. This can only be used
in DB2 V9.1 and then only for specific parameters such as
'database_memory' - see the DB2 documentation for details.

=item Manual

Keep the value computed by DB2 and switch to manual configuration, but
don't override the current computed value.  The value specified in this
call is ignored. This can only be used in DB2 V9.1.

=back

=item Flag

An optional parameter that specifies where to set the configuration
parameters.  It can be set to C<Immediate>, C<Delayed> and C<Reset>.
In the absence of this parameter, DB2 defaults to C<Immediate>.  If
multiple flag values need to be combined (e.g. Reset + Immediate), a
hash-reference with the flag names as keys and a true value can be
specified.

WARNING: if a configuration parameter is only set immediately, and no
separate call is made to set the delayed value, it may be lost when a
new DB2 process is started.

=item Version

=back

This method returns true on success and false on failure.

=head2 GetDatabaseConfig

This method is used to inquire database manager configuration
parameters.  The parameters supported are taken from a configuration
file, C<DB2::Admin/db2_config_params.pl>, which is complete for
database configuration parameters up to DB2 release V9.7.

Querying delayed and default database parameters does not require an
instance attach or database connection.  Querying current database
parameters (the 'Immediate' flag) requires a database connection has
been established.

This method takes the following named parameters:

=over 4

=item Param

The name of the configuration parameter; optionally, a reference to an
array of configuration parameters.  The names are case-insensitive.

=item Flag

An optional parameter that specifies where to get the configuration
parameters.  It can be set to C<Immediate> (the DB2 default),
C<Delayed> or C<Defaults>.  If multiple flag values need to be
combined (e.g. Delayed + Defaults), a hash-reference with the flag
names as keys and a true value can be specified.

=item Version

=back

The return value is an array of results, each a hash reference with
C<Name> and C<Value> fields, and an optional C<Automatic> field if the
database configuration parameter is set automatically.  The order of
the results matches the order specified in the C<Name> parameter.

=head2 UpdateDatabaseConfig

This method is used to update database manager configuration
parameters.  The parameters supported are taken from a configuration
file, C<DB2::Admin/db2_config_params.pl>, which is complete for database
configuration parameters up to DB2 release V9.7.

Updating delayed and default database parameters does not require an
instance attach or database connection.  Updating current database
parameters (the 'Immediate' flag) requires a database connection has
been established.

WARNING: if a configuration parameter is only set immediately, and no
separate call is made to set the delayed value, it may be lost when a
new DB2 process is started.

This method takes the following named parameters:

=over 4

=item Param

A hash-reference with the fields C<Name>, C<Value> and optionally an
entry-level flag (C<Automatic>, C<Computed> or C<Manual>, see below).

Optionally, a reference to an array of hash-references of the same
structure.

The C<Name> field is case-insensitive.  The C<Value> field is required
when the C<Flag> is C<Immediate> or C<Delayed>, but not allowed when
the C<Flag> is C<Reset>.

The entry-level flags are:

=over 4

=item Automatic

Let DB2 set the value automatically.  The value specified in this
call is accepted but will be overriden by DB2.

=item Computed

Let DB2 set the value once at start-up.  The value specified in this
call is accepted but will be overriden by DB2. This can only be used
in DB2 V9.1 and then only for specific parameters such as
'database_memory' - see the DB2 documentation for details.

=item Manual

Keep the value computed by DB2 and switch to manual configuration, but
don't override the current computed value.  The value specified in this
call is ignored. This can only be used in DB2 V9.1.

=back

=item Flag

An optional parameter that specifies where to get the configuration
parameters.  It can be set to C<Immediate> (the DB2 default),
C<Delayed> and C<Reset>. If multiple flag values need to be combined
(e.g. Reset + Delayed), a hash-reference with the flag names as keys
and a true value can be specified.

=item Version

=back

=head2 GetDatabaseDirectory

This method does not require an instance attachment.  It queries the
database directory and returns an array of hash-references, each with
fields like C<Database>, C<Alias> and C<Type>.  The fields available
depends on the entry in the database directory; blank fields are not
present in the hash.  The names of the fields match those in the
C<CatalogDatabase> method used to add new entries to the database
directory.

This method takes one optional named parameter, C<Path>.  When omitted,
the system database directory is retrieved.

=head2 CatalogDatabase

This method adds a new database to the database directory.  No
instance attachment or database connection is required.

This method takes named parameters that match the values returned by
the C<GetDatabaseDirectory> method:

=over 4

=item Alias

The database alias name.  This parameter is required.  The database
alias must be unique within the database directory.

=item Database

The database name.  This parameter is required.

=item NodeName

This parameter is optional and used for remote databases.  This should
match an entry in the node directory.

=item Path

This parameter is optional and used for locally cataloged databases.

=item Comment

This parameter is optional and provides a comment describing the database.

=item DBType

This parameter is required and describes the database type.  The
following values are supported:

=over 4

=item Indirect

=item Remote

=item DCE

=back

=item Authentication

This parameter is optional and used to describe the database
authentication.  Doing so is optional: when omitted (or set to the
default of "Not specified"), the DB2 client will ask the server for
its desired authentication method as part of the connection handshake.
Setting the authentication in the database to a value conflicting with
that at the database server will cause the client to fail to connect.

The following values are supported:

=over 4

=item Server

=item Client

=item Kerberos

=item Not specified

=item DCE

=item DCS

=item Kerberos / Server Encrypt

=item DCS Encrypt

=item Server Encrypt

=item Server / Data Encrypted

=item GSS Plugin

=item GSS Plugin / Server Encrypt

=item Server / Optional Data Encrypted

=back

=item Principal

The Kerberos principal for the database, if Kerberos authentication is
used.

=back

=head2 UncatalogDatabase

This method removes an entry from the database directory.  It takes
one named parameter, C<Alias>.

=head2 GetNodeDirectory

This method does not require an instance attachment.  It queries the
node directory and returns an array of hash-references, each with
fields like C<HostName>, C<NodeName> and C<Protocol>.  The fields
available depends on the entry in the node directory; blank fields are
not present in the hash.

This method does not take any parameters.

=head2 CatalogNode

This method adds a new node to the node directory.  No
instance attachment or database connection is required.

This method takes named parameters that match the values returned by
the C<GetNodeDirectory> method:

=over 4

=item NodeName

The node name.  This parameter is required.  The node alias must be
unique within the node directory.

=item Comment

This parameter is optional and provides a comment describing the node.

=item Protocol

This parameter is required and describes the protocol used to connect
to the database.  Only a subset of node types is supported: TCP/IP
(including v4 and v6), SOCKS (including v4), and Local.  The protocol
can be specified in the same format as returned by C<getNodeDirectory>
or by a shorter name.  The values supported are:

=over 4

=item TCPIP

=item TCP/IP

Alias for C<TCPIP> matching C<GetNodeDirectory>

=item TCPIP4

=item TCP/IPv4

Alias for C<TCPIP4> matching C<GetNodeDirectory>; only on DB2 V9.

=item TCPIP6

=item TCP/IPv6

Alias for C<TCPIP6> matching C<GetNodeDirectory>; only on DB2 V9.

=item SOCKS

=item SOCKS4

=item TCP/IPv4 using SOCKS

Alias for C<SOCKS4> matching C<GetNodeDirectory>; only on DB2 V9.

=item Local

=item Local IPC

Alias for C<Local> matching C<GetNodeDirectory>

=back

=item Hostname

This parameter is required for TCP/IP and SOCKS nodes and describes
the hostname of the remote database.

=item ServiceName

This parameter is required for TCP/IP and SOCKS nodes and describes
the port number or service name of the remote database.

=item InstanceName

This parameter is required for Local IPC nodes and describes the
instance name.

=back

=head2 UncatalogNode

This method removes an entry from the node directory.  It takes one
named parameter, C<NodeName>.

=head2 GetDCSDirectory

This method does not require an instance attachment.  It queries the
DCS (gateway) directory and returns an array of hash-references, each
with fields like C<Database>, C<Target> and C<Library>.  The fields
available depends on the entry in the DCS directory; blank fields are
not present in the hash.

This method does not take any parameters.

=head2 CatalogDCSDatabase

This method adds a new DCS database to the DCS directory.  No
instance attachment or database connection is required.

This method takes named parameters that match the values returned by
the C<GetDCSDirectory> method:

=over 4

=item Database

The local database name.  This parameter is required.  The database
name must be unique within the DCS directory.

=item Target

The target database name.  This parameter is required.

=item Library

This parameter is optional and describes the application requester
library to be used.  When omitted, DB2 connect will be used.

=item Parameter

This parameter is optional and contains connect options for the DCS
database.

=item Comment

This parameter is optional and  provides a comment describing the  DCS
database.

=back

=head2 UncatalogDCSDatabase

This method removes an entry from the DCS directory.  It takes one
named parameter, C<Database>.

=head2 ForceApplications

This method forces selected applications (specified by agent id) that
are connected to the instance.  Applications are forced
asynchronously; please see the documentation for the C<sqlefrce> API
call for limitations and implementation.

This method takes an array of numeric agent ids and returns a boolean.
Note that the underlying API sometimes returns success even if one
or more agent ids were invalid and could not be forced.

Invoking this method may be career suicide when used on production
instances. Use with care.

=head2 ForceAllApplications

This method forces all applications connected to the instance.
Applications are forced asynchronously; please see the documentation
for the C<sqlefrce> API call for limitations and implementation.

This method takes no parameters and returns a boolean.

Invoking this method may be career suicide when used on production
instances. Use with care.

=head2 Export

This method is used to export table data to a file.  At this time,
only a limited subset of DB2 export functionality is supported;
specifically, support for column renames and table hierarchies is not
provided.  Additional functionality will be added on request if deemed
useful.

This method takes a large set of named parameters and returns an
integer with the number of rows exported on success and -1 on error.

=over 4

=item Database

The database name.  This parameter is required.  A connection to this
database must exist, i.e. the C<Connect> method must have been called
for this database.

=item Schema

The schema name of the table to export.  This parameter is required.

=item Table

The name of the table to export.  This parameter is required.

=item Columns

An optional parameter with an array-reference of the columns to be
exported.

=item Where

An optional parameter with the WHERE clause selecting the data to be
exported.  The WHERE keyword itself should not be included in this
parameter.  Placeholders in the DBI fashion are not supported; all
selection values must be literals and strings must be quoted properly.

=item FinalClauses

An optional parameter with SELECT clauses that follow the WHERE
clause, i.e. optional ORDER BY, GROUP BY, HAVING, FETCH, and ISOLATION
clauses.  Placeholders are not supported.

=item FileType

This parameter is mandatory and specifies the type of output file:
C<DEL> for delimited files (CSV-style) or C<IXF> for IXF files.

=item FileOptions

An optional parameter with a hash-reference of file export options.
At this time, the options below are supported, all of which apply only
to the C<DEL> file type unless otherwise mentioned.

=over 4

=item CharDel

The delimiter around string fields.

=item CodePage

The code page (character set) modifier, e.g. 819 or 1208.

=item ColDel

The column delimiter.

=item DatesISO

Write out dates in ISO format, i.e. YYYY-MM-DD.

=item DecPlusBlank

Replace the leading + before a decimal number by a blank

=item LobsInFile

This option can be used with both IXF and DEL files.  It specifies
that the file will contain references to external file(s) with LOB
information.  This parameter must be combined with the C<LobPath>
parameter.

=item NoCharDel

Don't write delimiters around character fields.  Note that DB2 will
not be able to import the data unless the C<NoCharDel> option is
specified for the import or load operation -- use this only for export
to other databases or products.

=item StripZeros

Strip leading zeros before numbers

=item TimestampFormat

The timestamp format.

=item XmlInSepFiles

This option is relevant for DB2 V9.1 and later and applies to export
of files with XML data.  It needs to be combined with the XmlPath
option.

The boolean XmlInSepFiles option determines whether each XML document
(contents of an XML column in a single record) is written to a
separate file, or whether all such XML data is written to a single
file.  The default is false (write all XML data to a single file).

=back

=item OutputFile

This mandatory parameter specifies the name of the output file.

=item LogFile

This optional parameter specifies the name of the error log file.
This file is appended to when it already exists.  If omitted, the log
goes to C</dev/null> or C<nul:>.

=item LobPath

This optional parameter specifies the name of a directory where LOBs
are stored.  This must be combined with the C<LobsInFile> file option
and may be combined with the C<LobFile> parameter.

The C<LobPath> parameter may be a string or a reference to an array of
strings.  In the latter case, DB2 will stripe LOBs across multiple
directories.

The directory name(s) specified must already exist, must be defined on
the client machine from which the Export command is run, and must be
writable by the user issuing the Export command.  If the resulting
files are intended to be loaded with the C<Load> command, the
directory name needs to be visible to the target database server - see
the documentation for the C<Load> C<LobPath> parameter for details.

=item LobFile

This optional parameter specifies the filename prefix for LOB files.
It can only be specified if the C<LobsInFile> file modifier and the
C<LobPath> parameter are present.

The C<LobFile> parameter may be a string or a reference to an array of
strings.

=item ExportOptions

This optional parameter is a reference to a hash with export options
and can only be used with DB2 V9.1 or later.  The following export
options are defined:

=over 4

=item XmlSaveSchemas

This boolean option determines whether XML schema ids will be included
in the output file or not.

=back

=item XmlPath

This optional parameter can only be used with DB2 V9.1 or later and
specifies the name of a directory where XML data will be stored.  This
may be combined with the C<XmlInSepFiles> file option, the
C<XmlSaveSchema> export option and the C<XmlFile> parameter.

The C<XmlPath> parameter may be a string or a reference to an array of
strings.  In the latter case, DB2 will stripe XML data across multiple
directories.

The directory name(s) specified must already exist, must be defined on
the client machine from which the Export command is run, and must be
writable by the user issuing the Export command.

=item XmlFile

This optional parameter specifies the filename prefix for XML files.
It can only be specified if the C<XmlPath> parameter is present.

The C<XmlFile> parameter may be a string or a reference to an array of
strings.

=back

=head2 Import

This method is used to import a file into a table.  Existing data can
be added to (insert mode), replaced (replace mode), or overwritten on
duplicate keys (insert_update mode).  The import functions go through
the transaction log; no tablespace backup is required once the
operation succeeds.

Importing data is less efficient than the C<Load> method.  IBM
recommends load over import for more than 50,000 rows or 50MB of data.

At this time, only a limited subset of DB2 import functionality is
supported; specifically, support for table hierarchies and XML
schema-related validation options is not provided.  Additional
functionality will be added on request if deemed useful.

This method takes a large set of named parameters and returns a hash
reference with row information on success and C<undef> on failure.

=over 4

=item Database

The database name.  This parameter is required.  A connection to this
database must exist, i.e. the C<Connect> method must have been called
for this database.

=item Schema

The schema name of the table to import into.  This parameter is
required.

=item Table

The name of the table to import into.  This parameter is required.

=item TargetColumns

An optional array-reference with the names of the columns to load.
This should correspond to the input file column specification of the
C<InputColumns> parameter.

=item Operation

The import operation.  Legal values are:

=over 4

=item Insert

Insert rows into the table, appending to the existing data.  Skip rows
with duplicate keys.

=item Insert_Update

Insert rows into the table, appending to the existing data. Row with
duplicate keys replace existing rows.

=item Replace

Replace the contents of the table (i.e. delete all existing rows
before importing the data).

=back

=item FileType

This parameter is mandatory and specifies the type of input file:
C<DEL> for delimited files (CSV-style) or C<IXF> for IXF files.

=item FileOptions

An optional parameter with a hash-reference of file import options
(describing the input file, not the import operation).  At this time,
seven generic options are supported for all file types and two options
are supported for the C<DEL> file type.

=over 4

=item GeneratedIgnore

=item GeneratedMissing

=item IdentityIgnore

=item IdentityMissing

=item NoDefaults

=item UseDefaults

=item CharDel

The delimiter around string fields (DEL files only).

=item CodePage

The code page (character set) modifier, e.g. 819 or 1208.

=item ColDel

The column delimiter (DEL files only).

=item DateFormat

The format for date values (DEL files only). See the IBM documentation
for details.  A useful value to import Sybase-generated files with a
date format like 'Apr  5 2005' is

  'DateFormat' => 'MMM DD YYYY'

=item DelPriorityChar

For DEL files: support embedded newlines in column values

=item ImpliedDecimal

A flag indicating the position of the decimal point is implied (DEL
files only)

=item KeepBlanks

Keep leading and trailing blanks for character fields (DEL files only)

=item LobsInFile

This option can be used with both IXF and DEL files.  It specifies
that the file will contain references to external file(s) with LOB
information.  This parameter must be combined with the C<LobPath>
parameter.

=item NoCharDel

Don't assume delimiters around character fields (DEL files only). This
should be used only for import from other databases or products.

=item StripTBlanks

A flag indicating that trailing blanks need to be stripped.  Yes, this
flag has an ugly name - it really I<is> spelled C<StripTBlanks>.

=item TimeFormat

The time format (DEL files only)

=item TimestampFormat

The format for date/time values (DEL files only). See the IBM
documentation for details.  A useful value to import Sybase-generated
files with a timestamp format like 'Apr  5 2005 11:59:59:000PM' is

  'TimestampFormat' => 'MMM DD YYYY HH:MM:SS:UUUTT'

=back

=item InputFile

This mandatory parameter specifies the name of the input file.

=item InputColumns

This optional parameter is an array-reference that indicates which of
the columns in the input file should be used for import.  For IXF
files, this is an array of column names, selecting which columns from
the file are of interest.  For DEL files, this is an array of column
positions (starting at 1).

For example, if a DEL files contains 5 columns, and the second column
must be skipped, specify:

  InputColumns => [ 1, 3, 4, 5 ]

The related C<TargetColumns> parameter allows you to specify which
column names in the target table are to be loaded.

=item LogFile

This optional parameter specifies the name of the error log file.
This file is appended to when it already exists.  If omitted, the log
goes to C</dev/null> or C<nul:>.

=item ImportOptions

An optional hash reference with import options (those affecting the
import operation itself, not describing the input file).

=over 4

=item RowCount

The maximum number of rows to import

=item RestartCount

The number of rows to skip before starting; intended for use after a
previous import operation failed partway through.

=item SkipCount

Functionally identical to C<RestartCount>

=item CommitCount

How often import should commit.  The default is 'Automatic'.

=item WarningCount

The maximum number of warnings before ending the import.  The default
is 0 (infinite).

=item Timeout

A boolean parameter indicating whether the C<locktimeout> parameter
should be honored.  When true, or if this option is omitted, lock
timeouts are respected; when set to false, there is no timeout.

=item AccessLevel

A string indicating the access level allowed while the import is in
progress. The default is 'None' (import locks the table exclusively);
the other allowed option is 'Write'.

=item XmlParse

A string indicating the way XML data should be parsed.  Supported
values are 'Preserve' (also 'PreserveWhitespace') and 'Skip' (also
'SkipWhitespace').  This option can only be specified with DB2 V9.1
and later.

=back

=item LobPath

This optional parameter specifies the name of a directory where LOBs
are stored.  This must be combined with the C<LobsInFile> file option.

The C<LobPath> parameter may be a string or a reference to an array of
strings.  It must match the C<LobPath> parameter specified for the
C<Export> command that generated the data and LOB files.

The directory name(s) specified must already exist, must be defined on
the client machine from which the Import command is run, and must be
readable by the user issuing the Import command.

=item XmlPath

This optional parameter specifies the name of a directory where XML
data is stored.  This parameter is only valid in DB2 V9.1 and later.

The C<XmlPath> parameter may be a string or a reference to an array of
strings.  It must match the C<XmlPath> parameter specified for the
C<Export> command that generated the data and XML files.

The directory name(s) specified must already exist, must be defined on
the client machine from which the Import command is run, and must be
readable by the user issuing the Import command.

=back

The return value is a hash reference with the following keys:

=over 4

=item RowsRead

=item RowsInserted

=item RowsUpdated

=item RowsRejected

=item RowsSkipped

=item RowsCommitted

=back

=head2 Load

This method is used to load a file into a table.  Existing data can be
added to (insert mode) or replaced (replace mode), or overwritten on
duplicate keys (insert_update mode).  The load functions do not go
through the transaction log and may not be recoverable (see the long
disclaimer further in this description).

Loading data is more efficient than the C<Import> method, but has a
higher startup cost.  IBM recommends load over import for more than
50,000 rows or 50MB of data.

This method is only available for DB2 release 8.2 and higher (the LOAD
functions in previous DB2 releases has a substantially different API,
for which no perl wrapper has been implemented).

At this time, only a limited subset of DB2 load functionality is
supported; specifically, support for TSM media, DataLinks and table
hierarchies is not provided.  Additional functionality will be added
on request if deemed useful.

Because the C<Load> functions bypass the transaction log, a loaded
table may not be usable after the load completes, and may not be
available after a database restart - unless the appropriate measures
are taken.  Please see the DB2 LOAD documentation for full details.  A
short summary (that omits a lot of details and caveats):

=over 4

=item *

Load is not subject to restrictions for databases configured to use
circular logging.  Generally, only non-important test databases are
configured with circular logging; most databases have archive logging
enabled.

=item *

If the load is marked as non-recoverable, it is not subject to use
restrictions once the load completes.  However, the table will be
unavailable if the database is restarted before a backup is taken.
This is different from Sybase, where the table will be available in
the pre-load state.

=item *

If the load is marked as recoverable (the default), either the loaded
data must be copied by the server (see the C<CopyDirectory> argument),
or a database or tablespace backup must be performed by the DBAs.  If
this is not done, the table may be put in a mode where data can be
read but not updated.

=item *

If the load fails, a follow-up command may have to be issues to
continue or terminate the load.  This command is I<not> issued
automatically, because there are cases where terminating a partially
failed load will make things worse (e.g. force index rebuilds).

=back

This method takes a large set of named parameters and returns a hash
reference with row information on success (optionally a pair of hash
references with row and DPF information) and C<undef> on failure.

=over 4

=item Database

The database name.  This parameter is required.  A connection to this
database must exist, i.e. the C<Connect> method must have been called
for this database.

=item Schema

The schema name of the table to load into.  This parameter is
required.

=item Table

The name of the table to load into.  This parameter is required.

=item TargetColumns

An optional array-reference with the names of the columns to load.
This should correspond to the input file column specification of the
C<InputColumns> parameter.

=item Operation

The load operation.  Legal values are:

=over 4

=item Insert

Insert rows into the table, appending to the existing data.  Skip rows
with duplicate keys.

=item Replace

Replace the contents of the table (i.e. delete all existing rows
before loading the data).  On DB2 V9.5, this has the same effect as
"Replace KeepDictionary".

=item Replace KeepDictionary

This option is only valid on DB2 V9.5.  For compressed tables, the
compression dictionary is retained.  Unlike DB2 V9.1, a separate reorg
step is no longer required.

=item Replace ResetDictionary

This option is only valid on DB2 V9.5.  For compressed tables, a new
compression dictionary is calculated.  Unlike DB2 V9.1, a separate
reorg step is no longer required.

=item Restart

Restart a previously partially completed load.

=item Terminate

Terminate a previously partially completed load.

=back

=item SourceType

This   parameter is mandatory and  specifies   the type of input data:
C<DEL> for  delimited files (CSV-style), C<IXF>  for IXF files, C<SQL>
or C<Statement> for  a SQL statement.   Note that DB2 does not support
loading IXF files into DPF databases.

=item FileLocation

For data loaded from file (DEL / IXF), indicates whether the data is
readable on the database server (C<Server>) or only available on a
remote client (C<Client>).  When omitted, this parameter defaults to
the safe value of C<Client>.

Specify C<Server> when the load is invoked on the database server, or
when the file is available on a network drive that has the same
pathname on client machine and server host.

=item FileOptions

An optional parameter with a hash-reference of file load options
(describing the input file, not the load operation).  Please see the
DB2 documentation for the meaning of these options; this documentation
just lists them.

First, generic options for both IXF and DEL files:

=over 4

=item AnyOrder

=item GeneratedIgnore

=item GeneratedMissing

=item GeneratedOverride

=item IdentityIgnore

=item IdentityMissing

=item IdentityOverride

=item LobsInFile

This option can be used with both IXF and DEL files.  It specifies
that the file will contain references to external file(s) with LOB
information.  This parameter must be combined with the C<LobPath>
parameter.

=item NoRowWarnings

=item UseDefaults

=item IndexFreespace

=item PageFreespace

=item TotalFreespace

=back

Next, the options for DEL files:

=over 4

=item CharDel

=item CodePage

The code page (character set) modifier, e.g. 819 or 1208.

=item ColDel

=item DateFormat

The format for date values. See the IBM documentation for details.  A
useful value to load Sybase-generated files with a date format like
'Apr  5 2005' is

  'DateFormat' => 'MMM DD YYYY'

=item DatesISO

=item DecPlusBlank

=item DecPt

=item DelPriorityChar

Support embedded newlines in column values

=item DumpFile

The name of the file to write records from the input file that cannot
be parsed.  This file is server-side, so for loads from the client you
want to make sure to specify a filename on network filesystem that is
visible to both client and server machine.  See also the
'DumpFileAccessAll' parameter.

NOTE: the dumpfile may have at most one file extension,
i.e. 'LOAD.FILE' is legal but 'LOAD.DUMP.FILE' is not.  This
restriction is imposed by DB2, not the perl API.

=item DumpFileAccessAll

This boolean parameter can only be specified when 'DumpFile' is
present.  It indicates that the dumpfile should be globally readable.
The default is to make the dump file readable only by the database
server instance userid and the DB2 administrators group.

=item ImpliedDecimal

=item KeepBlanks

=item NoCharDel

Don't assume delimiters around character fields (DEL files only). This
should be used only for load from other databases or products.

=item TimeFormat

=item TimestampFormat

The format for date/time values. See the IBM documentation for
details.  A useful value to load Sybase-generated files with a
timestamp format like 'Apr  5 2005 11:59:59:000PM' is

  'TimestampFormat' => 'MMM DD YYYY HH:MM:S:UUUTT'

=back

Finally, the options for IXF files:

=over 4

=item ForceIn

=item NoCheckLengths

=back

=item InputFile

This parameter is required for IXF and DEL files and specifies the
name of the input file.

For DEL files, you can specify either a string (one file) or a
reference to an array of strings (multiple files).

For IXF files, you can only specify a string (one file).

=item InputStatement

This parameter is required for SQL statements and specifies the SELECT
statement to read the data to be loaded.

=item InputColumns

This optional parameter is an array-reference that indicates which of
the columns in the input file should be used for loading.  For IXF
files, this is an array of column names, selecting which columns from
the file are of interest.  For DEL files, this is an array of column
positions (starting at 1).

For example, if a DEL files contains 5 columns, and the second column
must be skipped, specify:

  InputColumns => [ 1, 3, 4, 5 ]

The related C<TargetColumns> parameter allows you to specify which
column names in the target table are to be loaded.

=item CopyDirectory

For a recoverable load, the load functions can make a copy of the
parsed input data on the database server (in internal DB2 format)
before performing the load operation.  Even though the loaded data is
not in the transaction log, the database can recover the table by
re-loading the copied files.

This parameter specify the server-side directory wheres such copy
files will be stored.  Always pick such a directory in conjunction with
your DBA.

Morgan Stanley note: The Sybase::Xfer equivalent should pick this for
the user according to a rule specified by the DBA, and this parameter
should be a boolean: make a copy yes/no.

=item LogFile

This optional parameter specifies the name of the error log file.
This file is appended to when it already exists.  If omitted, the log
goes to C</dev/null> or C<nul:>.

If you are loading into a partitioned (DPF) database, this file will
be the basename; additional details will be found in files with the
partition number and load phase appended.  For example, if you specify
the logfile '/var/tmp/load.out', additional log files will have names
of the format '/var/tmp/load.out.<phase>.<partition>'.

=item TempFilesPath

This optional parameter specifies the name of the directory, on the
database server, where the load operation will store temporary files
(messages, consistency points, delete phase information).  It can be
safely omitted, in which case the database server will use a default
directory for this.

=item LoadOptions

An optional hash reference with load options (those affecting the load
operation itself, not describing the input file).  Please see the DB2
documentation for the meaning of these options; this documentation
just lists them.

=over 4

=item RowCount

The maximum number of rows to load.

=item UseTablespace

The tablespace to use to rebuild the index(es).

=item SaveCount

The number of rows to load before establishing a consistency point
from which the load can be restarted.

=item DataBufferSize

=item SortBufferSize

=item WarningCount

=item HoldQuiesce

Boolean

=item CpuParallelism

=item DiskParallelism

=item NonRecoverable

Boolean.  The default is false (recoverable).

=item IndexingMode

Legal values are:

=over 4

=item AutoSelect

=item Rebuild

=item Incremental

=item Deferred

=back

=item AccessLevel

Legal values are:

=over 4

=item None

=item Read

=back

=item LockWithForce

Boolean

=item CheckPending

Legal values are:

=over 4

=item Immediate

=item Deferred

=back

=item Statistics

This parameter determines whether to colelct statistics during load.
This requires that a runstats profile has been previously set up for
the table. Legal values are:

=over 4

=item None

=item UseProfile

=back

=item XmlParse

A string indicating the way XML data should be parsed.  Supported
values are 'Preserve' (also 'PreserveWhitespace') and 'Skip' (also
'SkipWhitespace').  This option can only be specified with DB2 V9.5
and later.

=back

=item DPFOptions

An optional hash reference with DPF (partitioned database) load
options (those affecting the DPF aspects of the load operation itself,
not describing the input file).  Please see the DB2 documentation for
the meaning of these options; this documentation just lists them.

The presence of this hash reference also triggers the extended return
value (described below).  In cases where you want to have the extended
return value but do not want to set DPF options, just pass an empty
hash reference.

=over 4

=item OutputDBPartNums

An array reference with database partition numbers

=item PartitioningDBPartNums

An array reference with database partition numbers

=item MaxNumPartAgents

Integer

=item IsolatePartErrors

This can have the following string values:

=over 4

=item SetupErrorsOnly

=item LoadErrorsOnly

=item SetupAndLoadErrors

=item NoIsolation

=back

=item StatusInterval

Integer.

=item PortRange

An array reference with two port numbers

=item CheckTruncation

Boolean

=item Trace

Integer

=item Newline

Boolean

=item OmitHeader

Boolean

=item RunStatDBPartnum

Integer

=back

=item ExceptionSchema

This optional parameter determines the schema name for the exception
table (set by the 'ExceptionTable' parameter).  If omitted, the
default is to use the 'Schema' parameter.

=item ExceptionTable

This optional parameter determines the exception table.  Rows that can
be loaded into the table but violate index or foreign key constraints
will be stored into this table.  See also the 'ExceptionSchema'
parameter.

=item LobPath

This optional parameter specifies the name of a directory where LOBs
are stored.  This must be combined with the C<LobsInFile> file option.

The C<LobPath> parameter may be a string or a reference to an array of
strings.  It must match the C<LobPath> parameter specified for the
C<Export> command that generated the data and LOB files.

The directory name(s) specified must be visible to the database server
machine, and both the directory and the files it contains must be
readable by the userid under which the database server is running.
This generally means the LOB path should be on a network share (NFS)
visible to both the client machine running the Export and the database
server handling the Load; it may also require that the permission for
LOB files be changed to world-readable.

=item XmlPath

This optional parameter specifies the name of a directory where XML
data is stored.  This parameter is only valid in DB2 V9.5 and later.

The C<XmlPath> parameter may be a string or a reference to an array of
strings.  It must match the C<XmlPath> parameter specified for the
C<Export> command that generated the data and XML files.

The directory name(s) specified must be visible to the database server
machine, and both the directory and the files it contains must be
readable by the userid under which the database server is running.
This generally means the XML path should be on a network share (NFS)
visible to both the client machine running the Export and the database
server handling the Load; it may also require that the permission for
XML files be changed to world-readable.

=back

The return value is a pair of hash references, the first one with
overall load results and the second with DPF-specific load results, or
a single C<undef> on failure.  If C<wantarray> is false, only the
first hash reference is returned.

The first return value has the following keys:

=over 4

=item RowsRead

=item RowsSkipped

=item RowsLoaded

=item RowsRejected

=item RowsDeleted

=item RowsCommitted

=back

The second return value is an empoty hash reference unless the
C<DPFOptions> input parameter is specified.  If so, it has the
following keys:

=over 4

=item RowsRead

=item RowsRejected

=item RowsPartitioned

=item AgentInfo

A reference to an array of hash references, each with the following
keys:

=over 4

=item SQLCode

=item TableState

=item NodeNum

=item AgentType

=back

=back

=head2 LoadQuery

This method is used to query the state of a load against a database
table.  It indicates the state of the table, the load phase, row
counts, and messages.  It requires a database connection; the database
name itself is not specified as a parameter.

This method takes the following named parameters, all mandatory:

=over 4

=item Schema

The schema name of the table to load into.  This parameter is
required.

=item Table

The name of the table to load into.  This parameter is required.

=item Messages

The amount of messages returned in the logfile.  The following values
may be specified:

=over 4

=item All

=item None

=item New

=back

=item LogFile

The name of the output file to write the messages to

=back

This method returns a hash-reference on success and C<undef> on
failure.

=head2 Runstats

This method is used to collect statistics for a table and/or its
indexes.  This method requires a database connection.

At this time, only a subset of runstats features have been
implemented; specifically, the column distribution options and columns
group features are not supported.  This may change in future releases.

This method takes the following named parameters:

=over 4

=item Database

This mandatory parameter specifies the database name.  A connection to
this database must already exist.

=item Schema

The mandatory parameter contains the table schema name; it is also the
default schema name for any indexes specified.

=item Table

The mandatory parameter contains the table name.

=item Options

This optional parameter contains a hash reference that contains a
mixture of flags (boolean values) and numerical values, as described
below.  Not every flag and option can be meaningfully combined with
other flags and options; invalid combinations will lead to a DB2
error (the perl API does not check this).

=over 4

=item AllColumns

This boolean option is used to collect statistics for all table
columns.  In the absence of any other option and the absence of the
'Columns' parameter, this is the default.  See also the 'KeyCOlumns'
option.

=item KeyColumns

This boolean option is used to collect statistics for key table
columns (those that make up all the indexes on the table).

This option is mutually exclusive with the 'AllColumns' option, unless
the 'Distribution' option is also specified.  In that case, basic
statistics are collected for all columns and distribution statistics
are computed for the key table columns.

=item Distribution

This boolean option is used to collect distribution statistics.  It
can be combined with the 'AllColumns' and 'KeyColumns' options or the
'Columns' parameter.

=item AllIndexes

This boolean option is used to collect statistics for all indexes
defined on the table.  When used, the 'Indexes' parameter should be
omitted.

=item DetailedIndexes

This boolean option is used to collect detailed statistics for
table indexes.  It can be combined with the 'AllIndexes' option or the
'Indexes' parameter.

=item SampledIndexes

This boolean option is used to collect sampled statistics for table
indexes.  It can be combined with the 'AllIndexes' option or the
'Indexes' parameter.  It overrides the 'DetailedIndexes' option.

=item AllowRead

This boolean option is used to allow only read access on the table
while statistics are being collected.  The default is to allow both
read and write access.

=item BernoulliSampling

This numerical option enables Bernoulli sampling on the table data.
This is the default sampling method (the other is 'SystemSampling').
The option value must be a percentage value (between 0 and 100).

This option is mutually exclusive with 'SystemSampling'.

=item SystemSampling

This numerical option enables system sampling on the table data.  This
is the alternative sampling method (the default is
'BernoulliSampling').  The option value must be a percentage value
(between 0 and 100).

This option is mutually exclusive with 'BernoulliSampling'.

=item Repeatable

This numerical option is used to make sampling of the table data
repeatable.  The option value is the sampling seed.  This option can
be combined with 'BernoulliSampling' or 'SystemSampling'.

=item UseProfile

This boolean option is used to collect statistics depending on a
previously defined statistics profile for the table.  When specified,
the other options are ignore.

=item SetProfile

This boolean option is used to collect statistics and then set the
statistics profile.  Future Runstats calls with the 'UseProfile'
option will re-use the current statistics settings.

=item SetProfileOnly

This boolean option is used to set the statistics profile without
actually collecting data.  Future Runstats calls with the
'UseProfile' option will re-use the current statistics settings.

=item UpdateProfile

This boolean option is used to collect statistics and then update the
statistics profile with the current settings.  Future Runstats calls
with the 'UseProfile' option will re-use the combination of existing
and current current statistics settings.

=item UpdateProfileOnly

This boolean option is used to update the statistics profile without
actually collecting data.  Future Runstats calls with the
'UseProfile' option will re-use the combination of existing and
current current statistics settings.

=item ExcludingXML

This boolean option is used to skip collecting statistics on XML
columns.

This option is only available with DB2 V9.1 and later.

=item DefaultFreqValues

This numerical option is used to set the default number of frequent
values for the table.  In the full Runstats API, this can be
overridden on a per-column basis, but this implementation does not
support that.

=item DefaultQuantiles

This numerical option is used to set the default number of quantiles
for the table.  In the full Runstats API, this can be overridden on a
per-column basis, but this implementation does not support that.

=item ImpactPriority

This numerical option is used to set the impact of runstats.  The
priority is between 0 and 100, with 0 being unthrottled and a number
between 1 and 100 indicating a low priority (1) to high priority
(100).  The default when this option is omitted is 0 (unthrottled).

=back

=item Columns

This optional parameter contains a hash reference with column names as
keys and options as values.  The option can be a non-zero value
(e.g. 1) to indicate the column is of interest, or a hash-reference
with the column options.  The only option supported at this time is
'LikeStatistics', but that is expected to change in future DB2
releases.  An example 'Columns' value is listed below:

  'Columns' => { 'FirstName' => 1, # Collect stats
                 'LastName'  => { 'LikeStatistics' => 1 },
                 'Salary'    => 0, # Don't collect stats - same as omitting
                 'City'      => { 'LikeStatistics' => 1 },
               }

=item Indexes

This optional parameter contains an array reference with the name of
the table indexes to be used.  Each index name must either be
qualified by a schema name, or must have the same schema specified for
the table.

This parameter should not be combined with the 'AllIndexes' option and
may be combined with the 'DetailedIndexes' or 'SampledIndexes' option.

=back

=head2 ListHistory

This method is used to query the history of backups, roll forwards,
loads, tablespace actions, etc.  It applies to a database, but doesn't
require a database connection (just an instance attachment) - IBM is
not very consistent here.  This method can be quite slow if selection
criteria are not specified.  The selection criteria (action, object
name and start time) are logically ANDed.

This method specifies up to four named parameters, of which only
C<Database> is required.  It returns an array with hash-references
describing the history in detail; use of C<Data::Dumper> to study the
results is recommended.

=over 4

=item Database

The database name or alias to list the history for.  Required.

=item Action

The history action to list.  The default is C<All>.  Valid actions
are:

=over 4

=item All

=item Backup

=item RollForward

=item Reorg

=item AlterTablespace

=item DropTable

=item Load

This selects load with and without copy

=item RenameTablespace

=item CreateTableSpace / DropTablespace

Either of these selects both types of events

=item ArchiveLog

=back

=item ObjectName

A filter to select the object of interest.  This is either a tablespace
name, or a fully qualified table name (schema + table).

=item StartTime

The date and time of the first history entry of interest.  This is
specified in DB2 timestamp format, e.g. <200501311230'.  A prefix can
specified, e.g. C<2005> for January 1 of 2004, C<200502> for February
1 of 2005, C<20050215> for midnight of February 15 of 2005, etc.

=back

=head2 Rebind

This method is used to rebind a package.  It takes the following named
parameters:

=over 4

=item Database

The database name.  A connection to this database must exist.

=item Schema

The schema name of the package (may be 'NULLID' for nameless packages).

=item Package

The package name.

=item Options

An optional hash reference with rebind options.  It may contain the
following keys:

=over 4

=item Version

The package version number (integer)

=item Resolve

The rebind semantics: "Any" or "Conservative"

=item ReOpt

The re-optimization semantics: "None", "Once" or "Always".

=back

The default is version-less packages, any binding type and no
re-optimization.

=back

=head2 ListUtilities

This method lists the currently active utilities for the instance or
the specified database.  It is implemented using an instance snapshot.
If attaching to the database instance requires a userid and password,
an attachment must be established before calling this method.

This method has two optional named parameters, C<Database> and
C<Version>.  The C<Database> option which is used to select utilities
for a specific database; the C<Version> allows use of a different
database release level.

The return value is a list of hash-references with the following keys:

=over 4

=item Database

The database name

=item ID

The utility run ID

=item Utility

The utility type (e.g. 'RUNSTATS')

=item Description

A description of the utility or parameters for the utility

=item Priority

The utility priority (0 means unthrottled)

=item StartTime

The utility start time in text format

=item StartTimeVal

The utility start time, in numeric format suitable for use with
C<localtime> or C<gmtime>.

=back

=head2 ClientInfo

This method is used to get or set client information for a connection.
This cannot be used to override the information that the DB2 server
lists for a connection, but it can be used to provided additional
information that is recorded by the audit and monitoring tools.  Under
the covers, this method calls the DB2 C<sqleseti> and C<sqleqryi>
functions.

This method takes the following parameters, all optional:

=over 4

=item Database

The database name for which the client information should be set. A
connection to this database must exist, i.e. C<Connect> must have been
called beforehand.

If no database name is provided, the client information applies to all
connections, existing and future, for which no connection-specific
client information has been set.

=item ClientUserid

The client userid.  A useful case to set this is when the application
using the DB2::Admin module runs under a generic (production) userid, but
is performing an action for a known human userid.  By setting the
ClientUserid option, DB2 monitoring data will list both the generic
and human userids.

Note that setting the ClientUserid does not change any DB2-level
permissioning or authorization.  It only provides additional
monitoring information.

=item Workstation

The workstation name.  A useful case to set this is when the application
using the DB2::Admin module is part of a three-tier application, and is
performing an action on behalf of a user at a specific known
workstation, e.g. a client desktop name or remote IP address.

=item Application

The application name.  A useful case to set this is when the
application using the DB2::Admin module is part of a three-tier
application, and is performing an action on behalf of a known
requesting application, e.g. a specific web or client application.

=item AccountingString

The accounting string.

=back

The return value from this method is a hash with the same four fields,
all of which will be present only if the value is non-empty.

=head2 Backup

This method performs a database backup.  For a DPF database, it backs
up the node specified in the C<DB2NODE> environment variable.  In DB2
V9.5, it can back up all nodes of a DPF database.

This method takes four named parameters and returns a hash reference,
described in more detail after the parameters.

=over 4

=item Database

The database name or alias.  This parameter is required.

=item Target

The database target.  This can either be a string (a directory name)
or a reference to an array of directory names.  This parameter is
required.

=item Tablespaces

An optional array reference with a lkist of tablespace names to back
up.  Specifying this parameter switches from a database backup to a
tablespace backup.

=item Options

A required hash reference with backup options.

=over 4

=item Type

The type of backup.  This cna be C<Full>, C<Incremental> or C<Delta>.

=item Action

The backup action.  Technically, the abckup cna either eb fully
automated (the default), or it can go through multiple phases:
parameter check, start, promt, continue, etc.  This parameter allows
the user to specify the backup type/stage.  Supported values are
C<NoInterrupt> (the default), C<Start>, C<Continue>, C<Terminate>,
C<DeviceTerminate>, C<ParamCheck> and C<ParamCheckOnly>.

=item Nodes

This parameter is only valid on DB2 V9.5 and only for DPF databases.
It can be C<All> for a system-wide backup of all DPF nodes, or a
reference to an array of node numbers to back up.  Use of this
parameter triggers the creation of the C<NodeInfo> field in the return
value.  It is mutually exclusive with the C<ExceptNodes> parameter.

=item ExceptNodes

This parameter is only valid on DB2 V9.5 and only for DPF databases.
It is reference to an array of node numbers I<not> to back up.  Use of
this parameter triggers the creation of the C<NodeInfo> field in the
return value.  It is mutually exclusive with the C<Nodes> parameter.

=item Online

A boolean option specifying an online or offline backup.  The default
is an offline backup.

=item Compress

A boolean option specifying whether to compress the backup.  The
default is a non-compressed backup.

=item IncludeLogs

A boolean option specifying that database logs must be included.  This
parameter is mutually exclusive with the C<ExcludeLogs> option.
Omitting both C<IncludeLogs> and C<ExcludeLogs> selects the default
for the backup type, which is to include logs for snapshot backups and
to exclude logs in all other cases.

=item ExcludeLogs

A boolean option specifying that database logs must be excluded.  This
parameter is mutually exclusive with the C<IncludeLogs> option.
Omitting both C<IncludeLogs> and C<ExcludeLogs> selects the default
for the backup type, which is to include logs for snapshot backups and
to exclude logs in all other cases.

=item ImpactPriority

An integer specifying the impact priority.  When omitted, the backup
runs unthrottled.

=item Parallelism

An integer specifying the degree of parallelism (number of buffer
manipulators).

=item NumBuffers

An integer specifying the number of backup buffers to be used.

=item BufferSize

An integer specifying the size of the abckup buffer in 4K pages.

=item TargetType

The backup target type.  The default is C<Local>, i.e. a backup to a
filesystem.  Other options are C<XBSA>, C<TSM>, C<Snapshot> and
C<Other>.

=item Userid

An optional connect userid.

=item Password

An optional password to be used with the connect userid.

=back

=back

The return value of the C<Backup> method is a reference to a hash with
the following entries:

=over 4

=item ApplicationId

=item Timestamp

=item BackupSize

The size of the backup in megabytes

=item SQLCode

=item Message

The error message if the SQL code is not zero

=item State

The description if the SQL state, if available

=item NodeInfo

An optional array reference with per-node information.  This is only
available for DPF databases where the C<Nodes> or C<ExceptNodes>
option was specified.  Each array element is a hash reference with the
following elements (C<Message> and C<State> are optional):

=over 4

=item NodeNum

=item BackupSize

=item SQLCode

=item Message

=item State

=back

=back

=head1 AUTHOR

Hildo Biersma

=head1 SEE ALSO

DB2::Admin::Constants(3), DB2::Admin::DataStream(3)

=cut
