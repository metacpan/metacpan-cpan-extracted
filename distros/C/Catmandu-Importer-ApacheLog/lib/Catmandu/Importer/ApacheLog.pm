package Catmandu::Importer::ApacheLog;
use Catmandu::Sane;
use Catmandu::Util qw(:is :check);
use Apache::Log::Parser;
use Moo;

our $VERSION = '0.0112';

with 'Catmandu::Importer';

has formats => (
    is => 'ro',
    isa => sub { check_array_ref($_[0]); },
    required => 1,
    lazy => 1,
    default => sub { ["common","combined"]; },
    coerce => sub {
        my $f = $_[0];
        if ( is_string $f ) {
            $f = [ $f ];
        }
        $f;
    }
);
has _parser  => (
	is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_parser',
);

sub _build_parser {
    my $self = $_[0];
    Apache::Log::Parser->new(fast => $self->formats());
}

sub generator {
	my ($self) = @_;

	return sub {
        state $fh = $self->fh;
        state $parser = $self->_parser();
        my $line = <$fh>;
        return unless defined $line;
        my $l = $line;
        chomp $l;
        my $r =  $parser->parse($line);
        $r->{_log} = $line;
        $r;
	}
}

=head1 NAME

Catmandu::Importer::ApacheLog - Catmandu importer for importing log entries

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-Importer-ApacheLog.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-Importer-ApacheLog)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-Importer-ApacheLog/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-Importer-ApacheLog)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-Importer-ApacheLog.png)](http://cpants.cpanauthors.org/dist/Catmandu-Importer-ApacheLog)

=end markdown

=head1 DESCRIPTION

This importer reads every entry in the log file, and put the log entries (status, rhost ..) into a record.
The original line is stored in the attribute '_log'.

=head1 METHODS

=head2 new ( file => $file, fix => $fix, formats => ['combined','common'] )

=over 4

=item file

    File to import. Can also be a string reference or a file handle. See L<Catmandu::Importer>

=item fix

    Fix to apply to every record. See L<Catmandu::Importer>

=item formats

    Array reference of formats

    By default ['combined','common']

    For more information see L<Apache::Log::Parser>, and look for the option 'fast'.

=back

=head1 SYNOPSIS


    #!/usr/bin/env perl
    use Catmandu::Importer::ApacheLog;
    use Data::Dumper;

    my $importer = Catmandu::Importer::ApacheLog->new(
        file => "/var/log/httpd/access_log"
    );

    $importer->each(sub{
        print Dumper(shift);
    });

    #!/bin/bash
    catmandu convert ApacheLog --file access.log to YAML

=head1 AUTHORS

    Nicolas Franck C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

    L<Catmandu>, L<Catmandu::Importer> , L<Apache::Log::Parser>

=cut

1;
