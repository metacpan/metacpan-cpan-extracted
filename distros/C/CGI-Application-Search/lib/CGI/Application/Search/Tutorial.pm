use strict;    # this makes CPANTS happy, even though it's straight POD

=head1 NAME 

CGI::Application::Search::Tutorial - How do we use this thing?

=head1 DESCRIPTION

Need information on how to setup Swish-e for use with 
L<CGI::Application::Search>?

Need more information on using the AJAX capabilities of 
L<CGI::Application::Search>?

Then you've come to the right place

=head1 BRIEF SWISH-E TUTORIAL

You can skip this section if you're a Swish-e veteran.  Otherwise,
read on for a step-by-step guide to adding a search interface to your
site using CGI::Application::Search.

=head2 Step 1: Install Swish-e

The first thing you need to do is install Swish-e.  First, download it
from the swish-e site:

   http://swish-e.org

Then unpack it, cd into the directory, build and install:

  tar zxf swish-e-2.4.3.tar.gz
  cd swish-e-2.4.3
  ./configure
  make
  make install

You'll also need to build the Perl module, SWISH::API, which this
module uses:

  cd perl
  perl Makefile.PL
  make
  make install

=head2 Step 2: Setup a Config File

The first step to setting up a swish-e search engine is writing a
config file.  Swish-e supports a smorgasborg of configuration options
but just a few will get you started.

  # index all HTML files in /path/to/index
  IndexDir /path/to/index
  IndexOnly .html .htm
  IndexContents HTML2 .html .htm

  # C::A::Search needs a description, use the first 1,500 characters
  # of the body
  StoreDescription HTML2 <body> 1500

  # remove doc-root path so links will work on the results page
  ReplaceRules remove /path/to/index

Put the above in a file called F<swish-e.conf>.

NOTE: The above is a very simple swish-e.conf file. To bask in the
power and flexibility that is swish-e, please see the official documentation. 

=head2 Step 3: Run the Indexer

Now that you've got a basic configuration file you can index your site.  
The corresponding simple command is:

  $ swish-e -v 1 -c swish-e.conf -f /path/to/swishe-index

The last part is the place where Swish-e will write its index.  It
should be the name of a file in a directory writable by you and
readable by your CGI scripts.

Later you'll need to setup the indexer to run from cron, but for now
just run it once.

=head2 Step 4: Run a Test Search

Swish-e has a command-line interface to running searches which you can
use to confirm that your index is working.  For example, to search for
"foo":

  $ swish-e -w foo -f /path/to/swishe-index

If that works you should see some hits (assuming your site contains
"foo").

=head2 Step 5: Setup an Instance Script

Like all CGI::Application modules, CGI::Application::Search requires
an instance script.  Create a file called 'search.pl' or 'search.cgi'
in a place where your web server will execute it.  Put this in it:

  #!/usr/bin/perl -w
  use strict;
  use CGI::Application::Search;
  my $app = CGI::Application::Search->new(
    PARAMS => { SWISHE_INDEX => '/path/to/index' }
  );
  $app->run();

Now make it executable:

  $ chmod +x search.pl

=head2 Step 6: Test Your Instance Script

First, test it on the command-line:

  $ ./search.pl

That should show you the HTML for the search form with no results.
Now try it in your browser:

  http://yoursite.example.com/search.pl

If that doesn't work, check your error log.  Do not email me or the
CGI::Application mailing list until you check your error log.  Yes, I
mean you. Thanks.

=head2 Step 7: Rejoice

You've just completed the world's easiest search system setup!  Now go
setup that indexing cronjob.

=head1 AJAX USAGE

L<CGI::Application::Search> provides 2 features implemented in AJAX
(Asynchronous Javascript And XML). These are:

=over

=item Non-Refresh Search

Only the relevant portions of the page
are changed, not the entire page. This results in a faster search, especially
if the page is surrounded by other dynamic elements (navigation, side bars, etc).

=item Auto-Suggest

As the user types, they are presented with suggestions that match the letters/words
they have entered so far.

=back

Both are configurable and overrideable and can also be turned off completely.
Both make use of the B<Prototype> and B<Scriptaculous> JavaScript libraries 
(available at L<http://prototype.conio.net/> and L<http://script.aculo.us>).

Although our example AJAX templates have these libraries included (using 
C<< HTML::Prototype->define_javascript_functions() >> we recommend that you
actually download these libraries yourself and put them into your web document
tree and reference them in C<< <script> >> tags. This will allow them to be
cached by the browser instead of reparsed on each page fetch.

  <script src="/prototype.js" type="text/javascript"></script>
  <script src="/scriptaculous.js" type="text/javascript"></script>

You are encouraged to look at the sample templates included with this distribution
while you are learning how the JavaScript, CSS, C<< <forms> >> and links all work
together.

=head2 SETTING UP NON-REFRESH SEARCH

This is fairly straight forward. All form submissions and all
links are converted into calls to the C<< Ajax.Updater() >> method instead.

Form submissions will be serialized into query strings, and both links
and form submissions will be sent to the server. What ever the server
sends back will just replace the contents of the C<< <div> >> with the
id of 'search_listing'. And while the browser waits for the response,
the 'search_listing' div is replaced by a simple message.

    <div id="search_listing"></div>

    <script type="text/javascript">
    <!--
        new Ajax.Updater(
            'search_listing',
            url,
            {
                parameters: query,
                asynchronous: 1,
                onLoading: function(request) {
                    $('search_listing').innerHTML = "<strong>" + msg + " ...</strong>";
                }
            }
        );
    -->
    </script>


You can use the same template for both the inital request to view the full
search page (with search form) and to just return the Non-Refresh search
results. Simply use the 'ajax' flag to determine what to show when. See
the sample templates (F<templates/ajax_search_results.tmpl> and 
F<templates/ajax_search_results.tt>) for examples.

After you have added the appropriate C<< <div> >> and Javascript, then
simple set the B<AJAX> config parameter to true in your L<CGI::Application::Search>'s
params.

=head2 SETTING UP AUTO-SUGGEST  

By default, the AUTO-SUGGEST feature will use a simple flat file that contains
the words to suggest, in alphabetical order, one word per line. You can specify
the file (B<AUTO_SUGGEST_FILE>) and whether or not the application should cache the 
values it pulls from the file (B<AUTO_SUGGEST_CACHE>) which is useful if the file 
only contains a few thousand words and you're in a persistent environment. 

You can also specify the maximum number of suggestions that can be sent to the 
user at a given time (B<AUTO_SUGGEST_LIMIT>). This is useful to not only speed i
up the suggestions, but also keeps from overwhelming the use.

A common use-case is to suggest words that are known to exist in the Swish-e
index. After your index has been set up, it's pretty trivial to extract all
of the words that exist into a separate file perfect for use as an 
B<AUTO_SUGGEST_FILE>.

This command will create an alphabetical listing of every word in your documents
that has at least 2 alphabetical characters.

    # in bash
    swish-e -T INDEX_WORDS_META -f swishe.index \
        | grep -o -P "^\S+"  \
        | grep -P "[a-z]{2}" \
     > auto_suggest_file

Then in your template, you have to make sure that an C<< Ajax.Autocompleter() >> which
will watch the form input in question and send the requests to the search app (for the
'suggestions' run mode) and then show the user those suggestions.

    <script type="text/javascript">
    <!--
        var url = '<tmpl_var url>';
        new Ajax.Autocompleter( 
            'keywords', 
            'keywords_auto_complete', 
            url, 
            { parameters: "rm=suggestions"  }
        )
    //-->
    </script>

Next, make sure that you have the appropriate C<< <div> >> in your HTML to contain
those suggestions (most likely immediately below the form input). It would also probably
be desireable to turn the browser's built-in auto-completion off for this field.

    <input type="text" name="keywords" id="keywords" autocomplete="off" />
    <div class="auto_complete" id="keywords_auto_complete"></div>

The last step is to make sure that you have the appropriate CSS styles defined so that
your auto-suggested results can be shown in the client. The easiest to get these CSS rules
is from HTML::Prototype. Take the output from the following command, paste it into your
templates and customize to match your look and feel.

    perl -MHTML::Prototype -e 'print HTML::Prototype->auto_complete_stylesheet . "\n"';

=head1 AUTHOR

Michael Peters <mpeters@plusthree.com>

Thanks to Plus Three, LP (http://www.plusthree.com) for sponsoring my work on this module.

=head1 CONTRIBUTORS

=over

=item Sam Tregar <sam@tregar.com>

=back

=cut

# just in case someone is stupid enough to actually 'use' us :)

1;

