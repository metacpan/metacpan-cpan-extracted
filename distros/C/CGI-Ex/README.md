# NAME

CGI::Ex - CGI utility suite - makes powerful application writing fun and easy

[![master](https://travis-ci.org/ljepson/CGI-Ex.svg?branch=master)](https://travis-ci.org/ljepson/CGI-Ex)

# CGI::Ex SYNOPSIS

    ### You probably don't want to use CGI::Ex directly
    ### You probably should use CGI::Ex::App instead.

    my $cgix = CGI::Ex->new;

    $cgix->print_content_type;

    my $hash = $cgix->form;

    if ($hash->{'bounce'}) {

        $cgix->set_cookie({
            name  => ...,
            value => ...,
        });

        $cgix->location_bounce($new_url_location);
        exit;
    }

    if (scalar keys %$form) {
         my $val_hash = $cgix->conf_read($pathtovalidation);
         my $err_obj = $cgix->validate($hash, $val_hash);
         if ($err_obj) {
             my $errors  = $err_obj->as_hash;
             my $input   = "Some content";
             my $content = "";
             $cgix->swap_template(\$input, $errors, $content);
             $cgix->fill({text => \$content, form => $hashref});
             print $content;
             exit;
         } else {
             print "Success";
         }
    } else {
         print "Main page";
    }

# DESCRIPTION

CGI::Ex provides a suite of utilities to make writing CGI scripts
more enjoyable.  Although they can all be used separately, the
main functionality of each of the modules is best represented in
the CGI::Ex::App module.  CGI::Ex::App takes CGI application building
to the next step.  CGI::Ex::App is not quite a framework (which normally
includes pre-built html) instead CGI::Ex::App is an extended application
flow that dramatically reduces CGI build time in most cases.  It does so
using as little magic as possible.  See [CGI::Ex::App](https://metacpan.org/pod/CGI::Ex::App).

The main functionality is provided by several other modules that
may be used separately, or together through the CGI::Ex interface.

- `CGI::Ex::Template`

    A Template::Toolkit compatible processing engine.  With a few limitations,
    CGI::Ex::Template can be a drop in replacement for Template::Toolkit.

- `CGI::Ex::Fill`

    A regular expression based form filler inner (accessed through **->fill**
    or directly via its own functions).  Can be a drop in replacement for
    HTML::FillInForm.  See [CGI::Ex::Fill](https://metacpan.org/pod/CGI::Ex::Fill) for more information.

- `CGI::Ex::Validate`

    A form field / cgi parameter / any parameter validator (accessed through
    **->validate** or directly via its own methods).  Not quite a drop in
    for most validators, although it has most of the functionality of most
    of the validators but with the key additions of conditional validation.
    Has a tightly integrated JavaScript portion that allows for duplicate client
    side validation.  See [CGI::Ex::Validate](https://metacpan.org/pod/CGI::Ex::Validate) for more information.

- `CGI::Ex::Conf`

    A general use configuration, or settings, or key / value file reader.  Has
    ability for providing key fallback as well as immutable key definitions.  Has
    default support for yaml, storable, perl, ini, and xml and open architecture
    for definition of others.  See [CGI::Ex::Conf](https://metacpan.org/pod/CGI::Ex::Conf) for more information.

- `CGI::Ex::Auth`

    A highly configurable web based authentication system.  See [CGI::Ex::Auth](https://metacpan.org/pod/CGI::Ex::Auth) for
    more information.

# CGI::Ex METHODS

- `->fill`

    fill is used for filling hash or cgi object values into an existing
    html document (it doesn't deal at all with how you got the document).
    Arguments may be given as a hash, or a hashref or positional.  Some
    of the following arguments will only work using CGI::Ex::Fill - most
    will work with either CGI::Ex::Fill or HTML::FillInForm (assume they
    are available unless specified otherwise).  (See [CGI::Ex::Fill](https://metacpan.org/pod/CGI::Ex::Fill) for
    a full explanation of functionality).  The arguments to fill are as
    follows (and in order of position):

    - `text`

        Text should be a reference to a scalar string containing the html to
        be modified (actually it could be any reference or object reference
        that can be modified as a string).  It will be modified in place.
        Another named argument **scalarref** is available if you would like to
        copy rather than modify.

    - `form`

        Form may be a hashref, a cgi style object, a coderef, or an array of
        multiple hashrefs, cgi objects, and coderefs.  Hashes should be key
        value pairs.  CGI objects should be able
        to call the method **param** (This can be overrided).  Coderefs should
        expect the field name as an argument and should return a value.
        Values returned by form may be undef, scalar, arrayref, or coderef
        (coderef values should expect an argument of field name and should
        return a value).  The code ref options are available to delay or add
        options to the bringing in of form information - without having to
        tie the hash.  Coderefs are not available in HTML::FillInForm.  Also
        HTML::FillInForm only allows CGI objects if an arrayref is used.

        NOTE: Only one of the form, fdat, and fobject arguments are allowed at
        a time.

    - `target`

        The name of the form that the fields should be filled to.  The default
        value of undef, means to fill in all forms in the html.

    - `fill_passwords`

        Boolean value defaults to 1.  If set to zero - password fields will
        not be filled.

    - `ignore_fields`

        Specify which fields to not fill in.  It takes either array ref of
        names, or a hashref with the names as keys.  The hashref option is
        not available in CGI::Ex::Fill.

    Other named arguments are available for compatibility with HTML::FillInForm.
    They may only be used as named arguments.

    - `scalarref`

        Almost the same as the argument text.  If scalarref is used, the filled
        html will be returned.  If text is used the html passed is filled in place.

    - `arrayref`

        An array ref of lines of the document.  Forces a returned filled html
        document.

    - `file`

        An filename that will be opened, filled, and returned.

    - `fdat`

        A hashref of key value pairs.

    - `fobject`

        A cgi style object or arrayref of cgi style objects used for getting
        the key value pairs.  Should be capable of the ->param method and
        \->cookie method as document in [CGI](https://metacpan.org/pod/CGI).

    See [CGI::Ex::Fill](https://metacpan.org/pod/CGI::Ex::Fill) for more information about the filling process.

- `->object`

    Returns the CGI object that is currently being used by CGI::Ex.  If none
    has been set it will automatically generate an object of type
    $PREFERRED\_CGI\_MODULE which defaults to **CGI**.

- `->validate`

    Validate has a wide range of options available. (See [CGI::Ex::Validate](https://metacpan.org/pod/CGI::Ex::Validate)
    for a full explanation of functionality).  Validate has two arguments:

    - `form`

        Can be either a hashref to be validated, or a CGI style object (which
        has the param method).

    - `val_hash`

        The val\_hash can be one of three items.  First, it can be a straight
        perl hashref containing the validation to be done.  Second, it can
        be a YAML document string.  Third, it can be the path to a file
        containing the validation.  The validation in a validation file will
        be read in depending upon file extension.

- `->get_form`

    Very similar to CGI->new->Vars except that arrays are returned as
    arrays.  Not sure why CGI didn't do this anyway (well - yes -
    legacy Perl 4 - but at some point things need to be updated).

        my $hash = $cgix->get_form;
        my $hash = $cgix->get_form(CGI->new);
        my $hash = get_form();
        my $hash = get_form(CGI->new);

- `->set_form`

    Allow for setting a custom form hash.  Useful for testing, or other
    purposes.

        $cgix->set_form(\%new_form);

- `->get_cookies`

    Returns a hash of all cookies.

        my $hash = $cgix->get_cookies;
        my $hash = $cgix->get_cookies(CGI->new);
        my $hash = get_cookies();
        my $hash = get_cookies(CGI->new);

- `->set_cookies`

    Allow for setting a custom cookies hash.  Useful for testing, or other
    purposes.

        $cgix->set_cookies(\%new_cookies);

- `->make_form`

    Takes a hash and returns a query\_string.  A second optional argument
    may contain an arrayref of keys to use from the hash in building the
    query\_string.  First argument is undef, it will use the form stored
    in itself as the hash.

- `->content_type`

    Can be called multiple times during the same session.  Will only
    print content-type once.  (Useful if you don't know if something
    else already printed content-type).  Calling this sends the Content-type
    header.  Trying to print ->content\_type is an error.  For clarity,
    the method ->print\_content\_type is available.

        $cgix->print_content_type;

        # OR
        $cgix->print_content_type('text/html');

        # OR
        $cgix->print_content_type('text/html', 'utf-8');

- `->set_cookie`

    Arguments are the same as those to CGI->new->cookie({}).
    Uses CGI's cookie method to create a cookie, but then, depending on
    if content has already been sent to the browser will either print
    a Set-cookie header, or will add a &lt;meta http-equiv='set-cookie'>
    tag (this is supported on most major browsers).  This is useful if
    you don't know if something else already printed content-type.

- `->location_bounce`

    Depending on if content has already been sent to the browser will either print
    a Location header, or will add a &lt;meta http-equiv='refresh'>
    tag (this is supported on all major browsers).  This is useful if
    you don't know if something else already printed content-type.  Takes
    single argument of a url.

- `->last_modified`

    Depending on if content has already been sent to the browser will either print
    a Last-Modified header, or will add a &lt;meta http-equiv='Last-Modified'>
    tag (this is supported on most major browsers).  This is useful if
    you don't know if something else already printed content-type.  Takes an
    argument of either a time (may be a CGI -expires style time) or a filename.

- `->expires`

    Depending on if content has already been sent to the browser will either print
    a Expires header, or will add a &lt;meta http-equiv='Expires'>
    tag (this is supported on most major browsers).  This is useful if
    you don't know if something else already printed content-type.  Takes an
    argument of a time (may be a CGI -expires style time).

- `->send_status`

    Send a custom status.  Works in both CGI and mod\_perl.  Arguments are
    a status code and the content (optional).

- `->send_header`

    Send a http header.  Works in both CGI and mod\_perl.  Arguments are
    a header name and the value for that header.

- `->print_js`

    Prints out a javascript file.  Does everything it can to make sure
    that the javascript will cache.  Takes either a full filename,
    or a shortened name which will be looked for in @INC. (ie /full/path/to/my.js
    or CGI/Ex/validate.js or CGI::Ex::validate)

        #!/usr/bin/perl
        use CGI::Ex;
        CGI::Ex->print_js($ENV{'PATH_INFO'});

- `->swap_template`

    This is intended as a simple yet strong subroutine to swap
    in tags to a document.  It is intended to be very basic
    for those who may not want the full features of a Templating
    system such as Template::Toolkit (even though they should
    investigate them because they are pretty nice).  The default allows
    for basic template toolkit variable swapping.  There are two arguments.
    First is a string or a reference to a string.  If a string is passed,
    a copy of that string is swapped and returned.  If a reference to a
    string is passed, it is modified in place.  The second argument is
    a form, or a CGI object, or a cgiex object, or a coderef (if the second
    argument is missing, the cgiex object which called the method will be
    used).  If it is a coderef, it should accept key as its only argument and
    return the proper value.

        my $cgix = CGI::Ex->new;
        my $form = {foo  => 'bar',
                    this => {is => {nested => ['wow', 'wee']}}
                   };

        my $str =  $cgix->swap_template("<html>[% foo %]<br>[% foo %]</html>", $form));
        # $str eq '<html>bar<br>bar</html>'

        $str = $cgix->swap_template("[% this.is.nested.1 %]", $form));
        # $str eq 'wee'

        $str = "[% this.is.nested.0 %]";
        $cgix->swap_template(\$str, $form);
        # $str eq 'wow'

        # may also be called with only one argument as follows:
        # assuming $cgix had a query string of ?foo=bar&baz=wow&this=wee
        $str = "<html>([% foo %]) <br>
                ([% baz %]) <br>
                ([% this %]) </html>";
        $cgix->swap_template(\$str);
        #$str eq "<html>(bar) <br>
        #        (wow) <br>
        #        (wee) </html>";

    For further examples, please see the code contained in t/samples/cgi\_ex\_\*
    of this distribution.

    If at a later date, the developer upgrades to Template::Toolkit, the
    templates that were being swapped by CGI::Ex::swap\_template should
    be compatible with Template::Toolkit.

# MODULES

See also [CGI::Ex::App](https://metacpan.org/pod/CGI::Ex::App).

See also [CGI::Ex::Auth](https://metacpan.org/pod/CGI::Ex::Auth).

See also [CGI::Ex::Conf](https://metacpan.org/pod/CGI::Ex::Conf).

See also [CGI::Ex::Die](https://metacpan.org/pod/CGI::Ex::Die).

See also [CGI::Ex::Dump](https://metacpan.org/pod/CGI::Ex::Dump).

See also [CGI::Ex::Fill](https://metacpan.org/pod/CGI::Ex::Fill).

See also [CGI::Ex::Template](https://metacpan.org/pod/CGI::Ex::Template).

See also [CGI::Ex::Validate](https://metacpan.org/pod/CGI::Ex::Validate).

# LICENSE

This module may be distributed under the same terms as Perl itself.

# AUTHOR

Paul Seamons &lt;perl at seamons dot com>
