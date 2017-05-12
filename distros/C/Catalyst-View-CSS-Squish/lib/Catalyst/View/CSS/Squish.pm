package Catalyst::View::CSS::Squish;

use strict;
use warnings;

use base qw/Catalyst::View/;

our $VERSION='0.02';

use Carp qw/croak/;
use CSS::Squish;
use Data::Dump qw/dump/;
use Path::Class::File;

sub process {
    my ($self,$c) = @_;
    croak 'No CSS files specified in $c->stash->{template}'
        unless defined $c->stash->{template};
    my (@files) = ( ref $c->stash->{template} eq 'ARRAY' ?
        @{ $c->stash->{template} } : 
	split /\s+/, $c->stash->{template} );
    # map files to INCLUDE_PATH
    my $home=$self->config->{INCLUDE_PATH} || $c->path_to('root');
    @files = map { 
       Path::Class::File->new( $home, $_);
    } @files;
    # feed them to CSS::Squish and set the body.
    $c->res->body( CSS::Squish->concatenate(@files) );
}

=head1 NAME

Catalyst::View::CSS::Squish - Concenate your CSS files.

=head1 SYNOPSIS

    ./script/myapp_create.pl view Squish CSS::Squish

    sub css : Local {
	my ($self,$c) = @_;
	$c->stash->{template} = [ qw|/css/small.css /css/big.css| ];
	# or "/css/small.css /css/big.css"
        $c->forward($c->view('Squish'));
    }

=head1 DESCRIPTION

Take a set of CSS files and integrate them into one big file using 
L<CSS::Squish>.  The files are read from the 'template' stash variable,
and can be provided as a hashref or a space separated scalar.

=head1 CONFIG

=head2 INCLUDE_PATH 

The path where we should look for CSS files. Will default to the project
'root' dir under the home directory.

=head1 SEE ALSO

L<Catalyst> , L<Catalyst::View>, L<CSS::Squish>

=head1 AUTHOR

Marcus Ramberg C<mramberg@cpan.org>.

=head1 THANKS

To Jesse Vincent for pointing me towards this module.

=head1 LICENSE

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut 

1;
