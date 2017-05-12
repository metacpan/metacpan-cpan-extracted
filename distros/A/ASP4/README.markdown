# NAME

ASP4 - Fast, Simple and Scalable Web Development for Perl

# DESCRIPTION

ASP4 is a modern web development platform for Perl with a focus on speed, simplicity
and scalability.

# ASP OBJECTS

ASP4 brings our old friends `$Request`, `$Response`, `$Server` and `$Session`
back from the 1990's, but adds some new ever-present objects as well.  Together
the ASP objects provide a consistent interface to the incoming request, outgoing response,
server environment and configuration in-use by the application itself.

## $Form

This is a simple hash reference which contains the names and values of the incoming
request parameters for both GET and POST requests.

For example, the following request...

    /foo.asp?name=joe&color=red

...produces the following `$Form` object:

    $VAR1 = {
      name  => 'joe',
      color => 'red'
    };

Access form data just like any other hashref:

    Hello, <%= $Form->{name} %>, I see your favorite color is <%= $Form->{color} %>.

## $Server

The `$Server` object offers a few utility methods that don't really fit anywhere else.

### $Server->HTMLEncode( $string )

Given a string like `<br/>` returns a string like `&lt;br/&gt;`

### $Server->HTMLDecode( $string )

Given a string like `&lt;br/&gt;` returns a string like `<br/>`

### $Server->URLEncode( $string )

Given a string like `billg@microsoft.com` returns a string like `billg%40microsoft.com`

### $Server->URLDecode( $string )

Given a string like `billg%40microsoft.com` returns a string like `billg@microsoft.com`

### $Server->MapPath( $path )

Given a `$path` of `/foo.asp` would return something like `/var/www/example.com/htdocs/foo.asp`

### $Server->Mail( %args )

Sends an email via [Mail::Sendmail](http://search.cpan.org/perldoc?Mail::Sendmail).  In fact it simply calls the `sendmail(...)` function
provided by [Mail::Sendmail](http://search.cpan.org/perldoc?Mail::Sendmail).

Simple Example:

    $Server->Mail(
      from    => 'foo@bar.com',
      to      => 'bar@foo.com',
      subject => 'Hello, world!',
      message => 'this is a test message'
    );

To send an HTML email do the following:

    use MIME::Base64;
    $Server->Mail(
      from                        => 'foo@bar.com',
      to                          => 'bar@foo.com',
      subject                     => 'Hello, world!',
      'content-type'              => 'text/html',
      'content-transfer-encoding' => 'base64',
      message => encode_base64(<<"HTML")
    <html>
    <body>
      <p>This is an html email.</p>
      <p>You can see that <b>this text is bold</b>.</p>
    </body>
    </html>
    HTML
    );

Please see [Mail::Sendmail](http://search.cpan.org/perldoc?Mail::Sendmail) for further details and examples.

### $Server->RegisterCleanup( sub { ... }, \@args )

After the final response has been sent to the client, the server will execute
your subref and provide it the `\@args` passed in.

This is useful for long-running or asynchronous processes that don't require the
client to wait for a response.

## $Request

An instance of [ASP4::Request](http://search.cpan.org/perldoc?ASP4::Request), the `$Request` object contains specialized methods
for dealing with whatever the browser sent us.

Examples:

### $Request->Cookies( $name )

    my $cookie = $Request->Cookies("some-cookie-name");

### $Request->FileUpload( $field_name )

    if( my $file = $Request->FileUpload('avatar_pic') ) {
      # Handle the uploaded file:
      $file->SaveAs( "/var/media/$Session->{user_id}/avatar/" . $file->FileName );
    }

See also the [ASP4::FileUpload](http://search.cpan.org/perldoc?ASP4::FileUpload) documentation.

## $Response

An instance of [ASP4::Response](http://search.cpan.org/perldoc?ASP4::Response), the `$Response` object gives shortcuts for dealing
with the outgoing reply from the server back to the client.

Examples:

### $Response->Write( $string )

The following example prints the string `Hello, World!` to the browser:

    $Response->Write("Hello, World!");

Or, within an ASP script, `<%= "Hello, World" %>`

### $Response->Redirect( $url )

    $Response->Redirect( "/new/url/?foo=bar" );

### $Response->SetCookie( %args )

Setting cookies works as follows:

    $Response->SetCookie(
      name  => "cookie-name",
      value => "the-value",
      

    # The rest of these arguments are optional:
    

    # Expires: (If you don't specify the "expires" argument, the cookie will
    # be deleted when the browser is closed.
    expires => "3D",  # 3 days
    expires => "3H",  # or 3 hours
    expires => "3M",  # or 3 minutes
    

    # Domain: (defaults to $ENV{HTTP_HOST})
    domain  => ".example.com",    # works for *.example.com
    domain  => "www.example.com", # will ONLY work for www.example.com
    

      # Path:
      path    => "/some/folder/"    # will ONLY work within /some/folder/ on your website
    );

### $Response->Include( $path, %args )

ASP4's `$Response` object offers 3 different include methods.

    <!-- Normal SSI-style Include -->
    <!-- #include virtual="/includes/page.asp" -->

If you want to supply arguments to the included ASP script you can use `$Response->Include($path, \%args)`

    # Add the output of C</includes/page.asp> to the current output buffer:
    my %args = ( foo => "bar" );
    $Response->Include( $Server->MapPath("/includes/page.asp"), \%args );

`\%args` is optional.

Within the included ASP script, `\%args` is accessible like this:

    <%
      my ($self, $context, $args) = @_;
    %>

### $Response->TrapInclude( $path, %args )

Or if you need to capture the result of executing an ASP script and use it within
a variable, use `$Response->TrapInclude($path, \%args)`

    # Capture the output of C</includes/page.asp>:
    my %args = ( foo => "bar" );
    my $html = $Response->TrapInclude( $Server->MapPath("/includes/page.asp"), \%args );

`\%args` is optional.

Within the included ASP script, `\%args` is accessible like this:

    <%
      my ($self, $context, $args) = @_;
    %>

## $Session

The `$Session` object is an instance of a subclass of [ASP4::SessionStateManager](http://search.cpan.org/perldoc?ASP4::SessionStateManager)
(depending on your website's configuration).

The `$Session` object is a simple blessed hashref and should be used like a hashref.

Examples:

### Set a session variable

    $Session->{foo} = "bar";

    $Session->{thing} = {
      banana  => "yellow",
      cherry  => "red",
      peach   => "pink,
    };

### Get a session variable

    my $foo = $Session->{foo};

### $Session->save()

Called automatically at the end of every successful request, causes any changes
to the `$Session` to be saved to the database.

### $Session->reset()

Call `$Session->reset()` to clear all the data out of the session and save 
it to the database.

## $Config

The ASP4 `$Config` object is stored in a simple JSON format on disk, and accessible
everywhere within your entire ASP4 application as the global `$Config` object.

If ever you find yourself in a place without a `$Config` object, you can get one
like this:

    use ASP4::ConfigLoader;
    my $Config = ASP4::ConfigLoader->load();

See [ASP4::Config](http://search.cpan.org/perldoc?ASP4::Config) for full details on the ASP4 `$Config` object and its usage.

## $Stash

The `$Stash` is a simple hashref that is guaranteed to be the exact same hashref
throughout the entire lifetime of a request.

Anything placed within the `$Stash` at the very beginning of processing a request -
such as in a RequestFilter - will still be there at the very end of the request -
as in a RegisterCleanup handler.

Use the `$Stash` as a great place to store a piece of data for the duration of
a single request.

# DATABASE

While ASP4 __does not require__ its users to choose any specific database (eg: MySQL or PostgreSQL)
or ORM (object-relational mapper) the __recommended__ ORM is [Class::DBI::Lite](http://search.cpan.org/perldoc?Class::DBI::Lite)
since it has been completely and thoroughly tested to be 100% compatible with ASP4.

For full documentation about [Class::DBI::Lite](http://search.cpan.org/perldoc?Class::DBI::Lite) please view its documentation.

__NOTE:__ [Class::DBI::Lite](http://search.cpan.org/perldoc?Class::DBI::Lite) must be installed in addition to ASP4 as it is a separate library.

# ASP4 QuickStart

Here is an example project to get things going.

In the `data_connections.main` section of `conf/asp4-config.json` you should have
something like this:

    ...
      "main": {
        "dsn":              "DBI:mysql:database_name:data.mywebsite.com",
        "username":         "db-username",
        "password":         "db-pAsswOrd"
      }
    ...

Suppose you had the following tables in your database:

    create table users (
      user_id     bigint unsigned not null primary key auto_increment,
      email       varchar(200) not null,
      password    char(32) not null,
      created_on  timestamp not null default current_timestamp,
      unique(email)
    ) engine=innodb charset=utf8;
    

    create table messages (
      message_id    bigint unsigned not null primary key auto_increment,
      from_user_id  bigint unsigned not null,
      to_user_id    bigint unsigned not null,
      subject       varchar(100) not null,
      body          text,
      created_on    timestamp not null default current_timestamp,
      foreign key fk_messages_to_senders (from_user_id) references users (user_id) on delete cascade,
      foreign key fk_messages_to_recipients (to_user_id) references users (user_id) on delete cascade
    ) engine=innodb charset=utf8;

__NOTE:__ It's best to assign every ASP4 application its own namespace.  For this
example the namespace is `App::db::`

Create the file `lib/App::db/model.pm` and add the following lines:

    package App::db::model;
    

    use strict;
    use warnings 'all';
    use base 'Class::DBI::Lite::mysql';
    use ASP4::ConfigLoader;
    

    # Get our configuration object:
    my $Config = ASP4::ConfigLoader->load();
    

    # Get our main database connection info:
    my $conn = $Config->data_connections->main;
    

    # Setup our database connection:
    __PACKAGE__->connection(
      $conn->dsn,
      $conn->username,
      $conn->password
    );
    

    1;# return true:

Add the following `Class::DBI::Lite` entity classes:

`lib/App/db/user.pm`

    package App::db::user;
    

    use strict;
    use warnings 'all';
    use base 'App::db::model';
    use Digest::MD5 'md5_hex';
    use ASP4::ConfigLoader;
    

    __PACKAGE__->set_up_table('users');
    

    __PACKAGE__->has_many(
      messages_in =>
        'App::db::message'  =>
          'to_user_id'
    );
    

    __PACKAGE__->has_many(
      messages_out  =>
        'App::db::message'  =>
          'from_user_id'
    );
    

    # Hash the password before storing it in the database:
    __PACKAGE__->add_trigger( before_create => sub {
      my ($self) = @_;
      

      # Sign the password instead of storing it as plaintext:
      unless( $self->{password} =~ m{^([a-f0-9]{32})$}i ) {
        $self->{password} = $self->hash_password( $self->password );
      }
    });
    

    # Hash the new password before storing it in the database:
    __PACKAGE__->add_trigger( before_update_password => sub {
      my ($self, $old, $new) = @_;
      

      unless( $new =~ m{^([a-f0-9]{32})$}i ) {
        $self->{password} = $self->hash_password( $new );
      }
    });
    

    # Verify an email/password combination and return the user if a match is found:
    sub check_credentials {
      my ($self, %args) = @_;
      

    my ($result) = $self->search(
      email     => $args{email},
      password  => $self->hash_password( $args{password} ),
    );
    

      $result ? return $result : return;
    }
    

    # Convert a password string into its hashed value:
    sub hash_password {
      my ($self, $str) = @_;
      

      my $key = ASP4::ConfigLoader->load->system->settings->signing_key;
      return md5_hex( $str . $key );
    }
    

    1;# return true:

`lib/App/db/message.pm`

    package App::db::message;
    

    use strict;
    use warnings 'all';
    use base 'App::db::model';
    

    __PACKAGE__->set_up_table('messages');
    

    __PACKAGE__->belongs_to(
      sender  =>
        'App::db::user' =>
          'from_user_id'
    );
    

    __PACKAGE__->belongs_to(
      recipient =>
        'App::db::user' =>
          'to_user_id'
    );
    

    1;# return true:

Create your MasterPage like this:

File: `htdocs/masters/global.asp`

    <%@ MasterPage %>
    <!DOCTYPE html>
    <html>
      <head>
        <title><asp:ContentPlaceHolder id="meta_title"></asp:ContentPlaceHolder></title>
        <meta charset="utf-8" />
      </head>
      <body>
        <h1><asp:ContentPlaceHolder id="headline"></asp:ContentPlaceHolder></h1>
        <asp:ContentPlaceHolder id="main_content"></asp:ContentPlaceHolder>
      </body>
    </html>

File: `htdocs/index.asp`

    <%@ Page UseMasterPage="/masters/global.asp" %>
    

    <asp:Content PlaceHolderID="meta_title">Register</asp:Content>
    

    <asp:Content PlaceHolderID="headline">Register</asp:Content>
    

    <asp:Content PlaceHolderID="main_content">
    <%
      # Sticky forms work like this:
      if( my $args = $Session->{__lastArgs} ) {
        map { $Form->{$_} = $args->{$_} } keys %$args;
      }
      

      # Our validation errors:
      my $errors = $Session->{validation_errors} || { };
      $::err = sub {
        my $field = shift;
        my $error = $errors->{$field} or return;
        %><span class="field_error"><%= $Server->HTMLEncode( $error ) %></span><%
      };
    %>
    <form id="register_form" method="post" action="/handlers/myapp.register">
      <p>
        <label>Email:</label>
        <input type="text" name="email" value="<%= $Server->HTMLEncode( $Form->{email} ) %>" />
        <% $::err->("email"); %>
      </p>
      <p>
        <label>Password:</label>
        <input type="password" name="password" />
        <% $::err->("password"); %>
      </p>
      <p>
        <label>Confirm Password:</label>
        <input type="password" name="password2" />
        <% $::err->("password2"); %>
      </p>
      <p>
        <input type="submit" value="Register Now" />
      </p>
    </form>
    </asp:Content>

The form submits to the URL `/handlers/app.register` which means `handlers/app/register.pm`

File: `handlers/app/register.pm`

    package app::register;
    

    use strict;
    use warnings 'all';
    use base 'ASP4::FormHandler';
    use vars __PACKAGE__->VARS; # Import $Response, $Form, $Session, etc
    use App::db::user;
    

    sub run {
      my ($self, $context) = @_;
      

    # If there is an error, return the user to the registration page:
    if( my $errors = $self->validate() ) {
      $Session->{validation_errors} = $errors;
      $Session->{__lastArgs} = $Form;
      $Session->save;
      return $Response->Redirect( $ENV{HTTP_REFERER} );
    }
    

    # Create the user:
    my $user = eval {
      App::db::user->do_transaction(sub {
        return App::db::user->create(
          email     => $Form->{email},
          password  => $Form->{password},
        );
      });
    };
    

    if( $@ ) {
      # There was an error:
      $Session->{validation_errors} = {email => "Server error.  Sorry!"};
      $Session->{__lastArgs} = $Form;
      $Session->save;
      return $Response->Redirect( $ENV{HTTP_REFERER} );
    }
    else {
      # No error - Sign them in:
      $Session->{user_id} = $user->id;
      $Session->{msg} = "Thank you for registering!";
      $Session->save;
      

        # Redirect to /profile.asp:
      return $Response->Redirect("/profile.asp");
      }# end if()
    }
    

    sub validate {
      my ($self) = @_;
      

    $self->trim_form;
    

    my $errors = { };
    no warnings 'uninitialized';
    

    # email:
    if( length($Form->{email}) ) {
      # Basic email validation:
      unless( $Form->{email} =~ m{[^@]+@[^@]+\.[^@]+} ) {
        $errors->{email} = "Invalid email address";
      }
    }
    else {
      $errors->{email} = "Required";
    }
    

    # password:
    unless( length($Form->{password} ) {
      $errors->{password} = "Required";
    }
    

    # password2:
    if( length($Form->{password2}) ) {
      if( length($Form->{password}) ) {
        unless( $Form->{password} eq $Form->{password2} ) {
          $errors->{password2} = "Passwords don't match";
        }
      }
    }
    else {
      $errors->{password2} = "Required";
    }
    

    # Bail out of we already have errors:
    return $errors if keys %$errors;
    

    # See if the user already exists:
    if( App::db::user->count_search( email => $Form->{email} ) ) {
      $errors->{email} = "Already in use";
    }
    

      # Errors or not?:
      keys %$errors ? return $errors : return;
    }
    

    1;# return true:

File: `htdocs/profile.asp`

    <%@ Page UseMasterPage="/masters/global.asp" %>
    

    <asp:Content PlaceHolderID="meta_title">My Profile</asp:Content>
    

    <asp:Content PlaceHolderID="headline">My Profile</asp:Content>
    

    <asp:Content PlaceHolderID="main_content">
    <%
      if( my $msg = $Session->{msg} ) {
    %>
      <div class="message"><%= $msg %></div>
    <%
      }# end if()
    %>
    

    <%
      # Get our $user:
      use App::db::user;
      my $user = App::db::user->retrieve( $Session->{user_id} );
    %>
    

    <div style="float: left; width: 40%; border-right: solid 1px #000;">
      <h3>Incoming Messages</h3>
    <%
      foreach my $msg ( $user->messages_in(undef, { order_by => "created_on ASC"} ) ) {
    %>
      <div class="msg">
        <span class="from"><%= $msg->sender->email %></span> says:<br/>
        <div class="body"><%= $Server->HTMLEncode( $msg->body ) %></div>
        <span class="date"><%= $msg->created_on %></span>
      </div>
    <%
      }# end foreach()
    %>
    </div>
    

    <div style="float: right; width: 40%; border: dotted 1px #000;">
      <h3>Send New Message</h3>
      <form id="send_form" method="post" action="/handlers/app.send">
        <p>
          <label>Recipient:</label>
          <select name="to_user_id">
    <%
      my @users = App::db::user->search_where({
        user_id => {'!=' => $user->id }
      }, {
        order_by => "email"
      });
      foreach my $user ( @users ) {
    %>
            <option value="<%= $user->id %>"><%= $Server->HTMLEncode( $user->email ) %></option>
    <%
      }# end foreach()
    %>
          </select>
        </p>
        <p>
          <label>Subject:</label>
          <input type="text" name="subject" maxlength="100" />
        </p>
        <p>
          <label>Message:</label><br/>
          <textarea name="body"></textarea>
        </p>
        <p>
          <input type="submit" value="Send Message" />
        </p>
      </form>
    </div>
    </asp:Content>

The form submits to `/handlers/app.send` which maps to `handlers/app/send.pm`

File: `handlers/app/send.pm`

    package app::send;
    

    use strict;
    use warnings 'all';
    use base 'ASP4::FormHandler';
    use vars __PACKAGE__->VARS;
    use App::db::user;
    use App::db::message;
    

    sub run {
      my ($self, $context) = @_;
      

    # Create the message:
    my $msg = eval {
      App::db::message->do_transaction(sub {
        my $msg = App::db::message->create(
          from_user_id  => $Session->{user_id},
          to_user_id    => $Form->{to_user_id},
          subject       => $Form->{subject},
          body          => $Form->{body},
        );
        

        # Send an email to the recipient:
        $Server->Mail(
          from        => 'root@localhost',
          'reply-to'  => $msg->sender->email,
          to          => $msg->recipient->email,
          subject     => 'New in-club message',
          message     => <<"MSG",
    Dear user,
    

    Another user (@{[ $msg->sender->email ]}) has sent you an in-club message.
    

    Please login and view it on your profile at http://$ENV{HTTP_HOST}/
    

    Yours,
    The "In Club"
    MSG
        );
        

        # Finally:
        return $msg;
      });
    };
    

      if( $@ ) {
        $Session->{msg} = "Error: Your message could not be sent.";
        $Session->save;
        return $Response->Redirect( $ENV{HTTP_REFERER} );
      }
      else {
        $Session->{msg} = "New message sent successfully.";
        $Session->save;
        return $Response->Redirect( $ENV{HTTP_REFERER} );
      }
    }

# BUGS

It's possible that some bugs have found their way into this release.

Use RT [http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4](http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4) to submit bug reports.

# HOMEPAGE

Please visit the ASP4 homepage at [http://0x31337.org/code/](http://0x31337.org/code/) to see examples
of ASP4 in action.

# AUTHOR

John Drago <jdrago_999@yahoo.com>

# COPYRIGHT

This software is Free software and may be used and redistributed under the same
terms as perl itself.