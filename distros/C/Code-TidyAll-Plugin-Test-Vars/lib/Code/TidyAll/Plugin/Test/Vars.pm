package Code::TidyAll::Plugin::Test::Vars;

use strict;
use warnings;
use autodie;

our $VERSION = '0.04';

# To ensure that $self->tidyall->_tempdir is a Path::Tiny object.
use Code::TidyAll 0.50 ();
use Test::Vars 0.008;
use Path::Tiny qw( path );
use PPI::Document;

use Moo;

extends 'Code::TidyAll::Plugin';

has ignore_file => (
    is        => 'ro',
    predicate => '_has_ignore_file',
);

has _ignore_for_package => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_ignore_for_package',
);

sub BUILD {
    my $self = shift;

    # We need to read the file before we start checking anything so we can die
    # if it contains bad lines and not have it look like a failure in a
    # particular file we're tidying.
    $self->_ignore_for_package;

    return;
}

sub validate_source {
    my $self   = shift;
    my $source = shift;

    my $doc = PPI::Document->new( \$source );

    # Test::Vars only works with Perl code in a package anyway.
    my $package_stmt = $doc->find_first('PPI::Statement::Package')
        or return;
    my $package = $package_stmt->namespace
        or return;

    my @path = split /::/, $package;
    $path[-1] .= '.pm';

    ## no critic (Subroutines::ProtectPrivateSubs)
    my $file = $self->tidyall->_tempdir->child( 'lib', @path );
    ## use critic
    ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    $file->parent->mkpath( 0, 0755 );
    ## use critic
    $file->spew($source);

    return test_vars(
        $file,
        \&_result_handler,
        %{ $self->_ignore_for_package->{$package} || {} },
    );
}

sub _build_ignore_for_package {
    my $self = shift;

    return {} unless $self->_has_ignore_file;

    my %vars;
    my %regexes;

    open my $fh, '<', $self->ignore_file;
    while (<$fh>) {
        next unless /\S/;

        chomp;
        my ( $package, $ignore ) = split /\s*=\s*/;
        unless ( defined $package && defined $ignore ) {
            die 'Invalid line in ' . $self->ignore_file . ": $_\n";
        }

        if ( $ignore =~ m{^qr} ) {
            local $@ = undef;
            ## no critic (BuiltinFunctions::ProhibitStringyEval)
            $ignore = eval $ignore;
            ## use critic
            die $@ if $@;

            push @{ $regexes{$package} }, $ignore;
        }
        else {
            push @{ $vars{$package} }, $ignore;
        }
    }

    my %ignore;
    for my $package ( keys %regexes ) {
        my @re = @{ $regexes{$package} };
        $ignore{$package}{ignore_if} = sub {
            for my $re (@re) {
                return 1 if $_ =~ /$re/;
            }
            return 0;
        };
    }

    for my $package ( keys %vars ) {
        $ignore{$package}{ignore_vars}{$_} = 1 for @{ $vars{$package} };
    }

    return \%ignore;
}

sub _result_handler {
    shift;
    my $exit_code = shift;
    my $results   = shift;

    return unless $exit_code;

    my @errors = map { $_->[1] } grep { $_->[0] eq 'diag' } @{$results};
    die join q{}, map { "    $_\n" } @errors if @errors;

    return;
}

1;

# ABSTRACT: Provides Test::Vars plugin for Code::TidyAll

__END__

=pod

=head1 NAME

Code::TidyAll::Plugin::Test::Vars - Provides Test::Vars plugin for Code::TidyAll

=head1 VERSION

version 0.04

=head1 SYNOPSIS

In your F<.tidyallrc> file:

    [Test::Vars]
    select = **/*.pm

=head1 DESCRIPTION

This module uses L<Test::Vars> to detect unused variables in Perl modules.

=head1 CONFIGURATION

=over

=item ignore_file

This file can be used to ignore particular variables in particulate modules.
The syntax is as follows:

    Dir::Reader    = $pushed_dir

Each line contains a module name followed by an equal sign and then the
name of the variable to ignore.

=back

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/Code-TidyAll-Plugin-Test-Vars/issues>.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Greg Oschwald <goschwald@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2016 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
