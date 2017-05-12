package Biblio::Refbase;

use 5.006;

use strict;
use warnings;

our $VERSION = '0.04';

$VERSION = eval $VERSION;

use Carp;
use HTTP::Request::Common;
use HTTP::Status ':constants';
use LWP::UserAgent;
use URI;
use URI::QueryParam;

use constant REFBASE_LOGIN            => 'user_login.php';
use constant REFBASE_IMPORT           => 'import_modify.php';
use constant REFBASE_SHOW             => 'show.php';
use constant REFBASE_ERROR            => 'error.php';

use constant REFBASE_DEFAULT_URL      => 'http://localhost/';
use constant REFBASE_DEFAULT_USER     => 'user@refbase.net';
use constant REFBASE_DEFAULT_PASSWORD => 'start';
use constant REFBASE_DEFAULT_RELOGIN  => 1;
use constant REFBASE_DEFAULT_FORMAT   => 'ASCII';

use constant REFBASE_MSG_NO_HITS      => 'Nothing found';
use constant REFBASE_MSG_FORBIDDEN    => 'you have no permission';
use constant REFBASE_MSG_ERROR        => 'The following error occurred';
use constant REFBASE_MSG_QUERY_ERROR  => 'Your query:';

use constant REFBASE_EXPORT_FORMATS => (
  'ADS',
  'Atom XML',
  'BibTeX',
  'Endnote',
  'ISI',
  'MODS XML',
  'OAI_DC XML',
  'ODF XML',
  'RIS',
  'SRW_DC XML',
  'SRW_MODS XML',
  'Word XML',
);

use constant REFBASE_CITATION_FORMATS => (
  'ASCII',
  'HTML',
  'LaTeX',
  'LaTeX .bbl',
  'Markdown',
  'PDF',
  'RTF',
);

use constant REFBASE_CITATION_STYLES => (
  'APA',
  'AMA',
  'MLA',
  'Chicago',
  'Harvard 1',
  'Harvard 2',
  'Harvard 3',
  'Vancouver',
  'Ann Glaciol',
  'Deep Sea Res',
  'J Glaciol',
  'Mar Biol',
  'MEPS',
  'Polar Biol',
  'Text Citation',
);

use constant REFBASE_QUERY_PARAMS => (
  'author',
  'title',
  'type',
  'year',
  'publication',
  'abbrev_journal',
  'keywords',
  'abstract',
  'thesis',
  'area',
  'notes',
  'location',
  'serial',
  'date',
  'contribution_id',
  'where',
);



#
#  constructor
#

sub new {
  my $class = shift;
  unshift @_, 'url' if @_ % 2;
  my %conf = @_;

  my $self = bless {}, $class;

  for (qw'url user password relogin format style order rows records ua') {
    if (defined(my $value = delete $conf{$_})) {
      $self->$_($value);
    }
  }

  my $version = eval '$' . $class . '::VERSION';
  my $client = 'cli-' . join '-', split /::/, $class;
  $client .= '-' . $version if defined $version;
  $self->{_client} = $client;

  unless ($self->ua) {
    unless (defined $conf{agent}) {
      my $agent = $class;
      $agent .= ' ' . $version if defined $version;
      $conf{agent} = $agent;
    }
    $conf{env_proxy} = 1 unless exists $conf{env_proxy};
    $self->ua(LWP::UserAgent->new(%conf));
  }

  return $self;
}



#
#  accessors
#

sub url {
  shift->_accessor('url', @_);
}

sub user {
  shift->_accessor('user', @_);
}

sub password {
  shift->_accessor('password', @_);
}

sub relogin {
  shift->_accessor('relogin', @_);
}

sub format {
  my $self = shift;
  if (@_) {
    my $format = shift;
    _check_format($format);
    $self->{format} = $format;
    return $self;
  }
  $self->{format};
}

sub style {
  my $self = shift;
  if (@_) {
    my $style = shift;
    _check_style($style);
    $self->{style} = $style;
    return $self;
  }
  $self->{style};
}

sub order {
  shift->_accessor('order', @_);
}

sub rows {
  shift->_accessor('rows', @_);
}

sub records {
  shift->_accessor('records', @_);
}

sub ua {
  my $self = shift;
  if (@_) {
    my $ua = shift;
    croak q{Accessor 'ua' requires an object based on 'LWP::UserAgent'}
      unless ref $ua and $ua->isa('LWP::UserAgent');
    $self->{ua} = $ua;
    return $self;
  }
  $self->{ua};
}



#
#  public instance methods
#

sub search {
  my $self = shift;
  my %args = @_;

  my $account = $self->_account_args(\%args);
  my $search  = $self->_search_args(\%args);

  if (%args) {
    croak q{Unknown arguments provided to 'search' method:}
      . join("\n    ", '', sort keys %args) . "\n";
  }

  return $self->_search($account, $search);
}

sub upload {
  my $self = shift;
  unshift @_, 'content' if @_ % 2;
  my %args = @_;

  my $account = $self->_account_args(\%args);
  my $upload  = $self->_upload_args(\%args);

  my $show = delete $args{show};
  $show = %args unless defined $show;

  my $search = $self->_search_args(\%args);

  if (%args) {
    croak q{Unknown arguments provided to 'upload' method:}
      . join("\n    ", '', sort keys %args) . "\n";
  }

  my $url = $account->{url} . REFBASE_IMPORT;

  my $request = $upload->{uploadFile}
    ? POST $url, Content_Type => 'form-data', Content => $upload
    : POST $url, $upload;

  my $response = $self->_request($account, $request);

  unless ($response->is_error) {
    if (defined(my $location = $response->header('location'))) {
      if ($location =~ /^(${\REFBASE_SHOW}\?)/o) {
        my $q = URI->new($location)->query_form_hash;
        my ($rows) = ($q->{headerMsg} || '') =~ /(\d+)/;
        my $records = $q->{records} || '';
        if ($show) {
          $search->{records} ||= $q->{records};
          $search->{rows} ||= $rows;
          $response = $self->_search($account, $search);
        }
        else {
          my $content = $q->{headerMsg} ? $q->{headerMsg} . ' ' : '';
          $content   .= $q->{records}  if $q->{records};
          $response->code(HTTP_OK);
          $response->message('');
          $response->content($content);
        }
        $response->records($records)->rows($rows);
      }
      else {
        $response->code(HTTP_NOT_IMPLEMENTED);
        $response->message('Unexpected redirect location');
      }
    }
    elsif (index(${$response->content_ref}, scalar REFBASE_MSG_FORBIDDEN) == 0) {
      $response->code(HTTP_FORBIDDEN);
      $response->message('');
    }
    else {
      $response->code(HTTP_NOT_IMPLEMENTED);
      $response->message('Unexpected response');
    }
  }
  return $response
}

sub ping {
  my $self = shift;
  unshift @_, 'url' if @_ % 2;

  # use 'simple_request' instead of 'head' so redirections won't be followed
  # thus a redirection (e.g. to error page) will fail, too
  return $self->ua->simple_request(
    HEAD $self->_account_args({ @_ })->{url}
  )->is_success;
}



#
#  public static methods
#

sub formats {
  return sort +REFBASE_CITATION_FORMATS, REFBASE_EXPORT_FORMATS;
}

sub styles {
  return sort +REFBASE_CITATION_STYLES;
}



#
#  static fields and helper functions
#

# format and style mappings/parameters in static fields

my %_formats = map {
  _normalize_format_name($_) => {
    exportFormat => $_,
    submit       => 'Export',
    exportType   => 'file'
  }
} REFBASE_EXPORT_FORMATS;

for (REFBASE_CITATION_FORMATS) {
  $_formats{_normalize_format_name($_)} = {
    citeType => $_ ,
    submit   => 'Cite'
  };
}

my %_styles = map {
  _normalize_style_name($_) => $_
} REFBASE_CITATION_STYLES;

# storage for user sessions

my %_sessions;

# normalization functions for format and style names

sub _normalize_format_name {
  (my $name = lc shift) =~ s/\s+xml$//;
  $name =~ s/ \./_/;
  return $name;
}

sub _normalize_style_name {
  (my $name = lc shift) =~ s/\s+//g;
  return $name;
}

# functions for checking format and style and getting parameters

sub _check_format {
  my $name = shift;
  return unless defined $name and length $name;
  if (defined(my $format = $_formats{_normalize_format_name($name)})) {
    return $format;
  }
  croak "Format '$name' not available.\n"
    . 'Available formats:'
    . join("\n    ", '', formats()) . "\n";
}

sub _check_style {
  my $name = shift;
  return unless defined $name and length $name;
  if (defined(my $style = $_styles{_normalize_style_name($name)})) {
    return $style;
  }
  croak "Citation style '$name' not available.\n"
    . 'Available styles:'
    . join("\n    ", '', styles()) . "\n";
}



#
#  private instance methods
#

# accessor helper method

sub _accessor {
  my $self = shift;
  my $field = shift;
  if (@_) {
    $self->{$field} = shift;
    return $self;
  }
  return $self->{$field};
}

# perform a search query

sub _search {
  my ($self, $account, $param) = @_;

  my $request = POST $account->{url} . REFBASE_SHOW, $param;
  my $response = $self->_request($account, $request, 1);

  if ($response->is_success) {
    # idea: could parse number of hits from content when using ASCII format
    # or explicitly re-send query with format=ASCII and rows=1
    # then set $response->rows, too!
    $response->hits(index(${$response->content_ref}, scalar REFBASE_MSG_NO_HITS) == 0 ? 0 : 1);
  }
  return $response;
}

# HTTP request and error handling

sub _request {
  my ($self, $account, $request, $redirect) = @_;
  my $relogin = $account->{relogin};
  my $failed = 0;
  {
    # catch possible login failure
    eval { $request->header( cookie => $self->_session($account) ) };
    my $response = $@ ? $@ : $self->ua->simple_request($request);

    if (defined(my $location = $response->header('location'))) {
      if ($location =~ /^${\REFBASE_LOGIN}(\?|$)/o) {
        # handle redirection to login page

        # undefine stored session string
        $self->_session($account, undef);

        if ($relogin > $failed++) {
          redo;
        }
        elsif ($relogin < 1) {
          $response->code(HTTP_REQUEST_TIMEOUT);
          $response->message('Relogin required but disabled');
        }
        else {
          $response->code(HTTP_UNAUTHORIZED);
          $response->message("Relogin failed (tried $relogin times)");
        }
      }
      elsif ($location =~ /^${\REFBASE_ERROR}(\?|$)/o) {
        # turn redirection to error page into HTTP error
        my $q = URI->new($location)->query_form_hash;
        my $content = $q->{headerMsg} ? $q->{headerMsg} . ' ' : '';
        $content   .= $q->{errorMsg} if $q->{errorMsg};
        $response->code(HTTP_INTERNAL_SERVER_ERROR);
        $response->message('');
        $response->content($content);
      }
      elsif ($redirect) {
        # follow the redirection with redirect count subtracted by 1
        return $self->_request($account, GET($account->{url} . $location), $redirect - 1);
      }
    }
    elsif ($response->is_success) {
      if (index(${$response->content_ref}, scalar REFBASE_MSG_ERROR) == 0) {
        # inconsistency in refbase: POST to show.php in search method
        # does not return redirection to error.php when MySQL database fails
        $response->code(HTTP_INTERNAL_SERVER_ERROR);
        $response->message('');
      }
      elsif (index(${$response->content_ref}, scalar REFBASE_MSG_QUERY_ERROR) == 0) {
        # inconsistency in refbase: GET from search.php (redirected by a POST)
        # does not return redirection to error.php when SQL query is broken
        $response->code(HTTP_BAD_REQUEST);
        $response->message('');
      }
    }
    return bless $response, 'Biblio::Refbase::Response';
  }
}

# user authentication, session handling and relogin

sub _session {
  my $self = shift;
  my $account = shift;
  my $url  = $account->{url};
  my $user = $account->{user};
  if (@_) {
    $_sessions{$url}->{$user} = shift;
    return $self;
  }
  unless ($_sessions{$url}->{$user}) {
    my $response = $self->ua->simple_request(POST $url . REFBASE_LOGIN, {
      loginEmail    => $user,
      loginPassword => $account->{password},
    });
    if ($response->is_redirect and my $cookie = $response->header('set-cookie')) {
      $_sessions{$url}->{$user} = (split /;/, $cookie)[0];
    }
    else {
      unless ($response->is_error) {
        $response->code(HTTP_UNAUTHORIZED);
        $response->message('Login request denied');
        # wipe out HTML page
        $response->content('');
      }
      # raise an exception
      die $response;
    }
  }
  return $_sessions{$url}->{$user};
}

# setup account configuration from arguments hash, dynamic and static defaults

sub _account_args {
  my ($self, $args) = @_;

  my $url = delete $args->{url} || $self->url || REFBASE_DEFAULT_URL;
  $url .= '/' if substr($url, -1) ne '/';
  $url = 'http://' . $url unless $url =~ m{^https?://};

  my $relogin = delete $args->{relogin};
  $relogin = $self->relogin unless defined $relogin;
  $relogin = defined $relogin && $relogin =~ /(\d+)/ ? int $1 : REFBASE_DEFAULT_RELOGIN;

  return {
    url      => $url,
    user     => delete $args->{user}     || $self->user     || REFBASE_DEFAULT_USER,
    password => delete $args->{password} || $self->password || REFBASE_DEFAULT_PASSWORD,
    relogin  => $relogin,
  };
}

# mapping of module's argument names to refbase names

my %_names = (
  records => 'records',
  order   => 'citeOrder',
  rows    => 'showRows',
  start   => 'startRecord',
  query   => 'queryType',
  view    => 'viewType',
);

# setup search parameters from arguments hash, dynamic and static defaults

sub _search_args {
  my ($self, $args) = @_;
  my %param;

  for (REFBASE_QUERY_PARAMS) {
    if (defined(my $value = delete $args->{$_})) {
      $param{$_} = $value;
    }
  }
  $param{serial} = '.+' unless %param;

  my $format = $self->_format(delete $args->{format});
  @param{keys %$format} = values %$format;

  if (not exists $args->{style} or defined(my $style = delete $args->{style})) {
    if (defined($style = $self->_style($style))) {
      $param{citeStyle} = $style;
    }
  }

  for (qw'records order rows') {
    if (my $value = delete $args->{$_} || $self->$_) {
      $param{$_names{$_}} = $value;
    }
  }
  for (qw'start query view') {
    if (my $value = delete $args->{$_}) {
      $param{$_names{$_}} = $value;
    }
  }

  if (delete $args->{showquery}) {
    $param{showquery} = 1;
  }
  if (defined(my $showlinks = delete $args->{showLinks})) {
    $param{showLinks} = 0 if $showlinks eq '0';
  }
  $param{client} = $self->{_client};

  return \%param;
}

# setup upload parameters from arguments hash, dynamic and static defaults

sub _upload_args {
  my ($self, $args) = @_;
  my %param;

  if (defined(my $content = delete $args->{content})) {
    $param{uploadFile} = [ undef, 'filename', Content => $content ];
    $param{formType} = 'import';
  }
  elsif (defined(my $source_ids = delete $args->{source_ids})) {
    $param{sourceIDs} = ref $source_ids eq 'ARRAY'
      ? join ' ', @$source_ids
      : $source_ids;
    $param{formType} = 'importID';
  }
  else {
    croak q{upload requires either record content supplied by parameter 'content' or }
        . q{a list of record IDs in parameter 'source_ids'};
  }
  if (delete $args->{skipbad}) {
    $param{skipBadRecords} = 1;
  }
  if (defined(my $only = delete $args->{only})) {
    $param{importRecords} = $only;
    $param{importRecordsRadio} = 'only';
  }
  $param{client} = $self->{_client};

  return \%param;
}

# get the format and style parameters

sub _format {
  my ($self, $name) = @_;
  return _check_format($name || $self->format || REFBASE_DEFAULT_FORMAT);
}

sub _style {
  my ($self, $name) = @_;
  return _check_style($name || $self->style);
}



# extension to HTTP::Response

package Biblio::Refbase::Response;

# todo: investigation required on adding a DESTROY method

use base 'HTTP::Response';

sub _accessor {
  my $self = shift;
  my $field = '_BRR_' . shift;
  if (@_) {
    $self->{$field} = shift;
    return $self;
  }
  return $self->{$field};
}

sub hits { shift->_accessor('hits', @_) }

sub rows { shift->_accessor('rows', @_) }

sub records { shift->_accessor('records', @_) }



1;

__END__

=head1 NAME

Biblio::Refbase - Perl interface to refbase bibliographic manager

=head1 VERSION

This is Biblio::Refbase version 0.0.2, tested against refbase 0.9.5.

=head1 SYNOPSIS

  use Biblio::Refbase;

  my $refbase = Biblio::Refbase->new(
    url      => 'http://beta.refbase.net/',
    user     => 'guest@refbase.net',
    password => 'guest',
  );
  my $response = $refbase->search(
    keywords => 'baltic sea',    # Search in keywords.
    style    => 'Chicago',       # Set citation style.
  );
  if ($response->is_success) {   # all methods from
    if ($response->hits) {       # HTTP::Response
      print $response->content;  # available
    }
    else {
      print 'Nothing found!';
    }
  }
  else {
    print 'An error occurred: ', $response->status_line;
  }
  print "\n\n";

  $response = $refbase->upload(
    user       => 'user@refbase.net',  # Switch user for
    password   => 'user',              # this request.
    show       => 1,                   # Return records
    format     => 'BibTeX',            # in BibTeX format.
    source_ids => [                    # Upload records
      'arXiv:cs/0106057',              # from arXiv.org
      'arXiv:cond-mat/0210361',        # via source IDs.
    ],
  );
  if ($response->is_success) {
    print 'Number of records imported: ', $response->rows   , "\n";
    print 'ID range of records: '       , $response->records, "\n";
    print "Records:\n\n",  $response->content;
  }

  # Upload records by supplying a string of content:
  # $response = $refbase->upload( content => $content );

=head1 DESCRIPTION

Biblio::Refbase is an object-oriented interface to refbase
Web Reference Database sites.

refbase (L<http://www.refbase.net/>) is a web-based bibliographic manager
which can import and export references in various formats (including BibTeX,
Endnote, MODS and OpenOffice).

=head1 CONSTRUCTOR

=over 4

=item $refbase = Biblio::Refbase->new(%options);

Creates a new C<Biblio::Refbase> instance and returns it.

Key/value pair arguments set up the initial state. All arguments are
optional and define instance-wide default parameters for the method
calls that follow. With the exception of 'ua' these defaults can
be overridden on demand by method calls.

For missing parameters this module will either fall back to its own
static default values or let the targeted refbase site decide.

These are the default values used by this module:

  Key        Default             Comment
  --------------------------------------------------------------
  url        http://localhost/   base URL of a refbase site
  user       user@refbase.net
  password   start
  relogin    1                   relogin if session gets invalid
  format     ASCII               output format
  ua         (create new)        LWP::UserAgent object for reuse

The other available keys are:

  Key        Comment
  ------------------------------------
  style      citation style
  order      sort order of records
  rows       maximum number of records
  records    selection of record IDs

See L<"ACCESSORS"> section for further description.

Unless the key 'ua' contains an instance of C<LWP::UserAgent>, any additional
entries in the C<%options> hash will be passed unmodified to the constructor
of C<LWP::UserAgent>, which is used for performing the requests.

E.g. you can set your own user agent identification and specify a timeout
this way:

  $refbase = Biblio::Refbase->new(
    agent   => 'My Refbase Client',
    timeout => 5,
  );

=item $refbase = Biblio::Refbase->new($url);

=item $refbase = Biblio::Refbase->new($url, %options);

If the constructor is called with an uneven parameter list the first
element will be taken as the base URL:

  $refbase = Biblio::Refbase->new('http://localhost:8000/');

=back

=head1 ACCESSORS

The accessors are combined getter/setter methods. Used as setter
the instance will be returned, so setters can be chained. Example:

  $refbase->format('atom')->style('chicago');

=over 4

=item $refbase = $refbase->url($url);

Sets the default base URL of a refbase site. A trailing slash and
the scheme will be automatically added if omitted, i.e. these calls
will result in the same URL:

  $refbase->url('http://beta.refbase.net/');
  $refbase->url('http://beta.refbase.net');
  $refbase->url('beta.refbase.net');

The module's built-in default value for the base URL is 'http://localhost/'.

=item $url = $refbase->url;

Returns the current default base URL for this instance.

=item $refbase->user;

Returns/sets the default user name.
The module's default user is 'user@refbase.net'.

=item $refbase->password;

Returns/sets the default password.
The module's default password is 'start'.

=item $refbase->relogin;

Returns/sets the default value for automatic relogin. If a user session has
expired, the instance will try to relogin for as many times as set via
this accessor. A value of 0 disables the relogin feature. An undefined
value lets the instance use the module's default value of 1.

=item $refbase->format;

Returns/sets the default output format. The actual availability of a format
depends on the version of the targeted refbase installation.

This module should always know all output formats provided by the current
refbase software release.

Setting an unknown format lets the module croak.
The module's default format is 'ASCII'.

The known formats are:

   ADS
   ASCII
   Atom XML
   BibTeX
   Endnote
   HTML
   ISI
   LaTeX
   LaTeX .bbl
   Markdown
   MODS XML
   OAI_DC XML
   ODF XML
   PDF
   RIS
   RTF
   SRW_DC XML
   SRW_MODS XML
   Word XML

Case is ignored by the setter, the 'XML' appendices are optional and
'LaTeX .bbl' can also be written as 'LaTeX_bbl'. I.e. these statements set
the same format:

  $refbase->format('MODS XML');
  $refbase->format('mods');

Calling the C<formats> method returns a list of the known output formats.

=item $refbase->style;

Returns/sets the default citation style. The actual availability of a style
depends on the version of the targeted refbase installation.

This module should always know all citation styles provided by the
current refbase software release.

Setting an unknown style lets the module croak.

The known styles are:

  AMA
  Ann Glaciol
  APA
  Chicago
  Deep Sea Res
  Harvard 1
  Harvard 2
  Harvard 3
  J Glaciol
  Mar Biol
  MEPS
  MLA
  Polar Biol
  Text Citation
  Vancouver

Whitespace and case are ignored by the setter, i.e. these statements set
the same style:

  $refbase->style('Deep Sea Res');
  $refbase->style('deepseares');

Calling the C<styles> method returns a list of the known citation styles.

For more details on the styles and examples refer to page
'Citation styles' (L<http://www.refbase.net/index.php/Citation_styles>)
in the refbase documentation.

=item $refbase->order;

Returns/sets the default sort order for this instance.

refbase's internal default sort order is first by author fields, then year,
then title. This order is changed if one of the following values is provided:

  Value           Sort order
  ------------------------------------------------------
  year            year, then author and title
  type            type and thesis type, then default way
  type-year       type, thesis, year, author, title
  creation-date   date of creation, date of modification

=item $refbase->rows;

Returns/sets the default value for the maximum number of records to be
returned by a query.

=item $refbase->records;

Returns/sets the default record ID selection/range limiting subsequent
queries. IDs are separated by non-digits. A minus sign between two IDs defines
a range. The following statement sets a default selection of record ID 1
and all IDs from 5 to 8:

  $refbase->records('1,5-8');

=item $refbase->ua;

Returns/sets the C<LWP::UserAgent> object used by this instance for
performing HTTP requests.

=back

=head1 METHODS

=over 4

=item $response = $refbase->search(%args);

Searches a refbase database.

With the exception of 'ua' each instance-wide configurable value
can also be defined on a per-request basis (and thus will override
any given default).

See L<"ACCESSORS"> section for further description of these arguments:

  url        relogin   order
  user       format    rows
  password   style     records

The following keys correspond to fields in the refbase database:

  author            Author
  title             Title
  type              Type
  year              Year
  publication       Publication
  abbrev_journal    Abbreviated Journal
  keywords          Keywords
  abstract          Abstract
  thesis            Thesis
  area              Area
  notes             Notes
  location          Location
  serial            Serial (ID)
  date              Creation date
  contribution_id   institutional abbreviation

The 'date' key requires a date string in the format 'YYYY-MM-DD'.
The other fields can be searched with MySQL regular expressions.
For further details look at section 'Search syntax'
(L<http://www.refbase.net/index.php/Searching#Search_syntax>)
in the refbase documentation. For an explanation of the database fields
refer to page 'Table refs' (L<http://www.refbase.net/index.php/Table_refs>).

Custom search conditions:

  where       code for SQL WHERE clause

The content of the 'where' key must be valid MySQL code which refbase
will insert into the WHERE clause of its internally generated SQL query.

Field independent search arguments are:

  query       combination of searched fields: 'and' (default) or 'or'
  start       offset of the first search result, starting with 1

Special output options for ASCII and HTML formats:

  showquery   show SQL statement if set to 1 (ASCII only)
  showlinks   don't show links column if set to 0 (HTML only)
  view        view type (HTML only): 'Web', 'Print' or 'Mobile'

Refer to L<"EXAMPLES"> section for a short tutorial and working code
snippets.

=item $response = $refbase->upload(%args);

Imports/uploads records to a refbase database.

As with the C<search> method, all instance-wide configured values can be
overridden on a per-request basis (except 'ua'). See C<search> method and
L<"ACCESSORS"> section.

The C<upload> method requires one of these two keys to be present in the
arguments hash:

  content      a string containing records in a format known by refbase
  source_ids   a string or list of record IDs recognized by refbase

The 'source_ids' can be supplied either as a string of IDs separated by
blanks or as a reference to an array. If both keys are present, 'content'
will be used and 'source_ids' will be ignored.

Optional keys are:

  skipbad   skip unrecognized records if set to a true value
  only      record numbers/range to be imported from the source
  show      immediately search for the records imported by this call
            if set to a true value

If 'show' is set to a true value or any search field parameters (see
C<search> method) are present, the method call will perform a search request
after importing. The search request will automatically set the record selection
to the new IDs of the freshly imported records (overridable by 'records' key)
and the maximum number of records to the number of records that have
been imported (overridable by 'rows' key). I.e. if 'show' is true and no
search field parameters are set, the C<upload> method will return all
imported records (in the desired/default format and style).

Refer to L<"EXAMPLES"> section for a short tutorial and working code
snippets.

=item $response = $refbase->upload($content, %args);

If the constructor is called with an uneven arguments list the first
element will be taken as 'content'.

=item $boolean = $refbase->ping;

Checks if configured base URL is accessible.

=back

=head1 STATIC METHODS

=over 4

=item @formats = $refbase->formats;

=item @formats = Biblio::Refbase->formats;

Returns a list of available output formats known by this module.

=item @styles = $refbase->styles;

=item @styles = Biblio::Refbase->styles;

Returns a list of available citation styles known by this module.

=back

=head1 RESPONSE ACCESSOR METHODS

The C<search> and C<upload> methods return C<$response> objects.
A C<$response> object is a formerly instance of C<HTTP::Response>
that has been re-blessed into the package C<Biblio::Refbase::Response>.
This package subclasses C<HTTP::Response> and extends it by three fields
and the corresponding accessors. No methods are overridden.

=over 4

=item $response->hits;

Indicates the success of a C<search> request:

    1     search has found some records
    0     search has found nothing
  undef   search has failed

=item $response->rows;

Returns the number of records that have been imported by an C<upload>
request.

=item $response->records;

Returns the record ID range of the imported records, i.e. the first ID and the
last ID of the new records (joined by the minus sign). Or a single ID, if only
one record has been imported.

=back

See the documentation of C<HTTP::Response> for the methods inherited from
the base class.

=head1 EXAMPLES

=head2 Searching

First, a very simple example that will just perform a search without
applying any user parameters:

  $refbase  = Biblio::Refbase->new;   # create new instance
  $response = $refbase->search;       # search with defaults
  $content  = $response->content;     # store content

If there's an unmodified out-of-the-box installation of refbase at localhost,
C<$content> should now contain 5 records in ASCII format.

You should check the status of the C<$response> object before processing the
content. All accessors known from C<HTTP::Response> are available plus
L<the accessors added by this module|"RESPONSE ACCESSOR METHODS">:

  if ($response->is_success) {
    if ($response->hits) {            # hits is special to this module
      print "Found something!\n";
      $content = $response->content;
    }
    else {
      print "Found nothing!\n";
    }
  }
  else {
    print 'An error occurred: ', $response->status_line, "\n";
    $http_code = $response->code;
    $message   = $response->message;
  }

Let's provide the C<$refbase> object with connection parameters to access
the official beta refbase site:

  $refbase->url('http://beta.refbase.net/');
  $refbase->user('guest@refbase.net');
  $refbase->password('guest');

If you want you can chain the accessors:

  $refbase->url('http://beta.refbase.net/')
          ->user('guest@refbase.net')
          ->password('gest');

In the chained accessors example there was an intentional typo:
The password is wrong. This module will 'cast' the original response
from refbase (which redirects to a login page) to one having
the appropriate UNAUTHORIZED status code set and a short message
'Login request denied':

  if (($response = $refbase->search)->is_error) {
    print 'An error occurred: ', $response->status_line, "\n";
  }

=head2 Uploading data to refbase

More examples will be included in the next releases of this module.
Please refer to the L<"SYNOPSIS"> section for now.

=head1 BUGS AND LIMITATIONS

This module is ALPHA status. Interface and features could change.
Documentation and test suite are still incomplete. Some search options
have been omitted in this release.

=head1 SEE ALSO

=over 4

=item * refbase

L<http://www.refbase.net/>

=item * refbase Command line clients

L<http://cli.refbase.net/>

=item * L<LWP::UserAgent>

=item * L<HTTP::Response>

=back

=head1 AUTHOR

Henning Manske <hma@cpan.org>

=head1 ACKNOWLEDGEMENTS

Thanks to Matthias Steffens (info@refbase.net), the creator of refbase,
for encouraging feedback, explaining many details, testing this module
and commenting on the documentation.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2010 Henning Manske. All rights reserved.

This module is free software. You can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/>.

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
