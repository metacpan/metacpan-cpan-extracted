package Data::Clean::ToNonStringyNumber;

our $DATE = '2019-09-01'; # DATE
our $VERSION = '0.050'; # VERSION

use 5.010001;
use strict;
use warnings;

use parent qw(Data::Clean);
use vars qw($creating_singleton);

sub command_replace_with_non_stringy_number {
    require Scalar::Util::LooksLikeNumber;

    my ($self, $args) = @_;
    return '{{var}} = Scalar::Util::LooksLikeNumber::looks_like_number({{var}}) =~ /\\A(?:1|5|9|13)\\z/ ? {{var}}+0 : {{var}}';
}

sub new {
    my ($class, %opts) = @_;

    if (!%opts && !$creating_singleton) {
        warn "You are creating a new ".__PACKAGE__." object without customizing options. ".
            "You probably want to call get_cleanser() yet to get a singleton instead?";
    }

    $opts{""} //= ['replace_with_non_stringy_number'];
    $class->SUPER::new(%opts);
}

sub get_cleanser {
    my $class = shift;
    local $creating_singleton = 1;
    state $singleton = $class->new;
    $singleton;
}

1;
# ABSTRACT: Convert stringy numbers in data to non-stringy numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Clean::ToNonStringyNumber - Convert stringy numbers in data to non-stringy numbers

=head1 VERSION

This document describes version 0.050 of Data::Clean::ToNonStringyNumber (from Perl distribution Data-Clean-ToStringyNumber), released on 2019-09-01.

=head1 SYNOPSIS

 use Data::Clean::ToNonStringyNumber;
 my $cleanser = Data::Clean::ToNonStringyNumber->get_cleanser;
 my $data     = ["a", 1, "1.2", []];
 my $cleaned  = $cleanser->clean_in_place($data); # -> ["a", 1, 1.2, []]

=head1 DESCRIPTION

This class can convert stringy numbers in your data to non-stringy ones.

=for Pod::Coverage ^(new|command_.+)$

=head1 METHODS

=head2 CLASS->get_cleanser => $obj

Return a singleton instance.

=head2 $obj->clean_in_place($data) => $cleaned

Clean $data. Modify data in-place.

=head2 $obj->clone_and_clean($data) => $cleaned

Clean $data. Clone $data first.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Clean-ToStringyNumber>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Clean-ToStringyNumber>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Clean-ToStringyNumber>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Clean::ToStringyNumber>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016, 2014, 2013 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
