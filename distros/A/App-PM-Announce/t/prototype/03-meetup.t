#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
plan qw/no_plan/;

use DateTime;
use App::PM::Announce;
my $app = App::PM::Announce->new;
my $feed = App::PM::Announce::Feed::meetup->new(
    app => $app,
    username => 'robert...krimen@gmail.com',
    password => 'test8378',
    uri => 'http://www.meetup.com/The-San-Francisco-Beta-Tester-Meetup-Group/calendar/?action=new',
);
my $key = int rand $$;
$feed->announce(
    title => "Event title ($key)",
    description => "Event description ($key)",
    venue => 920502,
    datetime => DateTime->now->add(days => 10),
    image => Path::Class::File->new( 't/assets/bee.jpg' ),
);

ok(1);

__END__

use WWW::Mechanize;
use HTTP::Request::Common qw/POST/;
use HTML::TreeBuilder;
use URI;

my $agent = WWW::Mechanize->new;

$agent->get("http://www.meetup.com/login/");

$agent->submit_form(
    fields => {
        email => 'robert...krimen@gmail.com',
        password => 'test8378',
    },
    form_number => 1,
    button => 'submitButton',
);

die "Wasn't logged in" unless $agent->content =~ m/Your Meetup Groups/;

$agent->get("http://www.meetup.com/The-San-Francisco-Beta-Tester-Meetup-Group/calendar/?action=new");

$agent->submit_form(
    fields => {
        title => "Test meetup!",
        venueId => 920502,
        origId => 920502,
        'event.day' => 10,
        'event.month' => 4,
        'event.year' => 2010,
        'event.hour12' => 12,
        'event.minute' => 0,
        'event.ampm' => 'AM',
        description => 'A stupid meetup',
    },
    form_number => 1,
    button => 'submit_next',
);

warn $agent->content;

my $tree = HTML::TreeBuilder->new_from_content( $agent->content );

die "Unable to parse HTML" unless $tree;

my $a = $tree->look_down( _tag => 'a', sub { $_[0]->as_text =~ m/Or, go straight to this Meetup's page/ } );

die "Not sure if discussion was posted (couldn't find success link)" unless $a;

my $href = $a->attr( 'href' );

my $uri = URI->new( $href );
$uri->query( undef );

warn $uri;


__END__

0   pageLoadUniqueId    pageLoadUniqueId    hidden  1238658328659               
1   __force_urlname __force_urlname hidden  true                
2   title   title   text        <span class="requiredMark">* </span>Title   50  80  
3   eventDatePicker     fieldset                    
4   eventmonth  event.month select                  
5   eventday    event.day   select                  
6   eventyear   event.year  select                  
7           fieldset                    
8   eventhour   event.hour12    select                  
9   eventminute event.minute    select                  
10  eventampm   event.ampm  select                  
11      event.second    hidden  0               
12      todayYear   hidden  2009                
13      todayMonth  hidden  4               
14  venueId venueId hidden  0               
15  origId  origId  hidden  0               
16  search_log_id   search_log_id   hidden                  
17  search_rank search_rank hidden                  
18  search_sort search_sort hidden                  
19  search_desc search_desc hidden                  
20      VP_name_default hidden  Place Name              
21      VP_address1_default hidden  Street address or intersection              
22      VP_address2_default hidden  Apt., suite, floor number, etc.             
23      VP_city_default hidden  City name               
24      VP_zip_default  hidden  Optional if city/state is provided              
25      VP_phone_default    hidden  Place's phone number                
26      VP_web_default  hidden  http://www.venue.com                
27      VP_hours_default    hidden  Place's hours of operation              
28      VP_tag_default  hidden  Ex: backroom, extra seating, quiet              
29  btn_select_920502       button                  
30  hide_location   hide_location   checkbox    1               
31  hostIdentifyBlurb   hostIdentifyBlurb   text        How will members find you there?    50  80  
32  _description    description textarea        Why should people come?     5000    
33  photoId photoId hidden  0               
34  photo_prefs photo_prefs hidden  upload              
35  attachfile  attachfile  file    /home/rob/Pictures/9515.jpg             
36  host_9248191    host_9248191    checkbox    on  Alice 8378          

Checked
37  host_9017798    host_9017798    checkbox    on  Robert Krimen           
38  fee_mode_yes    fee_mode    radio   1   <strong>Yes,</strong> I'd like to charge my members         
39  payment_method  payment_method  hidden                  
40  payment_amazon  paymnet_method_type radio   amazon              
41  require_payment_yes require_payment checkbox    1               

Disabled
42  payment_cash    paymnet_method_type radio   cash                
43  fee_label   fee_label   text    Price       8   25  
44  fee_currency    fee_currency    select                  
45  amountYouCharge fee text    20.00       5   9   
46      fee_desc    text    per person      9   25  
47  fee_mode_no fee_mode    radio   0   <strong>No</strong>, I don't want to charge my members          

Checked
48  refund_none_yes refund_none_yes radio   1   No refunds are offered          
49  refund_policy_yes   refund_none_yes radio   0   I will refund members if…           
50  refund_event_cancellation_yes   refund_event_cancellation_yes   checkbox    1   the Meetup is cancelled         
51  refund_event_reschedule_yes refund_event_reschedule_yes checkbox    1   the Meetup is rescheduled           
52  refund_member_cancellation_yes  refund_member_cancellation_yes  checkbox    1               
53      refund_member_cancellation_days text    0       2       
54  refund_policy   refund_policy   textarea        Additional notes:           
55  rsvp_limit_yes  rsvp_limit  radio   1               
56  rsvp_limit_number   rsvp_limit_number   text    20  Yes, up to <input class="text isRadioSelector" dependson="rsvp_limit_yes" maxlength="3" size="3" name="rsvp_limit_number" id="rsvp_limit_number" value="20" type="text"> people can attend  3   3   
57  waiting_list_auto   waiting_list    radio   auto                
58  waiting_list_manual waiting_list    radio   manual              
59  waiting_list_off    waiting_list    radio   off             

Checked
60  rsvp_limit_no   rsvp_limit  radio   0   No RSVP limit           

Checked
61  deadline_yes    deadlineToggle  checkbox    1   Members can RSVP until:             
62  deadlinePicker      fieldset                    
63  deadlinemonth   rsvpCutoffTime.month    select                  
64  deadlineday rsvpCutoffTime.day  select                  
65  deadlineyear    rsvpCutoffTime.year select                  
66          fieldset                    
67  deadlinehour    rsvpCutoffTime.hour12   select                  
68  deadlineminute  rsvpCutoffTime.minute   select                  
69  deadlineampm    rsvpCutoffTime.ampm select                  
70      rsvpCutoffTime.second   hidden  0               
71  allowMaybeRsvps allowMaybeRsvps checkbox    on  Allow members to RSVP 'Maybe'           

Checked
72  guestLimitCheck guestLimitCheck checkbox    on              

Checked
73  guest_rsvp_limit    guestLimit  text    10  Allow members to RSVP for up to <input id="guest_rsvp_limit" class="text isRadioSelector" dependson="guestLimitCheck" name="guestLimit" value="10" maxlength="2" size="2" type="text"> guests   2   2   
74  notifyNewRsvp   notifyNewRsvp   checkbox    on  Email organizers when members RSVP          

Checked
75  notifyNewComment    notifyNewComment    checkbox    on  Email organizers when members comment           

Checked
76  emailReminders  emailReminders  checkbox    on  Send automatic announcements and reminders <a href="http://www.meetup.com/help/?sub=automated_announcements_and_reminders&amp;op=popup" target="_blank" class="popFAQ"><img src="http://img4.meetupstatic.com/img/2061232548061/icon_help_chapter.gif" alt="What's this" class="D_icon"></a>            

Checked
77      rsvp    hidden  1               
78  pre_event_survey_yes    pre_event_survey    checkbox    true    <strong>Yes,</strong> I'd like members who RSVP to optionally answer these questions…           
79  pre_event_survey_question_1 pre_event_survey_question_1 text        Question #1:            
80  numQuestions    numQuestions    hidden  1               
81      eventId hidden                  
82      eventAction hidden  adding              
83      copyName    hidden                  
84      action_cancel   hidden  cancelchange                
85      addFlow hidden                  
86      token   hidden  12386583286670.686488812138324              
87      action_next hidden  publish             
88      returnUri   hidden  ?action=new_item                
89      submit  hidden  submit              
90      newgrp  hidden                  
91      firstgrp    hidden                  
92      eventSuggestId  hidden                  
93      submit_next submit  Schedule Meetup

#$agent->request(
#    POST "http://sf.pm.org/cgi-bin/greymatter/gm.cgi", {
#        authorname => 'Test',
#        authorpassword => '',
#        newentrysubject => 'Test subject',
#        newentrymaintext => 'Test maintext',
#        newentrymoretext => '',
#        newentryallowkarma => 'no',
#        newentryallowcomments => 'no',
#        newentrystayattop => 'no',
#        thomas => 'Add This Entry',
#    },
#);

ok(1);

