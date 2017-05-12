package DBIx::Class::UUIDColumns;
use strict;
use warnings;
use vars qw($VERSION);

BEGIN {
    use base qw/DBIx::Class Class::Accessor::Grouped/;

    __PACKAGE__->mk_group_accessors('inherited', qw/uuid_auto_columns uuid_maker/);
};
__PACKAGE__->uuid_class(__PACKAGE__->_find_uuid_module);

# Always remember to do all digits for the version even if they're 0
# i.e. first release of 0.XX *must* be 0.XX000. This avoids fBSD ports
# brain damage and presumably various other packaging systems too

$VERSION = '0.02006';

sub uuid_columns {
    my $self = shift;

    if (scalar @_) {
        for (@_) {
            $self->throw_exception("column $_ doesn't exist") unless $self->has_column($_);
        }
        $self->uuid_auto_columns(\@_);
    };

    return $self->uuid_auto_columns || [];
}

sub uuid_class {
    my ($self, $class) = @_;

    if ($class) {
        $class = "DBIx::Class::UUIDColumns::UUIDMaker$class" if $class =~ /^::/;

        if (!eval "require $class") {
            $self->throw_exception("$class could not be loaded: $@");
        } elsif (!$class->isa('DBIx::Class::UUIDColumns::UUIDMaker')) {
            $self->throw_exception("$class is not a UUIDMaker subclass");
        } else {
            $self->uuid_maker($class->new);
        };
    };

    return ref $self->uuid_maker;
};

sub insert {
    my $self = shift;
    for my $column (@{$self->uuid_columns}) {
        $self->store_column( $column, $self->get_uuid )
            unless defined $self->get_column( $column );
    }
    $self->next::method(@_);
}

sub get_uuid {
    return shift->uuid_maker->as_string;
}

sub _find_uuid_module {
    if (eval{require Data::UUID}) {
        return '::Data::UUID';
    } elsif (eval{require Data::GUID}) {
        return '::Data::GUID';
    } elsif ($^O ne 'openbsd' && eval{require APR::UUID}) {
        # APR::UUID on openbsd causes some as yet unfound nastiness for XS
        return '::APR::UUID';
    } elsif (eval{require UUID}) {
        return '::UUID';
    } elsif (eval{
            # squelch the 'too late for INIT' warning in Win32::API::Type
            local $^W = 0;
            require Win32::Guidgen;
        }) {
        return '::Win32::Guidgen';
    } elsif (eval{require Win32API::GUID}) {
        return '::Win32API::GUID';
    } elsif (eval{require UUID::Random}) {
        return '::UUID::Random';
    } else {
        die 'no suitable uuid module could be found for use with DBIx::Class::UUIDColumns';
    };
};

1;
__END__

=head1 NAME

DBIx::Class::UUIDColumns - Implicit uuid columns

=head1 SYNOPSIS

In your L<DBIx::Class> table class:

  __PACKAGE__->load_components(qw/UUIDColumns ... Core/);
  __PACKAGE__->uuid_columns('artist_id');

B<Note:> The component needs to be loaded I<before> Core.

=head1 DESCRIPTION

This L<DBIx::Class> component resembles the behaviour of L<Class::DBI::UUID>,
to make some columns implicitly created as uuid.

When loaded, C<UUIDColumns> will search for a suitable uuid generation module
from the following list of supported modules:

  Data::UUID
  APR::UUID*
  UUID
  Win32::Guidgen
  Win32API::GUID

If no supporting module can be found, an exception will be thrown.

*APR::UUID will not be loaded under OpenBSD due to an as yet unidentified XS
issue.

If you would like to use a specific module, you can set L</uuid_class>:

  __PACKAGE__->uuid_class('::Data::UUID');
  __PACKAGE__->uuid_class('MyUUIDGenerator');

=head1 METHODS

=head2 get_uuid

Returns a uuid string from the current uuid_maker.

=head2 insert

Inserts a new uuid string into each column in L</uuid_columns>.

=head2 uuid_columns

Gets/sets the list of columns to be filled with uuids during insert.

  __PACKAGE__->uuid_columns('artist_id');

=head2 uuid_class

Takes the name of a UUIDMaker subclass to be used for uuid value generation.
This can be a fully qualified class name, or a shortcut name starting with ::
that matches one of the available L<DBIx::Class::UUIDColumns::UUIDMaker> subclasses:

  __PACKAGE__->uuid_class('CustomUUIDGenerator');
  # loads CustomeUUIDGenerator

  __PACKAGE__->uuid_class('::Data::UUID');
  # loads DBIx::Class::UUIDMaker::Data::UUID;

Note that C<uuid_class> checks to see that the specified class isa
L<DBIx::Class::UUIDColumns::UUIDMaker> subclass and throws and exception if it isn't.

=head2 uuid_maker

Returns the current UUIDMaker instance for the given module.

  my $uuid = __PACKAGE__->uuid_maker->as_string;

=head1 SEE ALSO

L<DBIx::Class::UUIDColumns::UUIDMaker>

=head1 AUTHOR

Chia-liang Kao <clkao@clkao.org>

=head1 CONTRIBUTERS

Chris Laco <claco@chrislaco.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.
