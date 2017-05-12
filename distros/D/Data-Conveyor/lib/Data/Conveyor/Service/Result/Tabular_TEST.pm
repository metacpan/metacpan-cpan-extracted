use 5.008;
use strict;
use warnings;

package Data::Conveyor::Service::Result::Tabular_TEST;
BEGIN {
  $Data::Conveyor::Service::Result::Tabular_TEST::VERSION = '1.103130';
}
# ABSTRACT: Stage-based conveyor-belt-like ticket handling system

use Error::Hierarchy::Test 'throws2_ok';
use Test::More;
use parent 'Data::Conveyor::Test';
use constant PLAN => 5;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    $self->test_list_of_hashes_input;
    $self->test_list_of_objects_input_ok;
    $self->test_list_of_objects_input_no_baz;
}

sub test_list_of_hashes_input {
    my $self = shift;
    my $o    = $self->make_real_object;
    my $rows = [
        { foo => 'row0foo', bar => 'row0bar', baz => 'row0baz' },
        { foo => 'row1foo', bar => 'row1bar', baz => 'row1baz' },
        { foo => 'row2foo', bar => 'row2bar', baz => 'row2baz' },
    ];
    $o->set_from_rows(
        fields => [qw/foo bar baz/],
        rows   => $rows,
    );
    is_deeply(
        scalar $o->rows,
        [   [qw/row0foo row0bar row0baz/], [qw/row1foo row1bar row1baz/],
            [qw/row2foo row2bar row2baz/],
        ],
        'list of hashes input: rows()'
    );
    is_deeply(scalar $o->result_as_list_of_hashes,
        $rows, 'list of hashes input: result_as_list_of_hashes()');
}

sub test_list_of_objects_input_ok {
    my $self = shift;
    my $o    = $self->make_real_object;
    my $rows = [
        Data::Conveyor::Temp001->new(row => 0),
        Data::Conveyor::Temp001->new(row => 1),
        Data::Conveyor::Temp001->new(row => 2),
    ];
    $o->set_from_rows(
        fields => [qw/foo bar baz/],
        rows   => $rows,
    );
    is_deeply(
        scalar $o->rows,
        [   [qw/row0foo row0bar row0baz/], [qw/row1foo row1bar row1baz/],
            [qw/row2foo row2bar row2baz/],
        ],
        'list of objects input (ok): rows()'
    );
    is_deeply(
        scalar $o->result_as_list_of_hashes,
        [   { foo => 'row0foo', bar => 'row0bar', baz => 'row0baz' },
            { foo => 'row1foo', bar => 'row1bar', baz => 'row1baz' },
            { foo => 'row2foo', bar => 'row2bar', baz => 'row2baz' },
        ],
        'list of objects input (ok): result_as_list_of_hashes()'
    );
}

sub test_list_of_objects_input_no_baz {
    my $self = shift;
    my $o    = $self->make_real_object;
    my $rows = [
        Data::Conveyor::Temp002->new(row => 0),
        Data::Conveyor::Temp002->new(row => 1),
        Data::Conveyor::Temp002->new(row => 2),
    ];
    throws2_ok {
        $o->set_from_rows(
            fields => [qw/foo bar baz/],
            rows   => $rows,
        );
    }
    'Error::Hierarchy::Internal::CustomMessage',
      qr/can't set field \[baz\] from row \[Data::Conveyor::Temp002=HASH\(/,
      "set_from_rows() using objects that can't baz()";
}

package Data::Conveyor::Temp001;
BEGIN {
  $Data::Conveyor::Temp001::VERSION = '1.103130';
}
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_scalar_accessors(qw(row));
sub foo { sprintf 'row%dfoo', $_[0]->row }
sub bar { sprintf 'row%dbar', $_[0]->row }
sub baz { sprintf 'row%dbaz', $_[0]->row }

package Data::Conveyor::Temp002;
BEGIN {
  $Data::Conveyor::Temp002::VERSION = '1.103130';
}
use parent 'Class::Accessor::Complex';
__PACKAGE__->mk_new->mk_scalar_accessors(qw(row));
sub foo { sprintf 'row%dfoo', $_[0]->row }
sub bar { sprintf 'row%dbar', $_[0]->row }

# this class can't baz()
1;


__END__
=pod

=head1 NAME

Data::Conveyor::Service::Result::Tabular_TEST - Stage-based conveyor-belt-like ticket handling system

=head1 VERSION

version 1.103130

=head1 METHODS

=head2 test_list_of_hashes_input

FIXME

=head2 test_list_of_objects_input_no_baz

FIXME

=head2 test_list_of_objects_input_ok

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Conveyor>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Data-Conveyor/>.

The development version lives at L<http://github.com/hanekomu/Data-Conveyor>
and may be cloned from L<git://github.com/hanekomu/Data-Conveyor>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

