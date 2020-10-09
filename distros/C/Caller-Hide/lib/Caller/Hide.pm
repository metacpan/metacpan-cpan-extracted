package Caller::Hide;
use strict;
use warnings;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use parent 'Exporter';
use Carp;

our @EXPORT_OK   = qw[ hide_package reveal_package ];
our %EXPORT_TAGS = (ALL => \@EXPORT_OK);

my %hidden;

{    # adapted from Hook::LexWrap
    no warnings 'redefine';
    *CORE::GLOBAL::caller = sub (;$) {
        my ($height) = ($_[0] || 0);
        my $i = 1;
        my $name_cache;
        while (1) {
            my @caller
                = CORE::caller() eq 'DB'
                ? do { package DB; CORE::caller($i++) }
                : CORE::caller($i++);
            return if not @caller;
            $caller[3] = $name_cache if $name_cache;
            $name_cache = $hidden{ $caller[0] } ? $caller[3] : '';
            next if $name_cache || $height-- != 0;
            return wantarray ? @_ ? @caller : @caller[ 0 .. 2 ] : $caller[0];
        }
    };
}

sub hide_package {
    my ($package) = @_;
    $hidden{$package} = 1;
    return;
}

sub reveal_package {
    my ($package) = @_;
    Carp::carp "$package not hidden" if not $hidden{$package};

    delete $hidden{$package};
    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Caller::Hide - hide packages from stack traces

=head1 SYNOPSIS

  package My::Wrapper;
  use Caller::Hide qw[ hide_package ];

  hide_package(__PACKAGE__);

=head1 FUNCTIONS

=head2 hide_package($pkg)

Set $pkg as hidden, it will no longer appear in stack traces
and direct calls to C<caller>.

=head2 reveal_package($pkg)

Set a previously hidden package to no longer be hidden.

=head1 AUTHOR

Szymon Nieznański <snez@cpan.org>

Original caller override code adapted from L<Hook::LexWrap>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
