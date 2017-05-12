#
# $Id: CGIOutputFastTemplate.pm,v 1.5 2005/01/27 23:30:50 scottb Exp $
#

package CGI::CRUD::CGIOutputFastTemplate;

use strict;
use CGI;
use DBI;
use CGI::AutoForm;
use CGI::FastTemplate;
use CGI::CRUD::Output;

@CGI::CRUD::CGIOutputFastTemplate::ISA = qw(CGI::CRUD::Output);

# CGI::FastTemplate path for templates
# May override by setting CRUDDY_FAST_TEMPLATE_PATH environment
# variable (e.g. SetEnv)
my $DEFAULT_TPL_PATH = '/var/www/tpl';

# CGI::FastTemplate 'main' template
# May override by setting CRUDDY_FAST_TEMPLATE_MAIN environment
# variable (e.g. SetEnv)
# -or-
# as a second argument to the C<output> method call
my $DEFAULT_TPL_MAIN = 'cruddy.tpl';


# May return undef if db connect error
sub new
{
    my $caller = shift;
    my ($q,$defaults) = @_;

    my $self = $caller->SUPER::new(@_);

    # Make sure to define env DBI_DSN, DBI_USER, etc (see man DBI)
    unless ($self->{dbh} = DBI->connect(undef,undef,undef,{ PrintError => 1, RaiseError => 0, AutoCommit => 1, }))
    {
        $self->perror("Database server not responding, contact your administrator");
        warn("Can't connect to db, check DBI_DSN, DBI_USER, etc env.");
        return undef;
    }

    $self->{cgi} = $q;
    $self->{user} = $q->remote_user();

    my %params = $q->Vars;

    my ($key,$val);
    while (($key,$val) = each(%params))
    {
        my @vals = split("\0",$params{$key});
        $params{$key} = \@vals if @vals > 1;
    }

    $self->{q} = \%params;

    $self->{tpl_vars} = $defaults;

    return $self;
}

sub form_attrs
{
    my ($caller,$form) = @_;
    $caller->SUPER::form_attrs($form);
    $form->{GT} = qq[WIDTH="80%" CELLPADDING="5" CELLSPACING="0" BORDER="0"];
    $form->{VFL} = qq[WIDTH="40%" ALIGN="RIGHT"];
    $form->{submit_button_attrs} = qq[class="formbutton" onmouseout="javascript:this.style.color='black';" onmouseover="javascript:this.style.color='red';"];
    return $form;
}

##at should somehow cache templates
##at Accept scalar references
sub output
{
    my ($self,$out,$tplf) = @_;
    $tplf = $ENV{CRUDDY_FAST_TEMPLATE_MAIN} || $DEFAULT_TPL_MAIN unless $tplf;

    my $tpl = new CGI::FastTemplate($ENV{CRUDDY_FAST_TEMPLATE_PATH} || $DEFAULT_TPL_PATH);
##at should check return value because an OS call was done
    $tpl->define(main => $tplf);
    $self->{tpl_vars}{BODY} = (ref($out) ? $$out : $out) if defined($out);
    $tpl->assign($self->{tpl_vars});
    $tpl->parse(CONTENT => 'main');
    my $gob = $tpl->fetch('CONTENT');

    print $self->{cgi}->header, $$gob;
    return 1;
}

1;
