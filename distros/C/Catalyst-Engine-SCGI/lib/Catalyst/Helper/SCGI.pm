package Catalyst::Helper::SCGI;

use warnings;
use strict;
use Config;
use File::Spec;

our $VERSION = '0.03';

=head1 NAME

Catalyst::Helper::SCGI - SCGI helper to create a scgi runner script to run the SCGI engine.

=cut

=head1 SYNOPSIS

use the helper to build the view module and associated templates.

	$ script/myapp_create.pl SCGI
	
=head1 DESCRIPTION

This helper module creates the runner script for the SCGI engine.

=cut

=head2 $self->mk_stuff ( $c, $helper, @args )
 
	Create SCGI runner script

=cut

sub mk_stuff {
    my ( $self, $helper, @args ) = @_;

    my $base = $helper->{base};
    my $app  = lc($helper->{app});

    $helper->render_file( "scgi_script",
        File::Spec->catfile( $base, 'script', "$app\_scgi.pl" ) );
    chmod 0700, "$base/script/$app\_scgi.pl";
}

=head1 AUTHOR

Orlando Vazquez, C< <orlando at 2wycked.net> >

=head1 BUGS

Please report any bugs or feature requests to
C<orlando at 2wycked.net>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2009 Orlando Vazquez, all rights reserved.
Copyright 2006 Victor Igumnov, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__

__scgi_script__
#!/usr/bin/env perl

BEGIN { $ENV{CATALYST_ENGINE} ||= 'SCGI' }

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use FindBin;
use lib "$FindBin::Bin/../lib";
use [% app %];

my $help = 0;
my ( $port, $detach );
 
GetOptions(
    'help|?'      => \$help,
    'port|p=s'  => \$port,
    'daemon|d'    => \$detach,
);

pod2usage(1) if $help;

[% app %]->run( 
    $port, 
    $detach,
);

1;

=head1 NAME

[% app %]_scgi.pl - Catalyst SCGI

=head1 SYNOPSIS

[% app %]_scgi.pl [options]
 
 Options:
   -? -help     display this help and exits
   -p -port    	Port to listen on
   -d -daemon   daemonize

=head1 DESCRIPTION

Run a Catalyst application as SCGI.

=head1 AUTHOR

Orlando Vazquez C<< orlando@2wycked.net >>

=head1 COPYRIGHT

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
