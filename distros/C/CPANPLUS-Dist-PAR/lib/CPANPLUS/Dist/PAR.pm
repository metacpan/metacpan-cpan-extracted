package CPANPLUS::Dist::PAR;
use strict;

use vars    qw[@ISA $VERSION];
use base    'CPANPLUS::Dist::Base';

use CPANPLUS::Error;
use File::Basename              qw[basename];
use Params::Check               qw[check];
use Module::Load::Conditional   qw[can_load];
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';

$VERSION =  '0.02';

local $Params::Check::VERBOSE = 1;

=head1 NAME

CPANPLUS::Dist::PAR - CPANPLUS distribution class to create PAR archives

=head1 SYNOPSIS

    use CPANPLUS::Backend;
    
    my $cb  = CPANPLUS::Backend->new;
    my $mod = $cb->module_tree('Some::Module');
    
    $mod->test( format => 'CPANPLUS::Dist::PAR' );

=head1 DESCRIPTION

Creates a C<PAR> distribution of a CPAN module, using the 
C<CPANPLUS::Dist::*> plugin structure.

See the C<CPANPLUS::Module> manpage how to pass formats to the install
methods.

See the C<PAR::Dist> manpage for details about the generated archives.

=cut

### we can't install things withour our dependencies.
sub format_available { 
    return unless can_load( modules => {
                            'PAR::Dist' => 0 
                        } );
    return 1;
}

sub create { 
    ### just in case you already did a create call for this module object
    ### just via a different dist object
    my $dist        = shift;
    my $self        = $dist->parent;
    my $dist_cpan   = $self->status->dist_cpan;
    $dist           = $self->status->dist   if      $self->status->dist;
    $self->status->dist( $dist )            unless  $self->status->dist;

    my $cb   = $self->parent;
    my $conf = $cb->configure_object;
    
    $dist->SUPER::create( @_ ) or return;
    
    msg( loc("Creating PAR dist of '%1'", $self->name), 1);

    ### par::dist is noisy, silence it
    ### XXX this doesn't quite work -- restoring STDOUT still has
    ### it closed
    #*STDOUT_SAVE = *STDOUT; close *STDOUT;
    my $par = eval {
        ### pass name and version explicitly, as parsing doesn't always
        ### work
        PAR::Dist::blib_to_par( 
            path    => $self->status->extract,
             version => $self->package_version,
             name    => $self->package_name,
        );
    };          
    
    ### error?
    if( $@ or not $par or not -e $par ) {
        error(loc("Could not create PAR distribution of %1: %2",
                  $self->name, $@ ));
        return;                  
    }

    my ($to,$fail);
    MOVE: {
        my $dir = File::Spec->catdir(
                        $conf->get_conf('base'),
                        CPANPLUS::Internals::Utils
                           ->_perl_version(perl => $^X),
                        $conf->_get_build('distdir'),
                        'PAR'
                    );      
        my $to  = File::Spec->catfile( $dir, basename($par) );

        $cb->_mkdir( dir => $dir )              or $fail++, last MOVE;                     
        $cb->_move( file => $par, to => $to )   or $fail++, last MOVE;                     
        msg(loc("PAR distribution written to: '%1'", $to), 1);
    
        $dist->status->dist( $to );
    } 
    
    return $dist->status->created(1) unless $fail;
    return;
}

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This module is copyright (c) 2006 Jos Boumans <kane@cpan.org>. 
All rights reserved.

This library is free software; you may redistribute and/or modify 
it under the same terms as Perl itself.

=head1 SEE ALSO

L<CPANPLUS::Backend>, L<CPANPLUS::Module>, L<CPANPLUS::Dist>, 
C<cpan2dist>, C<PAR::Dist>

=cut

# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:

1;
