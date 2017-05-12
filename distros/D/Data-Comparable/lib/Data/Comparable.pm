use 5.008;
use strict;
use warnings;

package Data::Comparable;
our $VERSION = '1.100840';
# ABSTRACT: Present your object for comparison purposes
use UNIVERSAL::require;
use parent 'Data::Inherited';

sub comparable_scalar {
    my ($self, $scalar, $skip_bless) = @_;
    my $class = ref $scalar;
    unless ($class) {

        # Convert the value into a string, because eq_or_diff seems to make a
        # difference between strings and numbers.
        return defined $scalar ? "$scalar" : $scalar;
    }

    # Make sure the class this scalar is referencing is loaded. Suppose you
    # dump an object that has been serialized (say, from a database). Then it
    # could happen that the corresponding classes haven't been loaded, and so
    # it would dump incorrectly.
    if ($class ne 'HASH' && $class ne 'ARRAY') {
        $class->require or die $@;
        if (UNIVERSAL::can($scalar, 'prepare_comparable')) {
            $scalar->prepare_comparable;
        }
    }
    if (UNIVERSAL::can($scalar, 'comparable')) {
        return $scalar->comparable($skip_bless);
    } elsif ($class eq 'ARRAY') {
        return [ map { $self->comparable_scalar($_, $skip_bless) } @$scalar ];
    } else {

        # else it must be a hash - we don't support other forms of blessed
        # things yet. We could explicitly check for UNIVERSAL::isa($scalar,
        # 'HASH'), but that's too slow for the typical case where there are
        # huge structures composed of lists and possibly blessed hashes.
        my $hash;
        while (my ($key, $value) = each %$scalar) {
            $hash->{$key} = $self->comparable_scalar($value, $skip_bless);
        }

        # It could be an object of a class that doesn't implement comparable,
        # so we got into this branch, but we still want to return a properly
        # blessed object.
        bless $hash, ref $scalar if ref $scalar ne 'HASH' && !$skip_bless;
        return $hash;
    }
}

sub comparable {
    my ($self, $skip_bless) = @_;
    if (UNIVERSAL::can($self, 'prepare_comparable')) {
        $self->prepare_comparable;
    }
    my %skip_keys = map { $_ => 1 } $self->every_list('SKIP_COMPARABLE_KEYS');
    my $copy = {};
    while (my ($key, $value) = each %$self) {
        next if exists $skip_keys{$key};
        $copy->{$key} = $self->comparable_scalar($value, $skip_bless);
    }
    bless $copy, ref $self unless $skip_bless;
    return $copy;
}

sub dump_comparable {
    my ($self, $skip_bless) = @_;
    require Data::Dumper;
    local $Data::Dumper::Indent = 1;
    Data::Dumper::Dumper($self->comparable($skip_bless));
}

sub yaml_dump_comparable {
    my ($self, $skip_bless) = @_;
    require YAML;
    YAML::Dump($self->comparable($skip_bless));
}

# So subclasses can call SUPER:: without worries.
sub prepare_comparable { }
1;


__END__
=pod

=head1 NAME

Data::Comparable - Present your object for comparison purposes

=head1 VERSION

version 1.100840

=head1 SYNOPSIS

  use base 'Data::Comparable';

  sub prepare_comparable {
      my $self = shift;
      $self->SUPER::prepare_comparable(@_);
      delete $self->{some_temp_value};
      $self->items;    # autovivify;
  }

  # in some test file:

  use Test::Differences;
  my $x = '...';
  my $y = '...';
  eq_or_diff($x->comparable, $y->comparable, 'objects are equal');

=head1 DESCRIPTION

When you define a class, it may not be so straightforward to compare two
objects of that class. For example, you want to compare object C<$x> to object
C<$y>. You would like to use C<is_deeply()> from Test::More, but it complains
that some hash keys are undef in one object but completely missing in the
other. That is easily solved by autovivifying the keys in question. Also, some
hash keys might be irrelevant to comparison - that is, you still consider two
objects to be equal even though they differ in some hash keys.

This is where Data::Comparable can help. It enables you to define how your
object wants to look like when it is being passed to some deep comparison
function like C<Test::More::is_deeply()> or
C<Test::Differences::eq_or_diff()>. If your class inherits from
Data::Comparable, it gets a method called C<comparable()>, which you can call
when comparing it. That is, you don't compare the actual objects, but their
comparable versions.

To define the comparable version of your object, your class has to implement
the C<prepare_comparable()> method. There you can autovivify any hash keys you
like or tweak your object in any way you need to make it comparable.

=head1 METHODS

=head2 comparable

FIXME

=head2 comparable_scalar

FIXME

=head2 dump_comparable

FIXME

=head2 prepare_comparable

FIXME

=head2 yaml_dump_comparable

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Comparable>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Comparable/>.

The development version lives at
L<http://github.com/hanekomu/Data-Comparable/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

