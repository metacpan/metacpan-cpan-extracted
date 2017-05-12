package Catalyst::Authentication::Store::DBIx::Class::User;

use Moose;
use namespace::autoclean;
extends 'Catalyst::Authentication::User';

use List::MoreUtils 'all';
use Try::Tiny;

has 'config'    => (is => 'rw');
has 'resultset' => (is => 'rw');
has '_user'     => (is => 'rw');
has '_roles'    => (is => 'rw');

sub new {
    my ( $class, $config, $c) = @_;

	$config->{user_model} = $config->{user_class}
        unless defined $config->{user_model};

    my $self = {
        resultset => $c->model($config->{'user_model'}),
        config => $config,
        _roles => undef,
        _user => undef
    };

    bless $self, $class;

    Catalyst::Exception->throw(
        "\$c->model('${ \$self->config->{user_model} }') did not return a resultset."
          . " Did you set user_model correctly?"
    ) unless $self->{resultset};

    $self->config->{'id_field'} = [$self->{'resultset'}->result_source->primary_columns]
        unless exists $self->config->{'id_field'};

    $self->config->{'id_field'} = [$self->config->{'id_field'}]
        unless ref $self->config->{'id_field'} eq 'ARRAY';

    Catalyst::Exception->throw(
        "id_field set to "
          . join(q{,} => @{ $self->config->{'id_field'} })
          . " but user table has no column by that name!"
    ) unless all { $self->{'resultset'}->result_source->has_column($_) } @{ $self->config->{'id_field'} };

    ## if we have lazyloading turned on - we should not query the DB unless something gets read.
    ## that's the idea anyway - still have to work out how to manage that - so for now we always force
    ## lazyload to off.
    $self->config->{lazyload} = 0;

#    if (!$self->config->{lazyload}) {
#        return $self->load_user($authinfo, $c);
#    } else {
#        ## what do we do with a lazyload?
#        ## presumably this is coming out of session storage.
#        ## use $authinfo to fill in the user in that case?
#    }

    return $self;
}


sub load {
    my ($self, $authinfo, $c) = @_;

    my $dbix_class_config = 0;

    if (exists($authinfo->{'dbix_class'})) {
        $authinfo = $authinfo->{'dbix_class'};
        $dbix_class_config = 1;
    }

    ## User can provide an arrayref containing the arguments to search on the user class.
    ## or even provide a prepared resultset, allowing maximum flexibility for user retrieval.
    ## these options are only available when using the dbix_class authinfo hash.
    if ($dbix_class_config && exists($authinfo->{'result'})) {
	$self->_user($authinfo->{'result'});
    } elsif ($dbix_class_config && exists($authinfo->{'resultset'})) {
        $self->_user($authinfo->{'resultset'}->first);
    } elsif ($dbix_class_config && exists($authinfo->{'searchargs'})) {
        $self->_user($self->resultset->search(@{$authinfo->{'searchargs'}})->first);
    } else {
        ## merge the ignore fields array into a hash - so we can do an easy check while building the query
        my %ignorefields = map { $_ => 1} @{$self->config->{'ignore_fields_in_find'}};
        my $searchargs = {};

        # now we walk all the fields passed in, and build up a search hash.
        foreach my $key (grep {!$ignorefields{$_}} keys %{$authinfo}) {
            if ($self->resultset->result_source->has_column($key)) {
                $searchargs->{$key} = $authinfo->{$key};
            }
        }
        if (keys %{$searchargs}) {
            $self->_user($self->resultset->search($searchargs)->first);
        } else {
            Catalyst::Exception->throw(
                "Failed to load user data.  You passed [" . join(',', keys %{$authinfo}) . "]"
                  . " to authenticate() but your user source (" .  $self->config->{'user_model'} . ")"
                  . " only has these columns: [" . join( ",", $self->resultset->result_source->columns ) . "]"
                  . "   Check your authenticate() call."
            );
        }
    }

    if ($self->get_object) {
        return $self;
    } else {
        return undef;
    }

}

sub supported_features {
    my $self = shift;

    return {
        session         => 1,
        roles           => 1,
    };
}


sub roles {
    my ( $self ) = shift;
    ## this used to load @wantedroles - but that doesn't seem to be used by the roles plugin, so I dropped it.

    ## shortcut if we have already retrieved them
    if (ref $self->_roles eq 'ARRAY') {
        return(@{$self->_roles});
    }

    my @roles = ();
    if (exists($self->config->{'role_column'})) {
        my $role_data = $self->get($self->config->{'role_column'});
        if ($role_data) {
            @roles = split /[\s,\|]+/, $self->get($self->config->{'role_column'});
        }
        $self->_roles(\@roles);
    } elsif (exists($self->config->{'role_relation'})) {
        my $relation = $self->config->{'role_relation'};
        if ($self->_user->$relation->result_source->has_column($self->config->{'role_field'})) {
            @roles = map {
                $_->get_column($self->config->{role_field})
            } $self->_user->$relation->search(undef, {
                columns => [ $self->config->{role_field} ]
            })->all;
            $self->_roles(\@roles);
        } else {
            Catalyst::Exception->throw("role table does not have a column called " . $self->config->{'role_field'});
        }
    } else {
        Catalyst::Exception->throw("user->roles accessed, but no role configuration found");
    }

    return @{$self->_roles};
}

sub for_session {
    my $self = shift;

    #return $self->get($self->config->{'id_field'});

    #my $frozenuser = $self->_user->result_source->schema->freeze( $self->_user );
    #return $frozenuser;

    my %userdata = $self->_user->get_columns();

    # If use_userdata_from_session is set, then store all of the columns of the user obj in the session
    if (exists($self->config->{'use_userdata_from_session'}) && $self->config->{'use_userdata_from_session'} != 0) {
        return \%userdata;
    } else { # Otherwise, we just need the PKs for load() to use.
        my %pk_fields = map { ($_ => $userdata{$_}) } @{ $self->config->{id_field} };
        return \%pk_fields;
    }
}

sub from_session {
    my ($self, $frozenuser, $c) = @_;

    #my $obj = $self->resultset->result_source->schema->thaw( $frozenuser );
    #$self->_user($obj);

    #if (!exists($self->config->{'use_userdata_from_session'}) || $self->config->{'use_userdata_from_session'} == 0) {
#        $self->_user->discard_changes();
#    }
#
#    return $self;
#
## if use_userdata_from_session is defined in the config, we fill in the user data from the session.
    if (exists($self->config->{'use_userdata_from_session'}) && $self->config->{'use_userdata_from_session'} != 0) {

        # We need to use inflate_result here since we -are- inflating a
        # result object from cached data, not creating a fresh one.
        # Components such as EncodedColumn wrap new() to ensure that a
        # provided password is hashed on the way in, and re-running the
        # hash function on data being restored is expensive and incorrect.

        my $class = $self->resultset->result_class;
        my $source = $self->resultset->result_source;
        my $obj = $class->inflate_result($source, { %$frozenuser });

        $obj->in_storage(1);
        $self->_user($obj);
        return $self;
    }

    if (ref $frozenuser eq 'HASH') {
        return $self->load({
            map { ($_ => $frozenuser->{$_}) }
            @{ $self->config->{id_field} }
        }, $c);
    }

    return $self->load( { $self->config->{'id_field'} => $frozenuser }, $c);
}

sub get {
    my ($self, $field) = @_;

    if (my $code = $self->_user->can($field)) {
        return $self->_user->$code;
    }
    elsif (my $accessor =
         try { $self->_user->result_source->column_info($field)->{accessor} }) {
        return $self->_user->$accessor;
    } else {
        # XXX this should probably throw
        return undef;
    }
}

sub get_object {
    my ($self, $force) = @_;

    if ($force) {
        $self->_user->discard_changes;
    }

    return $self->_user;
}

sub obj {
    my ($self, $force) = @_;

    return $self->get_object($force);
}

sub auto_create {
    my $self = shift;
    $self->_user( $self->resultset->auto_create( @_ ) );
    return $self;
}

sub auto_update {
    my $self = shift;
    $self->_user->auto_update( @_ );
}

sub can {
    my $self = shift;
    return $self->SUPER::can(@_) || do {
        my ($method) = @_;
        if (not ref $self) {
            undef;
        } elsif (not $self->_user) {
            undef;
        } elsif (my $code = $self->_user->can($method)) {
            sub { shift->_user->$code(@_) }
        } elsif (my $accessor =
            try { $self->_user->result_source->column_info($method)->{accessor} }) {
            sub { shift->_user->$accessor }
        } else {
            undef;
        }
    };
}

sub AUTOLOAD {
    my $self = shift;
    (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $method eq "DESTROY";

    return unless ref $self;

    if (my $code = $self->_user->can($method)) {
        return $self->_user->$code(@_);
    }
    elsif (my $accessor =
         try { $self->_user->result_source->column_info($method)->{accessor} }) {
        return $self->_user->$accessor(@_);
    } else {
        # XXX this should also throw
        return undef;
    }
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
__END__

=head1 NAME

Catalyst::Authentication::Store::DBIx::Class::User - The backing user
class for the Catalyst::Authentication::Store::DBIx::Class storage
module.

=head1 VERSION

This documentation refers to version 0.1506.

=head1 SYNOPSIS

Internal - not used directly, please see
L<Catalyst::Authentication::Store::DBIx::Class> for details on how to
use this module. If you need more information than is present there, read the
source.



=head1 DESCRIPTION

The Catalyst::Authentication::Store::DBIx::Class::User class implements user storage
connected to an underlying DBIx::Class schema object.

=head1 SUBROUTINES / METHODS

=head2 new

Constructor.

=head2 load ( $authinfo, $c )

Retrieves a user from storage using the information provided in $authinfo.

=head2 supported_features

Indicates the features supported by this class.  These are currently Roles and Session.

=head2 roles

Returns an array of roles associated with this user, if roles are configured for this user class.

=head2 for_session

Returns a serialized user for storage in the session.

=head2 from_session

Revives a serialized user from storage in the session.

=head2 get ( $fieldname )

Returns the value of $fieldname for the user in question.  Roughly translates to a call to
the DBIx::Class::Row's get_column( $fieldname ) routine.

=head2 get_object

Retrieves the DBIx::Class object that corresponds to this user

=head2 obj (method)

Synonym for get_object

=head2 auto_create

This is called when the auto_create_user option is turned on in
Catalyst::Plugin::Authentication and a user matching the authinfo provided is not found.
By default, this will call the C<auto_create()> method of the resultset associated
with this object. It is up to you to implement that method.

=head2 auto_update

This is called when the auto_update_user option is turned on in
Catalyst::Plugin::Authentication. Note that by default the DBIx::Class store
uses every field in the authinfo hash to match the user. This means any
information you provide with the intent to update must be ignored during the
user search process. Otherwise the information will most likely cause the user
record to not be found. To ignore fields in the search process, you
have to add the fields you wish to update to the 'ignore_fields_in_find'
authinfo element.  Alternately, you can use one of the advanced row retrieval
methods (searchargs or resultset).

By default, auto_update will call the C<auto_update()> method of the
DBIx::Class::Row object associated with the user. It is up to you to implement
that method (probably in your schema file)

=head2 AUTOLOAD

Delegates method calls to the underlying user row.

=head2 can

Delegates handling of the C<< can >> method to the underlying user row.

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Jason Kuri (jayk@cpan.org)

=head1 CONTRIBUTORS

Matt S Trout (mst) <mst@shadowcat.co.uk>

(fixes wrt can/AUTOLOAD sponsored by L<http://reask.com/>)

=head1 LICENSE

Copyright (c) 2007-2010 the aforementioned authors. All rights
reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
