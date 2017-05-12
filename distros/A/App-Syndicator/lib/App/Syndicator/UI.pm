use MooseX::Declare;

class App::Syndicator::UI  {
    use MooseX::Types::Moose 'Str';
    use App::Syndicator::Types ':all';
    use Curses::UI;

    has curses => ( 
        is => 'ro',
        isa => Curses_T,
        required => 1, 
        default =>  sub { 
            Curses::UI->new(
                -color_support => 1,
                -clear_on_exit => 1,
                -mouse_support => 0,
            ) 
        }, 
        handles => [qw/set_binding mainloop schedule_event/]
    );
    
    has db => (
        is => 'ro',
        isa => DB_T,
        required => 1,
    );

    has main_window => (
        is => 'rw',
        isa => Window_T,
        required => 1,
        lazy_build => 1
    );

    has status_window => (
        is => 'rw',
        isa => Window_T,
        required => 1,
        lazy_build => 1
    );

    has header_window => (
        is => 'rw',
        isa => Window_T,
        required => 1,
        lazy_build => 1
    );

    has list_window => (
        is => 'rw',
        isa => Window_T,
        required => 1,
        lazy_build => 1
    );

    has viewer => ( 
        is => 'rw',
        isa => TextViewer_T, 
        required => 1,
        lazy_build => 1,
    );

    has header_bar => ( 
        is => 'rw',
        isa => TextViewer_T, 
        required => 1,
        lazy_build => 1,
    );

    has status_bar => ( 
        is => 'rw',
        isa => TextViewer_T, 
        required => 1,
        lazy_build => 1,
    );

    has message_list => ( 
        is => 'rw',
        isa => ListBox_T, 
        required => 1,
        lazy_build => 1,
    );

    has focus => (
        is => 'rw',
        isa => Str,
        default => 'message_list'
    );

our $help_text = << 'EOD';
Key bindings

f     - fetch messages
d     - delete selected messages
r     - toggle read
s     - toggle star
j     - move up
k     - down down
/     - search forwards
?     - search backwards
space - select or de-select
tab   - switch focus
h     - help (this screen)
q     - quit

Links

* CPAN    - http://search.cpan.org/~rge/
* GitHub  - http://github.com/robinedwards/App-Syndicator
* Tweeter - @thefeatheryone
EOD

    method _build_status_window {
        my $status_win = $self->curses->add(
            'status', 'Window',
            -y => 0,
            -height => 1,
            -bg => 'blue',
            -fg => 'white',
        );

        $self->status_window($status_win);
    }

    method _build_main_window {
        my $main_win = $self->curses->add(
            'main', 'Window',
            -y => 12,
            -border => 0,
        );

        $self->main_window($main_win);
    }

    method _build_header_window {
        my $header_win = $self->curses->add(
            'header', 'Window',
            -y => 11,
            -height => 1,
            -bg => 'blue',
            -fg => 'white',
        );

        $self->header_window($header_win);
    }

    method _build_list_window {
        my $list_win = $self->curses->add(
            'list', 'Window',
            -y => 1,
            -height => 10,
            -border => 0,
        );

        $self->list_window($list_win);
    }

    method BUILD {
        my $status_bar = $self->status_window->add(
            'status', 'TextViewer',
            -bg => 'blue',
            -fg => 'white',
        );
        $self->status_bar($status_bar);

        my $textview = $self->main_window->add(
            'reader', 'TextViewer',
            -wrapping => 1,
            -vscrollbar => 'right',
        );
        $self->viewer($textview);

        my $header_bar = $self->header_window->add(
            'header', 'TextViewer',
            -bg => 'blue',
            -fg => 'white',
        );
        $self->header_bar($header_bar);

        my $listbox = $self->list_window->add(
            'list', 'Listbox',
            -multi => 1,
            -values => [1],
            -labels => {1 => 'No messages'},
            -onselchange => sub { $self->_message_list_change(@_) },
            -vscrollbar => 'right',
        );
        $self->message_list($listbox);

        $self->_bind_keys;
        $self->_init;
    }

    method _init {
        $self->_populate_message_list(
            $self->db->all_messages
        );
        $self->home;
        $self->_update_message_count;
        $self->curses->layout;
        $self->switch_focus;
    }

    method _bind_keys {
        $self->set_binding( sub { exit }, "q");
        $self->set_binding( sub { $self->fetch_messages }, "f");
        $self->set_binding( sub { $self->message_delete }, "d");
        $self->set_binding( sub { $self->message_toggle_read }, "r");
        $self->set_binding( sub { $self->message_toggle_star }, "s");
        $self->set_binding( sub { $self->home }, "h");
        $self->set_binding( sub { $self->switch_focus }, "\t");
    }

    method message_delete {
        for my $id ($self->_selected_messages) {
            my $pos = $self->message_list->{-ypos};
            delete $self->message_list->labels->{$id};
            
            my $msg = $self->db->lookup($id);
            $msg->delete;
            $self->db->store($msg);
            $self->db->dec_unread unless $msg->is_read;
            $self->db->dec_total;

            $self->message_list->values([
                grep { $id ne $_ } 
                    @{$self->message_list->values}
            ]);

            # select next in list
            $self->message_list->{-ypos} 
                = $pos <= $self->message_list->{-max_selected}
                    ? $pos : $self->message_list->{-max_selected};

            $self->_message_list_change;
        }

        $self->_update_message_count;
    }

    method message_toggle_read {
        for my $id ($self->_selected_messages) {
            my $msg = $self->db->lookup($id);

            $msg->is_read(!$msg->is_read);

            if ($msg->is_read) {
                $self->message_list->labels->{$id}
                    = $msg->render_title;
                $self->db->dec_unread;
            }
            else {
                $self->message_list->labels->{$id}
                    = $msg->render_title;
                $self->db->inc_unread;
            }

            $self->db->store($msg);
        }

        $self->_update_message_count;
        $self->curses->layout;
    }

    method message_toggle_star {
        for my $id ($self->_selected_messages) {
            my $msg = $self->db->lookup($id);

            $msg->star(!$msg->star);

            if ($msg->star) {
                $self->message_list->labels->{$id}
                    = $msg->render_title;
            }
            else {
                $self->message_list->labels->{$id}
                    = $msg->render_title;
            }

            $self->db->store($msg);
        }

        $self->_update_message_count;
        $self->curses->layout;
    }

    method fetch_messages {
        $self->_status_text('Fetching messages..');
        
        $self->db->fetch;
        $self->_populate_message_list($self->db->all_messages);
       
        $self->_update_message_count;
        $self->curses->layout;
    }

    method home {
        $self->_status_text('Help');
        $self->_viewer_text($help_text);
    }

    method switch_focus {
        if ($self->focus eq 'message_list') {
            $self->focus('viewer');
            $self->viewer->focus;
        }
        else {
            $self->focus('message_list');
            $self->message_list->focus;
        }
    }

    method _selected_messages {
        my @selected = $self->message_list->get;
        
        unless (scalar @selected) {
            @selected = ($self->message_list->get_active_value);
        }

        return @selected;
    }

    method _populate_message_list (Message_T @messages) {
        $self->message_list->values( 
            [  map { $_->id } @messages ]
        );

        $self->message_list->labels(
            { map { 
                $_->id => $_->render_title
                } @messages 
            }
        );

        $self->message_list->focus;
    }

    method _message_list_change {
        my $msg_id = $self->message_list->get_active_value;
        
        return unless defined $msg_id;

        my $msg = eval { $self->db->lookup($msg_id) };
        return unless defined $msg;

        $self->_render_message($msg);
        $self->message_list->focus;
    }

    method _update_message_count {
        $self->_status_text(
            $self->db->total. " messages, "
            . $self->db->unread
            . " unread."
        );
    }

    method _render_message (Message_T $msg) {
        my $title = $msg->published->dmy('-')
            .' '.$msg->published->hms(':')
            .' - '.$msg->title ;

        $self->header_bar->text($title);
        $self->header_bar->focus;

        $self->_viewer_text($msg->body."\n\n".$msg->link);
    }
    
    method _viewer_text (Str $text){
        $self->viewer->text($text);
        $self->viewer->cursor_to_home;
        $self->curses->layout;
    }

    method _status_text (Str $text?) {
        $text =~ s/\n//g;

        $self->status_bar->text(
            "App::Syndicator | $text"
        );
        
        $self->curses->layout;
    }

}
