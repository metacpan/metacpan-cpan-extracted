package Data::MuForm::Test;
# ABSTRACT: provides is_html method used in tests
use strict;
use warnings;
use base 'Test::Builder::Module';
use HTML::TreeBuilder;
use Test::Builder::Module;
our @EXPORT = ('is_html');
use Encode ('decode');


sub is_html {
    my ( $got, $expected, $message ) = @_;
    my $t1 = HTML::TreeBuilder->new;
    my $t2 = HTML::TreeBuilder->new;

    $got = decode('utf8', $got);
    $expected = decode('utf8', $expected);
    $t1->parse($got);
    $t1->eof;
    $t2->parse($expected);
    $t2->eof;
    my $out1 = $t1->as_XML;
    my $out2 = $t2->as_XML;
    $t1->delete;
    $t2->delete;
    my $tb = Data::MuForm::Test->builder;
    return $tb->is_eq($out1, $out2, $message);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::MuForm::Test - provides is_html method used in tests

=head1 VERSION

version 0.05

=head1 SYNOPSIS

Simple 'is_html' method for testing form rendering against
an expected value without having to fuss with exactly matching
newlines and spaces. Uses L<HTML::TreeBuilder>, which uses
L<HTML::Parser>.

=head1 AUTHOR

Gerda Shank

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
