#
#   DB::Ent - A Database Entity Layer
#   Copyright (C) 2001-2003 Erick Calder
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

=head1 NAME

DB::Ent - Database Entity Layer

=head1 SYNOPSIS

  use DB::Ent;
  $ef = DB::Ent->new();                      # entity factory
  $au = $ef->mk(artist => "Peter Gabriel");  # create an artist
  $cd = $au->mksub(CD => "Passion");         # create subordinate entity
  $cd->attr(id => "0x0440F020") || die;      # set attributes
  $cv = $dbe->mk(cover => "http://...");     # create a cover
  $cd->rel($cv);                             # link to CD
  $cd->rm();                                 # remove the CD

=head1 DESCRIPTION

This module presents an interface to an entity-centric database schema, providing all necessary methods to create, discover and manipulate entities and associated data.

The schema consists of 4 basic element storage types: 1) entities, 2) attributes, 3) relationships, and 4) extended attributes.

The terms C<entity> and C<attribute> are used here in accordance to the common definition used in relational database theory.

A differentiating factor between an entity and an attribute is that attributes serve no other purpose but to qualify an entity and cannot exist on their own.  Entities may exist without qualifiers, requiring only a name.

Relationships of various kinds may be established between any two entities and these may be codified, enumerated or both.

Extended attributes comprise special datatypes and are typically used to store large format data.

=cut

# --- prologue ----------------------------------------------------------------

package DB::Ent;

use 5.006;
use strict;
use warnings;

use Exporter;
use vars qw/@ISA/;

our $VERSION = substr q$Revision: 1.63 $, 10;
sub OK { 1; }

### TODO ###

# new(): allow empty values for attributes

# --- exported module interface -----------------------------------------------

=head1 SYNTAX

Methods are listed by declaring their signatures, the general format of which consists of a return value followed by an equal sign and the method name, followed by a list of parameters, e.g.

I<E<lt>returnE<gt> = method-name E<lt>requiredE<gt> [optional = default] {alternate1 | alternate2}>

=head2 Parameters

Required parameters are named within angles whilst optional parameters within brackets; alternative parameters use braces separated by pipes.  Whenever optional parameters are specified, the default value may be represented by following the parameter name with an equal sign and the default value.  When listing alternative parameters the syntax may nest brackets, e.g. the line below names that EITHER two required parameters may be passed OR a hash or hash reference.

I<{E<lt>val-1E<gt> E<lt>val-2E<gt> | hash[-ref]}>

Please note that failing to pass required arguments in a method call results in program death.

=head2 Return values

In general, methods return objects unless an error occurs in which case I<undef> is returned.  Certain methods specify their return value as I<ok> which indicates a success flag (set to I<undef> on failure).  Upon encountering an error, the caller should consult the {err} and {errstr} fields in the object which contain a numeric error code and its corresponding description string.

Return values are typically context-sensitive and may also be sensitive to the argument signature.  When different return values may be expected, these appear separated with pipes.  When the return value is an I<E<lt>errE<gt>>, if the context is scalar, only error code is returned.

=head2 Signature templates

Whenever the syntax for a method is indicated with a double colon, it specifies that the signature for the current method follows that of a template method which is indicated following the double colon (e.g. I<mksub :: mk>).  Parameters to the method in question are placed after the template's last required parameter and before its first optional parameter.

=cut

# --- entity factory methods --------------------------------------------------

=head1 METHODS

The module presents an object-oriented interface divided into two major functional groups: entity-factory methods, and entity-management methods.

Entity factory methods concern the binding of perl objects to datastore items.  This includes insertion, discovery and retrieval methods as well as entity-factory configuration methods.  This category includes the following:

=head2 <entity-factory> <err> = new [hash[-ref]]

Before entities can be created and managed, an entity factory must be instantiated.  This method returns such an object and receives two kinds of parameters: connection parameters, and configuration parameters.  If any error is encountered the method returns I<undef> for the object, followed by an error list.

Parameters are all passed as a hash or hash reference whose keys are described below:

I<Connection Parameters>

To establish a connection to a datastore, the caller must pass credentials.  These may be passed either in URL syntax and/or as separate keys.  Any information passed separately overrides the appropriate value in the URL.  If no connection information is passed, the variable I<DBE> in the main namespace is assumed to contain a URL with the information.  If this variable is empty, the environment variable of the same name is used.  Any credential pieces not passed assume defaults.

=over

=item DBED

Indicates the low-level driver to use.  At present this value defaults to and can only be set to C<DBI>.  As other low level drivers are written, their names may be passed here.

=item URL

Specifies a connection URL of the form: I<proto://[user[:pass]@][host[/database]]> where the items indicated in brackets are optional and which may be passed separately as described below.

=item proto

This key specifies the drivers to use for connecting to a datastore.  The value will be passed through to the I<DBED> and if not supplied, the DBED will select an appropriate default e.g. C<mysql>.

=item host

This indicates the name or IP address of the server hosting the datastore.  If not provided, the low level driver will choose a default.

=item user

Specifies the account to use for logging into the datastore.  If not provided the low-level driver will choose a default.

=item password

Necessary when security measures have been placed on the account in use.  Passwords are provided in plain-text.  If not provided, default is left to the low-level driver.

=item database

This key specifies the namespace within the server to use.  If not specified, a default home will be used.  Please note however that not all database systems either have a namespace concept, nor a default value for it.

=back

I<Configuration Parameters>

The following keys define various behaviours for the entity factory.  The values are stored as keys in the object itself and may be manipulated directly.

=over

=item mkuid

Specifies a code reference to be used in generating unique ids e.g. I<\MyModule::nextid>.  If no value is specified, unique strings are computed based on the md5 value of the canonicalised name.

=item dups

The duplicates flag indicates the action to take when db insert fails because an entity already exists.  The value may be set to any of the following constants B<DUPSQUIET>, B<DUPSWARN>, B<DUPSDIE> (see section B<CONSTANTS> at the end of this document).

=item upsert

This key allows the user to automatically overwrite existing entity attributes.  For more information please see the the B<mk()> method.

=item debug

Setting this key allows for debugging output to be produced by the module.  A 1 is the minimum required with increased verbosity resulting from larger values.  By default no debugging output is generated.

=item trace

Setting this key to a filename will cause all commands issued to the datastore to be recorded in the file.

=back

I<Virtual methods>

The following methods may be overridden by the caller as desired:

=over

=item dbcmd

This method is called with the full command about to be sent to the datastore.  By default this method does nothing;

=item dberr

This key allows the caller to specify an error handler to use when low-level driver problems arise.  The constants B<ERRWARN> (current default) and B<ERRDIE> may also be used to request that the default error handler die or merely warn upon errors;

=back

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = bless { DBED => "DBI", &args }, $class;

    $self->{debug} ||= 0;

    my $DBED = "DB::Ent::" . $self->{DBED};
    eval qq/require $DBED/ unless $self->{DBED} eq "DBI";
    @ISA = ($DBED);

    $self->u2h();
    $self->SUPER::new(
        debug => $self->{debug} - 1,
        trace => $self->{trace},
        );

    my @err = ($self->{err}, $self->{errstr});
    $self = undef if $err[0];
    wantarray() ? ($self, @err) : $self;
    }

=head2 <entity> = mk <entity-type> <entity-name> [attr-hashref]

Creates an entity with the given name and type and populates it with the attributes given in the optional hash reference.  If the object already exists in the datastore no insertion is made and any attributes provided are discarded, unless the I<upsert> flag is set in the entity factory, in which case all attributes specified are overwritten with the values supplied.

All entities have a unique id, normally calculated upon creation by the B<uid()> method (see Configuration Parameters for the B<new()> method).  This default id is generated from a combination of the name and type of entity and may be overridden by specifying the I<uid> key in the attribute hash.  Additionally, to generate the uid using the current uid generator but with an alternative value, the key I<uidstr> may be passed.

=cut

sub mk {
    my ($self, $type, $nm, $d) = @_;

    die qq/mk(): No name passed!/ unless $nm;
    die qq/mk(): No type passed!/ unless $type;

    my ($ent, $id);
    $id->{uid} = $d->{uid} || $self->uid($d->{uidstr} || "$type:$nm");
    delete $d->{uidstr};

    unless ($ent = $self->ent($id)) {
        $ent = {nm => $nm, type => $type, uid => $id->{uid}};
        $ent->{id} = $self->ins(ent => $ent) || return;
        $ent->{$_} = $self->{$_} for qw/dbh debug/;
        bless $ent, ref($self);
        }

    return $ent if $ent->attr($d) == 0;
    }

=head2 <entity[-list]> = ent <sel-hash-ref> [opts-hash[-ref]]

This method retrieves entities from the datastore.

Entities are returned according to selection criteria which are specified in a hash consisting of the attribute values being sought.  Values in the selection hash may contain list references when multiple matches are desired.  Additionally, hash values may contain the I<%> wildcard to indicate partial matches.  If no selection criteria are specified, the method will assume an I<id> is being sought and takes the value of I<$_>.

A hash of options intended to modify the return set may also be passed containing keys as outlined below:

=over

=item sort

Specifies the attribute(s) to sort results by.  A list reference may be passed when multiple values are desired; defaults to C<nm>.

=back

The return value consists of blessed objects, the number of which depends on the selection criteria.  When a single object is found it is returned as a scalar, unless the calling context requests a list.

B<Note:> The entities returned by this method contain only the most minimal of information i.e. that contained in the B<ent> table.  No attribute, relationship or other information is retrieved but these values may be got by calling specific methods for each.  For a catalogue of such methods please refer to the B<METHODS - Entity Management> section below.

=cut

sub ent {
    my $self = shift;
    my $sel = shift;
    $sel = { $sel =~ /^\d+$/ ? "id" :  "nm" => $sel }
        unless ref $sel;

    my $opts = &args;
    $opts->{sort} ||= "nm";

    my (@ent, @ret);
    @ent = $self->sel(ent => $sel, sort => $opts->{sort});
    push @ret, bless $_, $self for @ent;

    @ret == 1 && !wantarray() ? $ret[0] : @ret;
    }

=head2 <url> = cs

This method returns a url containing the connection information in use for the given datastore object.  For information on the format of this string, please refer to the I<URL> argument to the I<new()> method.

=cut

sub cs {
    my $self = shift;
    $self->h2u();
    }

# --- entity management methods -----------------------------------------------

=head1 METHODS - Entity Management

The methods listed below provide mechanisms for managing entity objects, their attributes and relationships.  These methods can only be called on the objects generated by calls to entity-factory methods.

=head2 <ok> = rm [RELSONLY]

Removes an entity and all relationships to other entities.  The method works recursively, destroying all dependencies, otherwise requested.  For more information please refer to the documentation for the B<rmrel> method.

=cut

sub rm {
    my ($self, $rels) = @_;

    $self->rmattr() || return;
    $self->rmrel(relsonly => $rels) || return;
    $self->del(ent => {id => $self->id}) || return;
    
    OK;
    }

=head2 mksub :: mk

Creates a sub-ordinate entity.  The method must be called from an object generated by an entity factory and assumes such serves as the parent.

=cut

sub mksub {
    my ($self, $type, $nm, $d) = @_;

    my $ent = $self->mk($type => $nm, $d)
        || return;
    $ent->rel($self)
        || return;

    $ent;
    } 

# --- attribute methods -------------------------------------------------------

=head2 <ok> | <attr-hash[-ref]> = attr [<name> [value = $_] | attr-hashref]

Sets attributes for an entity.

Two parameter signatures are allowed; in the first form the method sets a single attribute; the second form allows for multiple attributes to be set.  The return value in this case consists of an I<ok> value.

Attributes are created whenever they do not exist in the datastore but when already present, their values are respected, unless the I<upsert> flag in the entity factory is set.

The current value of an attribute may be updated via a calculation by passing a code reference as a I<value>.  The code-ref will be called with the value of I<$_> set to the current attribute's value and will be responsible for returning the new value, e.g. to increment a value the following may be used:

I<$self-E<gt>attr(count =E<gt> sub { $_++ });>

=cut

sub attr {
    my ($self, $attr, $val) = @_;

    $val = $_ unless ref($attr) || defined($val);
    my %attr = ref($attr) ? %$attr : ($attr, $val);

    #   bail if no attrs to process

    return !OK unless %attr;

    #    intrinsic attributes don't get stored in the C<attrs> table

    for ($self->tabcols("ent")) {
        next if /^id$/i;
        delete $attr{$_};
        }

    #   grab attributes in case me virgin

    $self->attrs() unless $self->{__cf}{attrs};

    #    insert attributes

    for (keys %attr) {
        my $v = $attr{$_} || next;
        $self->{$_} ||= "";
        next if $self->{$_} eq $v;

        my ($nm, $dt) = nmdt();     # attribute names may include datatype
        next unless $nm;            # attributes should have names
        $dt ||= strdt($v);          # guess datatype if not specified

        my $fn = $self->{$_} ? "upd" : "ins";
        my $ret = $self->$fn(
            attr => { nm => $nm, $dt => $v },
            { id => $self->id }
            );

        # inserts into C<attr> do not auto-generate
        # an id so the return value of ins() is not
        # meaninful and sqlerr() must be checked

        $ret = $self->dberr() if $fn eq "ins";
        return !OK unless $ret;

        $self->{$nm} = $v;
        }

    OK;
    }

=head2 <hash[-ref]> = attrs [attr-listref] [DTT]

Retrieves the attributes of an identity.  Specific attributes may be requested by passing their names in a list reference.  If the constant B<DTT> is passed, datatype information will be embedded in the keys of the return hash.

The attributes retrieved (and returned) are also embedded internally into the object.

=cut

sub attrs {
    my ($self, $nm, $dtt) = @_;

    my %attr;
    for ($self->sel(attr => {id => $self->id, nm => $nm})) {
        my $nm = $_->{nm};
        for my $dt (qw/s i f d/) {
            my $v = $_->{$dt} || next;
            $attr{$dtt ? "$dt:$nm" : $nm} = $v;
            last;
            }
        }

    $self->{__cf}{attrs} = 1;  # already queried
    %$self = (%$self, %attr);
    $nm ? $attr{$nm} : wantarray() ? %attr : \%attr;
    }

=head2 <ok> = rmattr [attr-list]

Removes an entity's attributes.  If a list of attribute names is provided, only those attributes are removed.

=cut

sub rmattr    {
    my $self = shift;
    my $crit = { id => $self->id() };
    $crit->{nm} = \@_ if @_;
    $self->del(attr => $crit);
    }

# --- relationship methods ----------------------------------------------------

=head2 <ok> = rel <entity[-listref]> [options-hashref]

Creates a relationship between the current entity and a list of given entities.  Relationshps are always enumerated but may also be codified, as indicated in the options hash optionally passed.  Valid keys for this hash are as follows:

=over

=item type

Specifies the type of relationship.  If no type is specified, the relationship is not considered to be codified.

=item nn

Passing a value with this key cements the relationship number between two entities.  Generally there is no good reason to want this, and as attempting to establish a relationship between to entities with the same numeric value (within a given relationship-type (code)) will cause an error, abstention from use of this key is recommended.  If not specified, its value is calculated as the next number available.

=item unique

If this key is set to true, the system will enforces a single relationship between the two entities (regardless of relationship type).  By default this value is false.

=item parent

Most commonly the caller will intend to create child relationships between the current entity and the passed list of subordinate entities.  At times however, it may be necessary to reverse the sense of this assignment, making each of the entities in the list, the parent of the current entity.  Setting this flag to true allows for that to happen.

=back

=cut

sub rel {
    my ($self, $rel, $opts) = @_;

    my @rel = ref($rel) eq "ARRAY" ? @$rel : ($rel);
    for (@rel) {
        my $i = $opts->{nn} || 1 + $self->max(rel => "i", {
            id => $self->id, pid => $_->id, type => $opts->{type}
            });

        next if $opts->{unique} && !$opts->{nn} && $i > 1;

        my ($id, $pid) = $opts->{parent} ? qw/pid id/ : qw/id pid/;
        $self->ins(rel => {
            $id => $self->id, $pid => $_->id, type => $opts->{type}, i => $i
            });
        return if $self->{err};
        }

    OK;
    }


=head2 <entity-list[-ref]> = rels [opts-hash[-ref]]

Returns a list of entities related to the current entity.  Please note that these values get cached inside the object as either I<_parents_> or I<_children_>.

The options hash specifies behaviour as follows:

=over

=item cd

The caller may limit the entities returned by relationship code.  The value passed may be either a scalar or a list reference.

=item parent

If this flag is set, instead of returning an entity's children, the parents are returned.

=back

=cut

sub rels {
    my $self = shift;
    my $opts = &args;

    my @ret; my $id = $opts->{parent} ? "id" : "pid";
    for ($self->sel(rel => {$id => $self->id, cd => $opts->{cd}})) {
        push @ret, $self->ent($_->{id});
        }

    $self->{$opts->{parent} ? "_parents_" : "_children_"} = \@ret;
    wantarray ? @ret : \@ret;
    }

=head2 <ok> = rmrel [ents => listref, relsonly => 1]

Removes an entity's relationships with the given list of entities by removing these from the datastore.  Please note that this process works recursively, removing children's children to any level, thus effectively pruning the relationship tree connected at the current entity.  If the list passed is empty, all children are removed.

If the flag I<relsonly> is set, the method only severs the entity's relationships with other entities without destroying these.

=cut

sub rmrel {
    my ($self, %args) = @_;

    unless ($args{relsonly}) {
        my @rels = $args{ents} || $self->rels();
        $_->rm() || last for @rels;
        }

    $self->del(rel => {id => $self->id}) || return;
    $self->del(rel => {pid => $self->id}) || return;

    OK;
    }

=head2 <hash-[ref]> = args [hash, hash-ref, ...]

This function conveniently parses arguments passed to a method.  It should be called in non OO style without arguments and returns a hash or hash reference (depending on context) with the values.

I<- exempli gratia ->

    sub tst {
        my $args = &DB::Ent::args;
        print $args->{key};
        }

=cut

sub args {
    my @ret = @_;
    for my $i (0 .. $#ret) {
        splice @ret, $i, 1, %{ $ret[$i] } if ref $ret[$i] eq "HASH";
        }

    wantarray() ? @ret : { @ret };
    }
        
# --- internal methods and functions ------------------------------------------

sub id {
    my $self = shift;
    $self->{id};
    }

#   converts a connection url to a hash

sub u2h {
    my $self = shift;
    local $_ = $self->{URL} || $::DBE || $ENV{DBE} || "";

    my @dbk = qw/proto usr pwd srv dbn/;
    my %url; @url{@dbk} = m|^(\w+)://(\w+):?(\w*)@?(\w+)/?(\w+)$|;
    $self->{$_} ||= $url{$_} for @dbk;
    }

#   converts a connection hash to a url

sub h2u {
    my $self = shift;
    local $_ = sprintf("%s://%s:%s@%s/%s",
        $self->{proto},
        $self->{usr}, $self->{pwd},
        $self->{srv}, $self->{dbn}
        );
    s/:@/@/;
    $_;
    }

#   generate unique id strings.
#   if a function has been defined for this purpose no string may
#   be necessary but if the uid is being generated by us, we need a
#   string (typically the name)

sub uid {
    my $self = shift;
    my $nm = shift;

    return $self->{mkuid}($nm) if $self->{mkuid};

    return unless $nm;
    require String::Canonical;
    import String::Canonical qw/cstr/;
    require Digest::MD5;
    import Digest::MD5 qw/md5_hex/;

    md5_hex(cstr($nm));
    }

#
#    Syntax:
#        <datatype> = strdt [string = $_]
#    Synopsis:
#        Returns the heuristic datatype of a string
#

sub strdt {
    local $_ = @_ > 0 ? shift : $_;
    return "i" if /^-?\d+$/;
    return "f" if /^-?\d+\.?\d*$/;
    return "d" if m|^\d{1,2}/\d{1,2}/(\d\d){1,2}|;
    return "s";
    }

#
#    Syntax:
#        <name> <datatype> = nmdt [attr-nm = $_]
#    Synopsis:
#        Splits a compound attribute name into its value
#        and it's datatype
#

sub nmdt {
    local $_ = shift || $_;
    my ($dt, $nm) = /^(?:(.):)?(.*)$/;    # datatype may be embedded
    return ($nm, $dt || "");
    }

=head1 CONSTANTS

A number of constants are used by the various methods; these are typically access directly from the package e.g. B<$DB::Ent::DTT>.  A description of each follows:

=over

=item DUPSQUIET

specifies that entity creation failures owning to duplicate keys should be silently ignored.

=item DUPSWARN

specifies duplicate key violations should issue warnings.

=item DUPSDIE

specifies duplicate key violations should cause the process to die.

=item ERRWARN

specifies that only warnings should be issued when encountering errors.

=item ERRDIE

specifies that the process should die when errors are found.

=item RELSONLY

#FIXME

=item DTT

#FIXME

=back

=cut

sub DUPSQUIET { 1; }
sub DUPSWARN { 2; }
sub DUPSDIE { 3; }
sub ERRWARN { 0; }
sub ERRDIE { 1; }
sub RELSONLY { 1; }
sub DTT      { 1; }

=head1 DRIVERS

Drivers are modules that provide low-level primitives to access specific datastores.  Please note that the I<entity>/I<attribute> nomenclature may not map directly to a I<table>/I<column>, I<file>/I<line>, I<record>/I<field>, I<row>/I<cell> or other metaphor supported by the underlying datastore.

At present only a DBI driver exists but a published API (see man page for DB::Ent::DBI) exists to allow developers to write other drivers.

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 SUPPORT

For help and thank you notes, e-mail the author directly.  To report a bug, submit a patch or add to our wishlist please visit the CPAN bug manager at: F<http://rt.cpan.org>

=head1 AVAILABILITY

The latest version of the tarball, RPM and SRPM may always be found at: F<http://perl.arix.com/>  Additionally the module is available from CPAN.

=head1 LICENCE AND COPYRIGHT

This utility is free and distributed under GPL, the Gnu Public License.  A copy of this license was included in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.gnu.org/licenses/> to obtain a copy of this license.

=head1 SEE ALSO

L<DB::Ent::DBI>

$Revision: 1.63 $, $Date: 2003/06/24 03:58:11 $

=cut

# --- DBI Driver --------------------------------------------------------------

=head1 NAME

DB::Ent::DBI - DBI Driver for DB::Ent

=head1 SYNOPSIS

  use DB::Ent::DBI;
  $dbx = DB::Ent::DBI->new();
  $dbx->ins();
  $dbx->del();
  $dbx->upd();

=head1 DESCRIPTION

This module provides a DBI-based driver for the DB::Ent schema abstraction layer and serves as a guideline for other driver development efforts by documenting the API.

Please note that for this driver the choice of nomenclature consists of I<table/column/row>.  Also, some methods return I<E<lt>errE<gt>>; this is a list consisting of a numeric error code, followed by its human-legible corresponding string.

=cut

# --- prologue ----------------------------------------------------------------

package DB::Ent::DBI;

use 5.006;
use strict;
use warnings;
use DBI;
use vars qw/$VERSION %tabs @QDTT/;

$VERSION = substr q$Revision: 1.63 $, 10;

@QDTT = qw/char text date/;             # datatypes that need quoting

%tabs = (
    ent => [
        "id int unsigned not null auto_increment primary key",
        "nm varchar(255)",              # name
        "type varchar(30)",             # namespace-qualified class
        "uid char(32) UNIQUE",          # universal id
        ],
    attr => [
        "id int unsigned not null",     # FK: ent (no DRI)
        "nm varchar(32)",               # name
        "i int",                        # various value
        "f float",                      # data types
        "s varchar(255)",
        "d datetime",
        "UNIQUE (id, nm)",
        ],
    rel => [
        "id int unsigned not null",     # FK: ent
        "pid int unsigned not null",    # parent id
        "type char(4)",                 # relationships can be codified
        "i int",                        # and/or enumerated
        "UNIQUE  (id, pid, type, i)",
        ],
    xattr => [
        "id int unsigned not null",     # FK: ent
        "type char(4)",
        "s  text",                      # ascii blob
        "FULLTEXT (s)",
        ],
    );

while (my ($tab, $cols) = each %tabs) {
    $tabs{$tab} = {};
    for (@$cols) {
        my ($nm, $def) = /^(\w+)\s*(.*)/i;
        if ($nm eq uc($nm)) {
            push @{$tabs{$tab}{mods}}, "$nm $def";
            next;
            }
        $tabs{$tab}{cols}{$nm}{def} = $def;
        $tabs{$tab}{cols}{$nm}{quote} ||= $def =~ /$_/i for @QDTT;
        }
    }

sub OK { 1; }

# --- exported module interface -----------------------------------------------

=head2 <db, err> = new [pass-through]

Used to generate a datastore connection object.  Any optional arguments passed may be used to create and configure the connection.  The method returns a list containing a blessed object, a numeric error code, and a human legible error string.

If the object is set to I<undef> the caller should check the error values, else the returned object may be used to access the methods listed below:

=cut

sub new {
    my $self = shift;
    return unless $self->dbc(&DB::Ent::args);

    $self->{dups} ||= $DB::Ent::DUPSWARN;
    $self->{dbh}->{PrintError} = 0;     # we'll display errors
    $self->{dbh}->trace(2, $self->{trace})
        if $self->{trace};

    OK;
    }

sub dbc {
    my $self = shift;
    %$self = (%$self, @_);

    $self->{proto} ||= "mysql";
    $self->{srv}   ||= "localhost";
    $self->{usr}   ||= (getpwuid($>))[0];
    $self->{pwd}   ||= "";
    $self->{dbn}   ||= "";

    my $dsn = join ":", "DBI", @{$self}{qw/proto dbn srv/};
    $self->{dbh} = DBI->connect($dsn, $self->{usr}, $self->{pwd});
    @{$self}{qw/err errstr/} = ($?, $!);

    !$?;
    }

=head2 <ok> = init

Used to create an entity schema this method must be called with extreme care as it will first destroy an existing schema, including all data.  Before this method may be called, a connection to the datastore must be established.

Typically it is not necessary for users to call this method directly since the B<new> method will call it if it detects that the datastore has not been initialised.

The storage element types (in the nomenclature of this driver these are database tables) created are named: I<ent>, I<attr>, I<rel>, and I<xattr>.  The B<nm> parameter to the various methods offered by this module must receive one of these values.

This method takes no arguments and returns a success flag.

=cut

sub init {
    my $self = shift;
    my %args = @_;
    for (keys %tabs) {
        $self->x("DROP TABLE IF EXISTS $_") if $args{DROP};
        $self->tabmk() || return;
        }
    OK;
    }

=head2 <id> = ins <nm> <attr-hashref> [filt-hashref]

Creates a new entry of the type indicated by the first argument passed (see docs for the I<init()> method above for a review of valid names).  Attributes must be passed in a hash reference and must match those allowed by the element type.

The return value consists of the id of the new entry; in case of failure error information is returned.

B<Note:> For signature compatibility with I<upd()>, this method accepts a filter hash reference whose keys are added to the I<attr-hashref>.  This makes for easy upserts!

=cut

# needs to support upserts and coderefs for values

sub ins {
    my ($self, $nm, $args, $filt) = @_;
    my (@cols, @vals);
    $args = {%$args, %$filt} if ref($filt) eq "HASH";
    for (keys %$args) {
        push @cols, $_;
        push @vals, $tabs{$nm}{cols}{$_}{quote}
            ? $self->q($args->{$_})
            : $args->{$_}
            ;
        }

    $self->x(
        sprintf("INSERT INTO $nm (%s) VALUES (%s)",
            join(",", @cols),
            join(",", @vals),
            )
        );
    }

=head2 <rows> = upd <nm> <attr-hashref> [filt-hashref]

This method updates an entry of the type specified by the I<nm> parameter (see docs for the I<init()> method above for a review of valid names).  The data updated is provided as a hash reference of attribute name/value pairs.  Additionally a filter may be provided (also as a hash reference of attribute name/value pairs) which limits the update operation to only those entries specified (in table parlance, this represents a row selector i.e. an sql where clause).

The return value indicates the number of rows affected.

=cut

sub upd {
    my ($self, $nm, $attr, $filt) = @_;

    my $attrs;
    $attrs .= "$_ = " . $self->q($attr->{$_}) . ", "
        for keys %$attr;
    $attrs =~ s/,\s+$//;
    my $WHERE = $self->where($nm, $filt);

    $self->x("UPDATE $nm SET $attrs $WHERE");
    }

=head2 <ok> = del <nm> <attr-hashref>

Deletes any entity that matches the given list of attributes' values.  Instead of not passing any attributes in the hash reference in order to delete all items in a table, pass the key I<ALL> set to 1 - this is to prevent costly mistakes.

=cut

sub del {
    my $self = shift;
    my ($nm, $cols) = @_;

    my $WHERE = $cols->{ALL} ? "" : $self->where($nm, $cols) || return;
    $self->x("DELETE FROM $nm $WHERE");
    }

=head2 <hashref-list> = sel <criteria-hash[-ref]>

Returns a list of hash references containing entities that match the selection criteria.  The values in the hash to this method may contain list references and wildcards are allowed within scalars for incomplete matching.
 
=cut

sub sel {
    my ($self, $nm, $cols, %opts) = @_;
    $opts{sort} ||= 1;

    my $WHERE = $self->where($nm, $cols);
    $self->x("SELECT * FROM $nm $WHERE ORDER BY $opts{sort}");
    }

sub max {
    my $self = shift;
    my $nm = shift;
    my $col = shift;
    my $WHERE = $self->where($nm, &DB::Ent::args);
    my @ret = $self->x("SELECT max($col) max FROM $nm $WHERE");
    $ret[0]->{max} || 0;
    }

=head2 <attr-list> = def <entity-type>

Returns a list of attributes associated with a particular entity type.

=cut

# --- internal utility methods ------------------------------------------------

sub tabcols {
    my $self = shift;
    my $nm = shift || $_;
    keys %{$tabs{$nm}{cols}};
    }

sub tabmk {
    my $self = shift;
    my $nm = shift || $_;
    
    my @cols;
    push @cols, "$_ $tabs{$nm}{cols}{$_}{def}"
        for keys %{$tabs{$nm}{cols}};
    push @cols, $_
        for @{$tabs{$nm}{mods}};
    $self->x(
        sprintf("CREATE TABLE IF NOT EXISTS $nm (%s)", join(",", @cols))
        );
    }

#   constructs predicates for a where clause

sub where {
    my $self = shift;
    my $tab = shift;

    my @ret; my %cols = &DB::Ent::args;
    while (my ($nm, $v) = each %cols) {
        next unless defined $v;

        my $q = $tabs{$tab}{cols}{$nm}{quote};
        if (ref $v eq "ARRAY") {
            $v = $q ? $self->qin($v) : $self->in($v);
            push @ret, "$nm IN ($v)";
            next;
            }
        if ($v =~ /%/) {
            push @ret, "$nm LIKE " . $self->q($v);
            next;
            }
        push @ret, "$nm = " . ($q ? $self->q($v) : $v);
        }

    return "WHERE " . join " AND ", @ret if @ret;
    }

#    safe-quotes a list[-ref] of strings

sub q {
    my $self = shift;
    my @v = &DB::Ent::args;
    $_ = $self->{dbh}->quote($_) for @v;
    warn "q(): multiple args but scalar context!"
        if @v > 1 && !wantarray();
    wantarray() ? @v : $v[0];
    }

sub in {
    my $self = shift;
    join ", ", &DB::Ent::args;
    }

#    returns a string ready for use with an IN statement

sub qin {
    my $self = shift;
    join ", ", $self->q(@_);
    }

#    Syntax:
#        <hashref-list> = x <sql-select>
#        <id> = x <sql-insert>
#        <rows> = x <sql-update>
#        <ok> = x <sql-else>

sub x {
    my $self = shift;
    $self->{cmd} = shift || $_ || return warn qq/x(): No command!/;
    $self->dbcmd() if $self->{debug} > 0;

    #   prepare and execute

    my $sth = $self->{dbh}->prepare($self->{cmd})
        || return $self->dberr();
    $sth->execute()
        || return $self->dberr();

    my $ok = $self->dberr();

    return $self->{dbh}->{mysql_insertid}
        if $self->{cmd} =~ /\bINSERT\b/i;

    return $self->{dbh}->rows
        if $self->{cmd} =~ /\bUPDATE\b/i;

    return $ok
        unless $self->{cmd} =~ /\bSELECT\b/i;

    my $ret = $sth->fetchall_arrayref({});
    wantarray() ? @$ret : $ret;
    }

sub dberr {
    my $self = shift;
    $self->{err} = $self->{dbh}->err || 0;
    $self->{errstr} = $self->{dbh}->errstr || "";

    my $die = $self->{DIE};
    if ($self->{err} == 1062) {
        return if $self->{dups} == $DB::Ent::DUPSQUIET;
        $die = undef if $self->{dups} == $DB::Ent::DUPSWARN;
        }
    if ($self->{err}) {
        $self->dbcmd() unless $self->{debug} > 0;
        $die && die($self->{errstr}) || warn($self->{errstr});
        }
    !$self->{err};
    }

sub dbcmd {
    my $self = shift;
    local $_ = shift || $self->{cmd};

    s/^\s*/> /mg; s/\t/    /g;
    $_ = sprintf("%s\n%s\n", ln("db->x()"), $_);

    print unless defined wantarray; $_;
    }

sub ln {
    my $title = shift;
    my $wd = shift || 60;
    my $ln = "-" x $wd;
    return $title ? substr("--- $title $ln", 0, $wd) : $ln;
    }

=head1 AUTHOR

Erick Calder <ecalder@cpan.org>

=head1 SUPPORT

For help and thank you notes, e-mail the author directly.  To report a bug, submit a patch or add to our wishlist please visit the CPAN bug manager at: F<http://rt.cpan.org>

=head1 AVAILABILITY

The latest version of the tarball, RPM and SRPM may always be found at: F<http://perl.arix.com/>  Additionally the module is available from CPAN.

=head1 SEE ALSO

L<DB::Ent>, L<hash>.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2002-2003 Erick Calder.

This product is free and distributed under the Gnu Public License (GPL).  A copy of this license was included in this distribution in a file called LICENSE. If for some reason, this file was not included, please see F<http://www.gnu.org/licenses/> to obtain a copy of this license.

$Id: Ent.pm,v 1.63 2003/06/24 03:58:11 ekkis Exp $

=cut

1; # yipiness :)
