use 5.008;
use strict;
use warnings;

package Data::Semantic::Test;
BEGIN {
  $Data::Semantic::Test::VERSION = '1.101620';
}

# ABSTRACT: Testing Data::Semantic objects
use Test::More;
use parent 'Test::CompanionClasses::Base';

sub PLAN {
    my $self = shift;
    my $plan = 0;
    for my $test ($self->TESTDATA) {
        my %normalize = %{ $test->{normalize} || {} };
        $plan +=
          @{ $test->{valid}   || [] } +
          @{ $test->{invalid} || [] } +
          keys %normalize;
    }
    $plan;
}

sub munge_args {
    my ($self, %args) = @_;
    %args;
}

sub test_is_valid {
    my ($self, $obj, $value, $testname) = @_;
    ok($obj->is_valid($value), $testname);
}

sub test_is_invalid {
    my ($self, $obj, $value, $testname) = @_;
    ok(!$obj->is_valid($value), $testname);
}

sub test_normalize {
    my ($self, $obj, $value, $expect, $testname) = @_;
    is($obj->normalize($value), $expect, $testname);
}

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    for my $test ($self->TESTDATA) {
        my %args = $self->munge_args(%{ $test->{args} || {} });

        # string representation for test name
        my $args = join ',' => map { "$_=$args{$_}" }
          sort keys %args;
        $args = '(none)' unless length $args;
        my $obj = $self->make_real_object(%args);
        $self->test_is_valid($obj, $_, "VALID   $args: $_")
          for @{ $test->{valid} || [] };

        # If a value is not even well-formed, it most certainly is not valid,
        # so add these tests as well.
        $self->test_is_invalid($obj, $_, "INVALID $args: $_")
          for @{ $test->{invalid} || [] };
        my %normalize = %{ $test->{normalize} || {} };
        while (my ($value, $expect) = each %normalize) {
            $self->test_normalize($obj, $value, $expect, "normalize($value)");
        }
    }
}
1;


__END__
=pod

=head1 NAME

Data::Semantic::Test - Testing Data::Semantic objects

=head1 VERSION

version 1.101620

=head1 DESCRIPTION

This class makes it easy to test new semantic data classes based on
L<Data::Semantic>. It uses the L<Test::CompanionClasses> mechanism. So to
test the subclass L<Data::Semantic::URI::http> you would write a corresponding
L<Data::Semantic::URI::http_TEST> test class. In your test class you need to
define the following structure:

    use constant TESTDATA => (
        {
            args => {},
            valid => [ qw(
                http://localhost/
                http://use.perl.org/~hanekomu/journal?entry=12345
            ) ],
            invalid  => [ qw(
                news://localhost/
                http://?123
                https://localhost/
            ) ],
            normalize => {
                foo => 'bar',
                baz => undef,
            },
        },
        {
            args => { scheme => 'https?' },
            valid => [ qw(
                http://localhost/
                http://use.perl.org/~hanekomu/journal?entry=12345
                https://localhost/
                https://use.perl.org/~hanekomu/journal?entry=12345
            ) ],
            invalid  => [ qw(
                news://localhost/
                http://?123
            ) ],
        },
        {
            args => { scheme => 'https' },
            valid => [ qw(
                https://localhost/
                https://use.perl.org/~hanekomu/journal?entry=12345
            ) ],
            invalid  => [ qw(
                http://localhost/
                http://use.perl.org/~hanekomu/journal?entry=12345
                http://?123
                news://localhost/
            ) ],
        },
    );

So you define one or more scenarios, each within its own hashref within the
C<TESTDATA> list. In each scenario you have a list of arguments to pass to the
semantic data object constructor. Given those arguments, certain values will
be considered valid and others invalid. 

See L<Test::CompanionClasses> for more information on how these tests are run.

=head1 METHODS

=head2 PLAN

FIXME

=head2 run

FIXME

=head2 munge_args

FIXME

=head2 test_is_invalid

FIXME

=head2 test_is_valid

FIXME

=head2 test_normalize

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Semantic/>.

The development version lives at
L<http://github.com/hanekomu/Data-Semantic/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

