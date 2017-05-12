package DBIx::MoCo;
use strict;
use warnings;
use base qw (Class::Data::Inheritable);

use DBIx::MoCo::Relation;
use DBIx::MoCo::List;
use DBIx::MoCo::Cache;
use DBIx::MoCo::Cache::Dummy;
use DBIx::MoCo::Schema;
use DBIx::MoCo::Column;

use Carp;
use Class::Trigger;
use Tie::IxHash;
use File::Spec;
use UNIVERSAL::require;

our $VERSION = '0.18';
our $AUTOLOAD;

my $cache_status = {
    retrieve_count        => 0,
    retrieve_cache_count  => 0,
    retrieve_icache_count => 0,
    retrieve_all_count    => 0,
    has_many_count        => 0,
    has_many_cache_count  => 0,
    has_many_icache_count => 0,
    retrieved_oids        => [],
};
my ($db,$session,$schema);

__PACKAGE__->mk_classdata($_) for 
    qw(cache_object default_cache_expiration icache_expiration
       cache_null_object table cache_cols_only _db_object save_explicitly list_class);

## NOTE: INIT block does not work well under mod_perl or POE.
## Please set cache_object() explicitly if you want to use transparent caching.
# INIT {
#     unless (defined __PACKAGE__->cache_object) {
#         if (Cache::FastMmap->require) {
#             my $file = File::Spec->catfile('/tmp', __PACKAGE__);

#             File::Spec->require or die $@;
#             __PACKAGE__->cache_object(
#                 Cache::FastMmap->new(
#                     share_file     => $file,
#                     unlink_on_exit => 1,
#                     expire_time    => 600, # sec
#                 ) or die $!
#             );

#             chmod(0666, $file) or die $! if -e $file;
#         } else {
#             warn "Using DBIx::MoCo::Cache is now deprecated because of memory leak."
#                 . "Install Cache::FastMmap instead, or setup cache_object explicitly.";

#             DBIx::MoCo::Cache->require or die $@;
#             __PACKAGE__->cache_object( DBIx::MoCo::Cache->new );
#         }
#     }
# }

__PACKAGE__->default_cache_expiration(60 * 60 * 3); # 3 hours
__PACKAGE__->icache_expiration(0); # Instance cache
__PACKAGE__->cache_null_object(1);

# SESSION & CACHE CONTROLLERS
__PACKAGE__->add_trigger(after_create => sub {
    my ($class, $self) = @_;
    $self or confess '$self is not specified';
    $class->store_self_cache($self);
    $class->flush_belongs_to($self);
});
__PACKAGE__->add_trigger(before_update => sub {
    my ($class, $self) = @_;
    $self or confess '$self is not specified';
    $class->flush_self_cache($self);
});
__PACKAGE__->add_trigger(after_update => sub {
    my ($class, $self) = @_;
    $self or confess '$self is not specified';
    $class->store_self_cache($self);
});
__PACKAGE__->add_trigger(before_delete => sub {
    my ($class, $self) = @_;
    $self or confess '$self is not specified';
    $class->flush_self_cache($self);
    $class->flush_belongs_to($self);
});

sub cache_status { $cache_status }

sub cache {
    my $class = shift;
    $class = ref($class) if ref($class);

    ## It is no matter costs of creating Dummy objects because it is a singleton.
    my $cache = $class->cache_object || DBIx::MoCo::Cache::Dummy->instance;

    my ($k,$v,$ex) = @_;
    # warn "$cache in $class";
    my $s = $class->is_in_session;
    if (defined $v) {
        $ex ||= $class->default_cache_expiration;
        $ex = "+$ex" if ($ex && ref($cache) eq 'Cache::Memory');
        if ($v eq '') {
            if ($cache->can('remove')) {
                $cache->remove($k);
            }
            if ($s) {
                delete $s->{cache}->{$k} if $k;
            }
        } else {
            if ($class->cache_cols_only && ref($v) &&
                    ref($v) =~ /::/ && $v->isa($class)) {
                # remove additional elements
                my @cols = @{$v->columns};
                for (qw(changed_cols to_be_updated object_id)) {
                    push @cols, $_ if (defined $v->{$_});
                }
                my $hash = {map {$_ => $v->{$_}} @cols};
                my $o = bless $hash, $class;
                $cache->set($k,$o,$ex);
                $s->{cache}->{$k} = $o if $s;
            } else {
                $cache->set($k,$v,$ex);
                $s->{cache}->{$k} = $v if $s;
            }
        }
        # warn $cache . '->set(' . $k . ')';
        return $v;
    } elsif ($k) {
        # warn "hit session cache for $k" if ($s && $s->{cache}->{$k});
        return $s->{cache}->{$k} || $cache->get($k);
    }
}

sub flush_belongs_to {} # it's delivered from MoCo::Relation

sub flush_self_cache {
    my ($class, $self) = @_;
    if (!$self && ref $class) {
        $self = $class;
        $class = ref $self;
    }
    $self or confess '$self is not specified';

    return unless $class->cache_object;

    my $rm = $class->cache_object->can('remove') ? 'remove' : 'delete';
    for (@{$self->object_ids}) {
        # warn "flush $_";
        #weaken($class->cache($_));
        $class->cache_object->$rm($_);
    }
}

sub store_self_cache {
    my ($class, $self) = @_;
    if (!$self && ref $class) {
        $self = $class;
        $class = ref $self;
    }
    $self or confess '$self is not specified';
    # warn "store $_" for @{$self->object_ids};
    my $icache = $self->icache;
    $self->flush_icache;
    $class->cache($_, $self) for @{$self->object_ids};
    $self->icache($icache) if $icache;
}

sub icache {
    my $self = shift;
    if ($_[0]) {
        $self->{_icache} = shift;
    } else {
        my $ex = $self->icache_expiration;
        $ex > 0 or return;
        if (!$self->{_icache} ||
                ($self->{_icache}->{_created} + $ex < time())) {
            $self->{_icache} = {_created => time()};
        }
    }
    return $self->{_icache};
}

sub flush_icache {
    my $self = shift;
    $self->{_icache} or return;
    if ($_[0]) {
        # warn "flush icache $_[0] for " . $self;
        delete $self->{_icache}->{$_[0]};
    } else {
        $self->{_icache} = undef;
    }
}

sub has_many_keys_cache_name {
    my $self = shift;
    my $attr = shift or return;
    my $oid = $self->object_id or return;
    return sprintf('%s-%s_keys', $oid, $attr);
}

sub flush_has_many_keys {
    my $self = shift;
    my $attr = shift or return;
    # $self->flush($self->has_many_keys_name($attr));
    # $self->flush($self->has_many_max_offset_name($attr));
    my $key = $self->has_many_keys_cache_name($attr);
    $self->cache($key, '');
}

# session controllers
sub start_session {
    my $class = shift;
    $class->end_session if $class->is_in_session;
    $session = {
        changed_objects => [],
        cache => {},
        pid => $$,
        created => time(),
    };
}

sub is_in_session { $session }
sub session { $session }
sub session_cache {
    my $s = shift->session or return;
    return $s->{cache};
}

sub end_session {
    my $class = shift;
    $session or return;
    $class->save_changed;
    $cache_status->{retrieved_oids} = [];
    $session = undef;
}

sub save_changed {
    my $class = shift;
    $class->is_in_session or return;
    for (@{$class->session->{changed_objects}}) {
        $_ or next;
        $_->save;
    }
}

# CLASS DEFINISION METHODS
sub relation { 'DBIx::MoCo::Relation' }

sub db_object {
    my $class = shift;
    if (my $db = shift) {
        $class->_db_object($db);
    }
    $class->_db_object;
}

sub has_a {
    my $class = shift;
    $class->relation->register($class, 'has_a', @_);
}
sub has_many {
    my $class = shift;
    $class->relation->register($class, 'has_many', @_);
}

sub schema {
    my $class = shift;
    $class = ref $class if ref $class;
    unless ($schema->{$class}) {
        $schema->{$class} = DBIx::MoCo::Schema->new($class);
    }
    return $schema->{$class};
}

for my $attr (qw/primary_keys unique_keys retrieve_keys columns/) {
    my $classdata = "_" . $attr;
    __PACKAGE__->mk_classdata($classdata);

    no strict 'refs';
    *{__PACKAGE__ . "\::$attr"} = sub {
        my $class = shift;
        if (@_) {
            my @keys = (ref $_[0] and ref $_[0] eq 'ARRAY') ? @{$_[0]} : @_;
            $class->$classdata(\@keys);
        } else {
            $class->$classdata
                ? $class->$classdata
                : $class->schema->$attr;
        }
    };
}

sub has_muid {
    my $class = shift;
    return ($class->has_column('muid') &&
                scalar @{$class->primary_keys} == 1);
}

sub has_column {
    my $class = shift;
    my $col = shift or return;
    $class->columns or return;
    grep { $col eq $_ } @{$class->columns};
}

sub utf8_columns {
    my $class = shift;
    $class->schema->utf8_columns(@_);
}

sub is_utf8_column {
    my $class = shift;
    my $col = shift or return;
    my $utf8 = $class->utf8_columns or return;
    ref $utf8 eq 'ARRAY' or return;
    return grep { $_ eq $col } @$utf8;
}

# DATA OPERATIONAL METHODS
sub object_id {
    my $self = shift;
    my $class = ref($self) || $self;
    $self = undef unless ref($self);
    if ($self && $self->{object_id}) {
        return $self->{object_id};
    }
    my $prefix = $class->object_id_prefix || '';
    my ($key, $col);
    if ($self && @{$class->retrieve_keys || $class->primary_keys}) {
        if ($self->has_muid) {
            $key = $self->muid;
        } else {
            for (sort @{$class->retrieve_keys || $class->primary_keys}) {
                defined($self->{$_}) or warn "$_ is undefined for $self" and return;
                $key .= "-$_-" . $self->{$_};
            }
            $key or die "couldn't create object_id for " . $self;
            $key = $prefix . $key;
        }
    } elsif ($_[3]) {
        my %args = @_;
        $key .= "-$_-$args{$_}" for (sort keys %args);
        $key = $prefix . $key;
    } elsif (@{$class->primary_keys} == 1) {
        my @args = @_;
        $col = defined $args[1] ? $args[0] : $class->primary_keys->[0];
        my $value = defined $args[1] ? $args[1] : $args[0];
        if ($col eq 'muid') {
            $key = $value;
        } else {
            $key = $prefix . '-' . $col . '-' . $value;
        }
    }
    $self->{object_id} = $key if $self;;
    return $key;
}

sub object_id_prefix {
    my $class = shift;
    $class = ref $class if ref $class;
    return $class;
}

sub db { $_[0]->db_object }

sub retrieve {
    my $cs = $cache_status;
    $cs->{retrieve_count}++;
    my $class = shift;
    $_[0] or carp "Retrieve keys not found";
    my $oid = $class->object_id(@_);
    my $c = $class->cache($oid);
    if (defined $c) {
        # warn "use cache $oid";
        $cs->{retrieve_cache_count}++;
        return $c;
    } else {
        # warn "use db $oid";
        my $o = $class->retrieve_by_db(@_);
        if ($o) {
            $class->store_self_cache($o);
            push @{$cs->{retrieved_oids}}, $oid if $class->is_in_session;
        } else {
            # $class->cache($oid => $o) if $o;
            # cache null object for performance.
            $class->cache($oid => $o) if $class->cache_null_object;
        }
        return $o;
    }
}

sub retrieve_by_db {
    my $class = shift;
    my %args = defined $_[1] ? @_ : ($class->primary_keys->[0] => $_[0]);
    my $res = $class->db->select($class->table,'*',\%args);
    my $h = $res->[0];
    return $h ? $class->new(%$h) : '';
}

sub restore_from_db {
    my $self = shift;
    my $class = ref $self or return;
    my $hash = $self->primary_keys_hash or return;
    my $res = $class->db->select($class->table,'*',$hash);
    my $h = $res->[0] or return;
    @{$self}{keys %$h} = @{$h}{keys %$h};
    $class->store_self_cache($self);
    return $self;
}

sub retrieve_multi {
    my $class = shift;
    my @list = @_ or return $class->_list([]);

    my (@cached_objects, @non_cached_queries);
    if ($class->cache_object && $class->cache_object->can('get_multi')) {
        my $ids = [ map { $class->object_id(%$_) } @list ];
        my $hash = $class->cache_object->get_multi(@$ids) || {};

        for (my $i = 0; $i <= $#list; $i++) {
            my $object = $hash->{$ids->[$i]};
            $object
                ? push @cached_objects, $object
                : push @non_cached_queries, $list[$i];
        }
    } else {
        for (@list) {
            my $cached_object = $class->cache( $class->object_id(%$_) );
            $cached_object
                ? push @cached_objects, $cached_object
                : push @non_cached_queries, $_;
        }
    }

    ## Updating cache status
    $class->cache_status->{retrieve_count} += scalar @list;
    $class->cache_status->{retrieve_cache_count} += scalar @cached_objects;

    ## All objects were found in cache.
    if (@cached_objects == @list) {
        my @ordered= $class->_merge_objects(\@list, @cached_objects);
        wantarray ? return @ordered : return $class->_list(\@ordered);
    }

    my (@clauses, @bind_values);
    for my $cond (@non_cached_queries) {
        my $subclause = join ' AND ', map {
            push @bind_values, $cond->{$_};
            sprintf "%s = ?", $_
        } keys %$cond;

        push @clauses, $subclause;
    }
    my $where_clause = join ' OR ', map { sprintf "(%s)", $_ } @clauses;

    my @objects_from_db = $class->search( where => [ $where_clause, @bind_values ] );

    if ($class->is_in_session) {
        push @{$class->cache_status->{retrieved_oids}}, map { $_->object_id } @objects_from_db;
    }

    for my $object (@objects_from_db) {
        $class->store_self_cache($object);
    }

    my @merged = $class->_merge_objects(\@list, @cached_objects, @objects_from_db);
    wantarray ? return @merged : return $class->_list(\@merged);
}

sub _merge_objects {
    my $class = shift;
    my $order = shift;

    my $tied = tie my %idt, 'Tie::IxHash'; ## orderd Hash
    $tied->Push($class->object_id( %$_ ) => undef) for @$order;

    for (@_) {
        my $id = $_->object_id;
        die "assert" if not exists $idt{$id};
        $tied->Push($id => $_);
    }

## cache_null_object() is now deprecated
#     for (keys %idt) {
#         if (not $idt{$_} and $class->cache_null_object) {
#             $class->cache( $_ => '' );
#         }
#     }

    grep { defined $_ } values %idt;
}

sub retrieve_or_create {
    my $class = shift;
    my %args = @_;
    my %keys;
    @keys{@{$class->primary_keys}} = @args{@{$class->primary_keys}};
    $class->retrieve(%keys) || $class->create(%args);
}

sub retrieve_all {
    my $cs = $cache_status;
    $cs->{retrieve_all_count}++;
    my $class = shift;
    my %args = @_;
    my $result = [];
    my $list = $class->retrieve_all_id_hash(%args);
    push @$result, $class->retrieve(%$_) for (@$list);
    wantarray ? @$result :
        $class->_list($result);
}

sub retrieve_all_id_hash {
    my $class = shift;
    my %args = @_;
    $args{table} = $class->table;
    $args{field} = join(',', @{$class->retrieve_keys || $class->primary_keys});
    my $res = $class->db->search(%args);
    return $res;
}

sub create {
    my $class = shift;
    my %args = @_;
    $class->call_trigger('before_create', \%args);
    my $o = $class->new(%args);
#     if ($class->is_in_session && $o->has_primary_keys) {
#         $o->set(to_be_inserted => 1);
#         $o->changed_cols->{$_}++ for (keys %args);
#         push @{$class->session->{changed_objects}}, $o;
#     } else {
    if ($class->save_explicitly) {
        $o->set(to_be_inserted => 1);
        $o->changed_cols->{$_}++ for keys %args;
    } else {
        $class->db->insert($class->table,\%args) or croak 'couldnt create';
        my $pk = $class->primary_keys->[0];
        unless (defined $args{$pk}) {
            my $id = $class->db->last_insert_id;
            $o->set($pk => $id);
        }
    }
    $class->call_trigger('after_create', $o);
    return $o;
}

sub delete {
    my $self = shift;
    my $class = ref($self) ? ref($self) : $self;
    $self = shift unless ref($self);
    $self or return;
    $self->call_trigger('before_delete', $self);
    $self->has_primary_keys or return;
    my %args;
    for (@{$class->primary_keys}) {
        $args{$_} = $self->{$_};
        defined($args{$_}) or die "$self doesn't have $_";
    }
    %args or die "$self doesn't have where condition";
    my $res = $class->db->delete($class->table,\%args) or croak 'couldnt delete';
    $self = undef;
    return $res;
}

sub delete_all {
    my $class = shift;
    my %args = @_;
    ref $args{where} eq 'HASH' or die 'please specify where in hash';
    my $list = $class->retrieve_all_id_hash(%args);
    my $caches = [];
    for (@$list) {
        my $oid = $class->object_id(%$_);
        my $c = $class->cache($oid) or next;
        push @$caches, $c;
    }
    $class->call_trigger('before_delete', $_) for (@$caches);
    $class->db->delete($class->table,$args{where}) or croak 'couldnt delete';
    return 1;
}

sub search {
    my $class = shift;
    my %args = @_;

    my $with = delete $args{with};

    $args{table} = $class->table;
    my $res = $class->db->search(%args);
    $_ = $class->new(%$_) for @$res;
    $class->merge_with($res, $with) if $with;

    wantarray ? @$res : $class->_list($res);
}

sub merge_with {
    my ($class, $res, $with, $without) = @_;

    my @with_attrs = (ref $with and ref $with eq 'ARRAY') ? @$with : $with;

    if ($without) {
        my @withouts = (ref $without and ref $without eq 'ARRAY') ? @$without : $without;
        my $regex = sprintf '(?:^%s$)', join '|', @withouts;
        @with_attrs = grep { $_ !~ m/$regex/ } @with_attrs;
    }

    for my $with_attr (@with_attrs) {
        my $rel = $class->relation->find_relation_by_attr($class => $with_attr)
            or croak "No such relation for attr '$with_attr' in $class";

        my $key = $rel->{option}->{key} or next;

        my ($my_key, $other_key);
        (ref $key and ref $key eq 'HASH')
            ? ($my_key, $other_key) = %$key
            : $my_key = $other_key  = $key;

        my @queries = map { +{ $other_key => $_->$my_key } } @$res;

        ## Only creating caches for less SQL queries.
        ## Those caches will be stored to the session cache if the session is activated.
        $rel->{class}->retrieve_multi(@queries);
    }

    $res;
}

sub count {
    my $class = shift;
    my $where = '';
    if ($_[1]) {
        my %args = @_;
        $where = \%args;
    } elsif ($_[0]) {
        $where = shift;
    }
    my $res = $class->db->search(
        table => $class->table,
        field => 'COUNT(*) as count',
        where => $where,
    );
    return $res->[0]->{count} || 0;
}

sub find {
    my $class = shift;
    my $where;
    if ($_[1]) {
        my %args = @_;
        $where = \%args;
    } elsif ($_[0]) {
        $where = shift;
    } else {
        return;
    }
    $class->search(
        where => $where,
        offset => 0,
        limit => 1,
    )->first;
}

sub quote {
    my $class = shift;
    $class->db->dbh->quote(shift);
}

sub scalar {
    my ($class, $method, @args) = @_;
    scalar $class->$method(@args);
}

sub AUTOLOAD {
    my $self = $_[0];
    my $class = ref($self) || $self;
    $self = undef unless ref($self);
    (my $method = $AUTOLOAD) =~ s!.+::!!;
    return if $method eq 'DESTROY';
    no strict 'refs';
    if ($method =~ /^retrieve_by_(.+?)(_or_create)?$/o) {
        my ($by, $create) = ($1,$2);
        *$AUTOLOAD = $create ? $class->_retrieve_by_or_create_handler($by) :
            $class->_retrieve_by_handler($by);
    } elsif ($method =~ /^(\w+)_as_(\w+)$/o) {
        my ($col,$as) = ($1,$2);
        *$AUTOLOAD = $class->_column_as_handler($col, $as);
    } elsif (defined $self->{$method} || $class->has_column($method)) {
        *$AUTOLOAD = sub { shift->param($method, @_) };
    } else {
        croak sprintf 'Can\'t locate object method "%s" via package %s', $method, $class;
    }
    goto &$AUTOLOAD;
}

sub inflate_column {
    my $class = shift;
    @_ % 2 and croak "You gave me an odd number of parameters to inflate_column()";

    my %args = @_;
    while (my ($col, $as) = each %args) {
        no strict 'refs';
        no warnings 'redefine';

        if (ref $as and ref $as eq 'HASH') {
            for (qw/inflate deflate/) {
                if ($as->{$_} and ref $as->{$_} ne 'CODE') {
                    croak sprintf "parameter '%s' takes only CODE reference", $_
                }
            }

            *{"$class\::$col"} = sub {
                my $self = shift;
                if (@_) {
                    $as->{deflate}
                        ? $self->param( $col => $as->{deflate}->(@_) )
                        : $self->param( $col => @_ );
                } else {
                    $as->{inflate}
                        ? $as->{inflate}->( $self->param($col) )
                        : $self->param( $col );
                }
            }
        } else {
            *{"$class\::$col"} = $class->_column_as_handler($col, $as);
        }
    }
}

{
    my $real_can = \&UNIVERSAL::can;
    no warnings 'redefine', 'once';
    *DBIx::MoCo::can = sub {
        my ($class, $method) = @_;
        if (my $sub = $real_can->(@_)) {
            # warn "found $method in $class";
            return $sub;
        }
        no strict 'refs';
        if (my $auto = *{$class . '::AUTOLOAD'}{CODE}) {
            return $auto;
        }
        $AUTOLOAD = $class . '::' . $method;
        eval {&DBIx::MoCo::AUTOLOAD(@_)} unless *$AUTOLOAD{CODE};
        return *$AUTOLOAD{CODE};
    };
}

sub _column_as_handler {
    my $class = shift;
    my ($colname, $as) = @_;
    unless (DBIx::MoCo::Column->can($as)) {
        my $plugin = "DBIx::MoCo::Column::$as";
        $plugin->require;
        croak "Couldn't load column plugin $plugin: $@"  if $@;
        {
            no strict 'refs';
            push @{"DBIx::MoCo::Column::ISA"}, $plugin;
        }
    }
    return sub {
        my $self = shift;
        my $column = $self->column($colname) or return;
        if (my $new = shift) {
            my $as_string = $as . '_as_string'; # e.g. URI_as_string
            my $v = $column->can($as_string) ?
                $column->$as_string($new) : scalar $new;
            $self->param($colname => $v);
        }
        $self->column($colname)->$as();
    }
}

sub column {
    my $self = shift;
    my $col = shift or return;
    return DBIx::MoCo::Column->new($self->{$col});
}

sub _retrieve_by_handler {
    my $class = shift;
    my $by = shift or return;
    if ($by =~ /.+_or_.+/) {
        my @keys = split('_or_', $by);
        return sub {
            my $self = shift;
            my $v = shift;
            for (@keys) {
                my $o = $self->retrieve($_ => $v);
                return $o if $o;
            }
        };
    } else {
        my @keys = split('_and_', $by);
        return sub {
            my $self = shift;
            my %args;
            @args{@keys} = @_;
            $self->retrieve(%args);
        };
    }
}

sub _retrieve_by_or_create_handler {
    my $class = shift;
    my $by = shift or return;
    my @keys = split('_and_', $by);
    return sub {
        my $self = shift;
        my %args;
        @args{@keys} = @_;
        return $self->retrieve(%args) || $class->create(%args);
    };
}

sub _list {
    my $class = shift;

    if ($class->list_class) {
        $class->list_class->require;
        if ($@ and $@ !~ m/^Can\'t locate .+? in \@INC/) {
            die $@;
        }
        return $class->list_class->new(@_);
    } else {
        return DBIx::MoCo::List->new(@_);
    }
}

sub DESTROY {
    my $class = shift;
    $class->save_changed;
}

sub new {
    my $class = shift;
    my %args = @_;
    my $self = \%args;
    $self->{changed_cols} = {};
    bless $self, $class;
    $self;
}

sub flush {
    my $self = shift;
    my $attr = shift or return;
    # warn "flush " . $self->object_id . '->' . $attr;
    $self->{$attr} = undef;
    $self->store_self_cache($self);
}

sub param {
    my $self = shift;
    my $class = ref $self or return;
    return unless(defined $_[0]);
    # if (defined $_[1]) {
    if (@_ > 1) {
        @_ % 2 and croak "You gave me an odd number of parameters to param()!";
        my %args = @_;
        $class->call_trigger('before_update', $self, \%args);
        $self->{$_} = $args{$_} for (keys %args);
        if ($class->is_in_session) {
            $self->{to_be_updated}++;
            $self->{changed_cols}->{$_}++ for (keys %args);
            push @{$class->session->{changed_objects}}, $self;
        } elsif ($class->save_explicitly) {
            $self->{to_be_updated}++;
            $self->{changed_cols}->{$_}++ for keys %args;
        } else {
            my $where = $self->primary_keys_hash or return;
            %$where or return;
            $class->db->update($class->table,\%args,$where) or croak 'couldnt update';
        }
        $class->call_trigger('after_update', $self);
        # return 1;
    }
    return $self->{$_[0]};
}

sub primary_keys_hash {
    my $self = shift;
    my $class = ref $self or return;
    @{$class->primary_keys} or return;
    my $hash = {};
    for (@{$class->primary_keys}) {
        defined $self->{$_} or return;
        $hash->{$_} = $self->{$_};
    }
    return $hash;
}

sub set {
    my $self = shift;
    my ($k,$v) = @_;
    $self->{$k} = $v;
}

sub has_primary_keys {
    my $self = shift;
    my $class = ref $self;
    for (@{$class->primary_keys}) {
        defined $self->{$_} or return;
    }
    return 1;
}

sub save {
    my $self = shift;
    my $class = ref $self;
    keys %{$self->{changed_cols}} or return;
    my %args;
    for (keys %{$self->{changed_cols}}) {
#        defined $self->{$_} or croak "$_ is undefined";
        exists $self->{$_} or croak "$_ is undefined";
        $args{$_} = $self->{$_};
    }
    if ($self->{to_be_inserted}) {
        $class->db->insert($class->table,\%args);
        $self->{changed_cols} = {};
        $self->{to_be_inserted} = undef;
    } elsif ($self->{to_be_updated}) {
        my $where = $self->primary_keys_hash or return;
        %$where or return;
        $class->db->update($class->table,\%args,$where);
        $self->{changed_cols} = {};
        $self->{to_be_updated} = undef;
    }
}

sub object_ids { # returns all possible oids
    my $self = shift;
    my $class = ref $self or return;
    my $oids = {};
    $oids->{$self->object_id} = 1 if $self->object_id;
    for my $key (@{$class->unique_keys}) {
        next unless defined $self->{$key};
        my $oid = $class->object_id($key => $self->{$key}) or next;
        $oids->{$oid}++;
    }
    return [sort keys %$oids];
}

1;

__END__

=head1 NAME

DBIx::MoCo - Light & Fast Model Component

=head1 SYNOPSIS

  # First, set up your db.
  package Blog::DataBase;
  use base qw(DBIx::MoCo::DataBase);

  __PACKAGE__->dsn('dbi:mysql:dbname=blog');
  __PACKAGE__->username('test');
  __PACKAGE__->password('test');

  1;

  # Second, create a base class for all models.
  package Blog::MoCo;
  use base qw 'DBIx::MoCo'; # Inherit DBIx::MoCo
  use Blog::DataBase;

  __PACKAGE__->db_object('Blog::DataBase');

  # If you want to use caching feature, you must explicitly set a
  # cache object via cache_object() method.

  use Cache::Memcached;
  my $cache = Cache::Memcached->new;
  $cache->set_servers([ ... ])
  __PACKAGE__->cache_object($cache); # Enables caching by memcached

  1;

  # Third, create your models.
  package Blog::User;
  use base qw 'Blog::MoCo';

  __PACKAGE__->table('user');
  __PACKAGE__->has_many(
      entries => 'Blog::Entry',
      { key => 'user_id' }
  );
  __PACKAGE__->has_many(
      bookmarks => 'Blog::Bookmark',
      { key => 'user_id' }
  );

  1;

  package Blog::Entry;
  use base qw 'Blog::MoCo';

  __PACKAGE__->table('entry');
  __PACKAGE__->has_a(
      user => 'Blog::User',
      { key => 'user_id' }
  );
  __PACKAGE__->has_many(
      bookmarks => 'Blog::Bookmark',
      { key => 'entry_id' }
  );

  1;

  package Blog::Bookmark;
  use base qw 'Blog::MoCo';

  __PACKAGE__->table('bookmark');
  __PACKAGE__->has_a(
      user => 'Blog::User',
      { key => 'user_id' }
  );
  __PACKAGE__->has_a(
      entry => 'Blog::Entry',
      { key => 'entry_id' }
  );

  1;

  # Now, You can use some methods same as Class::DBI.
  # And, all objects are stored in cache automatically.
  my $user = Blog::User->retrieve(user_id => 123);
  print $user->name;
  $user->name('jkontan'); # update db immediately
  print $user->name; # jkontan

  my $user2 = Blog::User->retrieve(user_id => 123);
  # $user is same as $user2

  # You can easily get has_many objects array.
  my $entries = $user->entries;
  my $entries2 = $user->entries;
  # $entries is same reference as $entries2
  my $entry = $entries->first; # isa Blog::Entry
  print $entry->title; # you can use methods in Entry class.

  Blog::Entry->create(
    user_id => 123,
    title => 'new entry!',
  );
  # $user->entries will be flushed automatically.
  my $entries3 = $user->entries;
  # $entries3 isnt $entries

  print ($entries->last eq $entries2->last); # 1
  print ($entries->last eq $entries3->last); # 1
  # same instance

  # You can delay update/create query to database using session.
  DBIx::MoCo->start_session;
  $user->name('jkondo'); # not saved now. changed in cache.
  print $user->name; # 'jkondo'
  $user->save; # update db
  print Blog::User->retrieve(123)->name; # 'jkondo'

  # Or, update queries will be thrown automatically after ending session.
  $user->name('jkontan');
  DBIx::MoCo->end_session;
  print Blog::User->retrieve(123)->name; # 'jkontan'

=head1 DESCRIPTION

Light & Fast Model Component

=head1 CLASS DEFINITION METHODS

Here are common methods related with class definitions.

=over 4

=item add_trigger

Adds triggers. Here are the types which called from DBIx::MoCo.

  before_create
  after_create
  before_update
  after_update
  before_delete

You can add your trigger like this.

  package Blog::User;
  __PACKAGE__->add_trigger(before_create => sub
    my ($class, $args) = @_;
    $args->{name} .= '-san';
  });

  # in your scripts
  my $u = Blog::User->create(name => 'ishizaki');
  is ($u->name, 'ishizaki-san'); # ok.

C<before_create> passes a hash reference of new object data as the
second argument, and all other triggers pass the instance C<$self>.

=item has_a

Defines has_a relationship between 2 models.

=item has_many

Defines has_many relationship between 2 models.
You can define additional conditions as below.

  Blog::User->has_many(
    root_messages => 'Blog::Message', {
      key => {name => 'to_name'},
      condition => 'reference_id is null',
      order => 'modified desc',
    },
  );

C<condition> is additional sql statement will be used in where
statement. C<order> is used for specifying order statement.

In above case, SQL statement will be

  SELECT message_id FROM message
  WHERE to_name = 'myname' AND reference_id is null
  ORDER BY modified desc

And, all each results will be inflated as Blog::Message by retrieving
all records again (with using cache).

=item retrieve_keys

Defines keys for retrieving by retrieve_all etc.

If there aren't any unique keys in your table, please specify these keys.

  package Blog::Bookmark;

  __PACKAGE__->retrieve_keys(['user_id', 'entry_id']);
  # When user can add multiple bookmarks onto same entry.

=item primary_keys

Returns primary keys. Usually it returns them automatically by
retrieving schema data from database.

But you can also redefine this parameter by overriding this method.
It's useful when MoCo cannot get schema data from your dsn.

  sub primary_keys {['user_id']}

=item unique_keys

Returns unique keys including primary keys. You can override this as same as C<primary_keys>.

  sub unique_keys {['user_id','name']}

=item schema

Returns DBIx::MoCo::Schema object reference related with your model
class.  You can set/get any parameters using Schema's C<param> method.
See L<DBIx::MoCo::Schema> for details.

=item columns

Returns array reference of column names.

=item has_column(col_name)

Returns which the table has the column or not.

=item utf8_columns

Receives array reference and defines utf8 columns.

When you call utf8 column method, you'll get string with utf8 flag on.
But you can get raw string when you call param('colname') method.

  __PACKAGE__->utf8_columns([qw(title body)]);

  my $e = Blog::Entry->retrieve(1);
  print Encode::is_utf8($e->title); # true
  print Encode::is_utf8($e->param('title')); # false
  print Encode::is_utf8($e->uri); # false

=item list_class

By default, retrieve_all(), search(), etc. return results as a
DBIx::MoCo::List object when in scalar context. If you want to add
some features into the list class, you can make a subclass of
DBIx::MoCo::List and tell your model class to use your own class
instead by specifying the class via list_class() method.

  # In Blog::Entry
  __PACKAGE__->list_class('Blog::Entry::List');

  # In Blog::Entry::List
  package Blog::Entry::List;
  use base qw/DBIx::MoCo::List/;

  sub to_rss {
      processing rss from entries ...
  }

  1;

  # The return value now has to_rss() method.
  my $entries = Blog::Entry->search( ... ); # is a Blog::Entry::List
  $entries->to_rss;

=back

=head1 CACHING FEATURE

=head2 Setup

If you want to use caching feature provided by DBIx::MoCo, you must
explicitly set the object via cache_object() method explained below,
which sets an object to be used when caching data from database. The
object can be, for example, a Cache::* modules such as Cache::Memory,
Cache::Memecached, etc.

  # In your Moco.pm
  package Blog::MoCo;
  use base qw 'DBIx::MoCo';

  ...

  use Cache::Memcached;
  my $cache = Cache::Memcached->new;
  $cache->set_servers([ ... ])

  __PACKAGE__->cache_object($cache); # Enables caching by memcached

=head2 Cache Algorithm

MoCo caches objects effectively.

There are 3 functions to control MoCo's cache. Their functions are
called appropriately when some operations are called to a particular
object.

Here are the 3 functions.

=over 4

=item store_self_cache

Stores self instance for all own possible object ids.

=item flush_self_cache

Flushes all caches for all own possible object ids.

=item flush_belongs_to

Flushes all caches whose have has_many arrays including the object.

=back

And, here are the triggers which call their functions.

=over 4

=item _after_create

Calls C<store_self_cache> and C<flush_belongs_to>.

=item _before_update

Calls C<flush_self_cache>.

=item _after_update

Calls C<store_self_cache>.

=item _before_delete

Calls C<flush_self_cache> and C<flush_belongs_to>.

=back

=head1 SESSION & CACHE METHODS

Here are common methods related with session.

=over 4

=item start_session

Starts session.

=item end_session

Ends session.

=item is_in_session

Returns DBIx::MoCo is in session or not.

=item cache_object

Sets an object to be used when caching data from database. For
example, the object can be a Cache::* modules such as Cache::Memory,
Cache::Memecached, etc.

=item cache_status

Returns cache status of the current session as a hash reference.
cache_status provides retrieve_count, retrieve_cache_count,
retrieved_oids retrieve_all_count, has_many_count,
has_many_cache_count,

=item flush

Delete attribute from given attr. name.

=item save

Saves changed columns in the current session.

=item icache_expiration

Specifies instance cache expiration time in seconds.  MoCo store
has_a, has_many instances in instance variable if this value is set.

  __PACKAGE__->icache_expiration(30);

It's not necessary to setup icache if you are runnnig MoCo with
DBIx::MoCo::Cache object because it is more powerful and as fast as
icache.

You'd better to consider this option when you are running MoCo with
centralized cache mechanism such as memcached.

=item cache_null_object

Specifies which MoCo will store null object when retrieve will fail.

=item object_id_prefix

This prefix is used for generating object ids and the ids are used as
cache keys. Default value of this prefix is the name of class.

This option is effective when you use some classes which have parent
-child relationships and they represent same table.

  package Blog::Entry;

  sub object_id_prefix { 'Blog::Entry' }

  1;

  package Blog::Entry::Video;
  use base qw(Blog::Entry);

  1;

MUID value is used for object_id when the class has muid field even if
this prefix is specified.

=back

=head1 DATA OPERATIONAL METHODS

Here are common methods related with operating data.

=over 4

=item retrieve

Retrieves an object and returns that using cache (if possible).

  my $u1 = Blog::User->retrieve(123); # retrieve by primary_key
  my $u2 = Blog::User->retrieve(user_id => 123); # same as above
  my $u3 = Blog::User->retrieve(name => 'jkondo'); # retrieve by name

=item restore_from_db

Restores self attributes from db.

=item retrieve_by_db

Retrieves an object from db.

=item retrieve_multi

Returns results of given array of conditions.

  my $users = Blog::User->retrieve_multi(
    {user_id => 123},
    {user_id => 234},
  );

=item retrieve_all

Returns results of given conditions as C<DBIx::MoCo::List> instance.

  my $users = Blog::User->retrieve_all(birthday => '2001-07-15');

=item retrieve_or_create

Retrieves a object or creates new record with given data and returns
that.

  my $user = Blog::User->retrieve_or_create(name => 'jkondo');

=item create

Creates new object and returns that.

  my $user = Blog::User->create(
    name => 'jkondo',
    birthday => '2001-07-15',
  );

=item delete

Deletes a object. You can call C<delete> as both of class and instance
method.

  $user->delete;
  Blog::User->delete($user);

=item delete_all

Deletes all records with given conditions. You should specify the
conditions as a hash reference.

  Blog::User->delete_all(where => {birthday => '2001-07-15'});

=item search

Returns results of given conditions as C<DBIx::MoCo::List> instance.
You can specify search conditions in 3 diferrent ways. "Hash reference
style", "Array reference style" and "Scalar style".

Hash reference style is same as SQL::Abstract style and like this.

  Blog::User->search(where => {name => 'jkondo'});

Array style is the most flexible. You can use placeholder.

  Blog::User->search(
    where => ['name = ?', 'jkondo'],
  );
  Blog::User->search(
    where => ['name in (?,?)', 'jkondo', 'cinnamon'],
  );
  Blog::Entry->search(
    where => ['name = :name and date like :date'],
             name => 'jkondo', date => '2007-04%'],
  );

Scalar style is the simplest one, and most flexible in other word.

  Blog::Entry->search(
    where => "name = 'jkondo' and DATE_ADD(date, INTERVAL 1 DAY) > NOW()',
  );

You can also specify C<field>, C<order>, C<offset>, C<limit>,
C<group>, C<with> too.  Full spec search statement will be like the
following.

  Blog::Entry->search(
    field => 'entry_id',
    where => ['name = ?', 'jkondo'],
    order => 'created desc',
    offset => 0,
    limit => 1,
    group => 'title',
    with  => [qw(user)], # for prefetching users related to each entry
  );

Search results will not be cached because MoCo expects that the
conditions for C<search> will be complicated and should not be cached.
You should use C<retrieve> or C<retrieve_all> method instead of
C<search> if you'll use simple conditions.

See L<Prefetching> section below for details of C<with> option in
C<search()> method.

=item count

Returns the count of results matched with given conditions. You can
specify the conditions in same way as C<search>'s where spec.

  Blog::User->count({name => 'jkondo'}); # Hash reference style
  Blog::User->count(['name => ?', 'jkondo']); # Array reference style
  Blog::User->count("name => 'jkondo'"); # Scalar style

=item find

Similar to search, but returns only the first item as a reference (not
as an array).

=item retrieve_by_column(_and_column2)

Auto generated method which returns an object by using key defined is
method and given value.

  my $user = Blog::User->retrieve_by_name('jkondo');

=item retrieve_by_column(_and_column2)_or_create

Similar to retrieve_or_create.

  my $user = Blog::User->retrieve_by_name_or_create('jkondo');

=item retrieve_by_column_or_column2

Returns an object matched with given column names.

  my $user = Blog::User->retrieve_by_user_id_or_name('jkondo');

=item param

Set or get attribute from given attr. name.

=item set

Set attribute which is not related with DB schema or set temporary.

=item column_as_something

Inflate column value by using DBIx::MoCo::Column::* plugins.
If you set up your plugin like this,

  package DBIx::MoCo::Column::URI;

  sub URI {
    my $self = shift;
    return URI->new($$self);
  }

  sub URI_as_string {
    my $class = shift;
    my $uri = shift or return;
    return $uri->as_string;
  }

  1;

Then, you can use column_as_URI method as following,

  my $e = MyEntry->retrieve(..);
  print $e->uri; # 'http://test.com/test'
  print $e->uri_as_URI->host; # 'test.com';

  my $uri = URI->new('http://www.test.com/test');
  $e->uri_as_URI($uri); # set uri by using URI instance

The name of infrate method which will be imported must be same as the
package name.

If you don't define "as string" method (such as C<URI_as_string>),
scalar evaluated value of given argument will be used for new value
instead.

=item has_a, has_many auto generated methods

If you define has_a, has_many relationships,

  package Blog::Entry;
  use base qw 'Blog::MoCo';

  __PACKAGE__->table('entry');
  __PACKAGE__->has_a(
      user => 'Blog::User',
      { key => 'user_id' }
  );
  __PACKAGE__->has_many(
      bookmarks => 'Blog::Bookmark',
      { key => 'entry_id' }
  );

You can use those keys as methods.

  my $e = Blog::Entry->retrieve(..);
  print $e->user; # isa Blog::User
  print $e->bookmarks; # isa ARRAY of Blog::Bookmark

=item quote

Quotes given string using DBI's quote method.

=back

=head1 HINTS FOR PERFORMANCE

=head2 Prefetching

By default, DBIx::MoCo can issue too many queries in such case as
below:

  my $user = Blog::User->retrieve(name => $name);
  for my $entry ( $user->entries ) {
      ## Entry has a user
      $entry->user->name;
  }

The code above executes more than twice as many queries as the count
C<$user->entries->size> method returns, which can cause problems on
performance when the count is large. DBIx::MoCo provides prefetching
feature to solve the problem.

You can specify the target to be prefetched by I<with> option in model
class definitions as below:

  package Blog::User;
  use base qw 'Blog::MoCo';

  __PACKAGE__->table('user');
  __PACKAGE__->has_many(
      entries => 'Blog::Entry',
      {
          key  => 'user_id',
          with => [qw(user)],  # Added
      }
  );
  1;

  package Blog::Entry;
  use base qw 'Blog::MoCo';

  __PACKAGE__->table('entry');
  __PACKAGE__->has_a(
      user => 'Blog::User',
      { key => 'user_id' }
  );
  1;

As a result, C<$user->entry> prefetches users of all entries, and
you'll see the performance is drastically improved.

  my $user = Blog::User->retrieve(name => $name);
  for my $entry ( $user->entries ) {              # Does prefetching
      ## Entry has a user
      $entry->user->name;
  }

In case that you temporally don't want the method to prefetch, you can
inhibit prefetching as below:

  $user->entries({ without => 'user' });

C<with> option described above can appear not only in has_many()
method, but also in search() method.

  my $entries = Blog::Entry->search(
      ...
      with => [qw(user)],
  );

  for my $entry ( @$entries ) {
      $entry->user->name;       # $entry->user is already prefetched
  }

=head1 FORM VALIDATION

You can validate user parameters using moco's schema. For example you
can define your validation profile using param like this,

  package Blog::User;

  __PACKAGE__->schema->param([
    name => ['NOT_BLANK', 'ASCII', ['DBIC_UNIQUE', 'Blog::User', 'name']],
    mail => ['NOT_BLANK', 'EMAIL_LOOSE'],
  ]);

And then,

  # In your scripts
  sub validate {
    my $self = shift;
    my $q = $self->query;
    my $prof = Blog::User->schema->param('validation');
    my $result = FormValidator::Simple->check($q => $prof);
    # handle errors ...
  }

=head1 SEE ALSO

L<DBIx::MoCo::DataBase>, L<SQL::Abstract>, L<Class::DBI>, L<Cache>,

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.comE<gt>,
Naoya Ito, E<lt>naoya@hatena.ne.jpE<gt>,
Kentaro Kuribayashi, E<lt>kentarok@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
