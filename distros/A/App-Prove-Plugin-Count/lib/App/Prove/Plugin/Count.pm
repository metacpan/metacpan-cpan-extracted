package App::Prove::Plugin::Count;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.03";

use App::Prove;
use Class::Method::Modifiers qw( around );
use TAP::Formatter::Base;

my $total_file_count;
my $current_file_count = 0;

sub load {
    around 'App::Prove::_get_tests' => sub {
        my $orig  = shift;
        my @tests = $orig->(@_);
        $total_file_count = scalar @tests;
        return @tests;
    };
    around 'TAP::Formatter::Base::_format_name' => sub {
        my $orig = shift;
        my $ret  = $orig->(@_);
        $current_file_count++;
        my $spacer = " "
            x ( length($total_file_count) - length($current_file_count) );
        return "[$spacer$current_file_count/$total_file_count] $ret";
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Prove::Plugin::Count - A prove plugin to count test files.

=head1 SYNOPSIS

    $ prove -PCount

    # [ 1/10] t/test1.t ....... ok
    # [ 2/10] t/test2.t ....... ok
    # ...

=head1 DESCRIPTION

App::Prove::Plugin::Count is a prove plugin to count test files.

This plugin adds current test file count and total test file count at the front of each test result.

=head1 LICENSE

Copyright (C) Masahiro Iuchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Iuchi E<lt>masahiro.iuchi@gmail.comE<gt>

=cut

