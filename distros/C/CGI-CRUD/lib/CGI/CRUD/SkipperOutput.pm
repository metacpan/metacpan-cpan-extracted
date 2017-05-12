#
# $Id: SkipperOutput.pm,v 1.7 2005/04/01 08:54:46 rsandberg Exp $

package CGI::CRUD::SkipperOutput;

use strict;
use DBI;
use CGI::CRUD::ApacheOutputFastTemplate;

@CGI::CRUD::SkipperOutput::ISA = qw(CGI::CRUD::ApacheOutputFastTemplate);

sub new
{
    my $caller = shift;
    my $self = $caller->SUPER::new(@_);

    # Make sure to define env DBI_DSN, DBI_USER, etc (see man DBI)
    # This should match the connect string in mod_perl_startup.pl (Apache::DBI->connect_on_init)
    unless ($self->{dbh} = DBI->connect(undef,undef,undef,{ PrintError => 1, RaiseError => 0, AutoCommit => 1, }))
    {
        $self->perror("Database server not responding, contact your administrator");
        warn("Can't connect to db, check DBI_DSN, DBI_USER, etc env.");
        return undef;
    }

    return $self;
}

sub form_attrs
{
    my ($caller,$form) = @_;
    $caller->SUPER::form_attrs($form);
    $form->{submit_button_attrs} = qq[class="formbutton" onmouseout="javascript:this.style.color='black';" onmouseover="javascript:this.style.color='red';"];
    return $form;
}

1;
