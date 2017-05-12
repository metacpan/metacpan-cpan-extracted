#!perl

=head1 COPYLEFT

 Mixing_HTML_and_BBcode.pm, v0.02 alpha 11/28/2010 By: N.K.A.

 This file is to discribe the usage of:
 AUBBC.pm - Advanced Universal Bulletin Board Code a Perl BBcode API

 shakaflex [at] gmail.com
 http://search.cpan.org/~sflex/

=head1 ABSTRACT

Advanced Universal Bulletin Board Code a Perl BBcode API

=head1 DESCRIPTION

This is a none working file(syntax checks ok)! It discribes one way to use this module
in projects like forums, blogs, wiki's, bulletin boards or other development.
Keep in mind Im trying to explain the settings, when to use methods to ensure
security of the module and a simple method to save user input to be
edited later.

Other settings may effect the message output also.

=cut

# Start the module
use AUBBC;
my $aubbc = new AUBBC;

# script_escape will need to be disabled in the settings method and
# this will tell the do_all_ubbc method not to use script_escape!
#
# other settings can be changed here if needed.
$aubbc->settings(
        script_escape => 0,
        );

# Build your own tags can be added, est......

# This will be the data or Administrator input from a HTML form to save to a backend.
# The message will have some BBcode mixed in HTML and a home made tage for full
# AUBBC support is <aubbc> Full AUBBC support </aubbc>

my $message = <<HTML;
<i>This will work</i> [i]This will work[/i]
[b]Work[/b] <b>Works too</b>
[email]safe\@email.com[/email]

<aubbc> [b]Full AUBBC support[/b]
<i>This will not work</i> [i]This will work[/i]
[b]Work[/b] <b>Not Work</b>
[email]safe\@email.com[/email]
</aubbc>
HTML


sub saving_data {
# This is to show how to save the user input safely to your backend
# you will need to use a module like CGI or what ever is out there
# to recive the HTML form data lets say the data is in $message

# Befor the data can be saved you will have to use the script_escape method on $message
# But not on the hole $message, so I use this filter to get the <aubbc> tag

$message =~ s/(<aubbc>(?s)(.*?)<\/aubbc>)/
        my $ret = $aubbc->script_escape( $2 );
        $ret ? '<aubbc>'.$ret."<\/aubbc>" : $1;
        /exg;

# Then save $message to your database, extra security methods maybe required or desired
# depending on the type of backend used.......

}

sub editing_data {
# This will be a two part subroutine. This first one will get the message from
# the backend and display the data in a HTML form to be edited lets say its
# in variable $form_data

# Since this gets into sandboxing the script_escape method you may want
# to play with settings for other view's or can skip the form feilds sandboxing
# the option 1 for script_escape is needed to not convert spaces, tab's, new lines

$form_data =~ s/(<aubbc>(?s)(.*?)<\/aubbc>)/
        my $ret = $aubbc->html_to_text( $2 );
        $ret ? '<aubbc>'.$ret."<\/aubbc>" : $1;
        /exg;
$form_data = $aubbc->script_escape( $form_data, 1 );

# Now $form_data can be printed in the form feild
# When the HTML form is submitted we fictitiously sent the edited data to editing_data2
# of this file to be saved
}

sub editing_data2 {
# Part 2 of editing data, you will need to use a module like CGI or what ever is out there
# to recive the HTML form data

# Before the HTML form data can be saved you will have to use the script_escape
# method with the regex on the variable that holds the HTML form data lets say its $message2

$message2 =~ s/(<aubbc>(?s)(.*?)<\/aubbc>)/
        my $ret = $aubbc->script_escape( $2 );
        $ret ? '<aubbc>'.$ret."<\/aubbc>" : $1;
        /exg;

# Then save it to your database, extra security methods maybe required or desired
# depending on the type of backend used.......

}

sub display_data {
# Get the data from the backend lets say we did that and its in $message3
# use do_all_ubbc on $message3 and

$message3 = $aubbc->do_all_ubbc($message3);

# Before you print we want to remove the <aubbc> home made element
$message3 =~ s{\<\/?aubbc\>}{}g;

# now $message3 is ready to be printed in HTML.
# Here you would want to print the propper HTML headers and elements with $message3 in it
# or return the variable, how ever you want to make it!!
}

