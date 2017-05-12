package App::Bulkmail;

use warnings;
use strict;

=head1 NAME

App::Bulkmail - Simple but flexible bulkmailer

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use App::Bulkmail;
    
    App::Bulkmail->run();

    ... or

    App::Bulkmail->run(
        dryrun     => 1,
        dump       => 1,
        template   => 'mail.tt',
        recipients => [
          { email => 'joe@example.net',  name => 'Joe Doe' },
          { email => 'jane@example.net', name => 'Jane Roe' },
        ],
    );

=head1 ARGUMENTS

=over 4

=item B<template> (filename or scalarref)

A Template Toolkit template. If the argument is a scalar ref it should contain
the template text otherwise is is used as a filename.

=item B<recipients> (filename or array of hashes)

A list of recipients.

=item B<dryrun> (boolean)

Wether to send mail. Default is to send mail!

=item B<dump> (boolean)

Dump mail in mbox format on STDOUT (default: no)

=item B<quiet> (boolean)

Prevent some messages on STDOUT (default: no)

=item B<verbose> (boolean)

Print some extra information on STDOUT (default: no)

=item B<progress> (Term::ProgressBar like object)

Use this as progress indicator. Default is to try to instantiate
Term::ProgressBAr if neiter dump, quiet, verbose is set.

=back

=cut

use Any::Moose;

use File::Slurp;
use Template;
use Carp;

has template => (
    is => 'rw',
    required => 1,
);

has recipients => (
    is => 'rw',
    required => 1,
);

for ( qw( dryrun dump quiet verbose progress ) ) {
    has $_ => (
        is => 'rw',
    );
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ ) {
        return $class->$orig( @_ );
    }

    require Getopt::Long
        or croak "Couldn't not load Getopt::Long in " . __PACKAGE__ . "\n";

    my %args;
    Getopt::Long::GetOptions( \%args,
        "template=s",
        "recipients=s",
        "dump!",
        "dryrun!",
        "quiet!",
        "verbose!",
    ) or croak "Couldn't parse command arguments";

    return \%args;
};

sub BUILD {
    my $self = shift;
    
    # Ok, this should really be a coercion
    unless ( ref $self->template eq 'SCALAR' ) {
        $self->template(
            scalar File::Slurp::read_file( $self->template, scalar_ref => 1 )
        );
    }

    # Ok, this should really be a coercion
    unless ( ref $self->recipients ) {
        my $file = $self->recipients;
        my $data;

        if ( $file =~ /\.yaml$/i ) {
            require YAML;
            $data = YAML::LoadFile( $file );

        } elsif ( $file =~ /\.json$/i ) {
            require JSON;
            $data = JSON::from_json( File::Slurp::read_file( $file ) );

        } elsif ( $file =~ /\.csv$/i ) {
            require Text::CSV_XS;
            $data = [ ];

            my $csv = Text::CSV_XS->new ({ binary => 1 });
            open my $fh, "<", $file or croak("Couldn't open file $file: $!\n");
            my @fields = @{ $csv->getline ($fh) };
            while ( my $row = $csv->getline ($fh) ) {
                push @{ $data }, { };
                @{ $data->[-1] }{ @fields } = @{ $row };
            }
            $csv->eof or croak("".$csv->error_diag);
        } else {
            $self->recipients(
                File::Slurp::read_file( $file, array_ref => 1 )
            )
        }

        if ( ref $data eq 'HASH' ) {
            $data = [
                map { $data->{ $_ }->{email} ||= $_; $data->{ $_ } }
                sort keys %{ $data }
            ];
        }

        $self->recipients( $data );
    }

    # progress should probably just be made lazy
    unless ( defined($self->progress) || $self->quiet || $self->verbose || $self->dump ) {
        $self->progress(
            Term::ProgressBar->new({
                count => scalar @{ $self->recipients },
                ETA   => 'linear',
            })
        ) if require Term::ProgressBar;

    }
}

sub run {
    my $self = shift;

    unless( blessed $self ) {
        $self = $self->new( @_ );
    }

    my $template = $self->template;
    my $verbose  = $self->verbose;
    my $dump     = $self->dump;
    my $dryrun   = $self->dryrun;
    my $progress = $self->progress;

    my $count = scalar @{ $self->recipients };
    my $fmt;
    if ( $verbose || $dump ) {
        my $len   = length "$count";
        $fmt      = "[%${len}d/%${len}d] %s";
    }

    my $tt = Template->new();

    my $done;
    for my $recipient (@{ $self->recipients }) {
        $done += 1;
        printf $fmt, $done, $count, "Processing $recipient\n" if $verbose;

        my $mail;
        $tt->process($template, $recipient, \$mail)
            or do {
                warn "Couldn't process template for $recipient";
                next;
            };

        printf "From bulkmailer.pl $fmt", $done, $count, "\n$mail" if $dump;

        next if $dryrun;

        open my $sendmail, "| /usr/lib/sendmail -t"
            or do {
                warn "Couldn't open sendmail while processing $recipient: $!";
                next;
            };

        print $sendmail $mail;

        close $sendmail
            or do {
                warn "Couldn't close sendmail while processing $recipient: $!";
                next;
            };
    } continue {
        $progress->update($done) if $progress;
    }

    $progress->update( $count ) if $progress;
}

=head1 AUTHOR

Peter Makholm, C<< <peter at makholm.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-bulkmail at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Bulkmail>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Bulkmail


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Bulkmail>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Bulkmail>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Bulkmail>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Bulkmail/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Makholm.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of App::Bulkmail
