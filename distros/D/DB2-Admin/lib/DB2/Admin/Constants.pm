#
# DB2::Admin::Constants - provide access to DB2 constants
#
# Copyright (c) 2007,2009, Morgan Stanley & Co. Incorporated
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
# $Id: Constants.pm,v 165.1 2009/01/22 17:54:09 biersma Exp $
#

package DB2::Admin::Constants;

use strict;
use Carp;

use Params::Validate qw(:all);

use vars qw($constant_info $constant_index $config_params);
require 'DB2/Admin/db2_constants.pl';
require 'DB2/Admin/db2_config_params.pl';

#
# Get information on a constant
#
# Parameters:
# - Constant name
# Returns:
# - undef if unknown / Ref to (cloned) hash ref with:
#  - Name
#  - Value
#  - Type
#  - Category (optional)
#  - Comment (optional)
#
sub GetInfo {
    my ($class, $name) = @_;

    return unless (defined $constant_info->{$name});
    return { %{ $constant_info->{$name} } };
}


#
# Get the value of a constant (which has to have the type 'Number')
#
# Parameters:
# - Constant name
# Returns:
# - Numerical value
#
sub GetValue {
    my ($class, $name) = @_;

    my $info = $constant_info->{$name};
    confess "Unknown constant '$name'"
      unless (defined $info);
    confess "Not a numerical constant '$name' (type is $info->{Type})"
      unless ($info->{Type} eq 'Number');
    return $info->{Value};
}


#
# Lookup an element by number / category
#
# Parameters:
# - Category: Element / Platform / Type / ...
# - Number
# Returns:
# - Constant name / undef
#
sub Lookup {
    my ($class, $category, $no) = @_;

    confess "Invalid category '$category'"
      unless (defined $constant_index->{$category});
    return $constant_index->{$category}{$no};
}


#
# Get information on a configuration parameter
#
# Parameters:
# - Name (case insensitive, e.g. 'maxagents') (not SQLF_xxx)
# - Domain ('Database' / 'Manager')
# FIXME: Maybe DB2 version
# Returns:
# - Ref to hash with information
#
my $domain_to_config;           # Domain -> Name -> Info
sub GetConfigParam {
    my $class = shift;
    my %params = validate(@_, { 'Name'   => 1,
                                'Domain' => 1,
                              });
    my ($name, $domain) = @params{qw(Name Domain)};
    $name = lc $name;

    #
    # Prime look-up hash
    #
    unless (defined $domain_to_config) {
        while (my ($constant, $info) = each %$config_params) {
            my $cur_name = lc($info->{'Name'});
            my $domains = $info->{'Domain'};
            $domains = [ $domains ] unless (ref $domains);
            my $entry = { %$info };
            $entry->{'Constant'} = $constant;
            foreach my $domain (@$domains) {
                if (defined $domain_to_config->{$domain}{$cur_name}) {
                    #
                    # There are cases where the same parameter name
                    # maps to different constants - typically if the
                    # size/type has changed.  The old one is obsolete,
                    # pick the new one.
                    #
                    # We can only truly solve this with additional
                    # meta-data, but there' a hack that should work:
                    # look up the constants and, of those defined,
                    # pick the one with the highest number.  If we run
                    # on e.g. DB2 V7.x or V8.1, a constant new to V8.2
                    # is not yet known, so we will skip it.
                    #
                    # Example: stmtheap (SQLF_DBTN_STMTHEAP /
                    # SQLF_DBTN_STMT_HEAP)
                    #
                    my $match_entry;
                    foreach my $try ($entry, $domain_to_config->{$domain}{$cur_name}) {
                        my $name = $try->{Constant};
                        my $info = $constant_info->{$name};
                        unless (defined $info) {
                            #print STDERR "XXX: Skipping undefined constant '$name' in duplicate-defined config param '$cur_name'\n";
                            next;
                        }
                        unless (defined $match_entry) {
                            $match_entry = $try;
                            next;
                        }
                        my $try_value = $info->{Value};
                        my $match_value = $constant_info->{ $match_entry->{Constant} }->{Value};
                        if ($try_value > $match_value) {
                            #print STDERR "XXX: Pick [$name] ($try_value) over [$match_entry->{Constant}] ($match_value)\n";
                            $match_entry = $try;
                        } else {
                            #print STDERR "XXX: Pick [$match_entry->{Constant}] ($match_value) over [$name] ($try_value)\n";
                        }
                    }
                    confess "Huh? No match at all"
                      unless (defined $match_entry);
                    $entry = $match_entry;

                    #print STDERR "WARNING: duplicate config param '$domain' '$cur_name' for constants '$domain_to_config->{$domain}{$cur_name}{Constant}' and '$constant'\n";
                }
                $domain_to_config->{$domain}{$cur_name} = $entry;
            }
        }
    }

    confess "Invalid domain '$domain' (expect " .
      join('/', sort keys %$domain_to_config) . ")"
        unless (defined $domain_to_config->{$domain});
    my $info = $domain_to_config->{$domain}{$name};
    warn "WARNING: unknown name '$domain' '$name'"
      unless (defined $info);
    return unless (defined $info);
    return { %$info };
}


1;                              # End on a positive note


__END__


=head1 NAME

DB2::Admin::Constants - Support for DB2 constants from "sqlmon.h" and "sqlutil.h" header files

=head1 SYNOPSIS

  use DB2::Admin::Constants;

  #
  # Lookup information (such as type, value) for a constant
  #
  my $info = DB2::Admin::Constants::->GetInfo('SQLM_CURRENT_NODE');

  #
  # Get numerical value for a constant
  #
  my $num = DB2::Admin::Constants::->GetValue('SQLM_CURRENT_NODE');

  #
  # Get the symbolic constant name for a category / number
  #
  my $name = DB2::Admin::Constants::->Lookup('Platform', 3);

  #
  # Lookup information on a database / database manager configuration
  # parameter. (Use GetDbConfig or GetDbmConfig in DB2::Admin to look
  # up the actual config params.)
  #
  my $info = DB2::Admin::Constants::->GetConfigParam('Name'   => 'maxagents',
                                                     'Domain' => 'Manager');

=head1 DESCRIPTION

This module provides perl language support for the constants from the
DB2 C<sqlmon.h> header file.  It allows developers to retrieve
information based on constant name or value.

The information on the constants is stored in the file
C<db2_constants.pl>, which is auto-generated by a script that parses
the C<sqlmon.h> and C<sqlutil.h> header files.  The constants have not
been defined as individual perl or C subroutines to avoid bloating the
symbol tables and memory usage.

The following information is kept for each constant:

=over 4

=item Type

This can be C<Number>, C<String>, C<Character> or C<Expression>

=item Value

The value of the constant

=item Category

The category is present for some constants and classifies the constant
as an C<Element>, C<Type>, C<Platform>, C<Lock>, C<Heap>, C<Class> or
C<Event>.  If available, the number to constant name lookup is
supported using the C<Lookup> method.

=item Comment

The comment is a description of the constant as provided in the header
file.  It is not available for all constants.

=back

=head1 METHODS

=head2 GetInfo

This method takes a constant name and returns a hash reference with
information available for the constant, or C<undef> if the constant is
not known.

=head2 GetValue

This method takes a constant name and returns the numerical value of
the constant.  If the constant is not known, or if the type of the
constant is not a number, it throws an exception.

=head2 Lookup

This method takes two parameters, a category and a number.  If returns
the constant name that matches both.  If the category is not known, it
throws an exception.  If the category is known but the value is not,
it returns C<undef>.

=head1 GetConfigParam

This method takes two named parameters, C<Name> and C<Domain>, that
represent a database or database manager configuration parameter.  It
returns a hash reference with information about the constant, or
C<undef> if the configuration parameter name is not know.  The return
value includes the corresponding constant name, type, domain, optional
size, and optional updateable parameter.

NOTE: This API is subject to change, as we may need to deal with the
same config parameter name mapping to a different constant name and
size depending on the DB2 release.

=over 4

=item Name

The name of a configuration parameter, for example C<maxagents>.  THis
is looked up in a case-insensitive manner.

=item Domain

One of C<Manager> or C<Database>.

=back

=head1 AUTHOR

Hildo Biersma

=head1 SEE ALSO

DB2::Admin(3)

=cut
