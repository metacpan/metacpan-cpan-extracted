
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Source;

=head1 NAME

CGI::FormBuilder::Source - Source adapters for FormBuilder

=head1 SYNOPSIS

    # Define a source adapter

    package CGI::FormBuilder::Source::Whatever;

    sub new {
        my $self  = shift;
        my $class = ref($self) || $self;
        my %opt   = @_;
        return bless \%opt, $class;
    }

    sub parse {
        my $self = shift;
        my $file = shift || $self->{source};

        # open the file and parse it, or whatever
        my %formopt;
        open(F, "<$file") || die "Can't read $file: $!";
        while (<F>) {
            # ... do stuff to the line ...
            $formopt{$fb_option} = $fb_value;
        }

        # return hash of $form options
        return wantarray ? %formopt : \%formopt;
    }

=cut

use strict;
use warnings;
no  warnings 'uninitialized';

our $VERSION = '3.20';
warn __PACKAGE__, " is not a real module, please read the docs\n"; 
1;
__END__

=head1 DESCRIPTION

This documentation describes the usage of B<FormBuilder> sources,
as well as how to write your own source adapter.

An external source is invoked by using the C<source> option to
the top-level C<new()> method:

    my $form = CGI::FormBuilder->new(
                    source => 'source_file.conf'
               );

This example points to a filename that contains a file following
the C<CGI::FormBuilder::Source::File> layout. Like with the C<template>
option, you can also specify C<source> as a reference to a hash,
allowing you to use other source adapters:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    source => {
                        type => 'File',
                        source => '/path/to/source.conf',
                    }
               );

The C<type> option specifies the name of the source adapter. Currently
accepted types are:

    File  -  CGI::FormBuilder::Source::File

In addition to one of these types, you can also specify a complete package name,
in which case that module will be autoloaded and its C<new()> and C<parse()>
routines used. For example:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    source => {
                        type => 'My::Source::Module',
                        somefile => '/path/to/source.conf',
                    }
               );

All other options besides C<type> are passed to the constructor for that
source module verbatim, so it's up to you and/or the source module on how
these additional options should be handled.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Source::File>,

=head1 REVISION

$Id: Source.pm 100 2007-03-02 18:13:13Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
