package CatalystX::LeakChecker;
our $VERSION = '0.06';
# ABSTRACT: Debug memory leaks in Catalyst applications

use Moose::Role;
use B::Deparse;
use Text::SimpleTable;
use Scalar::Util 'weaken';
use Devel::Cycle 'find_cycle';

sub deparse {
    my ($code) = @_;
    return q{sub } . B::Deparse->new->coderef2text($code) . q{;};
}

sub format_table {
    my @leaks = @_;
    my $t = Text::SimpleTable->new([52, 'Code'], [ 15, 'Variable' ]);
    $t->row(@$_) for map { [deparse($_->{code}), $_->{var}] } @leaks;
    return $t->draw;
}

sub format_leak {
    my ($leak, $sym) = @_;
    my @lines;
    my $ret = '$ctx';
    for my $element (@{ $leak }) {
        my ($type, $index, $ref, $val, $weak) = @{ $element };
        die $type if $weak;
        if ($type eq 'HASH') {
            $ret .= qq(->{$index}) if $type eq 'HASH';
        }
        elsif ($type eq 'ARRAY') {
            $ret .= qq(->[$index]) if $type eq 'ARRAY';
        }
        elsif ($type eq 'SCALAR') {
            $ret = qq(\${ ${ret} });
        }
        elsif ($type eq 'CODE') {
            push @lines, qq(\$${$sym} = ${ret};);
            push @lines, qq{code reference \$${$sym} deparses to: } . deparse($ref);
            $ret = qq($index);
            ${ $sym }++;
        }
    }
    return join qq{\n} => @lines, $ret;
}

use namespace::clean -except => 'meta';


sub found_leaks {
    my ($ctx, @leaks) = @_;
    my $t = Text::SimpleTable->new(70);

    my $sym = 'a';
    for my $leak (@leaks) {
        $t->row(format_leak($leak, \$sym), '');
    }

    my $msg = "Circular reference detected:\n" . $t->draw;
    $ctx->log->debug($msg) if $ctx->debug;
}

after finalize => sub {
    my ($ctx) = @_;
    my @leaks;

    my $weak_ctx = $ctx;
    weaken $weak_ctx;

    find_cycle($ctx, sub {
        my ($path) = @_;
        push @leaks, $path
            if $path->[0]->[2] == $weak_ctx;
    });
    return unless @leaks;

    $ctx->found_leaks(@leaks);
};

1;

__END__
=pod

=head1 NAME

CatalystX::LeakChecker - Debug memory leaks in Catalyst applications

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    package MyApp;
    use namespace::autoclean;

    extends 'Catalyst';
    with 'CatalystX::LeakChecker';

    __PACKAGE__->setup;

=head1 DESCRIPTION

It's easy to create memory leaks in Catalyst applications and often they're
hard to find. This module tries to help you finding them by automatically
checking for common causes of leaks.

This module is intended for debugging only. I suggest to not enable it in a
production environment.

=head1 METHODS

=head2 found_leaks(@leaks)

If any leaks were found, this method is called at the end of each request. A
list of leaks is passed to it. It logs a debug message like this:

    [debug] Circular reference detected:
    +------------------------------------------------------+-----------------+
    | $ctx->{stash}->{ctx}                                                   |
    '------------------------------------------------------+-----------------'

It's also able to find leaks in code references. A debug message for that might
look like this:

    [debug] Circular reference detected:
    +------------------------------------------------------+-----------------+
    | $a = $ctx->{stash}->{leak_closure};                                    |
    | code reference $a deparses to: sub {                                   |
    |     package TestApp::Controller::Affe;                                 |
    |     use warnings;                                                      |
    |     use strict 'refs';                                                 |
    |     $ctx->response->body('from leaky closure');                        |
    | };                                                                     |
    | ${ $ctx }                                                              |
    '------------------------------------------------------+-----------------'

Override this method if you want leaks to be reported differently.

=head1 AUTHORS

Florian Ragwitz <rafl@debian.org>
Tomas Doran <bobtfish@bobtfish.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

