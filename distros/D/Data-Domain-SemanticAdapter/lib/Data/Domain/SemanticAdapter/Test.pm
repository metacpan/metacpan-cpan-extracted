use 5.008;
use strict;
use warnings;

package Data::Domain::SemanticAdapter::Test;
our $VERSION = '1.100840';
# ABSTRACT: testing Data::Domain objects
use Hash::Rename;
use Test::More;
use parent qw(Data::Semantic::Test);

sub munge_args {
    my ($self, %args) = @_;

    # Our keys have a dash at the beginning - make sure every key has one.
    # This also makes it possible to use Data::Semantic::*::TestData::*
    # classes' data as it is automatically munged into the format we want.
    hash_rename %args, code => sub { s/^(?!-)/-/ };
    %args;
}

sub test_is_valid {
    my ($self, $obj, $value, $testname) = @_;

    # can be empty string or 0
    like($obj->inspect($value), qr/^0?$/, $testname);
}

sub test_is_invalid {
    my ($self, $obj, $value, $testname) = @_;

    # can be empty string or 0
    like($obj->inspect($value), qr/^(\w+)(::\w+)*: invalid$/, $testname);
}

# convenience test methods
sub is_excluded {
    my ($self, $domain, $data) = @_;
    like(
        $domain->inspect($data),
        qr/^(\w+)(::\w+)*: belongs to exclusion set$/,
        "excluded: $data"
    );
}

sub is_invalid {
    my ($self, $domain, $data) = @_;
    $self->test_is_invalid($domain, $data, "invalid: $data");
}

sub is_valid {
    my ($self, $domain, $data) = @_;
    $self->test_is_valid($domain, $data, "valid: $data");
}
1;


__END__
=pod

=head1 NAME

Data::Domain::SemanticAdapter::Test - testing Data::Domain objects

=head1 VERSION

version 1.100840

=head1 DESCRIPTION

This class can be used to test classes derived from
L<Data::Domain::SemanticAdapter>. It works in conjunction with
L<Test::CompanionClasses>.

=head1 METHODS

=head2 munge_args

Test data classes usually define C<TESTDATA()> to have arguments without
leading dashes. This method munges the args to the usual L<Data::Domain> style
by prepending a dash to those keys that don't already start with a dash.

So if the C<TESTDATA()> looks like this:

    use constant TESTDATA => (
        {
            args => { foo => 1, bar => 'baz' },
            valid => [ qw(
                ...
            ) ],
            invalid => [ qw(
                ...
            ) ],
        },
    );

the data domain object to be passed will effectively be constructed like this:

    $self->make_real_object('-foo' => 1', '-bar' => 'baz');

C<make_real_object()> comes from L<Test::CompanionClasses::Base>.

=head2 test_is_valid

Overrides this method by passing the value to be tested to the data domain
object's C<inspect()> method and checking that it either returns an empty
string or C<0>.

=head2 test_is_invalid

Overrides this method by passing the value to be tested to the data domain
object's C<inspect()> method and checking that it returns an C<INVALID>
message as defined in L<Data::Domain>.

=head2 is_excluded

Takes a data domain object and a value to be tested. Passes the value to the
data domain object's C<inspect()> method and checks whether it returns an
C<EXCLUSION_SET> message as defined in L<Data::Domain>.

=head2 is_invalid

Takes a data domain object and a value to be tested. Passes the value to the
data domain object's C<inspect()> method and checks whether it returns an
C<INVALID> message as defined in L<Data::Domain>.

This method differs from C<test_is_invalid()> in that the latter is called
while iterating over C<TESTDATA()> and so it gets a test name as an argument,
while this method can be used for custom tests - it creates its own test
name.

=head2 is_valid

Analogous to C<is_invalid()>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Domain-SemanticAdapter>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Domain-SemanticAdapter/>.

The development version lives at
L<http://github.com/hanekomu/Data-Domain-SemanticAdapter/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

