package Data::TreeValidator::Sugar;
{
  $Data::TreeValidator::Sugar::VERSION = '0.04';
}
# ABSTRACT: Syntatic sugar for easily creating tree validators
use strict;
use warnings;

use aliased 'Data::TreeValidator::Branch';
use aliased 'Data::TreeValidator::Leaf';
use aliased 'Data::TreeValidator::RepeatingBranch';

use Data::TreeValidator::Constraints 'type';

use Sub::Exporter -setup => {
    exports => [ qw( branch leaf repeating ) ],
};

use MooseX::Params::Validate;
use MooseX::Types::Moose qw( CodeRef );

sub _branch {
    my ($class, $code) = @_;
    my %children = $code->();
    return $class->new( children => \%children );
}

sub branch (&;) {
    my ($code) = pos_validated_list(\@_,
        { isa => CodeRef }
    );
    return _branch(Branch, $code);
}

sub leaf {
    my @args = @_ == 1 ? (constraints => [ type($_[0]) ] )
                       : @_;
    return Leaf->new(@args);
}

sub repeating (&;) {
    my ($code) = pos_validated_list(\@_,
        { isa => CodeRef }
    );
    return _branch(RepeatingBranch, $code);
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Sugar - Syntatic sugar for easily creating tree validators

=head1 DESCRIPTION

This module exports a few helper functions which allow you to build up a
validation tree in a declarative manner.

All methods below are available for import into calling modules.

=head1 METHODS

=head2 branch { children... }

Create a L<Data::TreeValidator::Branch> object, with children. Children are
specified in a code ref, that should return a hash (not a reference) of all
children as <name, node> pairs.

=head2 leaf

Constructs a L<Data::TreeValidator::Leaf> object. All parameters passed are
passed through to the Leaf constructor.

=head2 repeating { children... }

Just like L<Data::TreeValidator::Sugar/branch>, but creates a
L<Data::TreeValidator::RepeatingBranch> instead of a standard branch.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

