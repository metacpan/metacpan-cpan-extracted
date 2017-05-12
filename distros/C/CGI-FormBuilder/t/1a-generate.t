#!/usr/bin/perl

# Copyright (c) Nate Wiger http://nateware.com.
# All Rights Reserved. If you're reading this, you're bored.
# 1a-generate.t - test FormBuilder generation of forms

use strict;

our $TESTING = 1;
our $DEBUG = $ENV{DEBUG} || 0;
our $LOGNAME = $ENV{LOGNAME} || '';
our $VERSION;
BEGIN { $VERSION = '3.10'; }

use Test;
use FindBin;

# use a BEGIN block so we print our plan before CGI::FormBuilder is loaded
BEGIN {
    unshift @INC, "$FindBin::Bin/../lib";
    my $numtests = 36;

    plan tests => $numtests + 1;

    # success if we said NOTEST
    if ($ENV{NOTEST}) {
        ok(1) for 1..$numtests;
        exit;
    }
}

# Need to fake a request or else we stall
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'ticket=111&user=pete&replacement=TRUE&action=Unsubscribe&name=Pete+Peteson&email=pete%40peteson.com&extra=junk&other_test=_other_other_test&_other_other_test=42';

use CGI::FormBuilder 3.10;
use CGI::FormBuilder::Test;

# What options we want to use, and what we expect to see
my @test = (
    #1
    {
        opt => { fields => [qw/name email/], sticky => 0 },
    },

    #2
    {
        opt => { fields => [qw/Upper Case/], values => { Upper => 1, Case => 0 }, table => 1 },
    },

    #3
    {
        opt => { fields => [qw/first_name last_name/], submit => 'Update', reset => 0 },
    },

    #4
    {
        opt => { fields => [qw/first_name last_name/], submit => 'Update', 
                 reset => 0, header => 1, body => {bgcolor => 'black'} },
    },

    #5
    {
        opt => { fields => {first_name => 'Nate', email => 'nate@wiger.org' },
                 validate => {email => 'EMAIL'}, required => [qw/first_name/],
                 stylesheet => 1, sticky => 0 },
    },

    #6
    {
        # utilize our query_string to test stickiness
        opt => { fields => [qw/ticket user part_number/], method => 'post', keepextras => 1,
                 validate => { ticket => '/^\d+$/' }, submit => [qw/Update Delete Cancel/],
                 lalign => 'left',
                },
    },

    #7
    {
        # max it out, baby
        opt => { fields => [qw/supply demand/],
                 options => { supply => [0..9], demand => [0..9] },
                 values  => { supply => [0..4], demand => [5..9] },
                 method => 'PuT', title => 'Econ 101', action => '/nowhere.cgi', header => 1, name => 'econ',
                 font   => 'arial,helvetica', fieldtype => 'select',
                 stylesheet => 1 },
    },

    #8
    {
        opt => { fields => [qw/db:name db:type db:tab ux:user ux:name/], static => 1 },
    },

    #9
    {
        # single-line search thing ala Yahoo!
        opt => { fields => 'search', submit => 'Go', reset => 0, table => 0, fieldtype => 'textarea' },
    },

    #10
    {
        opt => { fields => [qw/hostname domain/], header => 1,
                 keepextras => [qw/user ticket/],
                 values => [qw/localhost localdomain/],
                 validate => {hostname => 'HOST', domain => 'DOMAIN'},
                },
    },
 
    #11
    {
        opt => { fields => {first_name => 'Nate', email => 'nate@wiger.org' },
                 validate => {email => 'EMAIL'}, required => [qw/first_name/],
                 javascript => 0 },
    },

    #12
    {
        opt => { fields => [qw/earth wind fire water/], fieldattr => {type => 'TEXT'}},
    },

    #13
    {
        opt => { fields => [qw/earth wind fire water/],
                 options => { wind => [qw/<Slow> <Medium> <Fast>/], 
                              fire => [qw/&&MURDEROUS" &&HOT" &&WARM" &&COLD" &&CHILLY" &&OUT"/],
                            },
                 values => { water => '>>&c0ld&<<', earth => 'Wind >>' },
                 columns => 1,
               },
    },

    #14 - option maxing
    {
        opt => { fields => [qw/multiopt/], values => {multiopt => [1,2,6,9]},
                 options => { multiopt => [ 
                                 [1 => 'One'],   {2 => 'Two'},   {3 => 'Three'},
                                 {7 => 'Seven'}, [8 => 'Eight'], [9 => 'Nine'],
                                 {4 => 'Four'},  {5 => 'Five'},  [6 => 'Six'],
                                 [10 => 'Ten']
                               ],
                            },
                  sortopts => 'NUM',
                },
    },

    #15 - obscure features
    {
        opt => { fields => [qw/plain jane mane/],
                 nameopts => 1,
                 stylesheet => '/my/own/style.css',
                 styleclass => 'style_bitch',
                 body => {ignore => 'me'},
                 javascript => 0,
                 jsfunc => "   // -- user jsfunc option --\n",
                 labels => {plain => 'AAA', jane => 'BBB'},
                 options => {mane => [qw/ratty nappy mr_happy/]},
                 selectnum => 0,
                 title => 'Bobby',
                 header => 1, 
                },
    },

    #16
    {
        opt => { fields => [qw/name email/], sticky => 0 },
        mod => { name => {comment => 'Hey buddy'}, email => {comment => 'No email >> address??'} },
    },

    #17
    {
        opt => { fields => [qw/won too many/], columns => 1 },
        mod => { won  => { jsclick => 'taco_punch = 1'},
                 too  => { options => [0..2], jsclick => 'this.salami.value = "delicious"'},
                 many => { options => [0..9], jsclick => 'this.ham.value = "it\'s a pig, man!"'},
               },
    },

    #18
    {
        opt => { fields => [qw/refsort/] },
        mod => { refsort => { sortopts => \&refsort, 
                 options => [qw/99 9 8 83 7 73 6 61 66 5 4 104 3 2 10 1 101/] } },
    },

    #19 - table attr and field columns
    {
        opt => { fields => [qw/a b c/],
                 table  => { border => 1 },
                 td => { taco => 'beef', align => 'right' },
                 tr => { valign => 'top' },
                 th => { ignore => 'this' },
                 lalign => 'today',
                 selectnum => 10,
                },
        mod => { a => { options => [0..3], columns => 2, value => [1..2] },
                 b => { options => [4..9], columns => 3, comment => "Please fill these in" },
               },
    },

    #20 - order.cgi from manpage (big)
    {
        opt => { method => 'post',
                 stylesheet => 1,   # test 20
                 styleclass => 'shop',
                 name => 'order',
                 fields => [
                   qw(first_name last_name
                      email send_me_emails
                      address state zipcode
                      credit_card expiration)
                 ],

                 header => 1,
                 title  => 'Finalize Your Order',
                 submit => ['Place Order', 'Cancel'],
                 reset  => 0,
                 columns => 1,

                 validate => {
                     email   => 'EMAIL',
                     zipcode => 'ZIPCODE',
                     credit_card => 'CARD',
                     expiration  => 'MMYY',
                 },
                 required => 'ALL',
                 jsfunc => <<EOJS,
    // skip validation if they clicked "Cancel"
    if (form._submit.value == 'Cancel') return true;
EOJS
         },
         mod => { state => {
                     options => [qw(JS IW KS UW JS UR EE DJ HI YK NK TY)],
                     sortopts=> 'NAME'
                 },
                 send_me_emails => {
                     options => [[1 => 'Yes'], [0 => 'No']],
                     value   => 0,   # "No"
                 },
             },
    },

    #21 - "other" fields
    {
        opt => { javascript => 1, columns => 1, },
        mod => { favorite_color => {
                    name     => 'favorite_color',
                    options  => [qw(red green blue yellow)],
                    validate => 'NAME',
                    other    => 1 } },
    },

    #22 - "other" fields
    {
        opt => { javascript => 0, method => "post", columns => 1, },
        mod => { favorite_color => {
                    name     => 'favorite_color',
                    options  => [qw(red green blue yellow)],
                    validate => 'NAME',
                    other    => 1 } },
    },

    #23 - growable fields
    {
        opt => {},
        mod => { favorite_color => {
                    name     => 'favorite_color',
                    growable => 1 } },
    },

    #24 - growable fields
    {
        opt => {javascript => 0},
        mod => { favorite_color => {
                    name     => 'favorite_color',
                    growable => 1 } },
    },

    #25 - sessionids and fieldopts
    {
        opt => { sessionid => 'H8N0TAC5', header => 1,
                 fields    => [qw(acct: phone() taco.punch salad$)],
                 fieldopts => { 'acct:'   => { true => 'false', label => 'Acct #:' },
                                'phone()' => { options => [1], columns => 1, },
                                missing   => { value => 'not here', force => 1}
                               },
               },
    },

    #26 - disabled forms
    {
        opt => { disabled  => 'YES', cleanopts => 0, columns => 1,
                 fields    => [qw(acct phone taco salad)],
                 fieldopts => {acct => {type => 'radio', options => [qw(<b>on</b> <i>OFF</i>)]}}
                },
    },

    #27 - autofill fields
    {
        opt => { fields => [qw(text1 text2 textthree)], columns => 1,
                 fieldopts => {text2 => { id => 'mommy' }},
               },
    },

    #28 - new stylesheets to test all variations
    {
        opt => {
            stylesheet => 'fbstyle.css',
            submit     => [qw(Update Delete)],
            reset      => 'Showme',
            method     => 'POST',
            fields     => [qw(fullname gender fav_color lover)],    # need hash order
            header     => 1,
            columns    => 1,
            messages   => 'auto',
        },
        mod => {
            fullname => {
                label => 'Full Name',
                type  => 'text',
                required => 1,
            },
            gender => {
                label => 'Sex',
                options => [qw(M F)],
                comment => "It's one or the other",
            },
            fav_color => {
                label => 'Favy Colour',
                options => [qw(Red Green Blue Orange Yellow Purple)],
                comment => 'Choose just one, even if you have more than one',
                invalid => 1,   # tricky
            },
            lover => {
                label => 'Things you love',
                options => [qw(Sex Drugs Rock+Roll)],
                multiple => 1,
            },
        },
    },

    #29 - sticky in render()
    {
        opt => {
            fields => [qw(name email user)],
            values => {name => '_name_', email => '_email_', user => '_user_'},
            sticky => 0,
            required => 0,
            javascript => 0,
        },

        ren => {
            sticky => 1,
            required => 'ALL',
            javascript => 'auto',
        },
    },

    #30 - optgroups and selectname
    {
        opt => {
            fields => [qw(browser)],
            fieldtype => 'select',
        },
        mod => {
            browser => {
                selectname => 1,
                options => [
                    [ '', '' ],
                    [ '1', 'C', '' ],
                    [ '10', 'D1', '' ],
                    [ '9', 'D2', '' ],
                    [ '7', 'Option 1', 'D3' ],
                    [ '8', 'Option 2', 'D3' ],
                    [ '2', 'H', '' ],
                    [ '3', 'I', '' ],
                    [ '4', 'Option 1', 'J' ],
                    [ '40', 'Option 2', 'J' ],
                    [ '29', 'A', 'S' ],
                    [ '27', 'C', 'S' ],
                    [ '12', 'E', 'S' ],
                    [ '14', 'F', 'S' ],
                    [ '13', 'G', 'S' ],
                    [ '30', 'O', 'S' ],
                    [ '28', 'P', 'S' ],
                    [ '6', 'T', '' ],
                    [ '22', 'V A', '' ],
                    [ '16', 'Option 1', 'V1' ],
                    [ '17', 'Option 2', 'V2' ],
                    [ '18', 'Option 3', 'V2' ],
                    [ '5', 'W', '' ]
                ],
                optgroups => {
                    J => 'Jerky',
                    S  => 'Shoddy',
                },
            },
            select2 => {
                selectname => 0,
                options => [qw(a b)],
            },
            select3 => {
                selectname => 'choosey2',
                options => [qw(a b)],
            },
        },
    },

    #31 - Backbase tagname support (experiemental)
    {
        opt => {
            stylesheet => 'fbstyle.css',
            submit     => [qw(Update Delete)],
            reset      => 'Showme',
            method     => 'POST',
            fields     => [qw(fullname gender fav_color lover)],    # need hash order
            header     => 1,
            columns    => 1,
            messages   => 'auto',
            tagnames => {
                name   => 'b:name',
                select => 'b:select',
                value  => 'b:value',
                option => 'b:option',
                input  => 'b:input',
                table  => 'div',
                tr     => 'div',
                th     => 'div',
                td     => 'div',
            },
        },
        mod => {
            fullname => {
                label => 'Full Name',
                type  => 'text',
                required => 1,
            },
            gender => {
                label => 'Sex',
                options => [qw(M F)],
                comment => "It's one or the other",
            },
            fav_color => {
                label => 'Favy Colour',
                options => [qw(Red Green Blue Orange Yellow Purple)],
                comment => 'Choose just one, even if you have more than one',
                invalid => 1,   # tricky
            },
            lover => {
                label => 'Things you love',
                options => [qw(Sex Drugs Rock+Roll)],
                multiple => 1,
            },
        },
    },

    #32 - fieldsets
    {
        opt => {
            name => 'account',
            fieldsets => [[acct=>'Account Information'],
                          [prefs=>'User Preferences'],
                          [phone=>'Phone Number(s)']],
            stylesheet => 1,
            fields => [qw/first_name last_name outside_1 email home_phone new_set
                          work_phone call_me email_me outside_2 sex outside_3/],
        },
        mod => {
            first_name => { fieldset => 'acct' },
            last_name  => { fieldset => 'acct' },
            email      => { fieldset => 'acct' },
            home_phone => { fieldset => 'phone' },
            work_phone => { fieldset => 'phone' },
            new_set    => { fieldset => 'Inline Created' },
            call_me    => { fieldset => 'prefs' },
            email_me   => { fieldset => 'prefs' },
            first_name => { fieldset => 'acct' },
            sex        => { fieldset => 'acct', 
                            options  => [qw/Yes No/] },
        },
    },

    #33 - builtin Div.pm "template" support
    {
        opt => {
            name => 'parts',
            fields => [qw/ticket user email part_number/],
            fieldsets => [[acct=>'Account Information'],
                          [prefs=>'Part Information']],
            method => 'post',
            keepextras => 1,
            validate => { ticket => '/^\d+$/' },
            submit => [qw/Update Delete Cancel/],
            lalign => 'left',
            template => {type => 'div'},
            stylesheet => 1,
        },
        mod => {
            ticket => { fieldset => 'acct' },
            email  => { fieldset => 'prefs' },
        },
    },

    # Older tests moved from 1b-fields
    #34 - misc checkboxes
    {
        opt => {
            fields => [qw/name color/],
            labels => {color => 'Favorite Color'},
            validate => {email => 'EMAIL'},
            required => [qw/name/],
            sticky => 0, columns => 1,
            action => 'TEST', title => 'TEST',
        },
        mod => {
            color => {
                options => [qw(red> green& blue")],
                multiple => 1, cleanopts => 0,
            },
            name => {
                options => [qw(lower UPPER)], nameopts => 1,
            },
        },
    },

    #35
    {
        # check individual fields as static
        opt => {
            fields => [qw/name email color/],
            action => 'TEST',
            columns => 1
        },
        mod => {
            name  => { static => 1 },
            email => { type => 'static' },
        },
    },

    #36
    {
        opt => {
            fields => [qw/name color hid1 hid2/],
            action => 'TEST',
            columns => 1,
            values => { hid1 => 'Val1a' },
        },
        mod => {
            name => { static => 1, type => 'text' },
            hid1 => { type => 'hidden', value => 'Val1b' },  # should replace Val1a
            hid2 => { type => 'hidden', value => 'Val2' },
            color => { value => 'blew', options => [qw(read blew yell)] },
            Tummy => { value => [qw(lg xxl)], options => [qw(sm med lg xl xxl xxxl)] },
        },
    },
);

sub refsort {
    $_[0] <=> $_[1]
}

# Perl 5 is sick sometimes.
@test = @test[$ARGV[0] - 1] if @ARGV;
my $seq = $ARGV[0] || 1;

$ENV{HTTP_ACCEPT_LANGUAGE} = 'en_US';

# To test local %TAGNAMES
$CGI::FormBuilder::Util::TAGNAMES{name} = 'yellow';

# Cycle thru and try it out
for (@test) {

    my $form = CGI::FormBuilder->new(
                    debug  => $DEBUG,
                    header => $ENV{HEADER} || 0,
                    action => 'TEST',  # testing
                    title  => 'TEST',
                    %{ $_->{opt} }
               );

    # the ${mod} key twiddles fields
    for my $f ( sort keys %{$_->{mod} || {}} ) {
        my $o = $_->{mod}{$f};
        $o->{name} = $f;
        $form->field(%$o);
    }

    # just compare the output of render with what's expected
    # the correct string output is now in external files
    my $out = outfile($seq++);
    my $ren = $form->render(%{$_->{ren} || {}});
    my $ok  = ok($ren, $out);

    if (! $ok && $LOGNAME eq 'nwiger') {
        open(O, ">/tmp/fb.1.html");
        print O $out;
        close O;

        open(O, ">/tmp/fb.2.html");
        print O $ren;
        close O;

        system "diff /tmp/fb.1.html /tmp/fb.2.html";
        exit 1;
    }
}
ok($CGI::FormBuilder::Util::TAGNAMES{name}, 'yellow');

