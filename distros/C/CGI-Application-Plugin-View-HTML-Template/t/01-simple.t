use strict;
use Test::More tests => 1;


{

package My::App;
use base qw/CGI::Application/;
use CGI::Application::Plugin::View::HTML::Template;

sub setup {
        my $self = shift;
        $self->start_mode('test_rm');
        $self->run_modes(
                'test_rm'   => \&tmpl_test
        );

}

sub tmpl_test {
        my $self = shift;
        my $t = $self->load_tmpl('test.tmpl');
        $self->param('template', $t);
        $self->param('ping', 'Hello World: tmpl_test');
        return;
}

}



my $app = My::App->new(TMPL_PATH=>'test/templates/');
my $output = $app->run();

like($output, qr/---->Hello World: tmpl_test<----/);


