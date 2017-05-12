package CGI::Application::Search;
use base 'CGI::Application';
use strict;
use warnings;
use Carp;
use CGI::Application::Plugin::AnyTemplate;
use Data::Page;
use File::Spec::Functions qw(catfile splitpath catdir);
use Number::Format qw(format_bytes format_number);
use HTML::FillInForm;
use Time::HiRes;
use Time::Piece;
use POSIX qw(ceil);
use Text::Context;
use Unicode::Normalize;
use Encode qw(decode_utf8 encode_utf8);
use File::Slurp qw(read_file);

our $VERSION = '1.14';
our (
    $DEBUG,                # a debug flag
    @SUGGEST_CACHE,        # cached suggestions
    $SUGGEST_CACHE_TIME    # time of the last cache
);
$SUGGEST_CACHE_TIME = 0;

# some thing that will never appear in any doc that let's us return everything
our $BLANK_SEARCH = 'not asdfqweasdfasdflqkqoiqnwlekjiquwoienlkqw';

# load SWISH::API and complain if not available.  This is done here
# and not in Makefile.PL because SWISH::API is not on CPAN.  It's part
# of the Swish-e distribution.
BEGIN {
    eval "use SWISH::API";
    croak(<<END) if $@;

Unable to load SWISH::API.  This module is included in the Swish-e
distribution, inside the perl/ directory.  Please see the
CGI::Application::Search documentation for more details.

Error returned was: $@

END
}

__PACKAGE__->add_callback(
    init => sub {
        my $self = shift;
        return unless $self->param('UTF8');
        my $q = $self->query;
        $q->charset('UTF-8');

        # mark the strings as UTF8 so other stuff doesn't have to worry about it
        my @names = $q->param();
        foreach my $name (@names) {
            my @values = $q->param($name);
            foreach my $i (0 .. $#values) {
                # don't do filehandles
                next if lc(ref $values[$i]) eq 'fh';
                $values[$i] = Unicode::Normalize::NFC(decode_utf8($values[$i]));
            }

            $q->param($name => @values);
        }
    }
);

=head1 NAME 

CGI::Application::Search - Base class for CGI::App Swish-e site engines

=head1 SYNOPSIS

    package My::Search;
    use base 'CGI::Application::Search';

    sub cgiapp_init {
        my $self = shift;
        $self->param(
            'SWISHE_INDEX' => 'my-swishe.index',
            'TEMPLATE'     => 'search_results.tmpl',
        );
    }

    sub cgiapp_prerun {
        my $self  = shift;
        my $query = $self->query;

        # let the user turn context highlighting off
        $self->param('HIGHLIGHT' => 0) if $query->param('highlight_off');

        # let the user change which property is used in the sort
        my $sort_by = $query->param('sort_by');
        $self->param('SORT_BY' => $sort_by) if $sort_by;
    }

    1;

=head1 DESCRIPTION

A L<CGI::Application> based control module that uses Swish-e API in
perl (L<http://swish-e.org>) to to perform searches on a swish-e index
of documents.

=head2 Features

=over

=item * Sub-Classable. Unlike the Perl examples that come with swish-e,
this is not a script, and can be customized without modifiying the
original so that several sites may share the same underlying code.

=item * Uses L<CGI::Application::Plugin::AnyTemplate> to allow flexibility
in template engine choice (L<HTML::Template>, L<Template-Toolkit>
or L<Petal>).

=item * Built-in templates to use out of box or as examples for your
own templates

=item * HiLighted search results

=item * HiLighted pages linked from search results

=item * AJAX results sent to page without need of a page reload

=item * AJAX powered 'auto-suggest' to give the user list of choices
available for search

=back

=head1 TUTORIAL

If this is your first time using Swish-e (or you think you need
a refresher) or if you want step-by-step instructions on how to
use the AJAX capabilities of this module, then please see the
L<"Tutorial"|CGI::Application::Search::Tutorial>.

=head1 RUN_MODES

The start_mode is B<show_search>.

=head2 show_search()

This method will load the template pointed to by the B<TEMPLATE> param
(falling back to a default internal template if none is specified) and
display it to the user.  It will 'associate' this template with $self
so that any parameters in $self->param() are also accessible to the
template. It will also use L<HTML::FillInForm> to fill in the search form
with the previously selected parameters (unless it's a 'non-page-refresh'
AJAX search).

=cut 

sub show_search {
    my $self = shift;
    my $q    = $self->query();

    my $tmpl_file;

    # if we have a user specified template
    if ($self->param('TEMPLATE')) {
        $tmpl_file = $self->param('TEMPLATE');

    } else {
        # what type of template do we want?
        my $ext = $self->param('TEMPLATE_TYPE') eq 'TemplateToolkit' ? '.tt' : '.tmpl';

        # is it an AJAX template?
        $tmpl_file = ($self->param('AJAX') ? 'ajax_' : '') . "search_results$ext";
        $tmpl_file = catfile($self->param('DEFAULT_TEMPLATE_PATH'), $tmpl_file);
    }
    my $tmpl = $self->template->load($tmpl_file);

    # give it all the stuff in $self
    $tmpl->param(self => $self);
    foreach my $param qw(
      searched elapsed_time keywords hits first_page
      last_page prev_page next_page pages start_num
      stop_num total_entries
      ) {
        $tmpl->param($param => $self->param($param))
          if ($self->param($param));
      }

      # add this url to the template too
      $tmpl->param(url => $q->url(-absolute => 1, path_info => 1));

    # add the possible ajax flag
    $tmpl->param(ajax => $q->param('ajax'));

    my $output = $tmpl->output();

    # don't use FiF if we are using AJAX
    unless ($self->param('AJAX') && $q->param('ajax')) {
        my $filler = HTML::FillInForm->new();
        $output = $filler->fill(
            scalarref => ref($output) ? $output : \$output,
            fobject => $q,
            ($self->param('FIF_DEFAULTS') ? %{$self->param('FIF_DEFAULTS')} : ())
        );
    }
    return $output;
}

=head2 perform_search()

This is where the meat of the searching is performed. We create a
L<SWISH::API> object on the B<SWISHE_INDEX> and create the query for the
search based on the value of the I<keywords> parameter in CGI and any
other B<EXTRA_PROPERTIES>. The search is executed and if B<HIGHLIGHT>
is true we will use L<Search::Tools::HiLiter> to highlight it and then format
the results, only showing B<PER_PAGE> number of elements A paging list
is also shown for navigating through the results. Then we will return
to the B<show_search()> method for displaying everything.

=cut

sub _apply_range_values {
    my ($self, $search) = @_;
    my $q = $self->query;
    if ($self->param('EXTRA_RANGE_PROPERTIES')) {
        foreach my $prop (@{$self->param('EXTRA_RANGE_PROPERTIES')}) {
            my ($start, $stop) = ($q->param("${prop}_start"), $q->param("${prop}_stop"));
            if (defined $start and defined $stop) {
                $search->SetSearchLimit($prop, $start, $stop);
            }
        }
    }
}

sub perform_search {
    my $self = shift;
    my $q    = $self->query;

    # if we have any keywords
    my $keywords = $q->param('keywords');
    if (defined $keywords && !$self->param('results')) {
        my $index = $self->param('SWISHE_INDEX');

        # make sure the index exists and is readable
        croak "Index file $index does not exist!"
          unless (-e $index);

        $self->param('searched' => 1);
        my $start_time = Time::HiRes::time();

        # create my swish-e object
        my $swish = SWISH::API->new($index);
        croak "Problem reading $index : " . $swish->ErrorString
          if ($swish->Error);
        my $search = $swish->new_search_object();

        # add any range values
        $self->_apply_range_values($search);

        # set which property to sort by if given
        my $sort_by = $self->param('SORT_BY');
        $search->set_sort($sort_by) if $sort_by;

        my $search_query = $self->generate_search_query($keywords);

        # if we got one
        if (defined $search_query) {

            my $results = $search->execute($search_query);
            if ($swish->Error) {
                carp "Unable to create query: " . $swish->ErrorString
                  if ($DEBUG);
                return $self->show_search();
            }

            $self->param('elapsed_time' => format_number(Time::HiRes::time - $start_time, 3, 1));

            # create my pager and then go to the start page
            $self->_get_paging_vars($results);
            my @words = $self->_get_search_terms($swish, $search, $results, $keywords);
            $self->param(
                'hits' => $self->_process_results($swish, $search, $results, $search_query));
        } else {
            return $self->show_search();
        }
    }

    # if there are any extra properties used in the search, make them available to
    # the templates with the value in the query object
    my @extra_props;
    push(@extra_props, @{$self->param('EXTRA_PROPERTIES')}) if $self->param('EXTRA_PROPERTIES');
    push(@extra_props, @{$self->param('EXTRA_RANGE_PROPERTIES')})
      if $self->param('EXTRA_RANGE_PROPERTIES');
    foreach my $prop (@extra_props) {
        $self->param($prop => $q->param($prop));
    }
    $self->param('keywords' => $keywords);
    return $self->show_search();
}

=head2 highlight_remote_page

This run mode will fetch a remote page (with either a relative, or
absolute URL using the C<url> Query param) and highlight the keywords
used in the search on that page (the C<keywords> Query param) using the
B<HIGHLIGHT_TAG>, B<HIGHLIGHT_CLASS> or B<HIGHLIGHT_COLORS> options. This
run mode is best used in the links of the search results listing.

    <a href="?rm=highlight_remote_page;url=http%3A%2F%2Fexample.com%2Fabout_us%2Findex.html;keywords=Us">about us</a>

=cut

sub highlight_remote_page {
    my $self = shift;
    my $q    = $self->query();
    my $url  = $q->param('url');

    # if it's relative, get the hostname and make it absolute
    if ($url !~ /^https?:\/\//) {
        $url = $q->url(-base => 1) . $url;
    }
    return $self->_hilight_page($url);
}

sub _hilight_page {
    my ($self, $page) = @_;
    my $content;

    # Search::Tools::HiLiter doesn't like blank searches so handle those on our own
    if( -e $page ) {
        $content = decode_utf8(read_file($page));
    } else {
        require HTTP::Request;
        require LWP::UserAgent;
        my $ua  = LWP::UserAgent->new();
        my $request  = HTTP::Request->new( GET => $page);
        my $response = $ua->request($request);
        if ( $response->is_error ) {
            warn "Error: Couldn't get '$page': response code " . $response->code . "\n";
            return;
        }

        $content = $response->content;
    }

    my $search_query = $self->query->param('keywords');
    if( $search_query && $search_query ne $BLANK_SEARCH ) {
        eval { require Search::Tools::HiLiter };
        if ($@) {
            warn "Could not load Search::Tools::HiLiter so no hilighting will be done: $@";
        } else {
            $content = Search::Tools::HiLiter->new(
                tag    => $self->param('HIGHLIGHT_TAG'),
                class  => $self->param('HIGHLIGHT_CLASS'),
                colors => $self->param('HIGHLIGHT_COLORS'),
                query  => $search_query,
            )->hilite($content);
        }
    }
    return $content;
}

=head2 highlight_local_page

This run mode will fetch a local page (only allowing relative files based
in the B<DOCUMENT_ROOT> config var and the path using the C<path> Query
param) and highlight the keywords used in the search on that page (the
C<keywords> Query param) using the B<HIGHLIGHT_TAG>, B<HIGHLIGHT_CLASS>
or B<HIGHLIGHT_COLORS> options. This run mode is best used in the links
of the search results listing.

    <a href="?rm=highlight_local_page;path=%2Fabout_us%2Findex.html;keywords=Us">about us</a>

=cut

sub highlight_local_page {
    my $self     = shift;
    my $q        = $self->query();
    my $doc_root = $self->param('DOCUMENT_ROOT');
    my $path     = $q->param('path');

    if (!$doc_root) {
        croak "You must define your DOCUMENT_ROOT to use this run mode!";
    }

    # make sure $path doesn't have any '/..' tricks in it
    $path =~ s/\/\.\.//g;

    my $file = catfile($doc_root, $path);
    return $self->_hilight_page($file);
}

=head2 suggestions

This run mode will return an AJAX listing of words that should be
suggested to the user for the words that they have typed so far. It
uses the C<suggested_words()> method to actually choose which words to
send back.

=cut

sub suggestions {
    my $self = shift;

    if ($self->param('AUTO_SUGGEST')) {
        return $self->_auto_complete_results(
            $self->suggested_words($self->query->param('keywords')));
    } else {
        carp "Trying to use auto-suggest feature without AUTO_SUGGEST turned on!";
        return '';
    }
}

sub _auto_complete_results {
    my ($self, $values) = @_;
    my $html = '<ul>';
    foreach (@$values) {

        # straight from the CGI.pm bible.
        s/&/&amp;/g;
        s/\"/&quot;/g;    #"
        s/>/&gt;/g;
        s/</&lt;/g;
        s/'/&#39;/g;      #'
        $html .= "<li>$_</li>";
    }
    return $html . '</ul>';
}

=head1 OTHER METHODS

Most of the time you will not need to call the methods that are
implemented in this module. But in some cases customizing the templates
is not enought. If so, it might be prudent to override or extend these
methods in your derived class.

=head2 new()

We simply override and extend the L<CGI::Application> new() to setup
our defaults.

=cut

sub new {
    my ($class, %args) = @_;
    # setup my defaults
    $args{PARAMS} = {
        SWISHE_INDEX       => catfile('data', 'swish-e.index'),
        PER_PAGE           => 10,
        HIGHLIGHT          => 1,
        HIGHLIGHT_TAG      => q(strong),
        HIGHLIGHT_CLASS    => 'hilite',
        HIGHLIGHT_COLORS   => [],
        DESCRIPTION_LENGTH => 250,
        TEMPLATE_TYPE      => 'HTMLTemplate',
        TEMPLATE_CONFIG    => undef,
        UTF8               => 1,
        $args{PARAMS} ? %{$args{PARAMS}} : (),
    };

    my $self = $class->SUPER::new(%args);

    # setup the template configs
    my $path = catdir((splitpath($INC{'CGI/Application/Search.pm'}))[1], 'Search', 'templates',);
    $self->param('DEFAULT_TEMPLATE_PATH' => $path);
    my %tmpl_config = (
        default_type                => $self->param('TEMPLATE_TYPE'),
        auto_add_template_extension => 0,
        include_paths               => [$self->tmpl_path, $path],
        HTMLTemplate                => {
            global_vars       => 1,
            loop_context_vars => 1,
            die_on_bad_params => 0,
            associate         => $self,
        },
        HTMLTemplateExpr => {
            global_vars       => 1,
            loop_context_vars => 1,
            die_on_bad_params => 0,
            associate         => $self,
        },
        TemplateToolkit => {
            ABSOLUTE       => 1,
            DEBUG_PROVIDER => 1,
            DEBUG          => 1,
        },
    );

    # add any overriding TEMPLATE_CONFIG options
    if ($self->param('TEMPLATE_CONFIG')) {
        $tmpl_config{$self->param('TEMPLATE_TYPE')} =
          {%{$tmpl_config{$self->param('TEMPLATE_TYPE')}}, %{$self->param('TEMPLATE_CONFIG')},};
    }
    $self->template->config(%tmpl_config);
    return $self;
}

=head2 setup()

Here's were we setup our run modes. If you override this method, make
sure you also call it in your base class

    sub setup {
        my $self = shift;
        # do your thing
        ...
        $self->SUPER::setup();
    }

=cut

sub setup {
    my $self = shift;
    $self->start_mode('show_search');
    $self->run_modes(
        [
            qw(
              show_search
              perform_search
              highlight_remote_page
              highlight_local_page
              suggestions
              )
        ]
    );
}

=head2 generate_search_query($keywords)

This method is used to generate the query for swish-e from the
C<$keywords> (by default the 'keywords' CGI parameter), as well as any
B<EXTRA_PROPERTIES> that are present.

If you wish to generate your own search query then you should override
this method. This is common if you need to have access/authorization
control that will need to be taken into account for your search. (eg,
anything under /protected can't be seen by someone not logged in).

Please see the swish-e documentation on the exact syntax for the query.

=cut 

sub generate_search_query {
    my $self     = shift;
    my $keywords = shift;
    my $q        = $self->query;

    # create a new swish-e search object
    my $search = $keywords || '';
    $search =~ s/=/\=/g;    # escape '=' just in case

    # add any EXTRA_PROPERTIES to the search
    if ($self->param('EXTRA_PROPERTIES')) {
        foreach my $prop (@{$self->param('EXTRA_PROPERTIES')}) {
            my $value = $q->param($prop);
            $search .= ' and ' if $search;
            $search .= "$prop=($value)" if defined $value && length $value;
        }
    }

    return $search || $BLANK_SEARCH;
}

=head2 suggested_words($word)

This object method is used by the B<AUTO_SUGGEST> flag to return the words
that should be suggested to the user after they have typed a C<$word>.
It returns an array reference of those words.

By default it will just look for words in the B<AUTO_SUGGEST_FILE>
that begin with C<$word>. If you need more performance or flexibility
(eg, storing your words in a database and querying for them) you are
encouraged to override this method.

=cut

sub suggested_words {
    my ($self, $phrase) = @_;

    # just get the last word in this phrase
    my @phrase_words = split(/\s+/, $phrase);
    my $word = pop(@phrase_words);

    my $want_to_cache = $self->param('AUTO_SUGGEST_CACHE');
    my $file          = $self->param('AUTO_SUGGEST_FILE');
    my @suggestions;

    if (!$file) {
        warn "AUTO_SUGGEST_FILE was not specified!";
        return [];
    } elsif (!-r $file) {
        warn "AUTO_SUGGEST_FILE $file is not readable!";
        return [];
    }

    # if we are going to use the cache (meaning we want to use
    # it and there's up-to-date data in there)
    my $file_mod_time = (stat($file))[9];
    if (    $want_to_cache
        and @SUGGEST_CACHE
        and $SUGGEST_CACHE_TIME >= $file_mod_time)
    {
        foreach my $cached (@SUGGEST_CACHE) {

            # if it starts with this $word
            if (index($cached, lc $word) == 0) {
                push(@suggestions, $cached);

                # else if this is the first mis-match
            } elsif (@suggestions) {
                last;
            }

            # if we have a limit and we've reached it
            # don't do any more
            if (    $self->param('AUTO_SUGGEST_LIMIT')
                and @suggestions >= $self->param('AUTO_SUGGEST_LIMIT'))
            {
                last;
            }
        }

        # else we don't have anything cached, so just load from the file
    } else {

        # reset it if we want to cache
        if ($want_to_cache) {
            @SUGGEST_CACHE      = ();
            $SUGGEST_CACHE_TIME = time();
        }

        # read each line from the AUTO_SUGGEST_FILE
        my $IN;
        open($IN, '<', $file)
          or die "Could not open $file for reading! $!";

        # now look at each line
      LINE: while (my $line = <$IN>) {

            # if we want to cache the words in this file
            if ($want_to_cache) {
                chomp($line);
                push(@SUGGEST_CACHE, $line);
            }

            # if it starts with this $word
            if (index($line, lc $word) == 0) {
                chomp($line) unless ($want_to_cache);
                push(@suggestions, $line);

                # else if we aren't caching, and this is the first mis-match
                # then we want to finish and close the file
            } elsif (@suggestions && !$want_to_cache) {
                last LINE;
            }

            # if we have a limit and we've reached it
            # don't do any more
            if (    $self->param('AUTO_SUGGEST_LIMIT')
                and @suggestions >= $self->param('AUTO_SUGGEST_LIMIT'))
            {
                last;
            }
        }
        close($IN)
          or die "Could not close $file! $!";
    }

    # if we have something in the phrase that's not
    # in the word, add the phrase before the suggestion
    if (@phrase_words) {
        my $prefix = join(' ', @phrase_words);
        @suggestions = map { "$prefix $_" } @suggestions;
    }
    return \@suggestions;
}

=head1 CONFIGURATION

There are several configuration parameters that you can set at any time
(using C<< param() >> in your cgiapp_init, or PARAMS hash in new())
before the run mode is called that will affect the search and display
of the results. They are:

=head2 SWISHE_INDEX

This is the swishe index used for the searches. The default is
'data/swish-e.index'.  You will probably set this every time.

=head2 AJAX

This is a boolean indicating whether or not a non-page-refresh AJAX
search will be permitted.

Please see the L<"Tutorial"|CGI::Application::Search::Tutorial> for more
information on how to use the AJAX capabilities of this module.

=head2 TEMPLATE

The name of the search interface template. Default templates are included
with this distribution and will be used if you don't specify one. Which
default template is used depends on which B<TEMPLATE_TYPE> you are using
(I<HTMLTemplate> or I<TemplateToolkit>) and whether or not the B<AJAX>
flag is true.

These sample templates are installed with the module, or you can view them
by looking under the F<templates/> directory of the source distribution
(I<.tar.gz>).

Please see L<TEMPLATE USAGE> for more information on which variables
are passed into your template.

=head2 TEMPLATE_TYPE

This module uses L<CGI::Application::Plugin::AnyTemplate> to allow
flexibility in choosing which templating system to use for your
search. This works especially well when you are trying to integrate the
Search into an existing app with an existing templating structure.

This value is passed to the C<< $self->template->config() >> method as
the C<< default_type >>. By default it is 'HTMLTemplate'. Please see
L<CGI::Application::Plugin::AnyTemplate> for more options.

If you want more control of configuration for the template the it would
probably best be done by subclassing CGI::Application::Search and passing
your desired params to C<< $self->template->config >>.

=head2 PER_PAGE

How many search result items to display per page. The default is 10.

=head2 HIGHLIGHT

Boolean indicating whether or not we should highlight the description
given to the templates. The default is true.

=head2 HIGHLIGHT_TAG

The HTML tag used to surround the highlighted context. The default is C<<
strong >>.

=head2 HIGHLIGHT_CLASS

The class attribute of the B<HIGHLIGHT_TAG> HTML tag. This is useful
when you want to dictacte the style through a CSS style sheet. If given,
this value will override that of B<HIGHLIGHT_COLORS>. It has no value
by default.

=head2 HIGHLIGHT_COLORS

This is an array ref of acceptable HTML colors. If provided, it will
highlight each matching word/phrase in an alternating style. For instance,
if given 2 colors, every other highlighted phrase would be a different
color. By default it is an empty array.

=head2 EXTRA_PROPERTIES

This is an array ref of extra properties used in the search. By default,
the module will only use the value of the 'keywords' parameter coming
in the CGI query.  If anything is provided as an extra property then it
will be added to the query used in the search.

An example: You have some of you pages designated into categories. You
want the user to have the option of narrowing his results by category. You
add the word 'category' to the 'EXTRA_PROPERTIES' list and then you
add a 'category' form element that the user has the option of giving
a value to your search form. If the user gives that element a value,
then it will be seen and applied to the search. This will also only
work if you have the 'category' element defined for your documents (see
I<SWISH-E Configuration> and 'MetaNames' in the swish-e.org SWISH-CONF
documentation).

By default, this list is empty.

=head2 EXTRA_RANGE_PROPERTIES

This is almost exactly like the C<EXTRA_PROPERTIES> above except that
instead of searching for the given properties as simple strings, we
will use a range.  Since ranges need to values, if you're searching
for the C<foo> property, then you need to have a C<foo_start> and
a C<foo_end> value coming from the query. So if C<foo> is in your
C<EXTRA_RANGE_PROPERTIES> and you have a CGI query string like this:

    ?foo_start=123&foo_end=234

Then we will a generate a Swish-E query that looks something like this:

  -L foo 123 234

=head2 DESCRIPTION_LENGTH

This is the maximum length for the context (in chars) that is displayed
for each search result. The default is 250 characters.

=head2 DESCRIPTION_CONTEXT

This is the number of words on either side of the searched for words and
phrases (keywords) that will be displayed as part of the description. If
this is 0, then the entire description will be displayed. The default
is 0.

B<NOTE>: This directive will cause Search to use L<Text::Context>, which
can be slow and CPU intensive at times. These computations may prove to
be too much for some servers (eg, a shared hosting environment).

=head2 AUTO_SUGGEST

If true, then this will allow the broswer to give suggestions to the user
as they type. To use this, you must either use the B<AUTO_SUGGEST_FILE>
configuration option, or override the C<suggested_words()> method.

You template must also have the appropriate JavaScript code. Please see
the L<"Tutorial"|CGI::Application::Search::Tutorial> for more details.

=head2 AUTO_SUGGEST_FILE

The name of the file where the suggested words are stored. These words
should be in alphabetical order with one word per line.

=head2 AUTO_SUGGEST_CACHE

A boolean indicating whether or not the results of the
B<AUTO_SUGGEST_FILE> should be cached in memory or not. This will save
repeated file accesses when used in a persistant environment.

=head2 AUTO_SUGGEST_LIMIT

An integer count of the most suggestions to show the user at a time. This
is useful when you don't want to overwhelm the end user and take over
their screen with all of your helpful suggestions.

=head2 DOCUMENT_ROOT

This is the root directory to use when looking for files when using the
C<highlight_local_page> run mode.

=head2 SORT_BY

This is a string used by Swish-e to sort the results. The string is a
space separated list of valid document properties. Each property may
contain a qualifier (either C<asc> or C<desc>) that sets the direction
of the sort.  Leave it alone and Swish-e will sort by C<swishrank> in
descending order. But say you wanted to reverse that for some reason. You
could specify a C<SORT_BY> of

    swishrank asc

=head2 FIF_DEFAULTS

A hash reference of extra parameters that are passed to L<HTML::FillInForm>
when it does it's business with the forms. This is useful to telling
L<HTML::FillInForm> to skip certain forms or form elements.

=cut

#-------------------------PRIVATE METHODS-----------------------
sub _process_results {
    my ($self, $swish, $search, $results, $search_query) = @_;

    # now let's go through the results and build our loop
    my @result_loop = ();
    my $count       = 0;

    # while we still have more results
    while (my $current = $results->NextResult) {
        my %tmp = (
            reccount    => $current->Property('swishreccount'),
            rank        => $current->Property('swishrank'),
            title       => $current->Property('swishtitle'),
            path        => $current->Property('swishdocpath'),
            size        => format_bytes($current->Property('swishdocsize')),
            description => $current->Property('swishdescription') || '',
            last_modified =>
              localtime($current->Property('swishlastmodified'))->strftime('%B %d, %Y'),
        );

        # now add any EXTRA_PROPERTIES that we want to show
        if ($self->param('EXTRA_PROPERTIES')) {
            $tmp{$_} = eval { $current->Property($_) }
              foreach (@{$self->param('EXTRA_PROPERTIES')});
        }
        if ($self->param('EXTRA_RANGE_PROPERTIES')) {
            $tmp{$_} = eval { $current->Property($_) }
              foreach (@{$self->param('EXTRA_RANGE_PROPERTIES')});
        }

        my $description = $tmp{description};
        if ($description) {

            # if we want to zero in on the context
            if ($self->param('DESCRIPTION_CONTEXT')) {

                # get the keywords from the swish search
                my @keywords = ();
                foreach my $kw ($results->ParsedWords($self->param('SWISHE_INDEX'))) {

                    # remove boolean operators 'and', 'or' and 'not'
                    my $lc_kw = lc($kw);
                    if ($lc_kw ne 'and' && $lc_kw ne 'or' && $lc_kw ne 'not') {
                        push(@keywords, $kw);
                    }
                }

                # now get the context
                my $context = Text::Context->new($description, @keywords,);
                $description = $context->as_text();
            }

            # if we want to highlight the description
            if ($self->param('HIGHLIGHT') && $search_query && $search_query ne $BLANK_SEARCH) {
                eval { require Search::Tools::HiLiter };
                if ($@) {
                    warn "Could not load Search::Tools::HiLiter so no hilighting will be done: $@";
                } else {
                    my $hl = Search::Tools::HiLiter->new(
                        tag    => $self->param('HIGHLIGHT_TAG'),
                        class  => $self->param('HIGHLIGHT_CLASS'),
                        colors => $self->param('HIGHLIGHT_COLORS'),
                        query  => $search_query,
                    );
                    $description = $hl->plain($description);
                }
            }

            # now make sure it's the appropriate length
            $tmp{description} = substr($description, 0, $self->param('DESCRIPTION_LENGTH'));
        }
        push(@result_loop, \%tmp);

        # only go as far as the number per page
        ++$count;
        last if ($count == $self->param('PER_PAGE'));
    }
    return \@result_loop;
}

sub _get_search_terms {
    my ($self, $swish, $search, $results, $keywords) = @_;
    my @phrases = ();
    my %terms   = ();

    while ($keywords =~ /\G\s*"([^"]+)"/g) {
        push(@phrases, $1);
    }

    $keywords =~ s/"[^"]+?"//g;

    # remove stop words from highlighting
    # for some reason swish-e doesn't remove boolean operators as stop words... which
    # is probably good so that they actually get used in the searches, but still...
    my %stop_words = ();
    foreach my $word ($results->RemovedStopwords($self->param('SWISHE_INDEX')), 'and', 'or', 'not')
    {
        $stop_words{$word} = 1;
    }
    $stop_words{$_} = 1 foreach qw(and or not);

    for my $word (split(/\s+/, $keywords)) {
        if ($word) {
            next if $stop_words{$word};
            $terms{$word} = 1;
        }
    }

    # now look at the stems of these words
    $terms{$swish->fuzzify($swish->index_names, $_)->WordList} = 1 foreach (keys %terms);
    return keys %terms, @phrases;
}

# create a loop of pages with the first page, at most five pages before
# the current page, the current page, at most five pages after the current page
# and then the last page
sub _get_paging_vars {
    my ($self, $results) = @_;
    my @pages = ();

    # create my pager from the 'page' parameter in CGI or just use the first page
    my $page_num = $self->query->param('page') || 1;
    my $pager = Data::Page->new($results->Hits, $self->param('PER_PAGE'), $page_num);

    # go to the result that we want to look at first
    $results->SeekResult($pager->first - 1);

    # now let's create the paging summary vars
    $self->param('total_entries' => $pager->total_entries);
    $self->param('start_num'     => $pager->first);
    $self->param('stop_num'      => $pager->last);
    $self->param('next_page'     => $pager->next_page);
    $self->param('prev_page'     => $pager->previous_page);
    $self->param('first_page'    => $pager->first_page eq $page_num);
    $self->param('last_page'     => $pager->last_page eq $page_num);

    foreach (($page_num - 5) .. ($page_num + 5)) {
        # if we are in a real range
        if (($_ > 0) && ($_ <= ceil($pager->total_entries / $self->param('PER_PAGE')))) {
            my %hash = (page_num => $_, current => $_ eq $page_num);
            push(@pages, \%hash);
        }
    }
    $self->param(pages => \@pages) if ($#pages);
}

1;

__END__

=head1 TEMPLATE USAGE

Sample templates are included with this distribution.  These sample
templates are installed with the module, or you can view them by looking
under the F<templates/> directory of the source distribution (I<.tar.gz>).

Please feel free to copy and change them in what ever way you see fit. To
help give you more information to display (or not display, depending on
your preference) the following variables are available for your templates:

=head2 Global Tmpl Vars

These variables are available throughout the templates and contain
information related to the search as a whole:

=over 8

=item * ajax

A boolean indicating whether or not this search is an AJAX search or not.
You can use this flag to exclude everything but your search results in
your template.

=item * url

The URL of this application. This is useful if you want to use the same
templates in multiple applications, especially if you are using the AJAX
capabilities since they require the URL to submit to.

=item * searched

A boolean indicating whether or not a search was performed.

=item * keywords

The exact string that was recieved by the server from the input named
'keywords'

=item * elapsed_time

A string representing the number of seconds that the search took. This
will be a floating point number with a precision of 3.

=item * hits

This is an array of hashs (TMPL_LOOP in H::T) that contains one entry
for each result returned (for the current page). Each entry contains
the following keys:

=over 8

=item reccount

The C<swishreccount> property of the results as indexed by SWISH-E

=item rank

The rank to the result as given by SWISH-E (the C<swishrank> property)

=item title

The C<swishtitle> property of the results as indexed by SWISH-E

=item path

The C<swishdocpath> property of the results as indexed by SWISH-E

=item last_modified

The C<swishlastmodified> property of the results as indexed by SWISH-E
and then formatted using L<Time::Piece>'s C<strftime()> method with a
format string of C<%B %d, %Y>.

=item size

The C<swishdocsize> property of the results as indexed by SWISH-E and
then formatted with L<Number::Format>'s C<format_bytes()> method.

=item description

The C<swishdescription> property of the results as indexed by SWISH-E. If
B<HIGHLIGHT> is true, then this description will also have search
terms highlighted and will only be, at most, B<DESCRIPTION_LENGTH>
characters long.

=back

=item * pages

This is an array of hashes (TMPL_LOOP in H::T) that contains paging
information for the results. It contains the following keys:

=over 8

=item current

A boolean indicating whether or not this iteration is the current page
or not.

=item page_num

The integer number of the page.

=back

=item * first_page

This is a boolean indicating whether or not this page of the results is
the first or not.

=item * last_page

This is a boolean indicating whether or not this page of the results is
the last or not.

=item * prev_page

The integer number of the previous page. Will be 0 if there is no
previous page.

=item * next_page

The integer number of the next page. Will be 0 if there is no next page.

=item * start_num

This is the number of the first result on the current page

=item * stop_num

This is the number of the last result on the current page

=item * total_entries

The total number of results in their search, not the total number shown
on the page.

=back

=head1 OTHER NOTES

=over

=item *

If at any time prior to the execution of the 'perform_search' run mode
you set the C<< $self->param('results') >> parameter, a search will not
be performed. Instead those results are returned.  This is helpful when
you decide in the C<cgiapp_init> stage that this user does not have
permissions to perform the desired search.

=item *

You must use the I<StoreDescription> setting in your Swish-e configuration
file. If you don't you'll get an error when C::A::Search tries to retrieve
a description for each hit.

=back

=head1 AUTHOR

Michael Peters <mpeters@plusthree.com>

Thanks to Plus Three, LP (http://www.plusthree.com) for sponsoring my
work on this module.

=head1 CONTRIBUTORS

=over

=item Sam Tregar <sam@tregar.com>

=item Mark Stosberg <mark@summersault.com>

=item Eric Folley <efolley@plusthree.com>

=back


