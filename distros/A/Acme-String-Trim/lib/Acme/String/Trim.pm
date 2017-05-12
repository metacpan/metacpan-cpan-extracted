use strict;
use warnings;

package Acme::String::Trim;
{
  $Acme::String::Trim::VERSION = '0.003';
}

# ABSTRACT: Acme::String::Trim - Module to experiment with 'dist-zilla', github and cpan


sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    return bless { _string => shift, }, $class;
}


sub string {
    my ( $self, $string ) = @_;
    $self->{_string} = $string if defined $string;
    return $self->{_string};
}


sub trim {
    my $self = shift;
    $self->{_string} =~ s/^\s+|\s+$//gx;
    return $self->{_string};
}

1;

__END__
=pod

=head1 NAME

Acme::String::Trim - Acme::String::Trim - Module to experiment with 'dist-zilla', github and cpan

=head1 VERSION

version 0.003

=head1 DESCRIPTION

A sample module to experiment with 'dist-zilla', github and cpan

=head1 METHODS

=head2 new

traditional constructor

=head2 string

getter/setter for class attribute

=head2 trim

trim the string

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/abhishekisnot/Acme-String-Trim/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Abhishek Shende <abhishekisnot@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Abhishek Shende.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

