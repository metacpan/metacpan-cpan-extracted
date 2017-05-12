#------------------------------------------------------------------------------- 
# 
# File: include.pm
# Version: 0.1
# Author: Jeremy Wall
# Definition: This is the handler for plain text blocks in a template.
#             It basically just returns the text unchanged. I made it a
#             handler just in case we needed to do something to plain text
#             later on. 
#
#--------------------------------------------------------------------------
package Bricklayer::Templater::Handler::common::include;
use Bricklayer::Templater::Handler;
use Carp;
use base qw(Bricklayer::Templater::Handler);

sub run {
    my $self = shift;
    my $arg  = shift;
    my $App = $self->app();
    my $file = $self->attributes()->{file} or confess("no file requested");
        
    my $content = $App->load_template_file($file)
    	unless $self->{FileCache}{$file};
    $self->{FileCache}{$file} = $content
    	unless $_[0]->{FileCache}{$file};
    confess("no contents in file: $file") unless $content;
    $App->run_sequencer($self->{FileCache}{$file}, $arg);
    return;
}


return 1;
