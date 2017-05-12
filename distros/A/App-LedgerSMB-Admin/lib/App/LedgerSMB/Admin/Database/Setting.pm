=head1 NAME

App::LedgerSMB::Admin::Database::Setting - Access LSMB Settings from Admin Tools

=cut

package App::LedgerSMB::Admin::Database::Setting;
use Moo;
with 'PGObject::Simple::Role';

use PGObject::Util::DBMethod;

sub _get_dbh {
    my ($self) = @_;
    return $self->database->connect;
}

sub _get_prefix { 'setting_' };

=head1 SYNOPSIS

 my $db = App::LedgerSMB::Admin::Database->new(
      username => 'postgres',
      password => 'secret',
      host     => 'localhost',
      port     => '5432',
 );
 my $setting = App::LedgerSMB::Admin::Database::Setting->new(
     database    => $db,
     setting_key => 'separate_duties');
 my $sep_duties = $setting->value;

=head1 PROPERTIES

=head2 database

The database for the associated setting.  Must be a 
App::LedgerSMB:Admin::Database object

=cut

has database => (
    is => 'ro', 
   isa => sub { die 'Must be a Database Object' 
                  unless eval { $_[0]->isa('App::LedgerSMB::Admin::Database')};
          }
);

=head2 setting_key

The name of the setting

=cut

has setting_key => (is => 'ro');

=head2 value

The value of the setting.  Is looked up lazily.

=cut

has value => (is => 'lazy');

sub _build_value {
    my ($hash) = $_[0]->_get;
    return $hash->{value};
}

sub _get {
    my ($self) = @_;
    my ($hash) = $self->call_procedure(funcname => 'get', args => [$self->setting_key]);
    return $hash;
}

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Chris Travers.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Chris Travers's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
