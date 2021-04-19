package Test2::Plugin::Wrap2ndArgumentOfFailedCompareTestWithString;
use strict;
use warnings;
use PPIx::Utils qw(parse_arg_list);
use PPI;
use Test2::API qw(
    test2_add_callback_post_load
    test2_stack
);

my $loaded = 0;

sub import {
    my ($class) = @_;

    return if $loaded++;

    test2_add_callback_post_load(sub {
        my $hub = test2_stack()->top;

        $hub->listen(\&listener, inherit => 1);
    });
}

sub listener {
    my ($hub, $event) = @_;

    return unless $event->causes_fail;

    my $trace = $event->trace;
    my $file = $trace->file;
    my $line = $trace->line;

    my $doc = PPI::Document->new($file);
    my $stmt = $doc->find_first(sub {
        my (undef, $elem) = @_;
        return $elem->isa('PPI::Statement') && $elem->line_number == $line;
    });
    return unless $stmt;

    my $second_arg = (parse_arg_list($stmt->first_token))[1]->[0];
    return unless $second_arg;

    # A -> string(A)
    $second_arg->insert_before(PPI::Token::Word->new('string'));
    $second_arg->insert_before(PPI::Token::Structure->new('('));
    $second_arg->insert_after(PPI::Token::Structure->new(')'));

    $doc->save($file);
}

1;
__END__

=encoding utf-8

=head1 NAME

Test2::Plugin::Wrap2ndArgumentOfFailedCompareTestWithString - A Test2 plugin that wraps 2nd argument of failed assertions with C<string()>

=head1 SYNOPSIS

    use Test2::Plugin::Wrap2ndArgumentOfFailedCompareTestWithString;

=head1 DESCRIPTION

Test2::Plugin::Wrap2ndArgumentOfFailedCompareTestWithString is a Test2 plugin that wraps 2nd argument of failed assertions with C<string()>.

    use URI;
    my $url = 'https://www.example.com'
    my $uri = URI->new('https://www.example.com/');
    is $url, $uri;

The above test passes on Test::More because C<Test::More::is> compares both arguments as string.
On the contrary, the test fails on Test2::V0 because C<Test2::V0::is> checks both arguments are equal structurely (a string is not a URI instance).

    use URI;
    my $url = 'https://www.example.com'
    my $uri = URI->new('https://www.example.com/');
    is $url, string($uri);

This test passes on Test2::V0 because C<string()> enforces string comparison.

=head1 LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

utgwkk E<lt>utagawakiki@gmail.comE<gt>

=cut
