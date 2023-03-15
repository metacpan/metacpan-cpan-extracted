package Bot::BasicBot::Pluggable::Store;
$Bot::BasicBot::Pluggable::Store::VERSION = '1.30';
use strict;
use warnings;
use Carp qw( croak );
use Data::Dumper;
use Storable qw( nfreeze thaw );
use Try::Tiny;
use Module::Load qw();
use Log::Log4perl;

use base qw( );

sub new {
    my $class = shift;
    my $self;
    my $logger = Log::Log4perl->get_logger($class);
    if ( @_ % 2 == 0 ) {
        $self = bless {@_} => $class;
    }
    elsif ( @_ == 1 and ref $_[0] eq 'HASH' ) {
        $self = $class->new_from_hashref( $_[0] );
    }
    elsif ( @_ == 1 and !ref $_[0] ) {
        $self = $class->new_from_hashref( { type => $_[0] } );
    }
    elsif ( !@_ ) {
        $self = bless {} => $class;
    }
    else {
        $logger->warn(
"Argument to new() is neither an argument list, a hashref, a string nor empty"
        );
    }
    $self->init();
    $self->load();
    return $self;
}

sub new_from_hashref {
    my ( $class, $args ) = @_;
    my $logger = Log::Log4perl->get_logger($class);

    if ( ref($args) ne 'HASH' ) {
        $logger->warn('Argument to store_from_hashref must be a hashref');
    }

    my $store_class = delete $args->{type} || 'Memory';

    $store_class = "Bot::BasicBot::Pluggable::Store::$store_class"
      unless $store_class =~ /::/;

    # load the store class
    try { Module::Load::load $store_class; }
    catch { $logger->warn("Couldn't load $store_class - $_"); };

    my $store = $store_class->new( %{$args} );

    croak "Couldn't init a $store_class store\n" unless $store;

    return $store;
}

sub init { undef }

sub load { undef }

sub save { }

sub keys {
    my ( $self, $namespace, %opts ) = @_;
    my $mod = $self->{store}{$namespace} || {};
    return $self->_keys_aux( $mod, $namespace, %opts );
}

sub count_keys {
    my ( $self, $namespace, %opts ) = @_;
    $opts{_count_only} = 1;
    $self->keys( $namespace, %opts );
}

sub _keys_aux {
    my ( $self, $mod, $namespace, %opts ) = @_;

    my @res = ( exists $opts{res} ) ? @{ $opts{res} } : ();

    return CORE::keys %$mod unless @res;

    my @return;
    my $count = 0;
  OUTER: while ( my ($key) = each %$mod ) {
        for my $re (@res) {

            # limit matches
            $re = "^" . lc($namespace) . "_.*${re}.*"
              if $re =~ m!^[^\^].*[^\$]$!;
            next OUTER unless $key =~ m!$re!;
        }
        push @return, $key if ( !$opts{_count_only} );
        last if $opts{limit} && ++$count >= $opts{limit};

    }

    return ( $opts{_count_only} ) ? $count : @return;
}

sub get {
    my ( $self, $namespace, $key ) = @_;
    return $self->{store}{$namespace}{$key};
}

sub set {
    my ( $self, $namespace, $key, $value ) = @_;
    $self->{store}{$namespace}{$key} = $value;
    $self->save($namespace);
    return $self;
}

sub unset {
    my ( $self, $namespace, $key ) = @_;
    delete $self->{store}{$namespace}{$key};
    $self->save($namespace);
    return $self;
}

sub namespaces {
    my $self = shift;
    return CORE::keys( %{ $self->{store} } );
}

sub dump {
    my $self = shift;
    my $data = {};
    for my $n ( $self->namespaces ) {
        warn "Dumping namespace '$n'.\n";
        for my $k ( $self->keys($n) ) {
            $data->{$n}{$k} = $self->get( $n, $k );
        }
    }
    return nfreeze($data);
}

sub restore {
    my ( $self, $dump ) = @_;
    my $data = thaw($dump);
    for my $n ( CORE::keys(%$data) ) {
        warn "Restoring namespace '$n'.\n";
        for my $k ( CORE::keys( %{ $data->{$n} } ) ) {
            $self->set( $n, $k, $data->{$n}{$k} );
        }
    }
    warn "Complete.\n";
}

1;
__END__

=head1 NAME

Bot::BasicBot::Pluggable::Store - base class for the back-end pluggable store

=head1 VERSION

version 1.30

=head1 SYNOPSIS

  my $store = Bot::BasicBot::Pluggable::Store->new( option => "value" );

  my $namespace = "MyModule";

  for ( $store->keys($namespace) ) {
    my $value = $store->get($namespace, $_);
    $store->set( $namespace, $_, "$value and your momma." );
  }

Store classes should subclass this and provide some persistent way of storing things.

=head1 METHODS

=over 4

=item new()

Standard C<new> method, blesses a hash into the right class and
puts any key/value pairs passed to it into the blessed hash. If
called with an hash argument as its first argument, new_from_hashref
will be run with the hash as its only argument. See L</new_from_hashref>
for the possible keys and values. You can also pass a string and
it will try to call new_from_hashref with a hash reference { type
=> $string }. Calls C<load()> to load any internal variables, then
C<init>, which you can also override in your module.

=item new_from_hashref( $hashref )

Intended to be called as class method to dynamically create a store
object. It expects a hash reference as its only argument. The only
required hash element is a string specified by I<type>. This should
be either a fully qualified classname or a colonless string that
is appended to I<Bot::BasicBot::Pluggable::Store>. All other arguments
are passed down to the real object constructor.

=item init()

Called as part of new class construction, before C<load()>.

=item load()

Called as part of new class construction, after C<init()>.

=item save()

Subclass me. But, only if you want to. See ...Store::Storable.pm as an example.

=item keys($namespace,[$regex])

Returns a list of all store keys for the passed C<$namespace>.

If you pass C<$regex> then it will only pass the keys matching C<$regex>

=item get($namespace, $variable)

Returns the stored value of the C<$variable> from C<$namespace>.

=item set($namespace, $variable, $value)

Sets stored value for C<$variable> to C<$value> in C<$namespace>. Returns store object.

=item unset($namespace, $variable)

Removes the C<$variable> from the store. Returns store object.

=item namespaces()

Returns a list of all namespaces in the store.

=item dump()

Dumps the complete store to a huge Storable scalar. This is mostly so
you can convert from one store to another easily, i.e.:

  my $from = Bot::BasicBot::Pluggable::Store::Storable->new();
  my $to   = Bot::BasicBot::Pluggable::Store::DBI->new( ... );
  $to->restore( $from->dump );

C<dump> is written generally so you don't have to re-implement it in subclasses.

=item restore($data)

Restores the store from a L<dump()>.

=back

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Bot::BasicBot::Pluggable>

L<Bot::BasicBot::Pluggable::Module>
