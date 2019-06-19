package Data::Verifier::Filters;
$Data::Verifier::Filters::VERSION = '0.63';
use strict;
use warnings;

# ABSTRACT: Filters for values


sub collapse {
    my ($self, $val) = @_;
    return $val if not defined $val;

    $val =~ s/\s+/ /g;
    return $val;
}


sub flatten {
    my ($self, $val) = @_;
    return $val if not defined $val;

    $val =~ s/\s//g;
    return $val;
}


sub lower {
    my ($self, $val) = @_;
    return $val if not defined $val;

    return lc($val);
}


sub trim {
    my ($self, $val) = @_;
    return $val if not defined $val;

    $val =~ s/^\s+|\s+$//g;

    return $val;
}


sub upper {
    my ($self, $val) = @_;
    return $val if not defined $val;

    return uc($val);
}

1;

__END__

=pod

=head1 NAME

Data::Verifier::Filters - Filters for values

=head1 VERSION

version 0.63

=head1 SYNOPSIS

    use Data::Verifier;

    my $dv = Data::Verifier->new(profile => {
        name => {
            type    => 'Str',
            filters => [ qw(collapse trim) ]
        }
    });

    $dv->verify({ name => ' foo  bar  '});
    $dv->get_value('name'); # 'foo bar'

=head1 CUSTOM FILTERS

Adding a custom filter may be done by providing a coderef as one of the
filters:

  # Remove all whitespace
  my $sub = sub { my ($val) = @_; $val =~ s/\s//g; $val }

  $dv->verify({
    name => {
      type    => 'Str'
        filters => [ $sub ]
      }
  });
  $dv->get_value('name'); # No whitespace!

=head1 METHODS

=head2 collapse

Collapses all consecutive whitespace into a single space

=head2 flatten

Removes B<all whitespace>.

=head2 lower

Converts the value to lowercase.

=head2 trim

Removes leading and trailing whitespace

=head2 upper

Converts the value to uppercase.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
