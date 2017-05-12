#
# This file is part of App-Magpie
#
# This software is copyright (c) 2011 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::Magpie::Action::WebStatic;
# ABSTRACT: webstatic command implementation
$App::Magpie::Action::WebStatic::VERSION = '2.010';
use DateTime;
use File::Copy;
use LWP::Simple;
use Moose;
use ORDB::CPAN::Mageia;
use Parse::CPAN::Packages::Fast;
use Path::Tiny;
use RRDTool::OO;
use Readonly;
use Template;

use App::Magpie::Constants qw{ $SHAREDIR };


with 'App::Magpie::Role::Logging';

my $datadir = path( File::HomeDir->my_dist_data( "App-Magpie", { create=>1 } ) );
my $rrdsdir = $datadir->child( "rrds" );

my $rrdvers = $rrdsdir->child( "version" );
my %rrdfile = (
    mga_mods   => $rrdsdir->child( "mageia-modules.rrd" ),
    mga_dists  => $rrdsdir->child( "mageia-dists.rrd" ),
    cpan_mods  => $rrdsdir->child( "cpan-modules.rrd" ),
    cpan_dists => $rrdsdir->child( "cpan-dists.rrd" ),
);
my %rrd;




sub run {
    my ($self, $opts) = @_;
    $self->_migrate_and_create_rrds_if_needed;

    # -- first, update the rrd files
    $self->log( "** updating rrd files" );

    my $mgamods = ORDB::CPAN::Mageia::Module->count;
    $rrd{mga_mods}->update( $mgamods );
    $self->log_debug( "mageia modules: $mgamods" );

    my $mgadists = ORDB::CPAN::Mageia->selectcol_arrayref(
        'SELECT DISTINCT dist FROM module ORDER BY dist'
    );
    my $nbmgadists = scalar @$mgadists;
    $rrd{mga_dists}->update( $nbmgadists );
    $self->log_debug( "mageia dists: $nbmgadists" );

    my $modpkg = $datadir->child( "02packages.details.txt.gz" );
    my $src    = "http://cpan.cpantesters.org/modules/02packages.details.txt.gz";
    mirror( $src, $modpkg->stringify );
    my $p = Parse::CPAN::Packages::Fast->new($modpkg->stringify);
    my $cpanmods  = $p->package_count;
    my $cpandists = $p->distribution_count;
    $rrd{cpan_mods}->update( $cpanmods );
    $self->log_debug( "cpan modules: $cpanmods" );
    $rrd{cpan_dists}->update( $cpandists );
    $self->log_debug( "cpan dists: $cpandists" );


    # -- create the web site
    $self->log( "** creating web site" );
    $opts->{directory} =~ s!/$!!;
    my $dir = path( $opts->{directory} . ".new" );
    $dir->remove_tree( { safe => 0 } ); $dir->mkpath;

    # images
    $self->log_debug( "images:" );
    my $imgdir = $dir->child( "images" );
    $imgdir->mkpath;
    $self->log_debug( " - mageia modules" );
    $rrd{mga_mods}->graph(
        image => $imgdir->child("mgamods.png"),
        width => 800,
        title => 'Number of available Perl modules in Mageia Linux',
        start => DateTime->new(year=>2012)->epoch,
        draw  => {
            thickness => 2,
            color     => '0000FF',
        },
        units_exponent => 0,
    );

    # template toolkit
    $self->log_debug( "template toolkit processing" );
    my $tt = Template->new({
        INCLUDE_PATH => $SHAREDIR->child("webstatic"),
        INTERPOLATE  => 1,
    }) or die "$Template::ERROR\n";

    my $vars = {
        mgamods  => $mgamods,
        mgadists => $nbmgadists,
        date     => scalar localtime,
    };
    $tt->process('index.tt2', $vars, $dir->child("index.html")->stringify)
        or die $tt->error(), "\n";

    # rrd files
    $self->log_debug( "copying rrd files" );
    my $rrdsubdir = $dir->child( "rrds" );
    $rrdsubdir->mkpath;
    foreach my $f ( keys %rrdfile ) {
        copy( $rrdfile{$f}->stringify, $rrdsubdir->stringify );
    }

    # update website in one pass: remove previous version, replace it by new one
    $self->log( "** updating web site" );
    my $olddir = path( $opts->{directory} );
    $olddir->remove_tree( { safe => 0 } );
    move( $dir->stringify, $olddir->stringify );
}


# -- private methods

sub _migrate_and_create_rrds_if_needed {
    my $self = shift;
    $rrdsdir->mkpath;

    # v0 - too bad, drop existing files
    my $rrdfile = $datadir->child( "modules.rrd" );
    if ( -e $rrdfile ) {
        $self->log( "converting from v0" );
        $self->log_debug( "removing $rrdfile" );
        $rrdfile->remove
    }

    # create rrds
    $self->log("creating rrd files");
    foreach my $f ( keys %rrdfile ) {
        $rrd{$f} = RRDTool::OO->new( file=>$rrdfile{$f} );
        next if -f $rrdfile{$f};
        $self->log_debug( "creating $rrdfile{$f}" );
        $rrd{$f}->create(
            step        => 60*60*24,            # 1 measure per day
            data_source => {
                name => "nb",
                type => "GAUGE",
            },
            archive => { rows => 365 * 100 },   # data kept for 100 years (!)
        );
    }

    # saving rrd schema version
    $self->log_debug( "saving schema version" );
    my $fh = $rrdvers->openw;
    $fh->print( "1" );
    $fh->close;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Magpie::Action::WebStatic - webstatic command implementation

=head1 VERSION

version 2.010

=head1 SYNOPSIS

    my $webstatic = App::Magpie::Action::WebStatic->new;
    $webstatic->run;

=head1 DESCRIPTION

This module implements the C<webstatic> action. It's in a module of its
own to be able to be C<require>-d without loading all other actions.

=head1 METHODS

=head2 run

    App::Magpie::Action::WebStatic->new->run( $opts );

Update the count of available modules in Mageia, and create a static
website with some information on them.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
