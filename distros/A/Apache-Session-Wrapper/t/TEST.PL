#!perl

use strict;
use warnings;


my $runner = Apache::TestRunPerl::Custom->new()->run(@ARGV);

# The custom module
package Apache::TestRunPerl::Custom;

use base qw(Apache::TestRunPerl);

use File::Spec;
use IO::File;


sub configure
{
    my $self = shift;

    my $conf_file = $self->_conf_file();
    my $skip_file = File::Spec->catfile( $self->{test_config}{vars}{t_conf}, 'skip' );

    for my $file ( $conf_file, $skip_file )
    {
        if ( -f $file )
        {
            unlink $file
                or die "Cannot unlink $file: $!";
        }
    }

    $self->SUPER::configure(@_);

    if ( $self->{test_config}{server}{rev} >= 2 )
    {
        my $apreq2 = $self->{test_config}->find_apache_module('mod_apreq2.so');

        if ($apreq2)
        {
            $self->_write_apreq_conf( "LoadModule apreq_module $apreq2" );
        }
        else
        {
            $self->_write_apreq_conf('');
            open my $fh, '>', $skip_file
                or die "Cannot write to $skip_file: $!";
        }
    }
    else
    {
        $self->_write_apreq_conf('');
    }
}

sub _conf_file { File::Spec->catfile( $_[0]->{test_config}{vars}{t_conf}, 'apreq2.conf' ) }

sub _write_apreq_conf
{
    my $self    = shift;
    my $content = shift;

    my $conf_file = $self->_conf_file();

    open my $fh, '>', $conf_file
        or die "Cannot write to $conf_file: $!";
    print $fh $content . "\n"
        or die "Cannot write to $conf_file: $!";
    close $fh
        or die "Cannot write to $conf_file: $!";
}


1;
