package API::MailboxOrg::Types;

# ABSTRACT: Types related to Mailbox.org API

use v5.24;

use strict;
use warnings;

use Type::Library
   -base,
   -declare => qw( HashRefRestricted Boolean );

use Type::Utils -all;
use Types::Standard -types;

use Carp;
use JSON::PP;
use Scalar::Util qw(blessed);

our $VERSION = '1.0.2'; # VERSION

my $meta = __PACKAGE__->meta;

$meta->add_type(
    name => 'HashRefRestricted',
    parent => HashRef,
    constraint_generator => sub {
        return $meta->get_type('HashRefRestricted') if !@_;

        my @keys = @_;

        croak "Need a list of valid keys" if !@keys;

        my %valid_keys = map { $_ => 1 } @keys;

        return sub {
            return if ref $_ ne 'HASH';
            return 1 if !$_->%*;

            for my $key ( keys $_->%* ) {
                return if !$valid_keys{$key};
            }

            return 1;
        };
    },
    coercion_generator => sub {
        my ($parent, $child, $param) = @_;
        return $parent->coercion;
    },
    #inline_generator => sub {},
    #deep_explanation => sub {},
);

$meta->add_type(
    name => 'Boolean',
    parent => InstanceOf['JSON::PP::Boolean'],
    constraint_generator => sub {
        return $meta->get_type('Boolean') if !@_;

        return sub {
            return if ! ( blessed $_ and $_->isa('JSON::PP::Boolean') );
            return 1;
        };
    },
    coercion_generator => sub {
        my ($parent, $child, $param) = @_;
        return $parent->coercion;
    },
);

coerce Boolean,
    from Bool,
        via {
            my $new = $_ ? $JSON::PP::true : $JSON::PP::false;
            $new;
        }
;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

API::MailboxOrg::Types - Types related to Mailbox.org API

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

    {
        package  # private package - do not index
            TestClass;

        use Moo;
        use API::MailboxOrg::Types qw(Boolean HashRefRestricted);

        has true_or_false => ( is => 'ro', isa => Boolean, coerce => 1 );
        has map           => ( is => 'ro', isa => HashRefRestricted[qw(a b)] ); # allow only keys a and b

        1;
    }

    my $obj = TestClass->new(
        true_or_false => 1,  # 0|1|""|undef|JSON::PP::Boolean object
        map  => {
            a => 1,
            b => 1,
            # a key 'c' would cause a 'die'
        },
    );

=head1 TYPES

=head2 HashRefRestricted[`a]

This expects a hash reference. You can restrict the allowed keys

=head2 Boolean

A JSON::PP::Boolean object.

=head1 COERCIONS

These coercions are defined.

=head2 To Boolean

=over 4

=item * String/Integer to boolean

The values "" (empty string), I<undef>, 0, and 1 are coerced to C<JSON::PP::Boolean> objects.

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
