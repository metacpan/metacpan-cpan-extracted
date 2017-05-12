package Data::ICal::RDF;

# le pragma
use 5.010;
use strict;
use warnings FATAL => 'all';

# le moo and friends
use Moo;
use namespace::autoclean;

# we do need these symbols
use RDF::Trine   qw(statement iri literal);
use UUID::Tiny   qw(UUID_V4);

# but don't screw around loading symbols on these
use DateTime                 ();
use DateTime::Duration       ();
use DateTime::Format::W3CDTF ();
use DateTime::Format::ICal   ();
use DateTime::TimeZone::ICal ();
use Data::ICal               ();
use MIME::Base64             ();
use IO::Scalar               ();
use Path::Class              ();
use Scalar::Util             ();

# oh and our buddy:
with 'Throwable';

=head1 NAME

Data::ICal::RDF - Turn iCal files into an RDF graph

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

# built-in ref types for our robust type checker
my %CORE = map { $_ => 1 } qw(SCALAR ARRAY HASH CODE REF GLOB LVALUE
                              FORMAT IO VSTRING Regexp);
sub _is_really {
    my ($val, $type) = @_;
    # bail out early on undef
    return unless defined $val;

    # bail out early on literals
    my $ref = ref $val or return;

    if (Scalar::Util::blessed($val)) {
        # only do ->isa on non-core reftypes
        return $CORE{$type} ?
            Scalar::Util::reftype($val) eq $type : $val->isa($type);
    }
    else {
        # only return true if supplied reftype is in core
        return $CORE{$type} && $ref eq $type;
    }
}

# shorthands for UUID functions

sub _uuid () {
    lc UUID::Tiny::create_uuid_as_string(UUID_V4);
}

sub _uuid_urn () {
    'urn:uuid:' . _uuid;
}

# this thing has been copied a million and one times
my $NS = RDF::Trine::NamespaceMap->new({
    rdf   => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    rdfs  => 'http://www.w3.org/2000/01/rdf-schema#',
    owl   => 'http://www.w3.org/2002/07/owl#',
    xsd   => 'http://www.w3.org/2001/XMLSchema#',
    dct   => 'http://purl.org/dc/terms/',
    foaf  => 'http://xmlns.com/foaf/0.1/',
    ical  => 'http://www.w3.org/2002/12/cal/icaltzd#',
    geo   => 'http://www.w3.org/2003/01/geo/wgs84_pos#',
});

# this will capture the segments of a properly-formed v4 uuid
my $UUID4 = qr/([0-9A-Fa-f]{8})
               -?([0-9A-Fa-f]{4})
               -?(4[0-9A-Fa-f]{3})
               -?([89ABab][0-9A-Fa-f]{3})
               -?([0-9A-Fa-f]{12})/x;

# iCal properties and their default datatypes. types with a star are
# overrides

my %PROPS = (
    CALSCALE           => 'TEXT',
    METHOD             => 'TEXT',
    PRODID             => 'TEXT',
    VERSION            => 'TEXT',
    ATTACH             => 'URI',
    CATEGORIES         => 'LIST*',    # TEXT
    CLASS              => 'TEXT',
    COMMENT            => 'TEXT',
    DESCRIPTION        => 'TEXT',
    GEO                => 'COORDS*', # FLOAT
    LOCATION           => 'TEXT',
    'PERCENT-COMPLETE' => 'INTEGER',
    PRIORITY           => 'INTEGER',
    RESOURCES          => 'LIST*',    # TEXT
    STATUS             => 'LIST*',    # actually an enum
    SUMMARY            => 'TEXT',
    COMPLETED          => 'DATE-TIME',
    DTEND              => 'DATE-TIME',
    DUE                => 'DATE-TIME',
    DTSTART            => 'DATE-TIME',
    DURATION           => 'DURATION',
    FREEBUSY           => 'PERIOD',
    TRANSP             => 'LIST*', # actually enum
    TZID               => 'TEXT',
    TZNAME             => 'TEXT',
    TZOFFSETFROM       => 'UTC-OFFSET',
    TZOFFSETTO         => 'UTC-OFFSET',
    TZURL              => 'URI',
    ATTENDEE           => 'CAL-ADDRESS',
    CONTACT            => 'TEXT',
    ORGANIZER          => 'CAL-ADDRES',
    'RECURRENCE-ID'    => 'DATE-TIME',
    'RELATED-TO'       => 'TEXT', # actually UID
    URL                => 'URI',
    UID                => 'TEXT',
    EXDATE             => 'DATE-TIME',
    RDATE              => 'DATE-TIME',
    RRULE              => 'RECUR',
    ACTION             => 'LIST*', # actually enum
    REPEAT             => 'INTEGER',
    TRIGGER            => 'DURATION',
    CREATED            => 'DATE-TIME',
    DTSTAMP            => 'DATE-TIME',
    'LAST-MODIFIED'    => 'DATE-TIME',
    SEQUENCE           => 'INTEGER',
    'REQUEST-STATUS'   => 'TEXT',
);

# the icaltzd spec (http://www.w3.org/2002/12/cal/icaltzd#) is pretty
# much derived deterministically from rfc 2445 (now 5445). properties
# are lower case unless hyphenated, in which event they are camelCased.

# however we don't want to use the ical properties on everything,
# notably: created, last modified, geo coords
my %PRED = (
    CREATED         => $NS->dct->created,
    'LAST-MODIFIED' => $NS->dct->modified,
);

# this gives us the correct predicate
sub _predicate_for {
    my ($self, $prop) = @_;

    # get the name
    my $name = lc $prop->key;

    return $PRED{uc $name} if $PRED{uc $name};

    my ($first, @rest) = split /-/, $name;
    $name = $first . join '', map { ucfirst $_ } @rest if @rest;

    $NS->ical->uri($name);
}

# this is a helper for BINARY values.
sub _decode_property {
    my $prop = shift;
    my $enc  = uc($prop->parameters->{ENCODING} || 'BASE64');
    if ($enc eq 'BASE64') {
        # for some reason base64 is not built into Data::ICal.
        return MIME::Base64::decode($prop->value);
    }
    elsif ($enc eq 'QUOTED-PRINTABLE') {
        # QP *is* built in, however.
        return $prop->decoded_value;
    }
    else {
        return;
    }
}

# these get run as faux methods and their job is to insert statements
# into the temporary store.
my %VALS = (
    BINARY        => sub {
        # ohhhhhh this one's gonna be fun.
        my ($self, $prop, $s) = @_;

        # get the literal value
        my $val = _decode_property($prop);
        return unless defined $val;

        my $param  = $prop->parameters;

        # get a suitable content type
        my ($type) = (lc($param->{FMTTYPE} || 'application/octet-stream') =~
                          /^\s*(.*?)(?:\s*;.*)?$/);

        # too bad there isn't a standardized parameter for file names
        my $name = $param->{'X-FILENAME'} || $param->{'X-APPLE-FILENAME'};

        # this is where the securi-tah happens, folks.
        if (defined $name) {
            # remove any space padding
            $name =~ s/^\s*(.*?)\s*$/$1/;
            # scrub the filename of any naughty path info
            $name = Path::Class::File->new($name)->basename if $name ne '';

            # kill the name if all that's left is an empty string
            undef $name if $name eq '';
        }

        # turn the val into an IO object
        my $io = IO::Scalar->new(\$val);

        # now try to resolve the attachment
        my $o = eval { $self->resolve_binary->($self, $io, $type, $name) };
        $self->throw("resolve_binary callback failed: $@") if $@;
        $self->throw('resolve_binary callback returned an invalid value')
              unless _is_really($o, 'RDF::Trine::Node');

        my $p = $self->_predicate_for($prop);
        $self->model->add_statement(statement($s, $p, $o));

        $val;
    },
    BOOLEAN       => sub {
        my ($self, $prop, $s) = @_;

        # postel's law
        my $x = 1 if $prop->value =~ /1|true|on|yes/i;

        # output
        my $o = literal($x ? 'true' : 'false', undef, $NS->xsd->boolean);
        my $p = $self->_predicate_for($prop);
        $self->model->add_statement(statement($s, $p, $o));

        # now return proper boolean
        $x || 0;
    },
    'CAL-ADDRESS' => sub {},
    DATE          => sub {
        my ($self, $prop, $s) = @_;

        # this will croak a proper error
        my $dt = DateTime::Format::ICal->parse_datetime($prop->value);
        my $o  = literal($dt->ymd, undef, $NS->xsd->date);
        my $p  = $self->_predicate_for($prop);
        $self->model->add_statement(statement($s, $p, $o));

        # maybe make this a DateTime::Incomplete?
        $dt;
    },
    'DATE-TIME'   => sub {
        # this needs access to tz
        my ($self, $prop, $s) = @_;

        my $dt  = DateTime::Format::ICal->parse_datetime($prop->value);

        my $tzid = $prop->parameters->{TZID};
        #warn "TZID: $tzid" if $tzid;
        #require Data::Dumper;
        #warn Data::Dumper::Dumper($self->tz);
        if ($tzid and my $tz = $self->tz->{$tzid}) {
            #warn 'hooray that whole effort worked!';
            $dt->set_time_zone($tz);
        }

        my $dtf = DateTime::Format::W3CDTF->new;
        my $o = literal($dtf->format_datetime($dt),
                          undef, $NS->xsd->dateTime);
        my $p = $self->_predicate_for($prop);
        $self->model->add_statement(statement($s, $p, $o));
    },
    DURATION      => sub {
        my ($self, $prop, $s) = @_;
    },
    FLOAT         => sub {
        my ($self, $prop, $s) = @_;
        my ($f) = ($prop->value =~ /([+-]?\d+(?:\.\d+)?)/);
        return unless defined $f;

        my $p = $self->_predicate_for($prop);
        my $o = literal($f += 0.0, undef, $NS->xsd->decimal);
        $self->model->add_statement(statement($s, $p, $o));

        $f;
    },
    INTEGER       => sub {
        my ($self, $prop, $s) = @_;
        my ($d) = ($prop->value =~ /([+-]?\d+)/);
        return unless defined $d;

        my $p = $self->_predicate_for($prop);
        my $o = literal($d += 0, undef, $NS->xsd->integer);
        $self->model->add_statement(statement($s, $p, $o));

        $d;
    },
    PERIOD        => sub {
        # this needs access to tz
        my ($self, $prop, $s) = @_;
    },
    RECUR         => sub {
        # this needs access to dtstart which may itself need tz
        my ($self, $prop, $s) = @_;
    },
    TEXT          => sub {
        my ($self, $prop, $s) = @_;
        # get the property
        my $val = $prop->value;
        return unless defined $val;

        # trim whitespace
        $val =~ s/^\s*(.*?)\s*$/$1/sm;
        return if $val eq '';

        # prep the statement
        my $lang = $prop->parameters->{LANGUAGE};
        my $o = literal($val, $lang);
        my $p = $self->_predicate_for($prop);
        $self->model->add_statement(statement($s, $p, $o));

        # return the value just cause
        $val;
    },
    TIME          => sub {
        # this needs access to tz
        my ($self, $prop, $s) = @_;
    },
    URI           => sub {
        my ($self, $prop, $s) = @_;

        my $uri = URI->new($prop->value)->canonical;
        my $p = $self->_predicate_for($prop);
        $self->model->add_statement(statement($s, $p, iri($uri->as_string)));

        $uri;
    },
    'UTC-OFFSET'  => sub {},
    # now for my own pseudo-types
    COORDS        => sub {
        #my ($self, $prop, $s) = @_;
    },
    LIST          => sub {
        my ($self, $prop, $s) = @_;
        # so it turns out that Data::ICal or whatever it inherits from
        # can't tell the difference between an escaped comma and an
        # actual syntactical comma, meaning that this will always be
        # broken for strings that contain (literal) commas.
        my $x;
    },
);

# this marshals the contents of %VALS
sub _process_property {
    my ($self, $prop, $s) = @_;

    # XXX the two early exits in here would only happen if either of
    # the two hashes were wrong. i'm ambivalent about going to the
    # trouble of making them throw.

    # find the default type for the content
    my $key  = uc $prop->key;
    my $type = $PROPS{$key} or return;

    # star means override
    if ($type =~ /^(.*?)\*$/) {
        $type = $1;
    }
    else {
        # otherwise override the default from a param if it exists
        my $v = $prop->parameters->{VALUE};
        $type = $v if $v;
    }

    # find the processor for this value
    my $sub = $VALS{$type} or return;

    # now run the content processor against the property and the
    # subject node. note the return value of this method is set by
    # whatever receives the dispatch.

    # we don't want uninitialized value errors in here (even
    # though all properties should have a defined value).
    $sub->($self, $prop, $s) if defined $prop->value;
}


=head1 SYNOPSIS

    use Data::ICal::RDF;

    # Instantiate a processing context with the appropriate handlers:
    my $context = Data::ICal::RDF->new(
        resolve_uid    => sub {
            # returns an RDF node for the UID...
        },
        resolve_binary => sub {
            # stores a binary object and resolves any relations
            # between it and its supplied file name; returns either an
            # identifier for the content or an identifier for the
            # relation between the name and the content.
        },
    );

    # Process a Data::ICal object...
    $context->process($ical);

    # Successive calls to 'process' against different iCal objects
    # will accumulate statements in the context's internal model.

    # Now you can do whatever you like with the model.
    my $result = $context->model;

=head1 DESCRIPTION

This module is a processor context for turning L<Data::ICal> objects
into RDF data. By default it uses version 4 (i.e., random) UUIDs as
subject nodes.

=head1 METHODS

=head2 new %PARAMS

Initialize the processor context.

=over 4

=item resolve_uid

Supply a callback function to resolve the C<UID> property of an iCal
object. This function I<must> return a L<RDF::Trine::Node::Resource>
or L<RDF::Trine::Node::Blank>. The function is handed:

=over 4

=item 1.

The context object itself, meaning the function should be written as
if it were a mixin of L<Data::ICal::RDF>,

=item 2.

The C<UID> of the iCal entry as a string literal.

=back

This function is used in L</subject_for>, which is used by
L</process_events>, which is used by L</process>. If the function is
not reliable for any reason, such as a failure to access hardware or
network resources, those methods may C<croak>.

By default the processor will automatically convert iCal UIDs which
are V4 UUIDs into C<urn:uuid:> URIs and use them as the subjects of
the resulting RDF statements. Furthermore, this is checked I<before>
running this function to mitigate any database overhead (see
L</no_uuids>). A V4 UUID URN is also generated as the iCal data's
subject if this function returns C<undef>. If you do I<not> want to
use UUIDs, then this function must I<always> return a valid value.

Here is an example of a method in a fictitious class which generates a
closure suitable to pass into the L<Data::ICal::RDF> constructor:

    sub generate_resolve_uid {
        my $self = shift;
        return sub {
            my ($data_ical_rdf, $uid) = @_;

            # magically look up a resource node from some other
            # data source
            return $self->lookup_uid($uid);
        };
    }

This parameter is I<required>.

=cut

has resolve_uid => (
    is => 'ro',
    isa => sub { die 'resolve_uid must be a CODE reference'
          unless _is_really($_[0], 'CODE') },
    required => 1,
);

=item resolve_binary

Supply a callback function to handle inline C<BINARY> attachments.
This function I<must> return a L<RDF::Trine::Node::Resource> or
L<RDF::Trine::Node::Blank>. The function is handed:

=over 4

=item 1.

The context object itself, meaning the function should be written as
if it were a mixin of L<Data::ICal::RDF>,

=item 2.

The binary data as a seekable IO object,

=item 3.

The I<declared> Content-Type of the data (as in you might want to
verify it using something like L<File::MMagic> or
L<File::MimeInfo::Magic>),

=item 4.

The suggested file name, which will already be stripped of any
erroneous path information. File names of zero length or containing
only whitespace will not be passed into this function, so you need
only check if it is C<defined>.

=back

This function is used in the C<BINARY> type handler in
L</process_events>, which is used by L</process>. Once again, if this
function is not completely reliable, those methods may C<croak>.

Here is an example of a method in a fictitious class which generates a
closure suitable to pass into the L<Data::ICal::RDF> constructor:

    sub generate_resolve_binary {
        my $self = shift;
        return sub {
            my ($data_ical_rdf, $io, $type, $name) = @_;

            # store the content somewhere and get back an identifier
            my $content_id = $self->store($io, $type);

            # return the content ID if there is no file name
            return $content_id unless defined $name;

            # turn the name into an RDF literal
            $name = RDF::Trine::Node::Literal->new($name);

            # now retrieve the subject node that binds the filename
            # to the content identifier
            my $subj = $self->get_subject_for($content_id, $name);

            # now perhaps write the relevant statements back into
            # the parser context's internal model
            map { $data_ical_rdf->model->add_statement($_) }
                for $self->statements_for($content_id, $name);

            # now we want to return the retrieved *subject*, which
            # will be passed into the upstream RDF statement
            # generation function.
            return $subj;
        };
    }

This parameter is I<required>.

=cut

has resolve_binary => (
    is  => 'ro',
    isa => sub { die 'resolve_binary must be a CODE reference'
          unless _is_really($_[0], 'CODE') },
    required => 1,
);

=item model

Supply an L<RDF::Trine::Model> object to use instead of an internal
temporary model, for direct interface to some other RDF data
store. Note that this is also accessible through the L</model>
accessor.

This parameter is I<optional>.

=cut

has model => (
    is => 'ro',
    default => sub {
        RDF::Trine::Model->new(RDF::Trine::Store::Hexastore->new) },
);

=item tz

Supply a C<HASH> reference whose keys are I<known> iCal C<TZID>
identifiers, and the values are L<DateTime::TimeZone> objects. By
default, these values are gleaned from the supplied L<Data::ICal>
objects themselves and I<will override> any supplied values.

This parameter is I<optional>.

=cut

has tz => (
    is      => 'ro',
    isa     => sub { die
          'tz must be a HASH of DateTime::TimeZone objects'
              unless _is_really($_[0], 'HASH')
                  and values %{$_[0]} == grep {
                      _is_really($_, 'DateTime::TimeZone') } values %{$_[0]} },
    default => sub { { } },
);

=item no_uuids

This is a flag to alter the short-circuiting behaviour of
L</subject_for>. When set, it will I<not> attempt to return the result
of L</uid_is_uuid> before running L</resolve_uid>.

=back

=cut

has no_uuids => (
    is => 'rw',
    default => sub { 0 },
);

has _subjects => (
    is => 'ro',
    default => sub { { } },
);

=head2 process $ICAL

Process a L<Data::ICal> object and put it into the object's internal
model. Note that any C<VTIMEZONE> objects found will I<not> be
inserted into the model, but rather integrated into the appropriate
date/time-like property values.

Note as well that I<all> non-standard properties are I<ignored>, as
well as all non-standard property I<parameters> with the exception of
C<X-FILENAME> and C<X-APPLE-FILENAME> since there is no standard way
to suggest a file name for attachments.

This method calls L</subject_for> and therefore may croak if the
L</resolve_uid> callback fails for any reason.

=cut

sub process {
    my ($self, $ical) = @_;

    my @events;
    for my $entry (@{$ical->entries}) {
        my $t = $entry->ical_entry_type;

        # snag all the time zones
        if ($t eq 'VTIMEZONE') {
            my $dtz = DateTime::TimeZone::ICal->from_ical_entry($entry);
            # woops, looks like DateTime::TimeZone aliasing messes
            # with the name and causes time zones to be unfindable
            my $id = $entry->property('TZID')->[0]->value;
            $self->tz->{$id} = $dtz;

            # XXX should we create a timezone object in rdf?
        }
        elsif ($t eq 'VEVENT') {
            push @events, $entry;
        }
        else {
            # noop
        }
    }

    $self->process_events(@events);
}

=head2 process_events @EVENTS

Process a list of L<Data::ICal::Entry::Event> objects. This is called
by L</process> and therefore also may croak.

=cut

# take the events and put them in the temporary store
sub process_events {
    my ($self, @events) = @_;

    for my $event (@events) {
        # skip unless this is correct
        next unless _is_really($event, 'Data::ICal::Entry');
        next unless $event->ical_entry_type eq 'VEVENT';

        # get the uid separately and skip if it doesn't exist
        my ($uid) = @{$event->property('uid')} or next;

        # fetch the appropriate subject UUID for the ical uid
        my $s = eval { $self->subject_for($uid->value) };
        $self->throw($@) if $@;

        # don't forget to add the uid
        $self->model->add_statement(statement(
            $s, $NS->ical->uid, literal($uid->value, undef, $NS->xsd->string)));

        # don't forget to add the type
        $self->model->add_statement
            (statement($s, $NS->rdf->type, $NS->ical->Vevent));

        # generate a map of all valid properties and whether or not
        # they are permitted multiple values
        my %pmap = ((map { $_ => 0 }
                         ($event->mandatory_unique_properties,
                          $event->optional_unique_properties)),
                    (map { $_ => 1 }
                         ($event->mandatory_repeatable_properties,
                          $event->optional_repeatable_properties)));
        # we have already processed uid so let's get rid of it
        delete $pmap{uid};

        while (my ($name, $multi) = each %pmap) {
            # it's definitely easier to be indiscriminate about the
            # properties than to try to cherry-pick
            my @props = @{$event->property($name) || []} or next;

            # truncate if this is a single-valued property
            @props = ($props[0]) unless $multi;

            # interpret the property contents and put the resulting
            # RDF statements in the temporary model
            for my $val (@props) {
                $self->_process_property($val, $s);
            }
        }
    }

    # return *something*, right?
    return scalar @events;
}

=head2 subject_for $UID

Take an iCal C<UID> property and return a suitable RDF node which can
be used as a subject. This may call the L</resolve_uid> callback and
therefore may croak if it receives a bad value.

=cut

sub subject_for {
    my ($self, $uid) = @_;

    if (!$self->no_uuids and my $s = $self->uid_is_uuid($uid)) {
        return $s;
    }

    # now we check the cache
    if (my $s = $self->_subjects->{$uid}) {
        #warn "Found $s for $uid in cache";
        return $s;
    }

    # call out to the callback
    if (my $s = eval { $self->resolve_uid->($self, $uid) }) {
        $self->throw('resolve_uid callback returned an invalid value')
            unless _is_really($s, 'RDF::Trine::Node');
        $self->throw("Node $s returned from resolve_uid callback" .
                             ' is not suitable as a subject')
            unless ($s->is_resource or $s->is_blank);
        return $self->_subjects->{$uid} = $s;
    }
    # explode if the eval failed
    $self->throw("resolve_uid callback failed: $@") if $@;


    # if we can't find a cached entry or a mapping in the database,
    # then we create one from scratch (and cache it).
    my $s = iri(_uuid_urn);
    #warn "Generated $s for $uid";
    return $self->_subjects->{$uid} = $s;
}

=head2 uuid_is_uid $UID

Returns a suitable C<urn:uuid:> node if the iCal UID is also a valid
(version 4) UUID. Used by L</subject_for> and available in the
L<resolve_uid> and L<resolve_binary> functions.

=cut

sub uid_is_uuid {
    my ($self, $uid) = @_;

    # check to see if this is a V4 UUID
    if (my @parts = ($uid =~ $UUID4)) {
        # if it is, convert it into a resource node and return it
        my $s = iri('urn:uuid:' . lc join '-', @parts);
        #warn "$s is already a V4 UUID";
        return $s;
    }
}

=head2 model

Retrieve the L<RDF::Trine::Model> object embedded in the processor.

=head1 CAVEATS

This module is I<prototype-grade>, and may give you unexpected
results. It does not have a test suite to speak of, at least not until
I can come up with an adequate one. An exhaustive test suite to handle
the vagaries of the iCal format would likely take an order of
magnitude more effort than the module code itself. Nevertheless, I
know it works because I'm using it, so my "test suite" is production.
I repeat, this is I<not> mature software. Patches welcome.

Furthermore, a number of iCal datatype handlers are not implemented in
this early version. These are:

=over 4

=item

C<CAL-ADDRESS>

=item

C<DURATION>

=item

C<PERIOD>

=item

C<RECUR>

=item

C<TIME>

=item

C<UTC-OFFSET>

=back

In particular, a lack of a handler for the C<DURATION> type means
events that follow the C<DTSTART>/C<DURATION> form will be incomplete.
In practice this should not be a problem, as iCal, Outlook, etc. use
C<DTEND>. This is also in part a design issue, as to whether the
C<DURATION> I<property> should be normalized to C<DTEND>.

As well, the C<GEO>, C<RESOURCES>, and C<CLASS> properties are yet to
be implemented. Patches are welcome, as are work orders.

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-ical-rdf at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-ICal-RDF>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::ICal::RDF

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-ICal-RDF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-ICal-RDF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-ICal-RDF>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-ICal-RDF/>

=back

=head1 SEE ALSO

=over 4

=item

L<Data::ICal>

=item

L<RDF::Trine>

=item

L<DateTime::TimeZone::ICal>

=item

L<RFC 5545|http://tools.ietf.org/html/rfc5545>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Data::ICal::RDF
