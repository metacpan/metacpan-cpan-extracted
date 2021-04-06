package App::Codeowners::Formatter;
# ABSTRACT: Base class for formatting codeowners output


use warnings;
use strict;

our $VERSION = '0.50'; # VERSION

use Module::Load;


sub new {
    my $class = shift;
    my $args  = {@_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_};

    $args->{results} = [];

    # see if we can find a better class to bless into
    ($class, my $format) = $class->_best_formatter($args->{format}) if $args->{format};
    $args->{format} = $format;

    my $self = bless $args, $class;

    $self->start;

    return $self;
}

### _best_formatter
#   Find a formatter that can handle the format requested.
sub _best_formatter {
    my $class = shift;
    my $type  = shift || '';

    return ($class, $type) if $class ne __PACKAGE__;

    my ($name, $format) = $type =~ /^([A-Za-z]+)(?::(.*))?$/;
    if (!$name) {
        $name   = '';
        $format = '';
    }

    $name = lc($name);
    $name =~ s/:.*//;

    my @formatters = $class->formatters;

    # default to the string formatter since it has no dependencies
    my $package = __PACKAGE__.'::String';

    # look for a formatter whose name matches the format
    for my $formatter (@formatters) {
        my $module = lc($formatter);
        $module =~ s/.*:://;

        if ($module eq $name) {
            $package = $formatter;
            $type    = $format;
            last;
        }
    }

    load $package;
    return ($package, $type);
}


sub DESTROY {
    my $self = shift;
    my $global_destruction = shift;

    return if $global_destruction;

    my $results = $self->{results};
    $self->finish($results) if $results;
    delete $self->{results};
}


sub handle  { shift->{handle}  }
sub format  { shift->{format}  || '' }
sub columns { shift->{columns} || [] }
sub results { shift->{results} }


sub add_result {
    my $self = shift;
    $self->stream($_) for @_;
}


sub start  {}
sub stream { push @{$_[0]->results}, $_[1] }
sub finish {}


sub formatters {
    return qw(
        App::Codeowners::Formatter::CSV
        App::Codeowners::Formatter::JSON
        App::Codeowners::Formatter::String
        App::Codeowners::Formatter::TSV
        App::Codeowners::Formatter::Table
        App::Codeowners::Formatter::YAML
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Codeowners::Formatter - Base class for formatting codeowners output

=head1 VERSION

version 0.50

=head1 SYNOPSIS

    my $formatter = App::Codeowners::Formatter->new(handle => *STDOUT);
    $formatter->add_result($_) for @results;

=head1 DESCRIPTION

This is a base class for formatters. A formatter is a class that takes data records, stringifies
them, and prints them to an IO handle.

This class is mostly abstract, though it is also usable as a null formatter where results are simply
discarded if it is instantiated directly. These other formatters do more interesting things:

=over 4

=item *

L<App::Codeowners::Formatter::CSV>

=item *

L<App::Codeowners::Formatter::String>

=item *

L<App::Codeowners::Formatter::JSON>

=item *

L<App::Codeowners::Formatter::TSV>

=item *

L<App::Codeowners::Formatter::Table>

=item *

L<App::Codeowners::Formatter::YAML>

=back

=head1 ATTRIBUTES

=head2 handle

Get the IO handle associated with a formatter.

=head2 format

Get the format string, which may be used to customize the formatting.

=head2 columns

Get an arrayref of column headings.

=head2 results

Get an arrayref of all the results that have been provided to the formatter using L</add_result> but
have not yet been formatted.

=head1 METHODS

=head2 new

    $formatter = App::Codeowners::Formatter->new;
    $formatter = App::Codeowners::Formatter->new(%attributes);

Construct a new formatter.

=head2 DESTROY

Destructor calls L</finish>.

=head2 add_result

    $formatter->add_result($result);

Provide an additional lint result to be formatted.

=head2 start

    $formatter->start;

Begin formatting results. Called before any results are passed to the L</stream> method.

This method may print a header to the L</handle>. This method is used by subclasses and should
typically not be called explicitly.

=head2 stream

    $formatter->stream(\@result, ...);

Format one result.

This method is expected to print a string representation of the result to the L</handle>. This
method is used by subclasses and should typically not called be called explicitly.

The default implementation simply stores the L</results> so they will be available to L</finish>.

=head2 finish

    $formatter->finish;

End formatting results. Called after all results are passed to the L</stream> method.

This method may print a footer to the L</handle>. This method is used by subclasses and should
typically not be called explicitly.

=head2 formatters

    @formatters = App::Codeowners::Formatter->formatters;

Get a list of package names of potential formatters within the C<App::Codeowners::Formatter>
namespace.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/git-codeowners/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
