package BBS::Universal::Commands.pm;
BEGIN { our $VERSION = '0.001'; }

sub commands_initialize {
	my $self = shift;

	$self->{'debug'}->DEBUG(['Begin Commands initialize']);
	$self->{'COMMANDS'} = {
        'SHOW FULL BBS LIST' => sub {
            my $self = shift;
            $self->bbs_list(FALSE);
            return ($self->load_menu('files/main/bbs_listing'));
        },
        'SEARCH BBS LIST' => sub {
            my $self = shift;
            $self->bbs_list(TRUE);
            return ($self->load_menu('files/main/bbs_listing'));
        },
        'RSS FEEDS' => sub {
            my $self = shift;
            $self->news_rss_feeds();
            return ($self->load_menu('files/main/news'));
        },
        'UPDATE ACCOMPLISHMENTS' => sub {
            my $self = shift;
            $self->users_update_accomplishments();
            return ($self->load_menu('files/main/account'));
        },
        'RSS CATEGORIES' => sub {
            my $self = shift;
            $self->news_rss_categories();
            return ($self->load_menu('files/main/news'));
        },
        'FORUM CATEGORIES' => sub {
            my $self = shift;
            $self->messages_forum_categories();
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES LIST' => sub {
            my $self = shift;
            $self->messages_list_messages();
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES READ' => sub {
            my $self = shift;
            $self->messages_read_message();
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES EDIT' => sub {
            my $self = shift;
            $self->messages_edit_message('EDIT');
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES ADD' => sub {
            my $self = shift;
            $self->messages_edit_message('ADD');
            return ($self->load_menu('files/main/forums'));
        },
        'FORUM MESSAGES DELETE' => sub {
            my $self = shift;
            $self->messages_delete_message();
            return ($self->load_menu('files/main/forums'));
        },
        'UPDATE LOCATION' => sub {
            my $self = shift;
            $self->users_update_location();
            return ($self->load_menu('files/main/account'));
        },
        'UPDATE EMAIL' => sub {
            my $self = shift;
            $self->users_update_email();
            return ($self->load_menu('files/main/account'));
        },
        'UPDATE RETRO SYSTEMS' => sub {
            my $self = shift;
            $self->users_update_retro_systems();
            return ($self->load_menu('files/main/account'));
        },
        'CHANGE ACCESS LEVEL' => sub {
            my $self = shift;
            $self->users_change_access_level();
            return ($self->load_menu('files/main/account'));
        },
        'CHANGE BAUD RATE' => sub {
            my $self = shift;
            $self->users_change_baud_rate();
            return ($self->load_menu('files/main/account'));
        },
        'CHANGE DATE FORMAT' => sub {
            my $self = shift;
            $self->users_change_date_format();
            return ($self->load_menu('files/main/account'));
        },
        'CHANGE SCREEN SIZE' => sub {
            my $self = shift;
            $self->users_change_screen_size();
            return ($self->load_menu('files/main/account'));
        },
        'CHOOSE TEXT MODE' => sub {
            my $self = shift;
            $self->users_update_text_mode();
            return ($self->load_menu('files/main/account'));
        },
        'TOGGLE SHOW EMAIL' => sub {
            my $self = shift;
            $self->users_toggle_permission('show_email');
            return ($self->load_menu('files/main/account'));
        },
        'TOGGLE PREFER NICKNAME' => sub {
            my $self = shift;
            $self->users_toggle_permission('prefer_nickname');
            return ($self->load_menu('files/main/account'));
        },
        'TOGGLE PLAY FORTUNES' => sub {
            my $self = shift;
            $self->users_toggle_permission('play_fortunes');
            return ($self->load_menu('files/main/account'));
        },
        'BBS LIST ADD' => sub {
            my $self = shift;
            $self->bbs_list_add();
            return ($self->load_menu('files/main/bbs_listing'));
        },
        'BBS LISTING' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/bbs_listing'));
        },
        'LIST USERS' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/list_users'));
        },
        'ACCOUNT MANAGER' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/account'));
        },
        'BACK' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/menu'));
        },
        'DISCONNECT' => sub {
            my $self = shift;
            $self->output("\nDisconnect, are you sure (y|N)?  ");
            unless ($self->decision()) {
                return ($self->load_menu('files/main/menu'));
            }
            $self->output("\n");
        },
        'FILE CATEGORY' => sub {
            my $self = shift;
            $self->choose_file_category();
            return ($self->load_menu('files/main/files_menu'));
        },
        'FILES' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/files_menu'));
        },
        'LIST FILES SUMMARY' => sub {
            my $self = shift;
            $self->files_list_summary(FALSE);
            return ($self->load_menu('files/main/files_menu'));
        },
        'UPLOAD FILE' => sub {
            my $self = shift;
            $self->files_upload_choices();
            return ($self->load_menu('files/main/files_menu'));
        },
        'LIST FILES DETAILED' => sub {
            my $self = shift;
            $self->files_list_detailed(FALSE);
            return ($self->load_menu('files/main/files_menu'));
        },
        'SEARCH FILES SUMMARY' => sub {
            my $self = shift;
            $self->files_list_summary(TRUE);
            return ($self->load_menu('files/main/files_menu'));
        },
        'SEARCH FILES DETAILED' => sub {
            my $self = shift;
            $self->files_list_detailed(TRUE);
            return ($self->load_menu('files/main/files_menu'));
        },
        'NEWS' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/news'));
        },
        'NEWS SUMMARY' => sub {
            my $self = shift;
            $self->news_summary();
            return ($self->load_menu('files/main/news'));
        },
        'NEWS DISPLAY' => sub {
            my $self = shift;
            $self->news_display();
            return ($self->load_menu('files/main/news'));
        },
        'FORUMS' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/forums'));
        },
        'ABOUT' => sub {
            my $self = shift;
            return ($self->load_menu('files/main/about'));
        },
	};
	$self->{'debug'}->DEBUG(['End Commands initialize']);
}
1;
