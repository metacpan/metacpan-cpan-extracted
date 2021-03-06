package DBIx::Class::Helper::Row::Enumeration;

# ABSTRACT: Add methods for emum values

use v5.10.1;

use strict;
use warnings;

use Ref::Util  ();
use Sub::Quote ();

# RECOMMEND PREREQ: Ref::Util::XS

our $VERSION = 'v0.1.8';

# The names of all methods installed by this module.
my %MINE;



sub add_columns {
    my ( $self, @cols ) = @_;

    $self->next::method(@cols);

    my $class = Ref::Util::is_ref($self) || $self;

    foreach my $col (@cols) {

        next if ref $col;

        $col =~ s/^\+//;
        my $info = $self->column_info($col);

        next unless $info->{data_type} eq 'enum';

        next unless exists $info->{extra}{list};

        my $handlers = $info->{extra}{handles} //= sub { "is_" . $_[0] };

        next unless $handlers;

        if ( Ref::Util::is_plain_coderef($handlers) ) {
            $info->{extra}{handles} = {
                map {

                    if ( my $method = $handlers->( $_, $col, $class ) ) {
                        ( $method => $_ )
                    }
                    else {
                        ()
                    }

                } @{ $info->{extra}{list} }
            };
            $handlers = $info->{extra}{handles};
        }

        DBIx::Class::Exception->throw("handles is not a hashref")
          unless Ref::Util::is_plain_hashref($handlers);

        foreach my $handler ( keys %$handlers ) {
            next unless $handler;
            my $value = $handlers->{$handler} or next;

            my $method = "${class}::${handler}";

            # Keep track of what we've installed, and don't complain about
            # being asked to reinstall it. This is needed when using
            # DBIx::Class::Schema::Loader. In theory we should check whether
            # the current method is the one we installed, and throw anyway if
            # it isn't, but this seems adequate.
            DBIx::Class::Exception->throw("${method} is already defined")
              if $self->can($method) && !$MINE{$method};

            my $code =
              $info->{is_nullable}
              ? qq{ my \$val = \$_[0]->get_column("${col}"); }
              . qq{ defined(\$val) && \$val eq "${value}" }
              : qq{ \$_[0]->get_column("${col}") eq "${value}" };

            $MINE{$method} = 1;
            Sub::Quote::quote_sub $method, $code;

        }

    }

    return $self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Helper::Row::Enumeration - Add methods for emum values

=head1 VERSION

version v0.1.8

=head1 SYNOPSIS

In your result class:

  use base qw/DBIx::Class::Core/;

  __PACKAGE__->load_components(qw/ Helper::Row::Enumeration /);

  __PACKAGE__->add_column(

    foo => {
        data_type => 'enum',
        extra     => {
            list => [qw/ good bad ugly /],
        },
    },

with a row:

  if ($row->is_good) { ... }

=head1 DESCRIPTION

This plugin is inspired by L<MooseX::Enumeration>.

Suppose your database has a column with an enum value. Checks against
string values are prone to typos:

  if ($row->result eq 'faol') { ... }

when instead you wanted

  if ($row->result eq 'fail') { ... }

Using this plugin, you can avoid common bugs by checking against a
method instead:

  if ($row->is_fail) { ... }

=head1 Overriding method names

You can override method names by adding an extra C<handles> attribute
to the column definition:

    bar => {
        data_type => 'enum',
        extra     => {
            list   => [qw/ good bad ugly /],
            handles => {
                good_bar => 'good',
                coyote   => 'ugly',
            },
        },
    },

Note that only methods you specify will be added. In the above case,
there is no "is_bad" method added.

The C<handles> attribute can also be set to a code reference so that
method names can be generated dynamically:

    baz => {
        data_type => 'enum',
        extra     => {
            list   => [qw/ good bad ugly /],
            handles => sub {
                my ($value, $col, $class) = @_;

                return undef if $value eq 'deprecated';

                return "is_${col}_${value}";
            },
        },
    },
);

If the function returns C<undef>, then no method will be generated for
that value.

If C<handles> is set to "0", then no methods will be generated for the
column at all.

=for Pod::Coverage add_columns

=head1 KNOWN ISSUES

See also L</BUGS> below.

=head2 Overlapping enum values

Multiple columns with overlapping enum values will cause an error.
You'll need to specify a handler to rename methods or skip them
altogether.

=head2 Autogenerated Classes

You can use column modifiers to update autogenerated classes created
by the likes of L<DBIx::Class::Schema::Loader>.  However, the C<extra>
attributes are not deep-merged, so you will have to repeat them when
if you want to specify custom handlers, e.g.

  # Created by DBIx::Class::Schema::Loader etc.
  # DO NOT MODIFY THIS OR ANYTHING ABOVE! etc.

  __PACKAGE__->load_components(qw/ Helper::Row::Enumeration /);

  __PACKAGE__->add_columns(

    '+foo', # using default handlers

    '+baz' => {
        extra   => {
            list    => [qw/ good bad ugly /],
            handles => { ... },
        },
    },

  );

Note that this is by design, since the intention of column modifiers is
to override existing values.

=head1 SEE ALSO

L<DBIx::Class>

L<MooseX::Enumeration>

The module L<DBIx::Class::Helper::ResultSet::EnumMethods> adds
similar methods to resultsets.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/DBIx-Class-Helper-Row-Enumeration>
and may be cloned from L<git://github.com/robrwo/DBIx-Class-Helper-Row-Enumeration.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/DBIx-Class-Helper-Row-Enumeration/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 CONTRIBUTOR

=for stopwords Aaron Crane

Aaron Crane <arc@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
