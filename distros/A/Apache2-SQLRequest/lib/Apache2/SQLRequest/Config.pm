package Apache2::SQLRequest::Config;

use warnings FATAL => 'all';
use strict;

use Apache2::Module      ();
use Apache2::CmdParms    ();

use Apache2::Const -compile => 
    qw(TAKE1 TAKE2 TAKE3 ITERATE RSRC_CONF ACCESS_CONF OR_ALL);

my @directives;

push @directives => {
    name            => 'DSN',
    func            => __PACKAGE__ . '::_set_scalar',
    args_how        => Apache2::Const::TAKE1,
    req_override    => Apache2::Const::OR_ALL,
    errmsg          => 'dbi:dsn:string',
    cmd_data        => 'dsn',
};

push @directives => {
    name            => 'DBUser',
    func            => __PACKAGE__ . '::_set_scalar',
    args_how        => Apache2::Const::TAKE1,
    req_override    => Apache2::Const::OR_ALL,
    errmsg          => 'user',
    cmd_data        => 'user',
};

push @directives => {
    name            => 'DBPassword',
    func            => __PACKAGE__ . '::_set_scalar',
    args_how        => Apache2::Const::TAKE1,
    req_override    => Apache2::Const::OR_ALL,
    errmsg          => 'password',
    cmd_data        => 'password',
};

sub _set_sql_query {
    my ($self, $parms, $qname, $query) = @_;
    $self->{queries}         ||= {};
    $self->{queries}{$qname} ||= {};
    $self->{queries}{$qname}{string} = $query;
}

push @directives => {
    name            => 'SQLQuery',
    func            => __PACKAGE__ . '::_set_sql_query',
    args_how        => Apache2::Const::TAKE2,
    req_override    => Apache2::Const::OR_ALL,
    errmsg          => 'queryname query',
};

sub _add_bind_param {
    my ($self, $parms, $qname, $key, $val) = @_;
    #unless ($parms->path) {
    #    my $srv_cfg = Apache2::Module::get_config($self, $parms->server);
    #    my $query = $srv_cfg->{queries}{$qname};
    #    die "bind parameter defined for nonexistent query $qname." 
    #        unless defined $query;
    #    $query->{params} ||= {};
    #    $query->{params}{$key} = $val;
    #}
    my $query = $self->{queries}{$qname};
    die "bind parameter defined for nonexistent query $qname." 
        unless defined $query;
    $query->{params} ||= {};
    $query->{params}{$key} = $val;
}

push @directives => {
    name            => 'BindParam',
    func            => __PACKAGE__ . '::_add_bind_param',
    args_how        => Apache2::Const::TAKE3,
    req_override    => Apache2::Const::OR_ALL,
    errmsg          => 'queryname key value',
};

Apache2::Module::add(__PACKAGE__, \@directives) if Apache2::Module->can('add');

sub _set_scalar {
    my ($self, $parms, $arg) = @_;
    my $key = $parms->info;
    die "cmd_data must exist" unless defined $key;
    $self->{$key} = $arg;
    # this i don't get, shouldn't it be if, not unless? whatever.
    #unless ($parms->path) {
    #    my $srv_cfg = Apache2::Module::get_config($self, $parms->server);
    #    $srv_cfg->{$key} = $arg;
    #}
}

# XXX: YO: this is a cop-out.
sub _deep_hashref_merge {
    my ($base, $add) = @_;
    if (defined $add) {
        # the only condition we'd ever merge instead of supplant the new value
        if (defined $base and 
            UNIVERSAL::isa($base, 'HASH') and UNIVERSAL::isa($add, 'HASH')) {
            my %mrg = ();
            for my $k (keys %$add, keys %$base) {
                next if exists $mrg{$k};
                $mrg{$k} = _deep_hashref_merge($base->{$k}, $add->{$k});
            }
            return bless \%mrg, ref $add;
        }
        else {
            return $add;
            #return ref $add ? Clone::clone($add) : $add;
        }
    }
    else {
        #return ref $base ? Clone::clone($base) : $base;
        return $base;
    }
}

sub merge {
    my ($base, $add) = @_;
    #warn sprintf("%x", ModPerl::Util::current_perl_id());
    my %mrg = ();
    for my $key (keys %$base, keys %$add) {
        next if exists $mrg{$key};
        # XXX: replace this with a dispatch table
        if ($key eq 'queries') {
            $mrg{queries} ||= {};
            for my $query (keys %{$add->{queries}}, keys %{$base->{queries}}) {
                $mrg{queries}{$query} = $base->{queries}{$query} 
                    if exists $base->{queries}{$query};
                $mrg{queries}{$query} = $add->{queries}{$query}  
                    if exists $add->{queries}{$query};
            }
        }
        else {
            $mrg{$key} = $base->{$key} if exists $base->{$key};
            $mrg{$key} = $add->{$key}  if exists $add->{$key};
        }
    }
    return bless \%mrg, ref $base;
}

sub SERVER_MERGE    { merge(@_) }
sub DIR_MERGE       { merge(@_) }

1;
