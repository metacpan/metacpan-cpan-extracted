use strict;
use warnings;
package Chat::iFly;

use HTTP::Thin;
use HTTP::Request::Common;
use JSON;
use URI;
use Ouch;
use Moo;

my $convert_to_string = sub { "$_[0]" };

=head1 NAME

Chat::iFly - An interface to the iFlyChat service.

=head1 SYNOPSIS

 use Chat::iFly;
 
 my $chat = Chat::iFly->new(
    api_key                 => 'afsdadfafdsadfsafsd',
    static_asset_base_uri   => '//www.myserver.com/ifly',
    ajax_uri                => '//www.myserver.com/chat/login'
 );
 
 my $user = {
    id          => 4321,
    name        => 'Joe Blow',
    avatar_uri  => '//www.myserver.com/uploads/joe.blow.avatar.jpg',
    profile_uri => '//www.myserver.com/users/4321',
 };
 
 my $html_to_inline_into_page = $chat->render_html($user); 
 my $response_to_chat_login = $chat->render_ajax($user);


=head1 DESCRIPTION

A wrapper needed to authenticate to L<iflychat.com>.

=head2 Setup

You'll need to go here L<https://iflychat.com/iflyapi/index> and register for an API Key. You'll specify that using C<api_key> passed to the constructor.

You'll need to copy the C<public> folder from this distribution onto your web server somewhere. You'll specify where that is using the C<static_asset_base_uri> passed tot he constructor.

You'll need to build 2 things into your web server:

=over

=item Inline HTML

You'll need to inline the result of C<render_html> into any web page where you want the chat to appear.

=item AJAX Method

You'll need to set up an ajax method in your app that returns the result of C<render_ajax>. You'll pass the URL where that can be found into the constructor using C<ajax_uri>.

=back

And finally you need to call C<update_settings> to tell the iFly servers what your settings are. 


=head1 METHODS

The following methods are available.

=head2 new ( params ) 

Constructor.

=over

=item params

A hash of parameters.

=over

=item api_key

Required. The key generated on the iFly Chat Dashboard.

=cut

has api_key => (
    is          => 'rw',
    required    => 1,
);

=item static_asset_base_uri

Required. The URL where you have installed the static files found in the C<public> folder of the L<Chat::iFly> github repository.

=cut

has static_asset_base_uri => (
    is          => 'rw',
    required    => 1,
);

=item ajax_uri

Required. The URL where you have installed the response to the C<render_ajax> method.

=cut

has ajax_uri => (
    is          => 'rw',
    required    => 1,
);

=item minimize_chat_user_list

Defaults to C<2>. Must be 1 or 2. Minimize online user list by default. 2 means Yes. 1 means No.

=cut

has minimize_chat_user_list => (
    is          => 'rw',
    default     => sub { '2' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'minimize_chat_user_list must be 1 or 2', 'minimize_chat_user_list') unless ($_[0] ~~ [1,2]);
    }
);

=item enable_search_bar

Defaults to C<1>. Must be 1 or 2. Show search bar in online user list. 1 means Yes. 2 means No.

=cut

has enable_search_bar => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'enable_search_bar must be 1 or 2', 'enable_search_bar') unless ($_[0] ~~ [1,2]);
    }
);

=item chat_topbar_color

Defaults to C<#222222>. Choose the color of the top bar in the chat.

=cut

has chat_topbar_color => (
    is          => 'rw',
    default     => sub { '#222222' },
);

=item chat_topbar_text_color

Defaults to C<#FFFFFF>. Choose the color of the text in top bar in the chat.

=cut

has chat_topbar_text_color => (
    is          => 'rw',
    default     => sub { '#FFFFFF' },
);

=item font_color

Defaults to C<#222222>. Choose the color of the text in the chat.

=cut

has font_color => (
    is          => 'rw',
    default     => sub { '#222222' },
);

=item chat_list_header

Defaults to C<Chat>. This is the text that will appear in header of chat list.

=cut

has chat_list_header => (
    is          => 'rw',
    default     => sub { 'Chat' },
);

=item support_chat_init_label

Defaults to C<Chat with us>. The label for B<Start Chat> button, which when clicked upon will launch chat.

=cut

has support_chat_init_label => (
    is          => 'rw',
    default     => sub { 'Chat with us' },
);

=item support_chat_box_header

Defaults to C<Support>. This is the text that will appear as header of chat box.

=cut

has support_chat_box_header => (
    is          => 'rw',
    default     => sub { 'Support' },
);

=item support_chat_box_company_name

Defaults to C<Support Team>. Name of your team or company which the visitors will see in the chat box.

=cut

has support_chat_box_company_name => (
    is          => 'rw',
    default     => sub { 'Support Team' },
);

=item support_chat_box_company_tagline

Defaults to C<Ask us anything...>. Your team/company tagline.

=cut

has support_chat_box_company_tagline => (
    is          => 'rw',
    default     => sub { 'Ask us anything...' },
);

=item support_chat_auto_greet_enable

Defaults to 1. Must be 1 or 2. 1 means that the auto greeting is enabled.

=cut

has support_chat_auto_greet_enable => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'support_chat_auto_greet_enable must be 1 or 2', 'support_chat_auto_greet_enable') unless ($_[0] ~~ [1,2]);
    }
);

=item support_chat_auto_greet_message

Defaults to C<Hi there! Welcome to our website. Let us know if you have any query!>. This is the text of an auto greeting message which will be displayed to visitors.

=cut

has support_chat_auto_greet_message => (
    is          => 'rw',
    default     => sub { 'Hi there! Welcome to our website. Let us know if you have any query!' },
);


=item support_chat_auto_greet_time

Defaults to 1. The delay, in seconds, after which the first time visitors will be shown auto greeting message.

=cut

has support_chat_auto_greet_time => (
    is          => 'rw',
    coerce      => $convert_to_string,
    default     => sub { '1' },
);

=item support_chat_init_label_off

Defaults to C<Leave Message>. The label for B<Leave Message> button, which when clicked upon will offline form.

=cut

has support_chat_init_label_off => (
    is          => 'rw',
    default     => sub { 'Leave Message' },
);

=item support_chat_offline_message_desc

Defaults to C<Hello there. We are currently offline. Please leave us a message. Thanks.>. This is the description shown in Support Chat Offline window.

=cut

has support_chat_offline_message_desc => (
    is          => 'rw',
    default     => sub { 'Hello there. We are currently offline. Please leave us a message. Thanks.' },
);

=item support_chat_offline_message_label

Defaults to C<Message>. This is the label for the B<Message> textarea in Support Chat Offline window.

=cut

has support_chat_offline_message_label => (
    is          => 'rw',
    default     => sub { 'Message' },
);

=item support_chat_offline_message_contact

Defaults to C<Contact Details>. This is the label for the <i>Contact Details</i> textarea in Support Chat Offline window.

=cut

has support_chat_offline_message_contact => (
    is          => 'rw',
    default     => sub { 'Contact Details' },
);

=item support_chat_offline_message_send_button

Defaults to C<Send Message>. This is the label for the B<Send Button> textarea in Support Chat Offline window.

=cut

has support_chat_offline_message_send_button => (
    is          => 'rw',
    default     => sub { 'Send Message' },
);

=item support_chat_offline_message_email

Enter all email addresses (separated by comma) to which notification should be sent when a user leaves a message via Offline Form.

=cut

has support_chat_offline_message_email => (
    is          => 'rw',
    default     => sub { '' },
);

=item go_online_label

Defaults to C<Go Online>. Set this to change the label of the status of a user to an online state.

=cut

has go_online_label => (
    is          => 'rw',
    default     => sub { 'Go Online' },
);

=item go_idle_label

Defaults to C<Go Idle>. Set this to change the label of the status of a user to an idle state.

=cut

has go_idle_label => (
    is          => 'rw',
    default     => sub { 'Go Idle' },
);

=item new_message_label

Defaults to C<New chat message!>. Set this to change the label of the notification when a new chat message has come in.

=cut

has new_message_label => (
    is          => 'rw',
    default     => sub { 'New chat message!' },
);

=item public_chatroom_header

Defaults to C<Public Chatroom>. This is the text that will appear in header of public chatroom.

=cut

has public_chatroom_header => (
    is          => 'rw',
    default     => sub { 'Public Chatroom' },
);

=item enable_chatroom

Defaults to 1. Must be 1 or 2. 1 means that the public chatroom is enabled.

=cut

has enable_chatroom => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'enable_chatroom must be 1 or 2', 'enable_chatroom') unless ($_[0] ~~ [1,2]);
    }
);

=item theme

Defaults to C<light>. Must be C<light> or C<dark>. Other options may exist in the future, or you could create your own.

=cut

has theme => (
    is          => 'rw',
    default     => sub { 'light' },
);

=item notification_sound

Defaults to 1. Must be 1 or 2. When set to 1 the chat will play a notification sound when a message is posted.

=cut

has notification_sound => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'notification_sound must be 1 or 2', 'notification_sound') unless ($_[0] ~~ [1,2]);
    }
);

=item sound_player_uri

Defaults to C<static_asset_base_uri> + C</swf/sound.swf>. The URL to where the sound player is stored.

=cut

has sound_player_uri => (
    is          => 'rw',
    default     => sub { shift->static_asset_base_uri.'/swf/sound.swf' },
    lazy        => 1,
);

=item sound_file_uri

Defaults to C<static_asset_base_uri> + C</wav/notification.mp3>. The URL to where the notification sound is stored.

=cut

has sound_file_uri => (
    is          => 'rw',
    default     => sub { shift->static_asset_base_uri.'/wav/notification.mp3' },
    lazy        => 1,
);

=item enable_smiley

Defaults to 1. Must be 1 or 2. When set to 1 users will have access to emoticons. 

=cut

has enable_smiley => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'enable_smiley must be 1 or 2', 'enable_smiley') unless ($_[0] ~~ [1,2]);
    }
);

=item smiley_uri

Defaults to C<static_asset_base_uri> + C</smileys/very_emotional_emoticons-png/png-32x32/>. The URL to where the emoticons are stored.

=cut

has smiley_uri => (
    is          => 'rw',
    default     => sub { shift->static_asset_base_uri.'/smileys/very_emotional_emoticons-png/png-32x32/' },
    lazy        => 1,
);

=item log_messages

Defaults to 1. Must be 1 or 2. When set to 1 chat messages will be logged to the user's inbox. See C<get_message_inbox>.

=cut

has log_messages => (
    is          => 'rw',
    coerce      => $convert_to_string,
    default     => sub { '1' },
    isa         => sub {
        ouch(442, 'log_messages must be 1 or 2', 'log_messages') unless ($_[0] ~~ [1,2]);
    }
);

=item anon_prefix

Defaults to C<Guest>. A prefix that will be applied to anonymous generated usernames.

=cut

has anon_prefix => (
    is          => 'rw',
    default     => sub { 'Guest' },
);

=item use_local_anonymous_names

Perl boolean. When true guest names will be pulled from C<local_anonymous_names>, which is faster than consulting the remote server. When false a list of names will be polled from the iFly server.

=cut

has use_local_anonymous_names => (
    is          => 'rw',
    default     => sub { 1 },
);

=item local_anonymous_names

An array reference of local names. There's a default list of 50 or so English sounding names. For use with C<use_local_anonymous_names>.

=cut

has local_anonymous_names => (
    is          => 'rw',
    default     => sub { [qw(John Tim Tom Jason Fred Dave Mark James Don Ron Ed Sally Mary Sarah Kim Jim Nancy Wayne Bill Bob Karey Heather Victoria Becky Ana Larry Kayla Joe Tera Kevin Josh Chris Karen Maria Nadia Susan Mellisa Rebecca Bev Rachel Eddie Heidi Shana Shane Eric Erika)] },
    lazy        => 1,
);

=item use_stop_word_list

Defaults to 1. Must be 1. Whether to use C<stop_word_list> to filter user posts. 1 means don't filter. 2 means filter in public chat room. 3 means filter in private chats. 4 means filter in all chats.

=cut

has use_stop_word_list => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'use_stop_word_list must be 1, 2, 3 or 4', 'use_stop_word_list') unless ($_[0] ~~ [1,2,3,4]);
    }
);

=item stop_word_list

A comma separated string of "bad" words. A list of about a hundred defaults this list.

=cut

has stop_word_list => (
    is          => 'rw',
    default     => sub { 'asshole,assholes,bastard,beastial,beastiality,beastility,bestial,bestiality,bitch,bitcher,bitchers,bitches,bitchin,bitching,blowjob,blowjobs,bullshit,clit,cock,cocks,cocksuck,cocksucked,cocksucker,cocksucking,cocksucks,cum,cummer,cumming,cums,cumshot,cunillingus,cunnilingus,cunt,cuntlick,cuntlicker,cuntlicking,cunts,cyberfuc,cyberfuck,cyberfucked,cyberfucker,cyberfuckers,cyberfucking,damn,dildo,dildos,dick,dink,dinks,ejaculate,ejaculated,ejaculates,ejaculating,ejaculatings,ejaculation,fag,fagging,faggot,faggs,fagot,fagots,fags,fart,farted,farting,fartings,farts,farty,felatio,fellatio,fingerfuck,fingerfucked,fingerfucker,fingerfuckers,fingerfucking,fingerfucks,fistfuck,fistfucked,fistfucker,fistfuckers,fistfucking,fistfuckings,fistfucks,fuck,fucked,fucker,fuckers,fuckin,fucking,fuckings,fuckme,fucks,fuk,fuks,gangbang,gangbanged,gangbangs,gaysex,goddamn,hardcoresex,horniest,horny,hotsex,jism,jiz,jizm,kock,kondum,kondums,kum,kumer,kummer,kumming,kums,kunilingus,lust,lusting,mothafuck,mothafucka,mothafuckas,mothafuckaz,mothafucked,mothafucker,mothafuckers,mothafuckin,mothafucking,mothafuckings,mothafucks,motherfuck,motherfucked,motherfucker,motherfuckers,motherfuckin,motherfucking,motherfuckings,motherfucks,niger,nigger,niggers,orgasim,orgasims,orgasm,orgasms,phonesex,phuk,phuked,phuking,phukked,phukking,phuks,phuq,pis,piss,pisser,pissed,pisser,pissers,pises,pisses,pisin,pissin,pising,pissing,pisof,pissoff,porn,porno,pornography,pornos,prick,pricks,pussies,pusies,pussy,pusy,pussys,pusys,slut,sluts,smut,spunk' },
);

=item stop_links

Defaults to 1. Must be 1, 2, 3, or 4. 1 means don't block links. 2 means block in public chatroom. 3 menas block in private chat rooms. 4 means block in all chats.

=cut

has stop_links => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'stop_links must be 1, 2, 3, or 4', 'stop_links') unless ($_[0] ~~ [1,2,3,4]);
    }
);

=item allow_anon_links

Defaults to 2. Must be 1 or 2. 1 means apply C<stop_links> only to anonymous users. 2 means apply C<stop_links> to all users.

=cut

has allow_anon_links => (
    is          => 'rw',
    default     => sub { '2' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'allow_anon_links must be 1 or 2', 'allow_anon_links') unless ($_[0] ~~ [1,2]);
    }
);

=item allow_render_images

Defaults to 1. Must be 1 or 2. When set to 1 images and video links will be rendered inline in the chat.

=cut

has allow_render_images => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'allow_render_images must be 1 or 2', 'allow_render_images') unless ($_[0] ~~ [1,2]);
    }
);

=item allow_user_font_color

Defaults to 1. Must be 1 or 2. When set to 1 users can set their name color.

=cut

has allow_user_font_color => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'allow_user_font_color must be 1 or 2', 'allow_user_font_color') unless ($_[0] ~~ [1,2]);
    }
);

=item allow_single_message_delete

Defaults to 1. Must be 1, 2, or 3. Allow users to delete messages selectively when in private conversation. 1 means allow all users. 2 means allow moderators. 3 means do not allow.

=cut

has allow_single_message_delete => (
    is          => 'rw',
    default     => sub { '2' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'allow_single_message_delete must be 1, 2, or 3', 'allow_single_message_delete') unless ($_[0] ~~ [1,2,3]);
    }
);

=item allow_clear_room_history

Defaults to 1. Must be 1, 2, or 3. Allow users to clear all messages in a room. 1 means allow all users. 2 means allow moderators. 3 means do not allow.

=cut

has allow_clear_room_history => (
    is          => 'rw',
    default     => sub { '2' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'allow_clear_room_history must be 1, 2, or 3', 'allow_clear_room_history') unless ($_[0] ~~ [1,2,3]);
    }
);

=item rel

Defaults to 2. Must be 1 or 2. When set to 2 the chat will be in "Community" mode, which means users can talk to each other. When set to 1 the chat is in "Support" mode and users can only talk to admins.

=cut

has show_admin_list => (
    is          => 'rw',
    default     => sub { '2' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'show_admin_list must be 1 or 2', 'show_admin_list') unless ($_[0] ~~ [1,2]);
    }
);

=item user_picture

Defaults to 1. Must be 1 or 2. 1 means to enable user avatars.

=cut

has user_picture => (
    is          => 'rw',
    default     => sub { '1' },
    coerce      => $convert_to_string,
    isa         => sub {
        ouch(442, 'user_picture must be 1 or 2', 'user_picture') unless ($_[0] ~~ [1,2]);
    }
);

=item no_users_html

Determine how to render the list when no users are online. Defaults to:

 <div class="item-list"><ul><li class="drupalchatnousers even first last">No users online</li></ul></div>

=cut

has no_users_html => (
    is          => 'rw',
    default     => sub { '<div class="item-list"><ul><li class="drupalchatnousers even first last">No users online</li></ul></div>' },
);

=item uri

The base URI of the service you're interacting with. Defaults to C<https://api.iflychat.com>.

=cut

has uri => (
    is          => 'rw',
    default     => sub { 'https://api.iflychat.com' },
);

=item port

The port you're interacting with for iFly. Defaults to C<443>.

=cut

has port => (
    is          => 'rw',
    default     => sub { '443' },
    coerce      => $convert_to_string,
);

=item agent

A HTTP::Thin object.

=back

=cut

has agent => (
    is          => 'ro',
    required    => 0,
    lazy        => 1,
    builder     => '_build_agent',
);

sub _build_agent {
    return HTTP::Thin->new( )
}


=head2 render_html( user )

This method renders the HTML you need to inline into your web page to configure the chat.

=over

=item user

A hash reference containing a user as defined in C<get_key>. However, you only need to pass this in if the user is registered with the site, not for anonymous users.

=back

=cut

sub render_html {
    my ($self, $user) = @_;
    my $out = '<script type="text/javascript">Drupal={};Drupal.settings={};Drupal.settings.drupalchat={};Drupal.settings='.to_json($self->init($user)).';</script>';
    $out .= '<script type="text/javascript" src="' . $self->static_asset_base_uri .  '/js/ba-emotify.js"></script>';
    $out .= '<script type="text/javascript" src="' . $self->static_asset_base_uri .  '/js/jquery.titlealert.min.js"></script>';
    $out .= '<script type="text/javascript" src="' . $self->static_asset_base_uri .  '/js/iflychat.js"></script>';
    return $out;
}

=head2 render_ajax( user )

This method renders the response that will log the user into the chat.

B<NOTE:> For best performance and to ensure persistent user names for anonymous users you should cache the result of this method in your session management system.

=over

=item user

Required. A hash reference containing a user definition. For an anonymous user call C<generate_anonymous_user>. Otherwise define the user as described in the C<get_key> method.

=back

=cut

sub render_ajax {
    my ($self, $user) = @_;
    ouch(441, 'user is required', 'user') unless defined $user;
    return to_json({(%{$user}, %{$self->get_key($user)})});
}

=head2 init( user )

This method is called by C<render_html> to generate the list of settings to initialize the chat. There should proably not be a reason for you to call it yourself.

=over

=item user

A hash reference containing a user as defined in C<get_key>. However, you only need to pass this in if the user is registered with the site, not for anonymous users.

=back

=cut

sub init {
    my ($self, $user) = @_;
    my %settings = (
        username                => (defined $user && exists $user->{name} && $user->{name}) ? $user->{name} : '',
        uid                     => (defined $user && exists $user->{id} && $user->{id}) ? $user->{id} : '',
        current_timestamp       => time(),
        polling_method          => "3",
        pollUrl                 => ' ',
        sendUrl                 => ' ',
        statusUrl               => ' ',
        status                  => "1",
        goOnline                => $self->go_online_label,
        goIdle                  => $self->go_idle_label,
        newMessage              => $self->new_message_label,
        images                  => $self->static_asset_base_uri.'/themes/'.$self->theme.'/images/',
        sound                   => $self->sound_player_uri,
        soundFile               => $self->sound_file_uri,
        noUsers                 => $self->no_users_html,
        smileyURL               => $self->smiley_uri,
        addUrl                  => ' ',
        guestPrefix             => $self->anon_prefix,
        allowSmileys            => $self->enable_smiley,
        iup                     => $self->user_picture,
        open_chatlist_default   => $self->minimize_chat_user_list,
        useStopWordList         => $self->use_stop_word_list,
        blockHL                 => $self->stop_links,
        allowAnonHL             => $self->allow_anon_links,
        renderImageInline       => $self->allow_render_images,
        searchBar               => $self->enable_search_bar,        
        notificationSound       => $self->notification_sound,
        basePath                => '/',
        admin                   => (defined $user && exists $user->{is_admin} && $user->{is_admin}) ? "1" : "0",
        session_key             => '',
        exurl                   => $self->ajax_uri,
        external_host           => $self->uri,
        external_port           => $self->port,
        external_a_host         => $self->uri,
        external_a_port         => $self->port,
        upl                     => (defined $user && exists $user->{profile_uri} && $user->{profile_uri}) ? $user->{profile_uri} : '#',
    );
    
    if ($self->user_picture) {
        $settings{default_up} = $self->static_asset_base_uri.'/themes/'.$self->theme.'/images/default_avatar.png';
        $settings{up} = (defined $user && exists $user->{avatar_uri}) ? $user->{avatar_uri} : $settings{default_up};
        $settings{default_cr} = $self->static_asset_base_uri.'/themes/'.$self->theme.'/images/default_room.png';
    }
    
    if ($self->show_admin_list) {
        $settings{text_support_chat_init_label} = $self->support_chat_init_label;
        $settings{text_support_chat_box_header} = $self->support_chat_box_header;
        $settings{text_support_chat_box_company_name} = $self->support_chat_box_company_name;
        $settings{text_support_chat_box_company_tagline} = $self->support_chat_box_company_tagline;
        $settings{text_support_chat_auto_greet_enable} = $self->support_chat_auto_greet_enable;
        $settings{text_support_chat_auto_greet_message} = $self->support_chat_auto_greet_message;
        $settings{text_support_chat_auto_greet_time} = $self->support_chat_auto_greet_time;
        $settings{text_support_chat_offline_message_label} = $self->support_chat_offline_message_label;
        $settings{text_support_chat_offline_message_contact} = $self->support_chat_offline_message_contact;
        $settings{text_support_chat_offline_message_send_button} = $self->support_chat_offline_message_send_button;
        $settings{text_support_chat_offline_message_desc} = $self->support_chat_offline_message_desc;
        $settings{text_support_chat_init_label_off} = $self->support_chat_init_label_off;
    }
    
    if ($self->use_stop_word_list == 2) {
        $settings{stopWordList} = $self->stop_word_list;
    }

    return { drupalchat => \%settings };
}

=head2 generate_anonymous_user()

Generates an anonymous user hash reference to be used with C<get_key> or C<render_ajax>.

=cut

sub generate_anonymous_user {
    my $self = shift;
    my %user = ( id => '0-'.time() );
    if ($self->use_local_anonymous_names) {
        my $names = $self->local_anonymous_names;
        $user{name} = $self->anon_prefix.' '.$names->[rand @{$names}];
    }
    else {
        $user{name} = $self->anon_prefix.' '.$self->fetch_anonymous_name;
    }
    return \%user;
}

=head2 fetch_anonymous_name( )

Retrieves a random name from the iFly servers for anonymous users. This is called by C<generate_anonymous_user> and probably doesn't need to be used by you.

=cut

sub fetch_anonymous_name {
    my $self = shift;
    return $self->get('/anam/v/usa');
}


=head2 get_key( user )

This method is used to essentially log a user into the chat system. It generates a key that is used by the javascript to communicate back to the chat server.

=over

=item user

A hash reference containing the definition of a user. If this is an anonymous user then generate it using C<generate_anonymous_user>.

=over

=item id

The unique id of the user. It can be any alphanumeric string, and cannot contain special characters or start with a number. I recommend hex encoding your string and then prepending "ifly" on it to create a string that fits their ID scheme.

=item name

The name or username of the user.

=item is_admin

Defaults to 0. Can be set to 1 if the user should have chat admin privileges.

=item custom_roles

Defaults to C<normal>. Ignored entirely if C<is_admin> is set to 1. You can also pass in a hash of custom roles (not admin or normal) that will be used as CSS classes for styling. For example:

 {
    1   => 'cool',
    2   => 'slick',
 }

=item avatar_uri

A URI string that references a picture used to identify the user.

=item profile_uri

A URI string that will link other users to this user's profile on the web site.

=item relationships_set

This allows you to set up buddy lists within the chat. It is a hash reference taking the form of:

 {
    1   => {
        name        => 'friend',
        plural      => 'friends',
        valid_uids  =>  ['user_id_1', 'user_id_5', 'user_id_3']
    },
    2   => {
        name        => 'co-worker',
        plural      => 'co-workers',
        valid_uids  =>  ['user_id_3', 'user_id_4', 'user_id_2']
    },
 }


=back

=back 

=cut

sub get_key {
    my ($self, $user) = @_;
    my $result = from_json($self->post('/p/', {
        api_key         => $self->api_key,
        uname           => $user->{name},
        uid             => $user->{id} || 0,
        image_path      => $self->static_asset_base_uri.'/themes/'.$self->theme.'/images',
        isLog           => JSON::true,
        whichTheme      => 'blue',
        enableStatus    => JSON::true,
        role            => $user->{is_admin} ? 'admin' : ((exists $user->{custom_roles}) ? $user->{custom_roles} : 'normal'),
        validState      => ['available','offline','busy','idle'],
        up              => (exists $user->{avatar_uri}) ? $user->{avatar_uri} : $self->static_asset_base_uri.'/themes/'.$self->theme.'/images/default_avatar.png',
        upl             => (exists $user->{profile_uri}) ? $user->{profile_uri} : '#',
        rel             => (exists $user->{relationships_set}) ? 1 : undef,
        valid_uids      => $user->{relationships_set},
    }));
    $result->{uid} = $user->{id} || 0;
    $result->{name} = $user->{name};
    return $result;
}

=head2 update_settings( )

Updates the iFly servers with all the configured settings you passed into the constructor of this object. This must be called when you first start using this module, and also each time that you make changes to your settings.

=cut

sub update_settings {
    my ($self) = @_;
    return $self->post('/z/', {
        api_key                     => $self->api_key,
        enable_chatroom             => $self->enable_chatroom,
        theme                       => $self->theme,
        notify_sound                => $self->notification_sound,
        smileys                     => $self->enable_smiley,
        log_chat                    => $self->log_messages,
        chat_topbar_color           => $self->chat_topbar_color,
        chat_topbar_text_color      => $self->chat_topbar_text_color,
        font_color                  => $self->font_color,
        chat_list_header            => $self->chat_list_header,
        public_chatroom_header      => $self->public_chatroom_header,
        version                     => 'perl',
        show_admin_list             => $self->show_admin_list,        
        delmessage                  => $self->allow_clear_room_history,
        clear                       => $self->allow_single_message_delete,
        ufc                         => $self->allow_user_font_color,
        guest_prefix                => $self->anon_prefix,
        use_stop_word_list          => $self->use_stop_word_list,
        stop_word_list              => $self->stop_word_list,
    });
}

=head2 get_message_thread(uid1, uid2)

Returns a hash reference of a message thread between two users.

=over

=item uid1

Required. The unique user id of the first user in the discussion.

=item uid2

Required. The unique user id of the second user in the discussion.

=back

=cut

sub get_message_thread {
    my ($self, $uid1, $uid2) = @_;
    ouch(441, 'uid1 required', 'uid1') unless $uid1;
    ouch(441, 'uid2 required', 'uid2') unless $uid2;
    return from_json($self->post('/q/', { api_key => $self->api_key, uid1 => $uid1, uid2 => $uid2} ));
}

=head2 get_message_inbox(uid)

Returns a hash reference containing the messages in the user's inbox.

=over

=item uid

The unique user id of the user who's inbox you want to retrieve.

=back

=cut

sub get_message_inbox {
    my ($self, $uid) = @_;
    ouch(441, 'uid required', 'uid') unless $uid;
    return from_json($self->post('/r/', { api_key => $self->api_key, uid1 => $uid} ));
}



=head2 get(path, params)

Performs a C<GET> request, which is used for reading data from the service.

=over

=item path

The path to the REST interface you wish to call. 

=item params

A hash reference of parameters you wish to pass to the web service.

=back

=cut

sub get {
    my ($self, $path, $params) = @_;
    my $uri = $self->_create_uri($path);
    $uri->query_form($params);
    return $self->_process_request( GET $uri );
}


=head2 post(path, params)

Performs a C<POST> request, which is used for creating data in the service.

=over

=item path

The path to the REST interface you wish to call. 

=item params

A hash reference of parameters you wish to pass to the web service.

=back

=cut

sub post {
    my ($self, $path, $params) = @_;
    my $uri = $self->_create_uri($path);
    return $self->_process_request( POST $uri->as_string, Content_Type => 'application/json', Content => to_json($params) );
}

sub _create_uri {
    my $self = shift;
    my $path = shift;
    return URI->new($self->uri.$path);
}

sub _process_request {
    my $self = shift;
    $self->_process_response($self->agent->request( @_ ));
}

sub _process_response {
    my $self = shift;
    my $response = shift;
    if ($response->is_success) {
        return $response->decoded_content;
    }
    else {
        warn $response->decoded_content;
        ouch $response->code, $response->message, $response->decoded_content;
    }
}

=head1 PREREQS

L<HTTP::Thin>
L<Ouch>
L<HTTP::Request::Common>
L<JSON>
L<URI>
L<Moo>

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/Chat-iFly>

=item Bug Reports

L<http://github.com/rizen/Chat-iFly/issues>

=back

=head1 AUTHOR

JT Smith <jt_at_plainblack_dot_com>

=head1 LEGAL

This module is Copyright 2014 Plain Black Corporation. It is distributed under the same terms as Perl itself. 

=cut


1;
