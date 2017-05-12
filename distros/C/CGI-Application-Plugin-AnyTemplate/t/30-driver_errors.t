use strict;
use Test::More 'no_plan';

{
    package WebApp;
    use CGI::Application;
    use vars '@ISA';
    @ISA = ('CGI::Application');
    use Test::More;
    use CGI::Application::Plugin::AnyTemplate;
    use lib 't/tlib';

    sub setup {
        my $self = shift;
        $self->header_type('none');
        $self->start_mode('simple');
        $self->run_modes([qw/simple/]);

        $self->template('non_existent')->config(
            default_type  => '___NON_EXISTENT__',
        );
        $self->template('poorly_implemented1')->config(
            default_type  => 'MyCAPATDriver1',
        );
        $self->template('poorly_implemented2')->config(
            default_type  => 'MyCAPATDriver2',
        );
        $self->template('poorly_implemented3')->config(
            default_type  => 'MyCAPATDriver3',
        );
        $self->template('poorly_implemented4')->config(
            default_type  => 'MyCAPATDriver4',
        );
    }

    sub simple {
        my $self = shift;

        my $template;
        eval {
            $template = $self->template('non_existent')->load;
        };
        ok($@, 'non existent driver');
        eval {
            $template = $self->template('poorly_implemented1')->load;
        };
        ok($@, 'poorly implemented driver: missing init');

        $template = $self->template('poorly_implemented2')->load;
        eval {
            $template->output;
        };
        like($@, qr/render_template.*virtual/, 'poorly implemented driver - does not provide render_template method');
        '';
    }
}

WebApp->new->run;
