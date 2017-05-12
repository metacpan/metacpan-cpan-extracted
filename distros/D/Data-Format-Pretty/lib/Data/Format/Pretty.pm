package Data::Format::Pretty;

use 5.010001;
use strict;
use warnings;

use Module::Load;
use Module::Loaded;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw(ppr);
our @EXPORT_OK = qw(format_pretty print_pretty ppr);

our $VERSION = '0.04'; # VERSION

sub format_pretty {
    my ($data, $opts0) = @_;

    my %opts = $opts0 ? %$opts0 : ();
    my $module = $opts{module};
    if (!$module) {
        if ($ENV{GATEWAY_INTERFACE} || $ENV{PLACK_ENV}) {
            $module = 'HTML';
        } else {
            $module = 'Console';
        }
    }
    delete $opts{module};

    my $module_full = "Data::Format::Pretty::" . $module;
    load $module_full unless is_loaded $module_full;
    my $sub = \&{$module_full . "::format_pretty"};

    $sub->($data, \%opts);
}

sub print_pretty {
    print format_pretty(@_);
}

*ppr = \&print_pretty;

1;
# ABSTRACT: Pretty-print data structure


=pod

=head1 NAME

Data::Format::Pretty - Pretty-print data structure

=head1 VERSION

version 0.04

=head1 SYNOPSIS

In your program:

 use Data::Format::Pretty qw(format_pretty print_pretty);

 # automatically choose an appropriate formatter
 print format_pretty($data);

 # explicitly select a formatter
 print format_pretty($data, {module=>'JSON'});

 # specify formatter option(s)
 print format_pretty($data, {module=>'Console', interactive=>1});

 # shortcut for printing to output
 print_pretty($data);


 # ppr() is alias for print_pretty(), exported automatically. suitable for when
 # debugging.
 use Data::Format::Pretty;
 ppr [1, 2, 3];

=head1 DESCRIPTION

Data::Format::Pretty is an extremely simple framework for pretty-printing data
structure. Its focus is on "prettiness" and automatic detection of appropriate
format to use.

To develop a formatter, look at one of the formatter modules (like
L<Data::Format::Pretty::JSON>) for example. You only need to specify one
function, C<format_pretty>.

=head1 FUNCTIONS

=head2 format_pretty($data, \%opts) => STR

Send $data to formatter module (one of Data::Format::Pretty::* modules) and
return the result. Options:

=over 4

=item * module => STR

Select the formatter module. It will be prefixed with "Data::Format::Pretty::".

Currently if unspecified the default is 'Console', or 'HTML' if CGI/PSGI/plackup
environment is detected. In the future, more sophisticated detection logic will
be used.

=back

The rest of the options will be passed to the formatter module.

=head2 print_pretty($data, \%opts)

Just call format_pretty() and print() it.

=head2 ppr($data, \%opts) [EXPORTED BY DEFAULT]

Alias for print_pretty().

=head1 SEE ALSO

One of Data::Format::Pretty::* formatter, like L<Data::Format::Pretty::Console>,
L<Data::Format::Pretty::HTML>, L<Data::Format::Pretty::JSON>,
L<Data::Format::Pretty::YAML>.

Alternative data formatting framework/module family: L<Any::Renderer>.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

