package potest;

BEGIN {
    use FindBin qw ($RealBin $RealScript);
    use lib $FindBin::RealBin;
    use lib "$FindBin::RealBin/cpanlib";
    chdir $RealBin;
    if ( $ENV{'SERVER_SOFTWARE'} =~ /IIS/ ) {
        #open STDERR, '> iisError.log' || die "Can't write to $RealBin/issError.log: $!\n";
        #binmode STDERR;
        close STDERR;
    }#if
}#BEGIN

$| = 1;

use base 'CGI::Application';
use strict;

use CGI::Application::Plugin::I18N;


sub setup {
    my $self = shift;
    $self->start_mode('test');
    $self->tmpl_path('');
    $self->run_modes(
        'test'        => 'test',
    );

    # Get CGI query object
    my $q = $self->query();

    ### Configure I18N
    $self->i18n_config();

}#sub

sub test {
    my $self = shift;

    # Get CGI query object
    my $q = $self->query();

    $self->localtext_langs( $q->param( 'locale' ) );
    
    my $template = $self->load_tmpl( 'test.html', die_on_bad_params => 0 );
    $template->param(
        {   scriptname        => $RealScript,
            title             => $self->localtext( 'PO file test' ),
            message           => $self->localtext( 'Input locale' ),
            hello             => $self->localtext( 'Hello' ),
            colour            => $self->localtext( 'Colour' ),
            locale            => $q->param( 'locale' ),
        }
    );

    return $template->output();
}#sub


sub teardown {
    my $self = shift;

}#sub

sub cgiapp_prerun {
    my $self = shift;
    my $runmode = shift;
    
    ### Load modules based on runmode
    
}#sub


1;
