package Catmandu::Importer::LDAP;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Carp qw(confess);
use Net::LDAP;
use Moo;

with 'Catmandu::Importer';

our $VERSION = '0.0105';

has host          => (is => 'ro', default   => sub {'ldap://127.0.0.1:389'});
has base          => (is => 'ro', predicate => 1);
has password      => (is => 'ro', predicate => 1);
has search_base   => (is => 'ro', predicate => 1);
has search_filter => (is => 'ro', predicate => 1);
has ldap          => (is => 'ro', lazy      => 1, builder => '_build_ldap');
has attributes => (
    is     => 'ro',
    coerce => sub {
        my $attrs = $_[0];
        if (is_string $attrs) {
            return {map {$_ => {}} split ',', $attrs};
        }
        if (is_array_ref $attrs) {
            return {map {$_ => {}} @$attrs};
        }
        if ($attrs) {
            for my $attr (keys %$attrs) {
                $attrs->{$attr} = {} unless ref $attrs->{$attr};
            }
        }
        $attrs;
    },
);

sub _build_ldap {
    my $self = $_[0];
    my $ldap = Net::LDAP->new($self->host, raw => qr/;binary/) || confess $@;
    my $bind
        = $self->has_base
        ? $self->has_password
            ? $ldap->bind($self->base, password => $self->password)
            : $ldap->bind($self->base)
        : $ldap->bind;

    if ($bind->code != 0) {
        $self->log->error($bind->error);
        return undef;
    }
    $ldap;
}

sub _new_search {
    my $self = $_[0];
    my %args;
    $args{base}   = $self->search_base   if $self->has_search_base;
    $args{filter} = $self->search_filter if $self->has_search_filter;
    if (my $attrs = $self->attributes) {
        $args{attrs} = [keys %$attrs];
    }
    my $search = $self->ldap->search(%args);
    if ($search->code != 0) {
        $self->log->error($search->error);
    }
    $search;
}

sub generator {
    my $self = $_[0];
    sub {
        state $search = $self->_new_search;
        my $entry = $search->shift_entry // return;
        my $data  = {};
        if (my $attrs = $self->attributes) {
            for my $attr (keys %$attrs) {
                my $config = $attrs->{$attr};
                my $val = $entry->get_value($attr, asref => $config->{array})
                    // next;
                $data->{$config->{as} // $attr}
                    = $config->{array} ? [@$val] : $val;
            }
        }
        else {
            for my $attr ($entry->attributes) {
                my $val = $entry->get_value($attr, asref => 1);
                $data->{$attr} = [@$val];
            }
        }
        $data;
    };
}

=head1 NAME

Catmandu::Importer::LDAP - Package that imports LDAP directories

=head1 SYNOPSIS

    # From the command line

    # Anonymous bind to find all 'Patrick's
    $ catmandu convert LDAP \
            --host ldaps://ldaps.ugent.be \
            --search-filter '(givenName=Patrick)' \
            --search-base 'dc=ugent, dc=be' to YAML

    # From Perl

    use Catmandu;

    my $importer = Catmandu->importer('LDAP',
                         host          => 'ldaps://ldaps.ugent.be' ,
                         search_filter => '(givenName=Patrick)' ,
                         search_base   => 'dc=ugent, dc=be'
                    );

    my $exporter = Catmandu->exporter('YAML');

    $exporter->add_many($importer);

    $exporter->commit;

=head1 CONFIGURATION

=over

=item host

The LDAP host to connect to

=item base

The base to bind to (if not specified it is an anonymous bind)

=item password

The password needed for the bind

=item search_base

The DN that is the base object entry relative to which the search is to be performed.

=item search_filter

One or more search filters. E.g.

   (givenName=Patrick)    # search Patrick
   (&(givenName=Patrick)(postalCode=9000))  # search Patrick AND postalcode=9000
   (|)(givenName=Patrick)(postalCode=9000)) # search Patrick OR postcalcode=9000

=back

=head1 METHODS

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited.
The methods are not idempotent: LDAP streams can only be read once.

=head1 SEE ALSO

L<Catmandu> ,
L<Catmandu::Importer> ,
L<Catmandu::Iterable>

=cut

1;
