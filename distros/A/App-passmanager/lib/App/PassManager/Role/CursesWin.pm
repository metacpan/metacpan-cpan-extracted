package App::PassManager::Role::CursesWin;
{
  $App::PassManager::Role::CursesWin::VERSION = '1.113580';
}
use Moose::Role;

with 'App::PassManager::Role::Content';

use Curses::UI;
use Scalar::Util 'weaken';

has _ui_options => (
    is => 'rw',
    isa => 'HashRef',
    auto_deref => 1,
    lazy_build => 1,
    accessor => 'ui_options',
);
sub _build__ui_options {    
    return {
        -clear_on_exit => 1,
        -color_support => 1,
        -mouse_support => 0,
    };
}

has '_ui' => (
    is => 'ro',
    isa => 'Curses::UI',
    reader => 'ui',
    lazy_build => 1,
);

# must be lazy otherwise Curses::UI nobbles help output
sub _build__ui {
    my $self = shift;
    my $ui = Curses::UI->new( $self->ui_options );
    $ui->set_binding( sub { $self->abort   }, "\cR" );  # ctrl-r
    $ui->set_binding( sub { $self->cleanup }, "\cQ" );  # ctrl-q
    # $ui->set_binding( sub { $self->cleanup }, "\x1b" ); # escape
    return $ui;
}

has '_windows' => (
    is => 'ro',
    isa => 'HashRef',
    reader => 'win',
    default => sub { {} },
);

has '_win_config' => (
    is => 'ro',
    isa => 'HashRef',
    reader => 'win_config',
    auto_deref => 1,
    lazy_build => 1,
);

sub _build__win_config {
    return {
        -border       => 1, 
        -titlereverse => 0, 
        -padbottom    => 1,
        -ipad         => 1,
    }
}

sub new_root_win {
    my $self = shift;

    $self->win->{status} = $self->ui->add(
        'statuswin', 'Window', 
        -border => 0, 
        -y      => -1, 
        -height => 1,
        -width => -1,
    );
    $self->win->{status}->add('status', 'Label', 
        -text => "Quit: Ctrl-Q",
        -x => 2,
        -width => -1,
        -fg => 'magenta',
    );
}

sub new_base_win {
    my $self = shift;

    $self->new_root_win;

    $self->win->{browse} = $self->ui->add(
        'browse', 'Window', 
        -title => "Browser",
        $self->win_config,
    );

    my $pw = $self->win->{browse}->{'-bw'}; # XXX private?
    my $lbw = int($pw / 3);

    my $cl = $self->win->{browse}->add('category','Listbox',
        -title       => 'Category',
        -width       => $lbw,
        -border      => 1,
        -vscrollbar  => 1,
        -wraparound  => 1,
        -onchange    => sub { $self->service_list },
        -onselchange => sub { $self->service_show },
    );
    $cl->set_binding( sub { $self->delete(
        'Category', $self->data, $cl->get_active_value)
    }, 'd' );
    $cl->set_binding( sub { $self->edit(
        'Category', $self->data, $cl->get_active_value)
    }, 'e' );
    $cl->set_binding( sub { $self->add('Category', $self->data) }, 'a' );

    my $sl = $self->win->{browse}->add('service','Listbox',
        -title       => 'Service',
        -width       => $lbw,
        -x           => $lbw,
        -border      => 1,
        -vscrollbar  => 1,
        -wraparound  => 1,
        -onchange    => sub { $self->entry_list },
        -onselchange => sub { $self->entry_show },
        -onfocus     => sub { $self->entry_show },
    );
    $sl->set_routine('loose-focus', sub { $self->category_list });
    $sl->set_binding( sub { $self->delete(
        'Service', $self->data->{category}->{$cl->get}, $sl->get_active_value)
    }, 'd' );
    $sl->set_binding( sub { $self->edit(
        'Service', $self->data->{category}->{$cl->get}, $sl->get_active_value)
    }, 'e' );
    $sl->set_binding( sub { $self->add(
        'Service', $self->data->{category}->{$cl->get})
    }, 'a' );

    my $el = $self->win->{browse}->add('entry','Listbox',
        -title      => 'Entry',
        -width      => $lbw,
        -x          => (2 * $lbw),
        -border     => 1,
        -vscrollbar => 1,
        -wraparound => 1,
        -onchange   => sub { $self->display_entry },
    );
    $el->set_routine('loose-focus', sub { $self->service_list });
    $el->set_binding( sub { $self->delete('Entry',
        $self->data->{category}->{$cl->get}->{service}->{$sl->get}, $el->get_active_value)
    }, 'd' );
    $el->set_binding( sub { $self->edit('Entry',
        $self->data->{category}->{$cl->get}->{service}->{$sl->get}, $el->get_active_value)
    }, 'e' );
    $el->set_binding( sub { $self->add(
        'Entry', $self->data->{category}->{$cl->get}->{service}->{$sl->get})
    }, 'a' );
}

1;
