package App::Toodledo;
use strict;
use warnings;

our $VERSION = '2.17';

BEGIN { $PPI::XS_DISABLE = 1 }  # PPI::XS throws deprecation warnings in 5.16

use File::Spec;
use Digest::MD5 'md5_hex';
use Moose;
use MooseX::Method::Signatures;
use MooseX::ClassAttribute;
use JSON;
use URI::Encode qw(uri_encode);
use LWP::UserAgent;
use Date::Parse;
use YAML qw(LoadFile DumpFile);
use Log::Log4perl::Level;
with 'MooseX::Log::Log4perl';

use App::Toodledo::TokenCache;
use App::Toodledo::InfoCache;
use App::Toodledo::Account;
use App::Toodledo::Task;
use App::Toodledo::TaskCache;
use App::Toodledo::Util qw(home arg_encode preferred_date_format);

my $HOST          =  'api.toodledo.com';
my $ROOT_URL      =  "http://$HOST/2/";

class_has Info_File_Name  => ( is => 'rw', default => '.toodledorc' );
class_has Token_File_Name => ( is => 'rw', default => '.toodledo_token' );

has app_id        => ( is => 'rw', isa => 'Str', required => 1, );
has app_token     => ( is => 'rw', isa => 'Str', );
has user_id       => ( is => 'rw', isa => 'Str' );
has password      => ( is => 'rw', isa => 'Str', );
has key           => ( is => 'rw', isa => 'Str', );
has session_token => ( is => 'rw', isa => 'Str', );
has session_key   => ( is => 'rw', isa => 'Str', );
has user_agent    => ( is => 'ro', default => \&_make_user_agent );
has info_cache    => ( is => 'rw', isa => 'App::Toodledo::InfoCache' );
has account_info  => ( is => 'rw', isa => 'App::Toodledo::Account' );
has task_cache    => ( is => 'rw', isa => 'App::Toodledo::TaskCache' );

#initializes log4perl to log to screen if it hasn't been initialized
#Will default to $ERROR, if $ENV{APP_TOODLEDO_DEBUG} then will set to
#logger to $debug
sub BUILD
{
  if (!Log::Log4perl->initialized())#TODO: make it smart
  {
    if (defined $ENV{APP_TOODLEDO_DEBUG})
    {
        Log::Log4perl->easy_init($DEBUG);
    }
    else
    {
      Log::Log4perl->easy_init($ERROR);
    }
  }
}


method get_session_token ( Str :$app_token?, Str :$user_id? ) {
  my $app_id   = $self->app_id;
  $user_id   ||= $self->user_id or $self->log->logdie("No user_id");
  $app_token ||= $self->app_token or $self->log->logdie("No app_token");
  $self->user_id( $user_id );
  $self->app_token( $app_token );

  my $session_token = $self->_session_token_from_cache( $user_id, $app_id,
						        $app_token);
  $self->session_token( $session_token );
  $session_token;
}


method _session_token_from_cache ( Str $user_id!, Str $app_id!, Str $app_token! ) {
  my $token_cache = $self->_token_cache;
  my $session_token;
  if ( my $token_info = $token_cache->valid_token( user_id => $user_id,
						   app_id  => $app_id ) )
  {
    $self->log->debug( "Have valid saved token\n" );
    $session_token = $token_info->token;
  }
  else
  {
    $session_token = $self->new_session_token( $app_token );
    $token_cache->add_token_info( user_id => $user_id,
				  app_id  => $app_id,
				  token   => $session_token );
    $token_cache->save;
  }
  $session_token;
}


method get_session_token_from_rc ( Str $user_id? ) {
  $user_id ||= $self->user_id || $self->default_user_id
    or $self->log->logdie( "No user_id and no default user_id");
  my $app_id = $self->app_id;
  my $app_token = $self->app_token_of( $app_id )
    or $self->log->logdie("Cannot get app_token for $app_id");
  $self->get_session_token( app_token => $app_token, user_id => $user_id );
}


method _make_session_key ( Str $password!, Str $app_token!, Str $session_token! ) {
  md5_hex( md5_hex( $password ) . $app_token . $session_token );
}


method connect ( Str $password! ) {
  my $session_token = $self->session_token
    or $self->log->logdie("Need to get session token first");
  my $key = $self->_make_session_key( $password, $self->app_token,
				      $session_token );
  $self->session_key( $key );
  my $account_ref = $self->get( 'account' ) or $self->log->logdie( "No account info");
  $self->account_info( $account_ref );
  $key;
}


method login ( Str :$user_id, Str :$password!, Str :$app_token! ) {
  $self->app_token( $app_token );
  $self->get_session_token( user_id => $user_id, app_token => $app_token );
  $self->connect( $password );
}


method login_from_rc ( Str $user_id? ) {
  my @args = $user_id ? $user_id : ();
  $self->get_session_token_from_rc( @args );
  my $password = $self->password_of( $self->user_id )
    or $self->log->logdie("Cannot get password");
  $self->log->debug( "Loaded password from info cache\n" );
  $self->connect( $password );
}


sub _token_cache
{
  my $file = _token_cache_name();

  App::Toodledo::TokenCache->new_from_file( $file );
}


sub _token_cache_name
{
  File::Spec->catfile( home(), __PACKAGE__->Token_File_Name );
}


method app_token_of ( Str $app_id! ) {
  my $cache = $self->_get_info_cache;
  $cache->app_token_ref->{$app_id};
}


method password_of ( Str $user_id! ) {
  my $cache = $self->_get_info_cache;
  $cache->password_ref->{$user_id};
}


method default_user_id () {
  my $cache = $self->_get_info_cache;
  $cache->default_user_id;
}


method _get_info_cache () {
  my $file = _info_cache_name();

  $self->info_cache and return $self->info_cache;
  $self->log->debug( "Fetching info cache\n" );
  my $cache = App::Toodledo::InfoCache->new_from_file( $file );
  $self->info_cache( $cache );
  $cache;
}


sub _info_cache_name
{
  File::Spec->catfile( home(), __PACKAGE__->Info_File_Name );
}


method new_session_token ( Str $app_token! ) {
  my $sig    = $self->_signature( $self->user_id, $app_token );
  my $argref = { appid  => $self->app_id,
		 userid => $self->user_id,
		 sig    => $sig };
  $self->log->debug( "Creating new session token\n" );
  my $ref = $self->call_func( account => token => $argref );
  $ref->{token};
}


method _signature( Str $user_id!, Str $app_token! ) {
  md5_hex( "$user_id$app_token" );
}


method get ( Str $type!, %param ) {
  my $class = __PACKAGE__ . '::' . ucfirst( $type );
  $class =~ s/s\z//;
  eval "require $class";

  if ( $type eq 'tasks' )
  {
    $param{fields} ||= join ',' => $class->optional_attributes;  # All fields
    $param{start}  ||= 0;
  }

  my @things;
  FETCH: {
    my $ref = $self->call_func( $type => 'get', \%param );
    my @returned = ref $ref eq 'ARRAY' ? @$ref : $ref;

    my $counter = $type eq 'tasks' ? shift @returned : ();
    push @things, map { $class->new( %$_ ) } @returned;
    if ( $type eq 'tasks' && @returned )  # They have a different first field
    {
      if ( $param{start} + $counter->{num} != $counter->{total} )
      {
	$self->log->debug( "Start = $param{start}, Total = $counter->{total}, "

		. " Num = $counter->{num}\n" );
	$param{start} += $counter->{num};
	redo FETCH;
      }
    }
  }  # FETCH

  @things = sort { $a->ord <=> $b->ord } @things
    if @things && $things[0]->{ord};
  wantarray ? @things : shift @things;
}


sub _make_user_agent  # Might want to use Mechanize some day?
{
  LWP::UserAgent->new;
}


method call_func ( Str $func!, Str $subfunc!, HashRef $argref? ) {
  my $user_agent = $self->user_agent;
  $argref ||= {};
  $argref->{key} = $self->session_key if $self->session_key;
  $self->log->debug( "Calling function $func/$subfunc\n" );
  my %encoded_args = map { $_,  arg_encode( $argref->{$_} ) }
                         keys %$argref;
  my $res = $user_agent->post( "$ROOT_URL$func/$subfunc.php",
			       \%encoded_args );
  $res->code != 200
    and $self->log->logdie( "Unable to contact Toodledo\n");
  my $ref = decode_json( $res->content )
    or $self->log->logdie( "Content invalid\n");

  $self->log->logdie( $ref->{errorCode} == 500 ? "Toodledo offline\n"
                                 : "Error: " . $ref->{errorDesc})
    if ref $ref eq 'HASH' && $ref->{errorCode};
  $ref;
}


method select ( ArrayRef[Object] $o_ref, Str $expr ) {
  my $prototype = $o_ref->[0] or return;

  # XXX CODE SMELL: refactor to polymorphic method
  if ( ref( $prototype ) =~ /task/i )
  {
    $expr =~ s/(.*)/($1) && completed == 0/ unless $expr =~ /completed/;
  }

  $expr =~ s/\b$_\b/\$self->$_/g for $prototype->attribute_list;
  $self->log->debug( "Searching in " . @$o_ref . "objects for '$expr'\n" );
  my $selector = sub { my $self = shift; eval $expr };
  $self->grep_objects( $o_ref, $selector );
}


method grep_objects ( ArrayRef[Object] $o_ref, CodeRef $selector ) {
  grep { $selector->( $_ ) } @$o_ref;
}


method foreach ( ArrayRef[Object] $o_ref, CodeRef $callback, @args ) {
  for ( @$o_ref )
  {
    $callback->( $_, @args );
    $App::Toodledo::Task::can_use_cache = 1;
  }
}


# @args here is just for testing purposes. If used for real code, will
# produce unexpected and erroneous results.
method get_tasks_with_cache ( @args ) {
  $self->task_cache_valid and return $self->task_cache->tasks;
  # -1 => Completed & uncompleted tasks
  my @tasks = $self->get( tasks => comp => -1, @args );
  $self->store_tasks_in_cache( @tasks );
  @tasks;
}


method task_cache_valid () {
  my $ai = $self->account_info;
  unless ( $self->task_cache )
  {
    $self->task_cache( App::Toodledo::TaskCache->new );
    return unless $self->task_cache->exists;
    $self->task_cache->fetch;
  }

  my $fetched = $self->task_cache->last_updated;
  my $logstr = "Edited: " . localtime( $ai->lastedit_task )
             . ", Deleted: " . localtime( $ai->lastdelete_task )
             . " Fetched: " . localtime( $fetched );
  if ( $ai->lastedit_task >= $fetched || $ai->lastdelete_task >= $fetched )
  {
    $self->log->debug( "Task cache invalid ($logstr)\n" );
    return;
  }
  $self->log->debug( "Task cache valid ($logstr)\n" );
  return 1;
}


method store_tasks_in_cache ( App::Toodledo::Task @tasks ) {
  $self->task_cache or $self->task_cache( App::Toodledo::TaskCache->new );
  $self->task_cache->store( @tasks );
}


# Add a new whatever
method add( Object $object! ) {
  $object->add( $self );
}


method edit ( Object $object, @more ) {
  $object->edit( $self, @more );
}


# Remove a whatever... it needs only have the id field populated
method delete( Object $object ) {
  $object->delete( $self );
}


method readable ( Object $object, Str $attribute ) {
  my $value = $object->$attribute;
  if ( $attribute =~ /date\z/ )
  {
    $value or return '';
    return preferred_date_format( $self->account_info->dateformat, $value );
  }
  $value;
}


1;

__END__

=head1 NAME

App::Toodledo - Interacting with the Toodledo task management service.

=head1 SYNOPSIS

    use App::Toodledo;

    my $todo = App::Toodledo->new( user_id => 'rudolph', app_id => 'MyAppID' );
    $todo->login( password => 'secret', app_token => 'api2729372' )

    $todo = App::Toodledo->new( app_id => 'MyAppID' );
    $todo->login_from_rc;

    my @folders = $todo->get( 'folders' );
    my @tasks   = $todo->get_tasks_with_cache;
    my $time = time;

    # Tasks due in next day
    my @wanted  = $todo->select( \@tasks,
                  "duedate < $time + $ONEDAY && duedate  > $time" );
    my @privates = $todo->select( \@folders, "private > 0" );

    $todo->foreach( \@tasks, \&manipulate );
    $todo->edit( @tasks );

=head1 DESCRIPTION

Toodledo (L<http://www.toodledo.com/>) is a web-based capability for managing
to-do lists along Getting Things Done (GTD) lines.  This module
provides a Perl-based access to its API.

B<This version is a minimal port to version 2 of the Toodledo API.
It is not at all backwards compatible with version 0.07 or earlier of this
module.>
Toodledo now frowns upon using version 1 of the API; not using an
application token makes it almost impossible to get anything useful
done.

What do you need the API for?  Doesn't the web interface do everything
you want?  Not always.  See the examples included with this distribution.
For instance, Toodledo has only one level of notification and it's either
on or off.  With the API you can customize the heck out of notification.
Or suppose you want to find tasks where the due date has erroneously
been set to before the start date.  Toodledo lets you do this and the
online search function can't find them.  But with C<App::Toodledo> it's
as simple as:

  say $_->title for $todo->select( \@tasks => q{duedate && startdate > duedate} )

This is a very basic, preliminary Toodledo module.  I wrote it to do the
few things I wanted out of an API and when I feel a need for some
additional capability, I'll add it.  In the mean time, if there's something
you want it to do, feel free to submit a patch.  Or, heck, if you're
sufficiently motivated, I'll let you take over the whole thing.

This module uses L<MooseX::Method::Signatures> to perform argument validation.
If you violate the type checking you will quite probably get upwards of a
hundred lines of error messages.  That's the way it goes.

=head1 METHODS

=head2 $todo = App::Toodledo->new( %option );

Construct a new Toodledo handle.  No connection to the service is made.
Options are:

=over 4

=item app_id

Application ID.  See the Toodledo API documentation for details.

=item app_token

Application token.

=item user_id

User ID.

=back

The app_id entry in the option hash is mandatory.  The others may be
left out and supplied elsewhere.

=head2 $todo->get_session_token( user_id => $user_id, app_token => $app_token )

This call creates a session token and caches it in a file in your home
directory called C<.toodledo_token>, unless that file already exists and
contains a token younger than three hours, in which case
that one will be used.  The
published lifespan of a Toodledo token is four hours.  The
C<$app_token> must be the token given to you by the Toodledo site when
you registered the application that this code is running. The user_id is
the long string on your Toodledo account's "Settings" page.

If the user_id is not supplied here it must have been given in the
constructor.  Ditto for the app_token.

=head2 $todo->get_session_token_from_rc( [ $user_id ] )

Same as C<get_session_token>, only it obtains the arguments
from a YAML file in your home directory called C<.toodledorc>.
See the FILES section below for instructions on how to format
and populate that file.  If no C<user_id> is specified it will
look for and use a C<default_user_id> in the .toodledorc file.

=head2 $todo->login( %option )

The C<%option> hash must include the entries for C<password>
and C<app_token>.  Optionally it can include C<user_id>; if not
specified here, it must have been sent in the constructor.

=head2 $todo->login_from_rc( [$user_id] )

Optionally specify the user_id, else the same rules apply as for
C<get_session_token_from_rc>. The password will be taken from the
one associated with that user_id in the .toodledorc file.

=head2 $todo->call_func( $function, $subfunction, $argref )

Low-level Toodledo API access.  You should not need to use this unless
you're extending the App::Toodledo::Account functionality. (Please
contribute patches.)  C<$argref> is a hashref of arguments to the
call.  Refer to the Toodledo API documentation for formatting and
encoding.

=head2 $app_token = $todo->app_token_of( $app_id )

Convenience function for returning the application token of a given
application id by reading it from the .toodledorc file.

=head2 $password = $todo->password_of( $user_id )

Convenience function for returning the password for a given
user_id by reading it from the .toodledorc file.

=head2 $user_id = $todo->default_user_id

Convenience function for returning the default user_id by
reading it from the .toodledorc file.

$token = $todo->new_session_token( $app_token )

Return the temporary session token given the application token.
The user_id and app_id are read from the object.

=head2 @objects = $todo->get( $type )

Fetch and return a list of some kind of thing, the choices being the following
strings:

=over 4

=item tasks

=item folders

=item goals

=item contexts

=item notebooks

=back

The returned list will be of the corresponding App::Toodledo::I<whatever>
objects.  There are optional arguments for tasks:

=head2 @tasks = $todo->get( tasks => %param )

The optional named parameters correspond to the parameters that can be
specified in the Toodledo tasks/get API call: modbefore, modafter,
comp, start, num, fields.  Note that this call will not cache the
tasks returned, so it is safe to play with these parameters.  This
method will default C<fields> to all available fields.  It does I<not>
change C<comp>, which the Toodledo API defaults to all uncompleted tasks
only.

=head2 @tasks = $todo->get_tasks_with_cache( %param )

Same as get( tasks => %param ), except that the tasks are fetched from
the cache file C<~/.toodledo_task_cache> if it is still valid (Toodledo
reports no changes since cache update).  If there is no cache file, it
is populated after the tasks are fetched from Toodledo.  This fetches
all tasks, including completed ones, so can take a while.

=head2 $id = $todo->add( $object )

The argument should be a new App::Toodledo::I<whatever> object to be created.
The result is the id of the new object. Any of the standard object types
can be added.
Note: this method is overridden in App::Toodledo::Task.

=head2 $todo->delete( $object )

Delete the given object from Toodledo. The C<id> attribute of the object
must be correctly set. No other attributes will be used.
Note: this method is overridden in App::Toodledo::Task.

=head2 $todo->edit( $object )

The given object will be updated in Toodledo to match the one passed.
Note: this method is overridden in App::Toodledo::Task.  When the object
is a task, the signature is:

=head2 $todo->edit( $task, [@tasks] )

All of the tasks will be edited.  You are responsible for ensuring
that you do not exceed Toodledo limits on the number of tasks passed
(currently 50).

=head2 @objects = $todo->select( \@objects, $expr );

Select just the objects you need from the given array, based upon the
expression.  Any attribute of the given objects specified in the exprssion
will br turned into an object accessor for that attribute and the resulting
expression must be syntactically correct.  Any Perl code can be used; it will
be passed through C<eval>.  Examples:

=over 4

=item tag eq "garden" && status > 3

Must have the 'garden' tag (and only that tag) amd a status greater
than the index for the status value 'Planning'.  (Only makes sense for
a task list.)  To access (or change) the status as a string,
use C<status_str>.

=item title =~ /deliver/i && comp == 1

Title must match regex and task must be completed.

=back

The type of object is determined from the first one in the arrayref.

=head2 @objects = $todo->grep_objects( \@objects, $coderef )

Run $coderef for each object in the list.  Called by the
C<select> method but can be used by the user.  Ones for which
the C<$coderef> returns true will be passed through to the result.

=head2 $todo->foreach( \@objects, $coderef, [@args] )

Run the coderef on each object in the arrayref.  C<$coderef>
will be called with the object as the first argument and
any C<@args> as the rest.

=head2 $todo->readable( $object, $attribute )

Currently just looks to see if the given C<$attribute> of C<$object>
is a date and if so, returns the C<preferred_date_formst> string
from L<App::Toodledo::Util> instead of the stored epoch second count.
If the date is null, returns an empty string (rather than the Toodledo
display of "no date").

=head1 ERRORS

Any API call may croak if it returns an error.

=head1 FILES

=head2 ~/.toodledo_token

This file is in YAML format and caches the session token for one or
more application ids.  You should not need to edit it.

=head2 ~/.toodledorc

This file is in YAML format and is where you keep information to save
having to enter it in login calls.  It is not written by App::Toodledo.
It is of the following format:

  ---
  app_tokens:
    <app_id>: <app_token>
  default_user_id: <user_id>
  passwords:
    <user_id>: <password>

The app_id line may be repeated for as many application ids that you have.
It supplies the application token corresponding to each app_id.  Since
the app_id is a mnemonic string like 'cpantest' and the app_token is
a hex identifier supplied by Toodledo like 'api4e49ce90e5c31', this saves
the trouble of copying arcane strings into every program.
The password line may be repeated for as many user ids that you want
to manage.
The default_user_id is optional and will be used if none is specified
in a login call.

=head2 ~/.toodledo_task_cache

This file is in YAML format and is used by App::Toodledo to store a
cache of tasks.  You should not need to edit it.  If App::Toodledo is
using this cache and you believe it to be invalid, delete this file.

=head1 ENVIRONMENT

App::Toodledo uses log4perl for error logging and debug messages.  By
default they will be outputted to STDOUT, and STDERR.  A log4perl can
be specified in the users application, if one is not set App::Toodledo
will use Log::Log4perl::easy_init($ERROR); Setting the environment
variable C<APP_TOODLEDO_DEBUG> will cause debugging-type information
to be output to log4perl logger.  If a logger hasn't been set
App::Toodledo will use Log::Log4perl::easy_init($DEBUG);


=head1 AUTHOR

Peter J. Scott, C<< <cpan at psdt.com> >>

=head1 CONTRIBUTORS

Thanks to Edward Ash for the Log4Perl integration!

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-toodledo at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Toodledo>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

Realistically, I am not likely to have the time to respond to any bug
reports that don't impact code I use personally unless they include
complete fixes in the form of a patch file.  New functionality should
include documentation and test patches.

=head1 TODO

Help improve App::Toodledo!  Some low-hanging fruit you might want to
submit a patch for:

=over 4

=item *

Improve task caching to not be all-or-nothing.  Use SQLite and check
only for which tasks need to be added or removed.

=item *

Bulk addition of tasks.  (Bulk editing is enabled but currently
undocumented - see App::Toodledo::Task::edit.)

=item *

Separate task cache age testing from loading the whole cache, takes
too long.

=item *

Flesh out the L<App::Toodledo::Account> class with the methods
for querying an account.

=item *

Handling of the *date/*time attributes needs to be coordinated
so it is useful.

=back

=head1 EXAMPLES

To find all tasks with the 'Home' context and add a 'DIY' tag if not there:

  use App::Toodledo;
  my $todo = App::Toodledo->new( app_id => 'myregisteredappid' );
  $todo->login_from_rc;
  my @all_tasks = $todo->get_tasks_from_cache;
  for my $task ( $todo->select( \@tasks, 'context eq "Home" ) )
  {
    next if $task->has_tag( 'DIY' );
    $task->tag( $task->tag . ',DIY' );
    $todo->edit( $task );
  }

Feel free to contribute more examples as short and complete as that one
via email!

=head1 OBJECT MODEL

App::Toodledo is Moose-based.  Each of the object types (task, folder,
context, goal, location, notebook, and the account singleton) is
represented via an object class App::Toodledo::Task, App::Toodledo::Folder,
etc.  Each one of those classes contains each Toodledo attribute as
a writable attribute, e.g. $task->context( 12345 ). Additional methods
can be added (e.g., 'tags' is a simple convenience method for
App::Toodledo::Task) in each of those classes; the Toodledo attributes
are handled by being delegated to an internal object (e.g.,
App::Toodledo::TaskInternal) which implements a Role (e.g.,
App::Toodledo::TaskRole) that contains precisely and only the list
of Toodledo attributes.  (See L<App::Toodledo::Task> for details
on the C<context_name> method for accessing contexts via their names
instead of IDs.)

Therefore when Toodledo changes its attribute lists, change only
the corresponding Role class and everything will continue working.
You can add methods to the object class (e.g. App::Toodledo::Task)
without the class being cluttered with native Toodledo attributes.
You can override a Toodledo attribute if you ensure that the
base functionality still works; just call the method in the
delegated object directly.  (This delegate is named 'object'.)

=head1 DISCLAIMER

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM 'AS IS' WITHOUT
WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE
DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR
CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR
CONVEYS THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT
NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR
LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM
TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER
PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.


=head1 SUPPORT

You can find documentation for this module with the perldoc command:

    perldoc App::Toodledo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Toodledo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Toodledo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Toodledo>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Toodledo/>

=back

=head1 SEE ALSO

Toodledo API documentation: L<http://api.toodledo.com/2/account/>.

Getting Things Done, David Allen, ISBN 978-0142000281.

=head1 COPYRIGHT & LICENSE

Copyright 2009 - 2012 Peter J. Scott, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
