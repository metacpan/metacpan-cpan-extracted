package Contextual::Diag;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.03";

use Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/contextual_diag/;

use Carp ();
use Contextual::Diag::Value;

sub contextual_diag {

    if (wantarray) {
        _diag('wanted LIST context');
        return @_;
    }
    elsif(!defined wantarray) {
        _diag('wanted VOID context');
        return;
    }
    else {
        _diag('wanted SCALAR context');

        return Contextual::Diag::Value->new($_[0],
            BOOL      => sub { _diag('evaluated as BOOL in SCALAR context');  return $_[0] },
            NUM       => sub { _diag('evaluated as NUM in SCALAR context');   return $_[0] || 0   },
            STR       => sub { _diag('evaluated as STR in SCALAR context');   return $_[0] || ""  },
            SCALARREF => sub { _diag('scalar ref is evaluated as SCALARREF'); return defined $_[0] ? $_[0] : \"" },
            ARRAYREF  => sub { _diag('scalar ref is evaluated as ARRAYREF');  return defined $_[0] ? $_[0] : [] },
            HASHREF   => sub { _diag('scalar ref is evaluated as HASHREF');   return defined $_[0] ? $_[0] : {} },
            CODEREF   => sub { _diag('scalar ref is evaluated as CODEREF');   return defined $_[0] ? $_[0] : sub { } },
            GLOBREF   => sub { _diag('scalar ref is evaluated as GLOBREF');   return defined $_[0] ? $_[0] : do { no strict qw/refs/; my $package = __PACKAGE__; \*{$package} } },
            OBJREF    => sub { _diag('scalar ref is evaluated as OBJREF');    return defined $_[0] ? $_[0] : bless {}, __PACKAGE__ },
        );
    }
}

sub _diag {
    local $Carp::CarpLevel = 2;
    goto &Carp::carp;
}

1;
__END__

=encoding utf-8

=head1 NAME

Contextual::Diag - diagnosing perl context

=head1 SYNOPSIS

    use Contextual::Diag;

    if (contextual_diag) { }
    # => warn "evaluated as BOOL in SCALAR context"

    my $h = { key => contextual_diag 'hello' };
    # => warn "wanted LIST context"

=head1 DESCRIPTION

Contextual::Diag is a tool for diagnosing perl context.
The purpose of this module is to make it easier to learn perl context.

=head2 contextual_diag()

    contextual_diag(@_) => @_

By plugging in the context where you want to know, indicate what the context:

    # CASE: wanted LIST context
    my @t = contextual_diag qw/a b/
    my @t = ('a','b', contextual_diag())

    # CASE: wanted SCALAR context
    my $t = contextual_diag "hello"
    scalar contextual_diag qw/a b/

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

