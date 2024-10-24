package Code::Style::Kit::Parts::Test2;
use strict;
use warnings;
our $VERSION = '1.0.3'; # VERSION
# ABSTRACT: commonly used test modules (Test2 style)


use Import::Into;

sub feature_test_takes_arguments { 1 }
sub feature_test_export {
    my ($self, $caller, @arguments) = @_;

    require Test2::V0;
    Test2::V0->import::into($caller, @arguments);
    require lib;
    lib->import::into($caller, 't/lib');
    require Log::Any::Adapter;
    # log to TAP, showing the category, skipping the "how to use
    # this" message, and showing all log messages
    $ENV{TAP_LOG_ORIGIN}=1;
    $ENV{TAP_LOG_SHOW_USAGE}=0;
    Log::Any::Adapter->set(
        TAP => ( filter => 'none' ),
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Code::Style::Kit::Parts::Test2 - commonly used test modules (Test2 style)

=head1 VERSION

version 1.0.3

=head1 SYNOPSIS

  package My::Kit;
  use parent qw(Code::Style::Kit Code::Style::Kit::Parts::Test2);
  1;

Then:

  use My::Kit 'test';

  # write your test

=head1 DESCRIPTION

This part defines the C<test> feature, which imports L<< C<Test2::V0>
>>, adds F<t/lib> to C<@INC>, and sets up L<<
C<Log::Any::Adapter::TAP> >>.

Any argument given to the C<test> feature will be passed to
C<Test2::V0>:

  use My::Kit test => [ -srand => 0, -target => 'My::Class' ];

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by BroadBean UK, a CareerBuilder Company.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
