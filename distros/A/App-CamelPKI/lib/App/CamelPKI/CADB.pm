#!perl -w
package App::CamelPKI::CADB;

use warnings;
use strict;

=head1 NAME

B<App::CamelPKI::CADB> - Store L<App::CamelPKI::CA> datas in a SQLite database

=head1 SYNOPSIS

=for My::Tests::Below "synopsis"

    use App::CamelPKI::CADB;

    my $cadb = load App::CamelPKI::CADB($dir);

    my $serial = $cadb->next_serial("certificate");

    # ... making a $certificate with $serial ...

    $cadb->add($cert, foo => "bar", baz => [ "quux", "bloggs" ]);

    $cadb->revoke($certificate, -revocation_reason => "keyCompromise",
                  -compromise_time => "20070313104800Z");

    $cadb->commit();

    for(my $cursor = $cadb->search(-initially_valid_at => "now",
                                   -revoked => 1);
        $cursor->has_more; $cursor->next) {
          my $cert = $cursor->certificate;
          my %infos = $cursor->infos;
          my $revocation_time = $cursor->revocation_time;
          my $revocation_reason = $cursor->revocation_reason;
          my $compromise_time = $cursor->compromise_time;

          # ... making the CRL ...
    }

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

This class modelizes a CA database; this database store issued
certificates, nominative datas used for their creation, revocation
status of these certificates, and some incremental series for CRL
and certificates serial numbers.

For now, Camel-PKI only knows howto store certificates in an SQLite
database.

=head1 CAPABILITY DISCIPLINE

Possessing an I<App::CamelPKI::CADB> instance equates privilege to perform
all non-destructive write operations on this database; however, no
deletion of certificates is possible.

The L</facet_readonly> method returns a read-only version on this
database.

The L</debug_statements> method is restricted (see
L<App::CamelPKI::RestrictedClassMethod>), despite it not being a class
method; the result is that it cannot be called at all when
I<App::CamelPKI::RestrictedClassMethod> is active, which is what we want
(C<debug_statements()> is not meant to be called at all in
production).

=cut

use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile catdir);
use SQL::Translator 0.07; # On behalf of ->deploy()
use App::CamelPKI::Error;
use App::CamelPKI::RestrictedClassMethod ':Restricted';
use App::CamelPKI::Time;
use App::CamelPKI::Certificate;

=head1 METHODS

=head2 initdb($dir)

Populates $dir, a string containing the name of a directory, with an
empty database.  Returns immediately if $dir already exists.

=cut

sub initdb {
    my ($class, $dir) = @_;

    my $db_file = $class->_db_file($dir);
    my $dsn = $class->_dsn($dir);
    if (-f $db_file) {
        $class->_connect($dir); # Acts as a functional test
        return;
    }

    if (! -d $dir) {
        mkpath($dir) or
            throw App::CamelPKI::Error::IO("cannot create path",
                                      -IOfile => $dir);
    }

    $class->_connect($dir)->deploy();
    return;
}

=head2 load($dir)

Restricted constructor (see L<App::CamelPKI::RestrictedClassMethod>).
Loads the database from the $dir directory and returns a read-write
object.

=cut

sub load : Restricted {
    my ($class, $dir) = @_;
    $class->initdb($dir);

    my $self = bless
        { dbix => $class->_connect($dir),
        }, $class;
    $self->{dbix}->txn_begin;
    if (defined(our $debugsub)) { # See L</debug_statements>
        $self->{dbix}->storage->debugobj
            (App::CamelPKI::CADB::_Logger->new($debugsub));
        $self->{dbix}->storage->debug(1);
    }

    return $self;
}

=head2 add($cert, %infos)

Add a certificate to the database. $cert is an instance of
L<App::CamelPKI::Certificate> which must not be already existing.

%infos is a table of nominative informations, dealt as an opaque chain,
where keys must been validaded by the regular expression qr/[a-z0-9_]+/,
and values are character chains or references to a character chains table.

Semantics on these informations is at the caller's choice; from the
I<App::CamelPKI::CADB> point of view, these informations can be used as
search expression in L</search>, and be consulted using L</infos> in
L</App::CamelPKI::CADB::Cursor>.

=cut

sub add {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        if (@_ % 2);
    my ($self, $cert, %infos) = @_;

    my $dercert = $cert->serialize(-format => "DER");

    throw App::CamelPKI::Error::Database("Certificate already entered")
        if $self->{dbix}->resultset("Certificate")
            ->search({der => $dercert})->count;
    my $certid = $self->{dbix}->resultset("Certificate")->create
        ({der => $dercert, serial => $cert->get_serial,
          not_before => $cert->get_notBefore,
          not_after  => $cert->get_notAfter,
         })->id;
    foreach my $key (keys %infos) {
        foreach my $val (ref($infos{$key}) eq "ARRAY" ? @{$infos{$key}} :
                         ($infos{$key})) {
            $self->{dbix}->resultset("CertInfo")
                ->create({certid => $certid,
                          key => $key,
                          val => $val});
        }
    }
    1;
}

=head2 search(%criteria)

Search certificates that were added (L</add>) precedently, using
%criteria criteria in a conjonctive way (ie, dealt with the "AND"
operator).

If %criteria does not contain any key C<< -initially_valid_at >>
and C<< -revoked >>, then %criteria is supposed to implicitly contain

    -initially_valid_at => "now", -revoked => 0

to make I<search()> returns only valid certificates (in the RFC3280
way), if not stated otherwise.

In a more general way, keys and values for %criteria are:

=over

=item I<< -certificate => $cert >>

Renvoie uniquement le certificat identique à $cert, une instance de
L<App::CamelPKI::Certificate>.

=item I<< -initially_valid_at => $time >>

Returns only certificates that were initially scheduled to be valid at
$time date, regardless of whether they have been revoked (but see also
C<< -revoked >>). In other words, returns certificates that match

  notBefore <= $time && $time <= notAfter

$time is either an object of class L<App::CamelPKI::Time>, a date in the
"zulu" format (yyyymmddhhmmssZ), or the special string "now".

=item I<< -revoked => 1 >>

Returns only revoked certificates, ie those for which the most recent
call to L</revoke> did not specify C<< -reason => "removeFromCRL" >>.

=item I<< -revoked => 0 >>

Returns only valid certificates, or those that were un-revoked by
passing C<< -reason => "removeFromCRL" >> to L</revoke>.

=item I<< -revoked => undef >>

Search certificates without consideration for their revocation status.
Used to cancel the effect of the implicit value mentioned above.

=item I<< -serial => serial >>

Search certificates for the certifiate serial.

=item I<< $infokey => $infoval >>

where $infokey doesn't start by a hyphen (-): returns only
certificate(s) that had $infokey and $infoval among their %infos at
the time they where added using L</add>. $infoval may be undef,
indicating that any value for $infokey in %infos is acceptable.

=back

The return value in list context is a list of L<App::CamelPKI::Certificate>
object class. In scalar context, a B<cursor object> of the
L</App::CamelPKI::CADB::Cursor> class is returned.

=cut

sub search {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        unless (@_ % 2);
    my ($self, %searchkeys) = @_;

    if (! exists $searchkeys{-initially_valid_at} &&
        ! exists $searchkeys{-revoked}) {
        $searchkeys{-initially_valid_at} = "now";
        $searchkeys{-revoked} = 0;
    }

    # Using DBIx::Class release 0.07003, the join list to execute don't
    # support iterative enumeration, unlike the WHERE clauses. We must
    # use this dirty kludge, that violates DBIx::Class encapsulation in
    # two points:
    my @joins;
    my $cursor = $self->{dbix}->resultset("Certificate")
        ->search({ }, { join => \@joins }); # Encaps violation
    # number 1: we will be modifying \@joins later
    while(my ($k, $v) = each %searchkeys) {
        if ($k !~ m/^-/) {
            push(@joins, "infos");
            my $qualifier = (@joins == 1) ? "" : "_" . scalar(@joins);
            # encapsulation violation number 2: we try to guess the
            # way DBIx::Class disambiguates the join column names.
            $cursor = $cursor->search
                ({ "infos${qualifier}.key" => $k,
                   ( defined($v) ? ("infos${qualifier}.val" => $v) : () ),
                 });
        } elsif ($k eq "-certificate") {
            throw App::CamelPKI::Error::Internal("INCORRECT_ARGS")
                unless eval { $v->isa("App::CamelPKI::Certificate") };
            $cursor = $cursor->search
                ( { der => $v->serialize(-format => "DER") } );
        } elsif ($k eq "-initially_valid_at") {
            $v = App::CamelPKI::Time->parse($v);
            $cursor = $cursor->search
                ( { not_before => { "<=", $v->zulu },
                    not_after => { " >=", $v->zulu }} );
        } elsif ($k eq "-serial") {
        	$cursor = $cursor->search
                ( { serial => { "=", $v } } );
        } elsif ($k eq "-revoked") {
            if (! defined($v)) {
                # no-op
            } elsif ($v) {
                # Only revoked certificates
                $cursor = $cursor->search
                     # Yes, { "!=", undef } correctly translates to "IS
                     # NOT NULL". Props to SQL::Abstract!
                    ( [ -and => { revocation_time => { "!=", undef } },
                        { revocation_reason => { "!=", "removeFromCRL" } }
                      ] );
            } else {
                # Only *not* revoked certificates
                $cursor = $cursor->search
                    ( [ -or => { revocation_time => { "==", undef } },
                        { revocation_reason => "removeFromCRL" }
                      ] );
            }
        } else {
            throw App::CamelPKI::Error::Internal
                ("INCORRECT_ARGS", -details => "Unknown search key $k");
        }
    }
    $cursor = (ref($self) . "::Cursor")->_new
        ($cursor, $self->{dbix}->resultset("CertInfo"));
    return $cursor if ! wantarray;

    my @retval;
    for(; $cursor->has_more; $cursor->next) {
        push(@retval, $cursor->certificate);
    }
    return @retval;
}

=head2 revoke($cert, %options)

Mark a certificate as revoked, for the CA to know it must been 
included in the next CRLs. $cert is an instance of
L<App::CamelPKI::Certificate>. Known Named options are:

=over

=item I<< -revocation_time => $time >>

The revocation date, in "zulu" format (yyyymmddhhmmssZ). By default,
the current date is used.

=item I<< -revocation_reason => $reason >>

=item I<< -hold_instruction => $oid >>     (B<NOT IMPLEMENTED YET>)

=item I<< -hold_instruction => $string >>  (B<NOT IMPLEMENTED YET>)

=item I<< -compromise_time => $time >>

Values of the extensions of the same name in the CRL, as documented in
L<Crypt::OpenSSL::CA/add_entry>. By default, these extensions are
omitted.  Using C<removeFromCRL> as C<$reason> cancels the revocation
of this certificate.  Please note that values for keys
C<-hold_instruction> and C<-revocation_reason> undergo
canonicalization, so that they may read out differently from the
L</App::CamelPKI::CADB::Cursor> when fetched again.

=back

=cut


sub revoke {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        if (@_ % 2);
    my ($self, $cert, %options) = @_;

    throw App::CamelPKI::Error::Internal("UNIMPLEMENTED")
        if ($options{-hold_instruction});
    # ... And thus, I can just skip field canonicalization issues for
    # now!

    my $cursor = $self->{dbix}->resultset("Certificate")
        ->search({ der => $cert->serialize(-format => "DER") });
    throw App::CamelPKI::Error::Database
        ("Unknown certificate", -certificate => $cert)
            unless defined(my $row = $cursor->next);
    throw App::CamelPKI::Error::Database
        ("Duplicate certificate", -certificate => $cert)
            if $cursor->next;

    $row->revocation_time
        (App::CamelPKI::Time->parse($options{-revocation_time} || "now")
         ->zulu);
    $row->compromise_time
        (App::CamelPKI::Time->parse($options{-compromise_time})->zulu)
            if (exists $options{-compromise_time});
    $row->revocation_reason($options{-revocation_reason})
        if (exists $options{-revocation_reason});

    $row->update;

    1;
}

=head2 next_serial($seqname)

Increments the sequence named $seqname and returns its new value.
$seqname may be any string matching m/^[a-z]+$/i, at the caller's
choice. Sequences start at 2.

=cut

sub next_serial {
    my ($self, $seqname) = @_;
    my $row = $self->{dbix}->resultset("Sequence")->find_or_new
        ({name => $seqname});
    if (! $row->in_storage) {
        $row->val(2);
        $row->insert();
        return 2;
    } else {
        my $retval = $row->val + 1;
        $row->val($retval);
        $row->update();
        return $retval;
    }
}

=head2 commit()

Commits all modifications made with L</add>, L</revoke> and
L</next_serial> since the construction of this object, or the previous
call to I<commit()>, whichever is latest.  B<If commit() is not
called, no write will be made to the file system, and all
modifications will be lost!>.

=cut

sub commit {
    my ($self) = @_;
    $self->{dbix}->txn_commit();
    $self->{dbix}->txn_begin();
}

=head2 max_serial($seqname)

Returns (an approximation of) the current status of the sequence named
$seqname, ie an integer which is guaranteed to be superior or equal to
all previous values previously returned by L</next_serial>, and
strictly inferior to all values that will be returned in the future.

=cut

sub max_serial {
    my ($self, $seqname) = @_;
    my $row = $self->{dbix}->resultset("Sequence")->find_or_new
        ({name => $seqname});
    return ($row->in_storage ? $row->val : 0);
}


=head2 facet_readonly()

Returns a read-only copy of the database object: only L</search> and
L</max_serial> methods are available.

=cut

sub facet_readonly {
    my ($self) = @_;
    return bless { delegate => $self },
        "App::CamelPKI::CADB::FacetReadOnly";

    package App::CamelPKI::CADB::FacetReadOnly;

    use Class::Facet from => "App::CamelPKI::CADB",
        on_error => \&App::CamelPKI::Error::Privilege::on_facet_error,
        delegate => [qw(search max_serial)];
}

=head2 debug_statements($debugsub)

This restricted method (see L<App::CamelPKI::RestrictedClassMethod>)
installs $debugsub as the SQL request observer on all
I<App::CamelPKI::CADB> objects constructed later. This method will be
called thusly for each SQL request:

   $debugsub->($sql, @bind_values);

This mecanism is only destined for testing purposes; it should not
be used in production.

=cut

sub debug_statements : Restricted {
    my ($class, $debugsub) = @_;
    our $debugsub = $debugsub;
}

=head1 App::CamelPKI::CADB::Cursor

This class models a read only SQL cursor equivalent; instancies may be
constructed using L</search>.

An attentive reader will probably understand that's a fairly trivial
derivation of the L<DBIx::Class> API; However there is no reason to
return directly an instance of I<DBIx::Class> in L</search> because
it will violate the encapsulation of I<App::CamelPKI::CADB>. Consequence
could be a induced coupling (it should be impossible to refactor the
scheme without breaking the whole calling code), and worse, a 
privilege escape leading to a security breach (because it's also
possible to write with a I<DBIx::Class> cursor).

=cut

package App::CamelPKI::CADB::Cursor;

=begin internals

=head2 _new($realcursor, $infos_resultset)

Constructor. $realcursor is an instance of
L<DBIx::Class::ResultSet> coming from
L</App::CamelPKI::CADB::_Schema::Certificate> which represents all certificates
to be enumerated; $infos_resultset is an instance of
L<DBIx::Class::ResultSet> coming from L</App::CamelPKI::CADB::_Schema::CertInfos>
which represents the B<totality> of B<CertInfos> in database, and it's the
job of I<App::CamelPKI::CADB::Cursor> to restrict this search to what it is
interresting.

=cut

sub _new {
    my ($class, $cursor, $infos_resultset) = @_;
    return bless {
                      index => 0,
                      cursor => $cursor,
                      infos_set => $infos_resultset,
                     }, $class;
}

=head2 _fetch_certificates()

Execute the SQL request that rocks, grab in one shot all certificates
and their revocation informations, and cache them in $self->{certs}
which become a list of objects form the
L</App::CamelPKI::CADB::_Schema::Certificate>.

Rationale for this 'slurpy' behavior: SQLite does not appreciate to have
a statement in progress when you close the connection (symptom: 
C<cannot commit transaction - SQL statements in progress(1)>). That's 
why we cannot use the "streaming" mode of DBIx::Class without a complex
system of statement caching in one time, I'm just too lazy to implement
right now...

=cut

sub _fetch_certificates {
    my ($self) = @_;
    return if $self->{certs};
    $self->{certs} = [];
    $self->{cursor}->reset;
    while(my $row = $self->{cursor}->next) {
        push (@{$self->{certs}}, $row);
    }
    return;
}

=head2 _fetch_infos()

Functions as L</_fetch_certificates> (which is called before each operation
of this method), grab in one shot all nominative informations about
certificates, and cache them in $self->{infos} in the form of a reference
to a list of same length as @{$self->{certs}} and ordored the same way,
which contains as many multi-valued hash tables to store informations
as passed by L</add> at the time of the respective certificates insertion.

=cut

sub _fetch_infos {
    my ($self) = @_;
    return if $self->{infos};
    $self->_fetch_certificates;

    my %infos;

    # FIXME: we could repeat the $self->{cursor} SQL instead.
    # This could helps to play too much DBI placeholders...
    my $infocursor = $self->{infos_set}->search
        ({ certid => { in => [ map { $_->certid } @{$self->{certs}} ] }});
    $infocursor->reset;
    while(my $info = $infocursor->next) {
        push(@{$infos{$info->certid}->{$info->key}},
             $info->val);
    }

    $self->{infos} = [ map { ($infos{$_->certid} || {}) }
                       @{$self->{certs}} ];
    return;
}

=head2 _current()

Returns the tuple object currently under the cursor.

=cut

sub _current {
    my ($self) = @_;
    $self->_fetch_certificates;
    return $self->{certs}->[$self->{index}];
}

=end internals

=head2 count

Returns the total number of entries in this cursor, independently of the number
of times L</next> has already been called.

=cut

sub count {
    my ($self) = @_;
    return @{$self->{certs}} if $self->{certs};
    # No-camel optimization, isn't it? No! learning test of
    # DBIx::Class! Syntagm found in
    # L<DBIx::Class::Manual::Cookbook>.
    my $count = $self->{cursor}->search
        ({}, {
              select => [ { count => { distinct => 'me.certid' } } ],
              as     => [ 'count' ]
             });
    my $retval = $count->next->get_column("count");
    $count->next; # Reach the end of records, close the statment
    # subjacent handle, and so remove an useless warning.
    return $retval;
}

=head2 has_more

Returns true if, and only if, the cursor has still some results to propose.
All methods hereafter have an undef behavior when I<has_more> returns false.

=cut

sub has_more { defined(shift->_current) }

=head2 next

Makes the cursor advance one position.

=cut

sub next {
    my ($self) = @_;
    $self->{index}++;
    return;
}

=head2 certificate

Returns the certificate currently under the cursor, in a
L<App::CamelPKI::Certificate> object.

=cut

sub certificate { App::CamelPKI::Certificate->parse(shift->_current->der) }

=head2 infos

Returns a table of structures and contents simliar to the table 
%infos passed to L</add> at the time of the certiticate insertion
in database. In a scalar context, returns a reference on a hash
which contains references on lists; In a list context, returns this
same hash "flat" (a list alternating scalar keys and values which
are references on lists).

The order of the %info keys, and the order of values contained in when
more than on key provided, is B<not> preserved.

=cut

sub infos {
    my ($self) = @_;
    $self->_fetch_infos;
    return wantarray ? %{$self->{infos}->[$self->{index}]} :
        $self->{infos}->[$self->{index}];
}

=head2 revocation_time

=head2 revocation_reason

=head2 compromise_time

=head2 hold_instruction

Returns the canonical form of the revocation informations corresponding
to the certificate present under the cursor at that time: time stamps
are in "zulu" format; I<revocation_reason()> returns a symbolic character
chains among the one listed in RFC3280 section 5.3.1; I<hold_instruction()>
returns an OID in decimal notation separated by dots (for example
C<1.2.840.10040.2.1>).

=cut

sub revocation_time   { shift->_current->revocation_time   }
sub revocation_reason { shift->_current->revocation_reason }
sub compromise_time   { shift->_current->compromise_time   }
sub hold_instruction  { shift->_current->hold_instruction  }

=begin internals

=head1 INTERNAL METHODS

=cut

package App::CamelPKI::CADB;

=head2 DESTROY

Called when the object is to be destroyed; disconnect the underlying
database to get rid off stupid warnings (see discussions on
L<http://lists.rawmode.org/pipermail/dbix-class/2006-October/002567.html>).

=cut

sub DESTROY {
    local $@;
    my ($self) = @_;
    return if ! defined $self->{dbix};
    my $storage = $self->{dbix}->storage; return if ! defined $storage;
    $storage->disconnect;
}

=head1 INTERNAL CLASS METHODS

=head2 _schema_class

Returns the name of the object class containing the schema declaration,
L</App::CamelPKI::CADB::_Schema>.

=cut

sub _schema_class {
    my ($self) = @_;
    $self = ref($self) if ref($self);
    return "${self}::_Schema";
}

=head2 _db_file($homedir)

Returns the name of the file which contains the SQLite database.

=cut

sub _db_file {
    my ($class, $dir) = @_;
    return catfile($dir, "ca.db");
}

=head2 _dsn($homedir)

Returns the DSN (connection string for L</DBI>) usefull to connect
to the AC database present in $homedir.

=cut

sub _dsn {
    my ($class, $dir) = @_;
    return "dbi:SQLite:" . $class->_db_file($dir);
}

=head2 _connect($homedir)

=head2 _connect($homedir)

Creates and returns a L<DBIx::Class::Schema> connection to the database
present in $homedir, pursuant to values returned by class methods used
precedently.

=cut

sub _connect {
    my ($class, $dir) = @_;
    $class->_schema_class->connect($class->_dsn($dir), undef, undef,
                                   { RaiseError => 1, PrintError => 0,
                                     AutoCommit => 1 });
}

=head2 App::CamelPKI::CADB::_Schema::CertInfo

An instance of this class represents a line in the auxilliary table
C<cert_info>, each tuple (C, K, V) of this table modelise the relation
between "the C certificate has been added with the V value for the K
key in the %info parameters at the time L</add> was invoked". Note that
the API schema of L</add> and L</infos> allow for multi-valued keys in
%info.

=cut

package App::CamelPKI::CADB::_Schema::CertInfo;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw(Core));

__PACKAGE__->table("cert_info");
__PACKAGE__->add_columns
    (certid => { data_type => "integer",
                 is_nullable => 0,
               },
     key => { data_type => "text",
              is_nullable => 0 },
     val => { data_type => "text",
              is_nullable => 0 },
    );

=head2 App::CamelPKI::CADB::_Schema::Certificate

An instance of this class represents a line in the C<certificate>
table, which in its turn represent a certifice (what a surprise!)
and its revocation status informations.

=cut

package App::CamelPKI::CADB::_Schema::Certificate;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw(PK::Auto Core));

__PACKAGE__->table("certificate");

__PACKAGE__->add_columns
    # An unique number of certificate, which must *never be*
    # visible outside of the present class.
    (certid => { data_type => "integer",
                 is_nullable => 0,
                 auto_increment => 1,
               },
     # The certificate in the form of a DER encoded blob.
     der => { data_type => "blob",
              is_nullable => 0,
            },
     # La date de révocation, au format "zulu" à 4 chiffres pour
     # l'année; ou la date de retour en grâce dans un cas d'une
     # révocation temporaire abandonnée.  Initialement NULL au
     # moment de la certification.
     # The revocation date, in "zulu" format with 4 digits for the year
     # date; or the return in grace date in case of a canceled temporary
     # revocation. Initially NULL at the time of the certification.
     revocation_time => { data_type => "text",
                          is_nullable => 1,
                        },
     # The reason for revocation, in the form of a character string
     # (for example: "cessationOfOperation")
     revocation_reason => { data_type => "text",
                            is_nullable => 1,
                          },
     # The date of compromission, in "zulu" format.
     compromise_time => { data_type => "text",
                          is_nullable => 1,
                        },
     # The "hold instruction", in the form of an decimal OID notation
     # separated by dots.
     hold_instruction => { data_type => "text",
                           is_nullable => 1,
                         },

     # Fields that follow are de-normalisations on the "der" field,
     # to allow searchs.

     # The serial number, on a hexadecimal textual form, used by
     # Crypt::OpenSSL::CA (ie "0x1234deadbeef").
     serial => {data_type => "text",
                is_nullable => 0,
               },
     # Dates of validity for the certificate, in "zulu" format with
     # 4 digit for the year date.
     not_before => { data_type => "text",
                     is_nullable => 0 },
     not_after  => { data_type => "text",
                     is_nullable => 0 },
    );

__PACKAGE__->set_primary_key("certid");
__PACKAGE__->has_many("infos",
                      "App::CamelPKI::CADB::_Schema::CertInfo", "certid");

=head2 App::CamelPKI::CADB::_Schema::Sequence

This class represents the "sequences" table, which contains one line
for each sequence created with L</next_serial> or L</max_serial>.

=cut

package App::CamelPKI::CADB::_Schema::Sequence;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw(Core));

__PACKAGE__->table("sequences");

__PACKAGE__->add_columns
    # The name of the sequence, in minor case
    (name => { data_type => "text",
               is_nullable => 0,
             },
     # The current sequence number
     val =>  { data_type => "integer",
               is_nullable => 0,
             });

__PACKAGE__->set_primary_key("name");


=head2 App::CamelPKI::CADB::_Schema

This class represents the whole database schema. Instances of this 
class (created by L</_connect>) represent a connection to a concrete
database.

=cut

package App::CamelPKI::CADB::_Schema;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw(Certificate CertInfo Sequence));

=head3 throw_exception

Overload of the parent class to throw 
L<App::CamelPKI::Error/App::CamelPKI::Error::Database>.

=cut

sub throw_exception {
    my $self = shift;
    throw App::CamelPKI::Error::Database(join(" ", @_));
}

=head2 App::CamelPKI::CADB::_Logger

Auxilliary class to observe SQL requests, as suggested in
L<DBIx::Class:Manual::Cookbook/Profiling>. Used by L</load>
to honor the setting done by L</debug_statements>.

=cut

package App::CamelPKI::CADB::_Logger;

sub new {
    my ($class, $debugfunc) = @_;
    bless { debugfunc => $debugfunc }, $class;
}

sub txn_begin {}
sub txn_commit {}
sub query_start {}

sub query_end {
    my ($self, @params) = @_;
    $self->{debugfunc}->(@params);
}

require My::Tests::Below unless caller;
1;

__END__

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use File::Spec::Functions qw(catfile catdir);
use IO::File;
use Fatal qw(mkdir);
use File::Slurp qw(read_file);
use App::CamelPKI::Error;
use App::CamelPKI::Sys qw(fork_and_do);
use App::CamelPKI::Test qw(%test_self_signed_certs
                      %test_entity_certs);
use App::CamelPKI::Certificate;
use Crypt::OpenSSL::CA;

test "learning: storing with real pieces of NUL characters "
    . "inside" => sub {
        # Let's prepare a dummy schema...
        {
            package Bogus::Schema::Beware;
            use base qw/DBIx::Class/;
            __PACKAGE__->load_components(qw(Core));

            __PACKAGE__->table("beware");
            __PACKAGE__->add_columns("blob" => { data_type => "blob" });

            package Bogus::Schema;
            use base qw/DBIx::Class::Schema/;

            __PACKAGE__->load_classes(qw(Beware));
        }
        # This comment only serves to help Emacs out...

        my $testdsn = "dbi:SQLite:" .
            catdir(My::Tests::Below->tempdir, "testnul.db");
        Bogus::Schema->connect($testdsn)->deploy();

        my $bogon = "zoinx\0" x 2;
        my $schema = Bogus::Schema->connect($testdsn);
        $schema->resultset('Beware')->create
            ({ blob => $bogon });
        undef $schema;

        $schema = Bogus::Schema->connect($testdsn);
        is($schema->resultset('Beware')->first->blob, $bogon,
           "bogon has persisted as planned");

        my $resultset = $schema->resultset('Beware')
            ->search({blob => $bogon});
        is($resultset->count, 1, "searching per blob 1/2");
        $resultset = $schema->resultset('Beware')
            ->search({blob => $bogon . "\0"});
        is($resultset->count, 0, "searching per blob 2/2");
};

my $cert = App::CamelPKI::Certificate->parse
    ($test_self_signed_certs{"rsa1024"});


=head2 change_db_dir()

Change the value of $testdir and recreates an empty database therein.

=cut

my $testdir;
{
    my $unique = 0;
    sub change_db_dir {
        $unique++;
        $testdir = catdir(My::Tests::Below->tempdir, "testdb$unique");
    }
}
change_db_dir();

test "initialisation of the DB" => sub {
    local $SIG{__WARN__} = sub {
    								my $warn = shift;
    								if ($warn !~ /closing dbh with active statement handles/){
    									warn shift; fail
    								} 
    							}; # Making warnings
    # fatal, such as the usual suspect "Issuing rollback() ..."

    my $db = App::CamelPKI::CADB->load($testdir);
    ok($db->isa("App::CamelPKI::CADB"));
    is($db->search()->count(), 0);
};

=head2 open_db()

Open a connection to the database for testing purposes. SQL requests
are recorded in the @queries global variable, so that tests are able
to inspect the requests they caused to be made.  If the $debug_queries
variable is set to a true value, SQL requests will also be printed to
STDERR.

=cut

our @queries;
our $debug_queries;

App::CamelPKI::CADB->debug_statements(sub {
    my ($sql, @bind_values) = @_;
    push(@queries, $sql);
    map { $_ = "<der>" if m/[\000-\010]/ } @bind_values;
    diag join(" / ", $sql, @bind_values) . "\n" if $debug_queries;
});

sub open_db {
    my $cadb = load App::CamelPKI::CADB($testdir);
    return $cadb;
}

test "->add()" => sub {
    my $cadb = open_db;
    $cadb->add($cert, template => "foobar");
    try {
        $cadb->add($cert, zoinx => ["deux", "mille" ]);
        fail("inserting doubled bloom prohibited");
    } catch App::CamelPKI::Error::Database with {
        pass;
    };

    $cadb = open_db;
    $cadb->add($cert, template => "foobar"); # Works because the
    # transaction has been rollbacked
    $cadb->add(App::CamelPKI::Certificate->parse
               ($test_entity_certs{"rsa1024"}),
               foo => "bar",
               zoinx => ["is", "tan" ],
              );
    $cadb->commit;
    is($cadb->search()->count(), 2, "certificates in base");
};

test "->search() in list context" => sub {
    my $cadb = open_db;
    my @certs = $cadb->search(-initially_valid_at => "20010101020400Z");
    is(scalar(@certs), 0);
    @certs = $cadb->search(-initially_valid_at => "now");
    is(scalar(@certs), 2, "all certificates");
    grep { ok($_->isa("App::CamelPKI::Certificate")) } @certs;

    @certs = $cadb->search(-certificate => $cert);
    is(scalar(@certs), 1);
    ok($certs[0]->equals($cert));
};

test "->search() with a cursor" => sub {
    my $cadb = open_db;
    my $cursor = $cadb->search(-revoked => undef);
    is($cursor->count, 2);
    ok($cursor->has_more);
    ok($cursor->certificate->isa("App::CamelPKI::Certificate"));
    $cursor->next;
    ok($cursor->has_more);
    ok($cursor->certificate->isa("App::CamelPKI::Certificate"));
    $cursor->next;
    ok(! $cursor->has_more);

    $cursor = $cadb->search(-revoked => undef);
    isnt($cursor->infos, undef,
         "consulting ->infos available "
         . "even if we don't look for them");

    $cursor = $cadb->search(template => "foobar", -revoked => 0);
    ok($cursor->has_more);
    is($cursor->infos->{template}->[0], "foobar");
    ok($cursor->has_more, "the cursor did not move");
    $cursor->next; ok(! $cursor->has_more);

    $cursor = $cadb->search(template => "foobar", -revoked => 1);
    ok(! $cursor->has_more);
    is($cursor->count, 0, 'Filter "and" which exclude all');

    # This one is tricky: the search matches for two reasons (zoinx =>
    # "is" and zoinx => "tan"), but we want only one response back.
    $cursor = $cadb->search(zoinx => undef);
    is($cursor->count, 1);
    is_deeply([ sort @{$cursor->infos->{zoinx}}], [qw(is tan)])
        or warn Data::Dumper::Dumper(scalar $cursor->infos);
};

test "REGRESSION: searching with multiple nominatives keys" => sub {
    my $cadb = open_db;
    my @certs = $cadb->search(foo => "bar", zoinx => "is");
    is(scalar(@certs), 1);

    @certs = $cadb->search(foo => "bar", zoinx => "is", zoinx => "tan");
    is(scalar(@certs), 1);
};

test "->revoke()" => sub {
    my $cadb = open_db;
    $cadb->revoke($cert, -revocation_reason => "keyCompromise",
                  -compromise_time => "now");
    $cadb->commit();
    is($cadb->search()->count(), 1, "only valid certificates by default");
    is($cadb->search(-revoked => undef)->count(), 2,
       "all certificates");
    is($cadb->search(-revoked => 1)->revocation_reason, "keyCompromise");
    like($cadb->search(-revoked => 1)->compromise_time,
         qr/^\d{4}\d{2}\d{2}\d{2}\d{2}\d{2}Z$/,
         "the compromise time has been canonicalized");

    $cadb->revoke($cert, -revocation_reason => "removeFromCRL");
    $cadb->commit();
    is($cadb->search()->count(), 2, "certificate redemption");
};

test "->next_serial() et ->max_serial()" => sub {
    my $cadb = open_db;
    my @serialz = map { $cadb->next_serial("corn") } (1..10);
    grep { cmp_ok($serialz[$_], ">=", 2) } (0..$#serialz);
    grep { cmp_ok($serialz[$_ - 1], "<", $serialz[$_]) } (1..$#serialz);
    my $maxserial = $cadb->max_serial("corn");
    is($cadb->max_serial("corn"), $maxserial,
       "->max_serial is idempotent");

    grep { cmp_ok($serialz[$_], "<=", $maxserial) } (0..$#serialz);
    cmp_ok($cadb->next_serial("corn"), ">", $maxserial);
};

test "real unicity for ->next_serial() and ->max_serial()" => sub {
    my $numprocs = 5; my $numincs = 10; my $numcommits = 10;
    my $resultsfile = catfile($testdir, "serialz.txt");
    my $fd = new IO::File($resultsfile, ">");
    $fd->autoflush(1);
    my @pids = map { fork_and_do {
        my $base = open_db;
        COMMIT: for my $i (1..$numcommits) {
            my $done = try {
                for my $j (1..$numincs) {
                    $fd->print($base->next_serial("zoinx") . "\n");
                }
                $base->commit;
                1;
            } catch Error with {
                my $E = shift;
                die($E) unless ($E =~ m/database is locked/i);
                select(undef, undef, undef, rand);
                $base = open_db;
                0;
            };
            # If we got a serial with ->next_serial, the test as now
            # written makes it mandatory that we succeed to commit
            # later. It's not strictly needed if the caller knows how to
            # do a two-phase commit, but we err on the safe side.
            redo COMMIT if ! $done;
        }
    } } (1..$numprocs);
    while(@pids) { waitpid(shift(@pids), 0); }
    my @lines = read_file($resultsfile);
    is(scalar(@lines), $numprocs * $numincs * $numcommits,
       "right number of lines in $resultsfile");
    my %serialz = map { $_ => 1 } (@lines);
    is(scalar(keys %serialz), scalar(@lines),
       "no collision in $resultsfile");
};

change_db_dir();
use App::CamelPKI::Test qw(%test_public_keys %test_keys_plaintext);

test "->search() and left-join request optimization"
    => sub {
  my $cadb = open_db;
  my $pubkey = Crypt::OpenSSL::CA::PublicKey
      ->parse_RSA($test_public_keys{rsa1024});
  my $privkey = Crypt::OpenSSL::CA::PrivateKey
      ->parse($test_keys_plaintext{rsa1024});

  foreach my $i (1..100) {
      my $cert_to_be = Crypt::OpenSSL::CA::X509->new($pubkey);
      $cert_to_be->set_notBefore("20070101000000Z");
      $cert_to_be->set_notAfter("20570101000000Z");
      $cert_to_be->set_serial(sprintf("0x%x", $i));
      my $cert = App::CamelPKI::Certificate->parse
          ($cert_to_be->sign($privkey, "sha256"));
      $cadb->add($cert, foo => "bar", baz => "quux");
  }
  $cadb->commit();

  @queries = ();
  my $cursor = $cadb->search(-revoked => undef);
  foreach my $i (1..100) {
      ok($cursor->has_more);
      is($cursor->infos->{foo}->[0], "bar");
      is($cursor->infos->{baz}->[0], "quux");
      $cursor->next;
  }
  ok(! $cursor->has_more);

  cmp_ok(scalar(@queries), "<", 10,
         "the number of requests is sub-linear "
         . "wrt the number of fetched certificates");
};


change_db_dir();

test "REGRESSION: searching by infos must not mask some of them"
    => sub {
    my $cadb = open_db;
    my $cert = App::CamelPKI::Certificate->parse
        ($test_self_signed_certs{"rsa2048"});
    $cadb->add($cert, foo => "bar", baz => [ "quux", "bloggs" ]);

    # Witness Experiency:
    my $cursor = $cadb->search();
    is($cursor->count, 1);
    my $infos = $cursor->infos;
    is($infos->{foo}->[0], "bar")
        or warn Data::Dumper::Dumper($infos);
    is_deeply([sort @{$infos->{baz}}], [qw(bloggs quux)]);

    # Experiency test:
    $cursor = $cadb->search(foo => "bar");
    is($cursor->count, 1);
    is_deeply(scalar($cursor->infos), $infos)
        or warn Data::Dumper::Dumper(scalar($cursor->infos));
};

change_db_dir();

test "synopsis" => sub {
    my $code = My::Tests::Below->pod_code_snippet("synopsis");
    $code =~ s/\bmy /our /g;

    my $dir = $testdir;
    my $certificate = $cert;
    eval "package Synopsis; $code"; fail($@) if $@;

    cmp_ok($Synopsis::serial, ">=", 2);
    ok($Synopsis::cadb->isa("App::CamelPKI::CADB"));
    ok($Synopsis::cursor->isa("App::CamelPKI::CADB::Cursor"));
    is($Synopsis::cert->serialize(), $certificate->serialize());
    is($Synopsis::infos{foo}->[0], "bar");
    is_deeply([sort @{$Synopsis::infos{baz}}], [qw(bloggs quux)]);
    like($Synopsis::revocation_time, qr/^\d{4}\d{2}\d{2}\d{2}\d{2}\d{2}Z$/,
         "revocation time looks ok");
    is($Synopsis::revocation_reason, "keyCompromise");
    is($Synopsis::compromise_time, "20070313104800Z");
};

=end internals

=cut
