=head1 NAME

App::LedgerSMB::Admin::User - Administer LedgerSMB Users with DB Admin Tools

=cut

package App::LedgerSMB::Admin::User;
use Moo;
with 'PGObject::Simple::Role';
use PGObject::Util::DBMethod;

sub _get_dbh { $_[0]->connect }
sub _get_prefix { 'admin__' }

=head1 SYNPOPSIS

 use App::LedgerSMB::Admin;
 use App::LedgerSMB::Admin::User;
 use App::LedgerSMB::Admin::Database;
 App::LedgerSMB::Admin->add_paths(
    1.3 => '/usr/local/ledgersmb'
 );
 my $user = App::LedgerSMB::Admin::User->new(
    pls_import  => 0,
    first_name  => 'Chris',
    last_name   => 'Travers',
    is_employee => 0,
    is_person   => 1,
    username    => 'chris',
    temp_pass   => 'foobarbaz',
    country_id  => '232',
    database    => App::LedgerSMB::Admin::Database->new(
                       dbname => 'lsmb13',
                     username => 'postgres',
                     password => 'secret',
                         host => 'localhost',
                         port => '5432',
                   ),
 );
 $user->assign_roles($user->list_roles);
 $user->save;

=head1 PROPERTIES

=head2 database

The database object associated with this object.  Must be an object of type
App::LedgerSMB::Admin::Database.

=cut

has 'database' => (
         is => 'ro', 
         isa => sub {
              die 'Must be of type App::LedgerSMB::Admin::Database'
                   unless eval { $_[0]->isa('App::LedgerSMB::Admin::Database')};
                },
);

=head2 username

=cut

has username => (is => 'ro');

=head2 password

=cut

has password => (is => 'ro');

=head2 first_name

=cut

has first_name => (is => 'ro');

=head2 last_name

=cut

has last_name => (is => 'ro');

=head2 middle_name

=cut

has middle_name => (is => 'ro');

=head2 dob

Date of birth

=cut

has dob => (is => 'ro');

=head2 ssn

Social security number or tax id.

=cut

has ssn => (is => 'ro');

=head2 is_employee

bool, is true if we need to create an employee record when we save.

=cut

has is_employee => (
       is => 'ro', 
      isa => sub {
           die 'invalid bool' 
              unless 1 == scalar grep {$_[0] = $_} 
                   (undef, 0, 1, 't', 'f', 'true', 'false')
                   },
);

=head2 entity_id

=head2 id

=cut

has entity_id => (is => 'ro');
has id        => (is => 'ro');

=head1 METHODS

=head2 get

=cut

dbmethod get => (funcname => 'get_user');

=head2 reset_passwd

=cut

dbmethod reset_password => (funcname => 'save_user');

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
