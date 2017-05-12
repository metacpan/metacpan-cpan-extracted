#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Action::Missing;
# ABSTRACT: Missing command implementation
$App::Magpie::Action::Missing::VERSION = '2.010';
use Moose;
use ORDB::CPAN::Mageia;
use URPM;

with 'App::Magpie::Role::Logging';



sub run {
    my ($self, $opts) = @_;

    # read local rpm database
    my $db = URPM::DB::open();
    my @local;
    $db->traverse( sub { my ($pkg) = @_; push @local, $pkg->name; } );

    # see perl rpms available in mageia
    my %mageia;
    my $mgadists = ORDB::CPAN::Mageia->selectcol_arrayref(
        'SELECT DISTINCT pkgname FROM module ORDER BY dist'
    );
    @mageia{ @$mgadists } = ();

    # list available rpms not installed locally
    delete @mageia{ @local };
    say $_ for sort keys %mageia;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::Missing - Missing command implementation

=head1 VERSION

version 2.010

=head1 DESCRIPTION

This module implements the C<missing> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    App::Magpie::Action::Missing->new->run( $opts );

List Perl modules available in Mageia but not installed locally.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
