
use Test::More 'no_plan';
use strict;
$ENV{CGI_APP_RETURN_ONLY} = 1;

use URI;
use URI::QueryParam;

my $Created_Link;

{
    package WebApp;
    use CGI;
    use CGI::Application;
    use vars qw(@ISA);
    use URI;
    use URI::Escape;
    @ISA = ('CGI::Application');

    use Test::More;
    use CGI::Application::Plugin::LinkIntegrity;

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->run_modes([qw(
            link_okay
            create_link
            bad_user_no_biscuit
        )]);

        my %li_config = (
            secret  => 'extree seekrit',
        );
        if ($self->param('custom_rm')) {
            $li_config{'link_tampered_run_mode'} = 'bad_user_no_biscuit';
        }
        if ($self->param('check')) {
            $li_config{'checksum_param'} = $self->param('check');
        }
        if ($self->param('create_link')) {
            $self->start_mode('create_link');
            $li_config{'disable'} = 1;
        }
        else {
            $self->start_mode('link_okay');
        }
        $self->link_integrity_config(
            %li_config,
        );
    }

    sub link_okay {
        my $self = shift;
        return 'rm=link_okay';
    }
    sub create_link {
        my $self = shift;
        return $self->link($self->param('create_link'));
    }
    sub bad_user_no_biscuit {
        my $self = shift;
        return 'rm=bad_user_no_biscuit';
    }

}
###########################################################################
# Build the link
$ENV{'REQUEST_METHOD'} = 'POST';
$ENV{'SERVER_PORT'}    = '80';
$ENV{'SCRIPT_NAME'}    = '/cgi-bin/app.cgi';
$ENV{'SERVER_NAME'}    = 'www.example.com';
$ENV{'PATH_INFO'}      = '/my/happy/pathy/info';
$ENV{'QUERY_STRING'}   = 'zap=zoom&zap=zub&guff=gubbins&zap=zuzzu';

my $link = URI->new(WebApp->new(PARAMS => {
    create_link => 'http://www.example.com/script.cgi/path/info?p1=v1&p2=v2&p2=v3',
})->run);

# Validate it

$ENV{'REQUEST_METHOD'} = 'POST';
$ENV{'SERVER_PORT'}    = $link->port;
$ENV{'SCRIPT_NAME'}    = $link->path;
$ENV{'SERVER_NAME'}    = $link->authority;
$ENV{'PATH_INFO'}      = '';
$ENV{'QUERY_STRING'}   = $link->query;

is(WebApp->new->run, 'rm=link_okay', 'link_okay');

# remove the _checksum from the query - this should invalidate it
my $checksum = $link->query_param_delete('_checksum');
$ENV{'QUERY_STRING'}   = $link->query;

is(WebApp->new->run, '<h1>Access Denied</h1>', 'link_tampered (checksum removed)');

# add a bogus checksum - this should invalidate it
my $qf = $link->query_form_hash;
$qf->{'_checksum'} = 'xxxx';
$qf = $link->query_form_hash($qf);

$ENV{'QUERY_STRING'}   = $link->query;

is(WebApp->new->run, '<h1>Access Denied</h1>', 'link_tampered (checksum changed)');


# restore original checksum - this should revalidate it
$qf = $link->query_form_hash;
$qf->{'_checksum'} = $checksum;
$qf = $link->query_form_hash($qf);

$ENV{'QUERY_STRING'}   = $link->query;

is(WebApp->new->run, 'rm=link_okay', 'link_okay (original checksum added again)');
